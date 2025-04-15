#!/bin/bash

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Informationen Kopfzeile
#?──────────────────────────────────────────────────────────────────────────────────────────

tput reset # Bildschirmausgabe loeschen inklusive dem Scrollbereich.
SCRIPTNAME="opensimMULTITOOL II"
VERSION="V25.4.46.123"
echo -e "\e[36m$SCRIPTNAME\e[0m $VERSION"
echo "Dies ist ein Tool welches der Verwaltung von OpenSim Servern dient."
echo "Bitte beachten Sie, dass die Anwendung auf eigene Gefahr und Verantwortung erfolgt."
echo -e "\e[33mZum Abbrechen bitte STRG+C oder CTRL+C drücken.\e[0m"
echo " "

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Variablen setzen
#?──────────────────────────────────────────────────────────────────────────────────────────

# Hauptpfad des Skripts automatisch setzen
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR" || exit 1
echo "Das Arbeitsverzeichnis ist: $SCRIPT_DIR"
system_ip=$(hostname -I | awk '{print $1}')
echo "Ihre IP Adresse ist: $system_ip"; echo " "

KOMMANDO=$1 # Eingabeauswertung fuer Funktionen.
#MONEYCOPY="yes" # MoneyServer Installieren.

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Abhängigkeiten installieren
#?──────────────────────────────────────────────────────────────────────────────────────────

# Fehlende Abhängigkeiten installieren
function servercheck() {
    # Direkt kompatible Distributionen:
    # Debian 11+ (Bullseye, Bookworm) – Offiziell unterstützt für .NET 8
    # Ubuntu 18.04, 20.04, 22.04 – Microsoft bietet direkt kompatible Pakete
    # Linux Mint (basierend auf Ubuntu 20.04 oder 22.04)
    # Pop!_OS (System76, basiert auf Ubuntu)
    # MX Linux (Debian-basiert, integriert Ubuntu-Funktionen)
    # Arch Linux – Offiziell unterstützte Pakete über pacman
    # Manjaro – Bietet .NET-Pakete direkt über die Arch-Repositorys

    # Mögliche kompatible Distributionen (mit Anpassungen):
    # Kali Linux (basierend auf Debian 12, Anpassungen nötig für .NET-Pakete)
    # Zorin OS (Ubuntu-basiert, Unterstützung abhängig von Version)
    # elementary OS (Ubuntu-basiert, kann .NET aus Ubuntu-Quellen beziehen)
    # Raspberry Pi OS (Debian-basiert, erfordert manuelle Installation für .NET)

    # Ermitteln der Distribution und Version
    os_id=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    os_version=$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

    echo "Server läuft mit $os_id $os_version"

    # Prüfen, welche .NET-Version installiert werden muss
    if [[ "$os_id" == "ubuntu" || "$os_id" == "linuxmint" || "$os_id" == "pop_os" ]]; then
        if [[ "$os_version" == "22.04" || "$os_version" == "20.04" ]]; then
            required_dotnet="dotnet-sdk-8.0"
        elif [[ "$os_version" == "18.04" ]]; then
            required_dotnet="dotnet-sdk-6.0"
        fi
    elif [[ "$os_id" == "debian" && "$os_version" -ge "11" ]]; then
        required_dotnet="dotnet-sdk-8.0"
    elif [[ "$os_id" == "arch" || "$os_id" == "manjaro" ]]; then
        required_dotnet="dotnet-sdk-8.0"  # Spezifiziert gezielt Version 8.0
    else
        echo "✘ Keine unterstützte Version für .NET gefunden!"
        return 1
    fi

    # Prüfen, ob die richtige .NET-Version bereits installiert ist
    if [[ "$os_id" == "arch" || "$os_id" == "manjaro" ]]; then
        if ! pacman -Qi "$required_dotnet" >/dev/null 2>&1; then
            echo "Installiere $required_dotnet..."
            sudo pacman -S --noconfirm "$required_dotnet"
            echo "✓ $required_dotnet wurde erfolgreich installiert."
        else
            echo "✘ $required_dotnet ist bereits installiert."
        fi
    else
        if ! dpkg -s "$required_dotnet" >/dev/null 2>&1; then
            echo "Installiere $required_dotnet..."
            sudo apt-get install -y "$required_dotnet"
            echo "✓ $required_dotnet wurde erfolgreich installiert."
        else
            echo "✘ $required_dotnet ist bereits installiert."
        fi
    fi

    # Fehlende Pakete prüfen und installieren
    required_packages=("libc6" "libgcc-s1" "libgssapi-krb5-2" "libicu70" "liblttng-ust1" "libssl3" "libstdc++6" "libunwind8" "zlib1g" "libgdiplus" "zip" "screen")

    echo "Überprüfe fehlende Pakete..."
    for package in "${required_packages[@]}"; do
        if [[ "$os_id" == "arch" || "$os_id" == "manjaro" ]]; then
            if ! pacman -Qi "$package" >/dev/null 2>&1; then
                echo "✓ Installiere $package..."
                sudo pacman -S --noconfirm "$package"
            fi
        else
            if ! dpkg -s "$package" >/dev/null 2>&1; then
                echo "✓ Installiere $package..."
                sudo apt-get install -y "$package"
            fi
        fi
    done

    echo "✓ Alle benötigten Pakete wurden installiert."
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Start Stop Standalone
#?──────────────────────────────────────────────────────────────────────────────────────────

function standalonestart() {
    cd opensim/bin || exit 1
    screen -fa -S opensim -d -U -m dotnet OpenSim.dll
}

function standalonestop() {
    screen -S opensim -p 0 -X stuff "shutdown^M"
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Start Stop Grid
#?──────────────────────────────────────────────────────────────────────────────────────────

# OpenSim starten (robust → money → sim1 bis sim999)
function opensimstart() {
    echo -e "\e[32m"
    # Prüfen, ob das Verzeichnis "robust/bin" existiert und Robust.dll vorhanden ist
    if [[ -d "robust/bin" && -f "robust/bin/Robust.dll" ]]; then
        echo "✓ Starte RobustServer aus robust/bin..."
        cd robust/bin || exit 1
        screen -fa -S robustserver -d -U -m dotnet Robust.dll
        cd - >/dev/null 2>&1 || exit 1 # Zurück zum ursprünglichen Verzeichnis
        sleep 30
    else
        echo "✘ Robust.dll wurde nicht gefunden. Überspringe RobustServer."
    fi

    # Prüfen, ob MoneyServer.dll vorhanden ist
    if [[ -f "robust/bin/MoneyServer.dll" ]]; then
        echo "✓ Starte MoneyServer aus robust/bin..."
        cd robust/bin || exit 1
        screen -fa -S moneyserver -d -U -m dotnet MoneyServer.dll
        cd - >/dev/null 2>&1 || exit 1 # Zurück zum ursprünglichen Verzeichnis
        sleep 30
    else
        echo "✘ MoneyServer.dll wurde nicht gefunden. Überspringe MoneyServer."
    fi

    # Alle simX-Server starten (sim1 bis sim999)
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" && -f "$sim_dir/OpenSim.dll" ]]; then
            echo "✓ Starte sim$i aus $sim_dir..."
            cd "$sim_dir" || continue
            screen -fa -S "sim$i" -d -U -m dotnet OpenSim.dll
            cd - >/dev/null 2>&1 || continue # Zurück zum ursprünglichen Verzeichnis
            sleep 20
        fi
    done
    echo -e "\e[0m"
}

# OpenSim stoppen (sim999 bis sim1 → money → robust)
function opensimstop() {
    echo -e "\e[35m"    
    echo "✓ Stoppe alle sim Regionen..."
    for ((i=999; i>=1; i--)); do
        sim_dir="sim$i"
        if screen -list | grep -q "$sim_dir"; then
            screen -S "sim$i" -p 0 -X stuff "shutdown^M"
            echo "✓ sim$i wird heruntergefahren..."
            sleep 15
        fi
    done

    # Prüfen, ob MoneyServer läuft, bevor er gestoppt wird
    if screen -list | grep -q "moneyserver"; then
        echo "✓ Stoppe MoneyServer..."
        screen -S moneyserver -p 0 -X stuff "shutdown^M"
        sleep 30
    else
        echo "✘ MoneyServer läuft nicht. Überspringe Stoppvorgang."
    fi

    # Prüfen, ob RobustServer läuft, bevor er gestoppt wird
    if screen -list | grep -q "robust"; then
        echo "✓ Stoppe RobustServer..."
        screen -S robustserver -p 0 -X stuff "shutdown^M"
        sleep 30
    else
        echo "✘ RobustServer läuft nicht. Überspringe Stoppvorgang."
    fi
    echo -e "\e[0m"
}

# check_screens ist eine Grid Funktion und funktioniert nicht im Standalone.
function check_screens() {
    # echo "Überprüfung der laufenden OpenSim-Prozesse..."

    restart_all=false

    # Überprüfen, ob RobustServer läuft
    if [[ -d "robust/bin" && -f "robust/bin/Robust.dll" ]]; then
        screenRO=$(screen -ls | grep -w "robustserver")
        if [[ -z "$screenRO" ]]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - RobustServer läuft nicht und muss neu gestartet werden." >> ProblemRestarts.log
            restart_all=true
        fi
    fi

    # Überprüfen, ob MoneyServer läuft
    if [[ -d "robust/bin" && -f "robust/bin/MoneyServer.dll" ]];then
        screenMoney=$(screen -ls | grep -w "moneyserver")
        if [[ -z "$screenMoney" ]]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - MoneyServer läuft nicht und muss neu gestartet werden." >> ProblemRestarts.log
            restart_all=true
        fi
    fi

    # Überprüfen, ob sim1 läuft
    if [[ -d "sim1/bin" && -f "sim1/bin/OpenSim.dll" ]]; then
        screenSim1=$(screen -ls | grep -w "sim1")
        if [[ -z "$screenSim1" ]]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - Sim1 läuft nicht und muss neu gestartet werden." >> ProblemRestarts.log
            restart_all=true
        fi
    fi

    # Falls eines der kritischen Systeme ausgefallen ist, alles neu starten
    if [[ "$restart_all" == true ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Kritische Prozesse sind ausgefallen! OpenSim wird komplett neu gestartet." >> ProblemRestarts.log
        # opensimstart
        opensimrestart
        return 0
    fi

    # Überprüfen, ob andere simulierte Regionen (sim2 bis sim999) einzeln neu gestartet werden müssen
    for ((i=2; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" && -f "$sim_dir/OpenSim.dll" ]]; then
            screenSim=$(screen -ls | grep -w "sim$i")
            if [[ -z "$screenSim" ]]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Sim$i läuft nicht und wird einzeln neu gestartet." >> ProblemRestarts.log
                cd "$sim_dir" || continue
                screen -fa -S "sim$i" -d -U -m dotnet OpenSim.dll
                cd - >/dev/null 2>&1 || continue
                sleep 20
            fi
        fi
    done
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Erstellen eines OpenSimulators
#?──────────────────────────────────────────────────────────────────────────────────────────

function opensimgit() {
    echo "Möchten Sie den OpenSimulator vom GitHub verwenden oder aktualisieren? ([upgrade]/new)"
    read -r user_choice
    user_choice=${user_choice:-upgrade}

    if [[ "$user_choice" == "new" ]]; then
        # Falls eine alte Version existiert, wird sie gelöscht
        if [[ -d "opensim" ]]; then
            echo "Vorhandene OpenSimulator-Version wird gelöscht..."
            rm -rf opensim
            echo "✓ Alte OpenSimulator-Version wurde erfolgreich entfernt."
        fi

        echo "OpenSimulator wird von GitHub geholt..."
        git clone git://opensimulator.org/git/opensim opensim
        echo "✓ OpenSimulator wurde erfolgreich heruntergeladen."

    elif [[ "$user_choice" == "upgrade" ]]; then
        if [[ -d "opensim/.git" ]]; then
            echo "✓ Repository gefunden. Aktualisiere mit 'git pull'..."
            cd opensim || { echo "✘ Fehler: Kann nicht ins Verzeichnis wechseln!"; return 1; }
            git pull origin master && echo "✅ OpenSimulator erfolgreich aktualisiert!"
            cd ..
        else
            echo "⚠ OpenSimulator-Verzeichnis nicht gefunden. Klone Repository neu..."
            git clone git://opensimulator.org/git/opensim opensim && echo "✅ OpenSimulator erfolgreich heruntergeladen!"
        fi
    else
        echo "✘ Abbruch: Keine Aktion durchgeführt."
        return 1
    fi

    # .NET-Version auswählen
    echo "Möchten Sie diese Version mit .NET 6 oder .NET 8 betreiben? ([8]/6)"
    read -r dotnet_version
    dotnet_version=${dotnet_version:-8}

    if [[ "$dotnet_version" == "6" ]]; then
        echo "Wechsle zu .NET 6-Version..."
        cd opensim || { echo "Fehler: Verzeichnis 'opensim' nicht gefunden."; return 1; }
        git checkout dotnet6
        echo "✓ OpenSimulator wurde für .NET 6 umgebaut."
    else
        echo "✓ Standardmäßig wird .NET 8 verwendet."
    fi
}

function moneygit() {
    echo "Möchten Sie den MoneyServer vom GitHub verwenden oder aktualisieren? ([upgrade]/new)"
    read -r user_choice
    user_choice=${user_choice:-upgrade}

    if [[ "$user_choice" == "new" ]]; then
        if [[ -d "opensimcurrencyserver" ]]; then
            echo "Vorhandene MoneyServer-Version wird gelöscht..."
            rm -rf opensimcurrencyserver
            echo "✓ Alte MoneyServer-Version wurde erfolgreich entfernt."
        fi
        echo "MONEYSERVER: MoneyServer wird vom GIT geholt..."
        git clone https://github.com/ManfredAabye/opensimcurrencyserver-dotnet.git opensimcurrencyserver
        echo "✓ MoneyServer wurde erfolgreich heruntergeladen."
    elif [[ "$user_choice" == "upgrade" ]]; then
        if [[ -d "opensimcurrencyserver/.git" ]]; then
            echo "✓ Repository gefunden. Aktualisiere mit 'git pull'..."
            cd opensimcurrencyserver || { echo "✘ Fehler: Kann nicht ins Verzeichnis wechseln!"; return 1; }
            
            # Automatische Branch-Erkennung
            branch_name=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
            git pull origin "$branch_name" && echo "✅ MoneyServer erfolgreich aktualisiert!"
            
            cd ..
        else
            echo "⚠ MoneyServer-Verzeichnis nicht gefunden. Klone Repository neu..."
            git clone https://github.com/ManfredAabye/opensimcurrencyserver-dotnet.git opensimcurrencyserver && echo "✅ MoneyServer erfolgreich heruntergeladen!"
        fi
    else
        echo "✘ Abbruch: Keine Aktion durchgeführt."
        return 1
    fi

    # Prüfen, ob das Verzeichnis existiert, bevor es kopiert wird
    if [[ -d "opensimcurrencyserver/addon-modules" ]]; then
        cp -r opensimcurrencyserver/addon-modules opensim/
        echo "✓ MONEYSERVER: addon-modules wurde nach opensim kopiert"
    else
        echo "✘ MONEYSERVER: addon-modules existiert nicht"
    fi

    if [[ -d "opensimcurrencyserver/bin" ]]; then
        cp -r opensimcurrencyserver/bin opensim/
        echo "✓ MONEYSERVER: bin wurde nach opensim kopiert"
    else
        echo "✘ MONEYSERVER: bin existiert nicht"
    fi

    return 0
}

function ruthrothgit() {
    echo "Möchten Sie die Ruth2 und Roth2 Avatare neu klonen oder aktualisieren? ([upgrade]/new)"
    read -r user_choice
    user_choice=${user_choice:-upgrade}

    declare -A repos=(
        ["Ruth2"]="https://github.com/ManfredAabye/Ruth2.git"
        ["Roth2"]="https://github.com/ManfredAabye/Roth2.git"
    )

    for avatar in "${!repos[@]}"; do
        repo_url="${repos[$avatar]}"
        target_dir="$avatar"

        echo "➤ Bearbeite $avatar..."

        if [[ "$user_choice" == "new" ]]; then
            if [[ -d "$target_dir" ]]; then
                echo "  ➜ Alte Version von $avatar wird gelöscht..."
                rm -rf "$target_dir"
            fi
            echo "  ➜ Klone $avatar von GitHub..."
            git clone "$repo_url" "$target_dir" && echo "  ✅ $avatar wurde neu heruntergeladen."
        elif [[ "$user_choice" == "upgrade" ]]; then
            if [[ -d "$target_dir/.git" ]]; then
                echo "  ➜ Aktualisiere $avatar mit git pull..."
                cd "$target_dir" || { echo "✘ Fehler beim Wechsel in $target_dir"; continue; }
                branch_name=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
                git pull origin "$branch_name" && echo "  ✅ $avatar wurde aktualisiert."
                cd ..
            else
                echo "  ⚠ Verzeichnis $target_dir existiert nicht oder ist kein Git-Repo. Klone neu..."
                git clone "$repo_url" "$target_dir" && echo "  ✅ $avatar wurde neu heruntergeladen."
            fi
        else
            echo "✘ Ungültige Eingabe. Abbruch."
            return 1
        fi

        # IAR-Dateien kopieren
        echo "  ➜ Kopiere IAR-Dateien nach opensim/bin/Library..."

        if [[ "$avatar" == "Ruth2" ]]; then
            cp "$target_dir/Artifacts/IAR/Ruth2-v3.iar" opensim/bin/Library/ 2>/dev/null && echo "    ✓ Ruth2-v3.iar kopiert"
            cp "$target_dir/Artifacts/IAR/Ruth2-v4.iar" opensim/bin/Library/ 2>/dev/null && echo "    ✓ Ruth2-v4.iar kopiert"
        elif [[ "$avatar" == "Roth2" ]]; then
            cp "$target_dir/Artifacts/IAR/Roth2-v1.iar" opensim/bin/Library/ 2>/dev/null && echo "    ✓ Roth2-v1.iar kopiert"
            cp "$target_dir/Artifacts/IAR/Roth2-v2.iar" opensim/bin/Library/ 2>/dev/null && echo "    ✓ Roth2-v2.iar kopiert"
        fi
    done

    echo "✅ Alle Avatar-IAR-Dateien wurden verarbeitet."
    return 0
}

function avatarassetsgit() {
    local base_dir
    base_dir=$(pwd)

    # Repos als normaler String-Array (keine assoziativen Arrays!)
    local repo_data
    repo_data=(
        "https://github.com/ManfredAabye/Ruth2.git|Ruth2|Ruth2-v3.iar Ruth2-v4.iar"
        "https://github.com/ManfredAabye/Roth2.git|Roth2|Roth2-v1.iar Roth2-v2.iar"
    )

    for entry in "${repo_data[@]}"; do
        IFS='|' read -r repo_url repo_dir iar_files <<< "$entry"

        echo "📦 Klone Repository: $repo_url"
        if [[ -d "$repo_dir" ]]; then
            echo "🔁 Repository $repo_dir existiert bereits. Aktualisiere mit 'git pull'..."
            cd "$repo_dir" || { echo "✘ Fehler beim Wechsel in $repo_dir"; continue; }
            git pull
            cd "$base_dir" || exit
        else
            git clone "$repo_url" "$repo_dir" || { echo "✘ Fehler beim Klonen von $repo_url"; continue; }
        fi

        for iar in $iar_files; do
            local iar_path="$repo_dir/Artifacts/IAR/$iar"
            if [[ ! -f "$iar_path" ]]; then
                echo "⚠ IAR-Datei $iar_path nicht gefunden. Überspringe..."
                continue
            fi

            echo "🧩 Verarbeite $iar"
            mkdir -p temp_iar_extract
            tar -xzf "$iar_path" -C temp_iar_extract

            if [[ -d temp_iar_extract/assets ]]; then
                mkdir -p "opensim/bin/assets/${iar%.iar}"
                cp -r temp_iar_extract/assets/* "opensim/bin/assets/${iar%.iar}/"
                echo "✓ Assets kopiert nach opensim/bin/assets/${iar%.iar}"
            fi

            if [[ -d temp_iar_extract/inventory ]]; then
                mkdir -p "opensim/bin/inventory/${iar%.iar}"
                cp -r temp_iar_extract/inventory/* "opensim/bin/inventory/${iar%.iar}/"
                echo "✓ Inventory kopiert nach opensim/bin/inventory/${iar%.iar}"
            fi

            rm -rf temp_iar_extract
        done
    done

    echo "✅ Roth2 + Ruth2 Avatare wurden erfolgreich integriert."
}

function osslscriptsgit() {
    echo "Möchten Sie die OpenSim OSSL Beispiel-Skripte vom GitHub verwenden oder aktualisieren? ([upgrade]/new)"
    read -r user_choice
    user_choice=${user_choice:-upgrade}

    repo_name="opensim-ossl-example-scripts"
    repo_url="https://github.com/ManfredAabye/opensim-ossl-example-scripts.git"

    if [[ "$user_choice" == "new" ]]; then
        if [[ -d "$repo_name" ]]; then
            echo "Vorhandene Version wird gelöscht..."
            rm -rf "$repo_name"
            echo "✓ Alte Version wurde erfolgreich entfernt."
        fi
        echo "Beispiel-Skripte werden vom GitHub heruntergeladen..."
        git clone "$repo_url" "$repo_name" && echo "✓ Repository wurde erfolgreich heruntergeladen."
    elif [[ "$user_choice" == "upgrade" ]]; then
        if [[ -d "$repo_name/.git" ]]; then
            echo "✓ Repository gefunden. Aktualisiere mit 'git pull'..."
            cd "$repo_name" || { echo "✘ Fehler beim Wechsel ins Verzeichnis!"; return 1; }
            branch_name=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
            git pull origin "$branch_name" && echo "✅ Repository erfolgreich aktualisiert."
            cd ..
        else
            echo "⚠ Verzeichnis nicht gefunden oder kein Git-Repo. Klone Repository neu..."
            git clone "$repo_url" "$repo_name" && echo "✅ Repository wurde erfolgreich heruntergeladen."
        fi
    else
        echo "✘ Abbruch: Keine Aktion durchgeführt."
        return 1
    fi

    # Zielverzeichnisse erstellen falls nicht vorhanden
    mkdir -p opensim/bin/assets/
    mkdir -p opensim/bin/inventory/

    # Kopieren der Verzeichnisse
    if [[ -d "$repo_name/ScriptsAssetSet" ]]; then
        cp -r "$repo_name/ScriptsAssetSet" opensim/bin/assets/
        echo "✓ ScriptsAssetSet wurde nach opensim/bin/assets kopiert."
    else
        echo "✘ ScriptsAssetSet Verzeichnis nicht gefunden!"
    fi

    if [[ -d "$repo_name/inventory/ScriptsLibrary" ]]; then
        cp -r "$repo_name/inventory/ScriptsLibrary" opensim/bin/inventory/
        echo "✓ ScriptsLibrary wurde nach opensim/bin/inventory kopiert."
    else
        echo "✘ ScriptsLibrary Verzeichnis nicht gefunden!"
    fi

    return 0
}

function pbrtexturesgit() {
    textures_zip_url="https://github.com/ManfredAabye/OpenSim_PBR_Textures/releases/download/PBR/OpenSim_PBR_Textures.zip"
    zip_file="OpenSim_PBR_Textures.zip"
    unpacked_dir="OpenSim_PBR_Textures"
    target_dir="opensim"

    # ZIP herunterladen, wenn nicht vorhanden
    if [[ ! -f "$zip_file" ]]; then
        echo "Lade OpenSim PBR Texturen herunter..."
        if ! wget -q --show-progress -O "$zip_file" "$textures_zip_url"; then
            echo "✘ Fehler beim Herunterladen der Texturen!"
            return 1
        fi
        echo "✓ Download abgeschlossen: $zip_file"
    else
        echo "✓ ZIP-Datei bereits vorhanden: $zip_file"
    fi

    # Entpacken, wenn Verzeichnis noch nicht existiert
    if [[ ! -d "$unpacked_dir" ]]; then
        echo "Entpacke Texturen nach $unpacked_dir ..."
        unzip -q "$zip_file" -d .
        echo "✓ Entpackt."
    else
        echo "✓ Verzeichnis $unpacked_dir existiert bereits – überspringe Entpacken."
    fi

    # Kopieren nach opensim/bin
    if [[ -d "$unpacked_dir/bin" ]]; then
        echo "Kopiere Texturen nach $target_dir ..."
        cp -r "$unpacked_dir/bin" "$target_dir"
        echo "✓ Texturen erfolgreich installiert in $target_dir"
    else
        echo "✘ Verzeichnis $unpacked_dir/bin nicht gefunden!"
        return 1
    fi

    return 0
}

function opensimbuild() {
    echo "Möchten Sie den OpenSimulator jetzt erstellen? ([ja]/nein)"
    read -r user_choice

    user_choice=${user_choice:-ja}

    if [[ "$user_choice" == "ja" ]]; then
        if [[ -d "opensim" ]]; then
            cd opensim || { echo "Fehler: Verzeichnis 'opensim' nicht gefunden."; return 1; }
            echo "Starte Prebuild-Skript..."
            bash runprebuild.sh
            echo "Baue OpenSimulator..."
            dotnet build --configuration Release OpenSim.sln
            echo "✓ OpenSimulator wurde erfolgreich erstellt."
        else
            echo "✘ Fehler: Das Verzeichnis 'opensim' existiert nicht."
            return 1
        fi
    else
        echo "✘ Abbruch: OpenSimulator wird nicht erstellt."
    fi
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Erstellen eines OpenSimulators Grids
#?──────────────────────────────────────────────────────────────────────────────────────────

function createdirectory () {
    echo "Möchten Sie einen Gridserver oder einen Regionsserver erstellen? ([grid]/region)"
    read -r server_type

    # Standardmäßig Gridserver wählen, falls keine Eingabe erfolgt
    server_type=${server_type:-grid}

    if [[ "$server_type" == "grid" ]]; then
        echo "Erstelle robust Verzeichnis..."
        mkdir -p robust/bin
        echo "✓ Robust Verzeichnis wurde erstellt."

        # Nach der Erstellung des Gridservers auch die Regionsserver erstellen lassen
        echo "Wie viele Regionsserver benötigen Sie?"
        read -r num_regions
    elif [[ "$server_type" == "region" ]]; then
        echo "Wie viele Regionsserver benötigen Sie?"
        read -r num_regions
    else
        echo "✘ Ungültige Eingabe. Bitte geben Sie 'grid' oder 'region' ein."
        return 1
    fi

    # Überprüfen, ob die Anzahl der Regionsserver bis 999 geht
    if [[ "$num_regions" =~ ^[0-9]+$ && "$num_regions" -le 999 ]]; then
        for ((i=1; i<=num_regions; i++)); do
            dir_name="sim$i"
            if [[ ! -d "$dir_name" ]]; then
                mkdir -p "$dir_name/bin"
                echo "$dir_name wurde erstellt."
            else
                echo "$dir_name existiert bereits und wird übersprungen."
            fi
        done
    else
        echo "✘ Ungültige Anzahl an Regionsserver. Bitte geben Sie eine gültige Zahl zwischen 1 und 999 ein."
    fi
}

function opensimcopy () {
    echo -e "\e[32m"
    # Prüfen, ob das Verzeichnis "opensim" existiert
    if [[ ! -d "opensim" ]]; then
        echo "✘ Fehler: Das Verzeichnis 'opensim' existiert nicht."
        return 1
    fi

    # Prüfen, ob das Unterverzeichnis "opensim/bin" existiert
    if [[ ! -d "opensim/bin" ]]; then
        echo "✘ Fehler: Das Verzeichnis 'opensim/bin' existiert nicht."
        return 1
    fi

    # Prüfen, ob das Verzeichnis "robust" existiert und Dateien kopieren
    if [[ -d "robust/bin" ]]; then
        cp -r opensim/bin/* robust/bin
        echo "✓ Dateien aus 'opensim/bin' wurden nach 'robust/bin' kopiert."
    else
        echo "✘ Hinweis: 'robust' Verzeichnis nicht gefunden, keine Kopie durchgeführt."
    fi

    # Alle simX-Verzeichnisse suchen und Dateien kopieren
    for sim_dir in sim*; do
        if [[ -d "$sim_dir/bin" ]]; then
            cp -r opensim/bin/* "$sim_dir/bin/"
            echo "✓ Dateien aus 'opensim/bin' wurden nach '$sim_dir/bin' kopiert."
        fi
    done

    echo -e "\e[0m"
}

function mariasetup() {
    echo -e "\033[32m"
    
    # 1. Prüfen ob MariaDB installiert ist
    if ! command -v mariadb &> /dev/null && ! command -v mysql &> /dev/null; then
        echo -e "\033[33mMariaDB ist nicht installiert.\033[0m"
        echo "Möchten Sie MariaDB installieren? (j/n) " 
        read -r install_choice
        
        if [[ "$install_choice" =~ ^[jJ] ]]; then
            echo "Installiere MariaDB..."
            
            # Distro-spezifische Installation
            if [[ -f /etc/debian_version ]]; then
                sudo apt-get update
                sudo apt-get install -y mariadb-server
            elif [[ -f /etc/redhat-release ]]; then
                sudo yum install -y mariadb-server
                sudo systemctl start mariadb
                sudo systemctl enable mariadb
            else
                echo "Nicht unterstütztes Betriebssystem für automatische Installation"
                return 1
            fi
            
            # Sichere Installation durchführen
            sudo mysql_secure_installation
        else
            echo "Installation abgebrochen."
            return 0
        fi
    else
        echo "MariaDB ist bereits installiert."
    fi
    
    # 2. Datenbanken anlegen für vorhandene Server
    echo "Erstelle Datenbanken für vorhandene Server..."
    
    # Für RobustServer
    if [[ -d "robust" ]]; then
        echo "Erstelle Datenbank 'robust'..."
        sudo mysql -e "CREATE DATABASE IF NOT EXISTS robust;"
        sudo mysql -e "GRANT ALL PRIVILEGES ON robust.* TO 'robustuser'@'localhost' IDENTIFIED BY 'robustpassword';"
        sudo mysql -e "FLUSH PRIVILEGES;"
    fi
    
    # Für alle simX Server
    for ((i=1; i<=999; i++)); do
        if [[ -d "sim$i" ]]; then
            db_name="sim$i"
            echo "Erstelle Datenbank '$db_name'..."
            sudo mysql -e "CREATE DATABASE IF NOT EXISTS $db_name;"
            sudo mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO 'simuser'@'localhost' IDENTIFIED BY 'simpassword';"
            sudo mysql -e "FLUSH PRIVILEGES;"
        fi
    done
    
    echo -e "\n\033[32mDatenbankeinrichtung abgeschlossen!\033[0m"
    echo -e "Zusammenfassung der erstellten Datenbanken:"
    sudo mysql -e "SHOW DATABASES LIKE 'robust';"
    sudo mysql -e "SHOW DATABASES LIKE 'sim%';"
    echo -e "\033[0m"
}

function sqlsetup() {
    echo -e "\033[32m"
    
    # 1. Distribution Detection
    detect_distro() {
        if [[ -f /etc/os-release ]]; then
            awk -F= '/^ID=/ {print $2}' /etc/os-release | tr -d '"'
        elif [[ -f /etc/debian_version ]]; then
            echo "debian"
        elif [[ -f /etc/centos-release ]]; then
            echo "centos"
        else
            echo "unknown"
        fi
    }

    current_distro=$(detect_distro)
    supported_distros=("debian" "ubuntu" "linuxmint" "pop" "mx" "kali" "zorin" "elementary" "raspbian")

    if ! printf '%s\n' "${supported_distros[@]}" | grep -q "^$current_distro$"; then
        echo -e "\033[31mNicht unterstützte Distribution: $current_distro\033[0m"
        return 1
    fi

    # 2. MariaDB Installation Check
    if ! command -v mariadb &> /dev/null && ! command -v mysql &> /dev/null; then
        echo -e "\033[33mMariaDB ist nicht installiert.\033[0m"
        echo "Möchten Sie MariaDB installieren? (j/n) " 
        read -r install_choice
        
        if [[ "$install_choice" =~ ^[jJ] ]]; then
            echo "Installiere MariaDB für $current_distro..."
            
            case $current_distro in
                debian|ubuntu|linuxmint|pop|zorin|elementary|kali|mx)
                    sudo apt-get update
                    sudo apt-get install -y mariadb-server
                    ;;
                raspbian)
                    sudo apt-get update
                    sudo apt-get install -y mariadb-server-10.5
                    ;;
                *)
                    echo "Automatische Installation für $current_distro nicht verfügbar"
                    return 1
                    ;;
            esac
            
            # Secure Installation
            echo -e "\033[34mFühre sichere Installation durch...\033[0m"
            sudo mysql_secure_installation
        else
            echo "Installation abgebrochen."
            return 0
        fi
    else
        echo "MariaDB ist bereits installiert."
    fi
    
    # 3. Database Setup with Secure Random Passwords
    echo "Erstelle Datenbanken für vorhandene Server..."
    
    generate_password() {
        tr -dc 'A-Za-z0-9!@#$%^&*()' < /dev/urandom | head -c 16
    }
    
    # RobustServer DB
    if [[ -d "robust" ]]; then
        robust_pw=$(generate_password)
        echo "Erstelle Datenbank 'robust'..."
        sudo mysql -e "CREATE DATABASE IF NOT EXISTS robust;"
        sudo mysql -e "CREATE USER IF NOT EXISTS 'robustuser'@'localhost' IDENTIFIED BY '$robust_pw';"
        sudo mysql -e "GRANT ALL PRIVILEGES ON robust.* TO 'robustuser'@'localhost';"
        sudo mysql -e "FLUSH PRIVILEGES;"
        echo -e "\033[34mRobust DB Passwort: $robust_pw\033[0m"
    fi
    
    # simX Server DBs
    for ((i=1; i<=999; i++)); do
        if [[ -d "sim$i" ]]; then
            sim_pw=$(generate_password)
            db_name="sim$i"
            echo "Erstelle Datenbank '$db_name'..."
            sudo mysql -e "CREATE DATABASE IF NOT EXISTS $db_name;"
            sudo mysql -e "CREATE USER IF NOT EXISTS 'sim${i}user'@'localhost' IDENTIFIED BY '$sim_pw';"
            sudo mysql -e "GRANT ALL PRIVILEGES ON $db_name.* TO 'sim${i}user'@'localhost';"
            sudo mysql -e "FLUSH PRIVILEGES;"
            echo -e "\033[34mSim$i DB Passwort: $sim_pw\033[0m"
        fi
    done
    
    # 4. Post-Install Check
    echo -e "\n\033[32mDatenbankeinrichtung abgeschlossen!\033[0m"
    echo -e "Zusammenfassung:"
    sudo mysql -e "SELECT User, Host FROM mysql.user WHERE User LIKE 'robustuser' OR User LIKE 'sim%';"
    sudo mysql -e "SHOW DATABASES LIKE 'robust'; SHOW DATABASES LIKE 'sim%';"
    
    # Save passwords securely
    if [[ -d "robust" ]]; then
        echo "robust DB Passwort: $robust_pw" | sudo tee "$SCRIPT_DIR"/mariadb_passwords.txt >/dev/null
    fi
    for ((i=1; i<=999; i++)); do
        if [[ -d "sim$i" ]]; then
            echo "sim$i DB Passwort: $sim_pw" | sudo tee -a "$SCRIPT_DIR"/mariadb_passwords.txt >/dev/null
        fi
    done
    
    echo -e "\n\033[33mPasswörter wurden in $SCRIPT_DIR/mariadb_passwords.txt gespeichert\033[0m"
    echo -e "\033[0m"
}

setcrontab() {
    # Strict Mode: Fehler sofort erkennen
    set -euo pipefail

    # Sicherheitsabfrage: Nur als root/sudo ausführen
    if [ "$(id -u)" -ne 0 ]; then
        echo >&2 "FEHLER: Dieses Skript benötigt root-Rechte! (sudo verwenden)"
        return 1
    fi

    # Prüfen, ob SCRIPT_DIR gesetzt und gültig ist
    if [ -z "${SCRIPT_DIR:-}" ]; then
        echo >&2 "FEHLER: 'SCRIPT_DIR' muss gesetzt sein!"
        return 1
    fi

    if [ ! -d "$SCRIPT_DIR" ]; then
        echo >&2 "FEHLER: Verzeichnis '$SCRIPT_DIR' existiert nicht!"
        return 1
    fi

    # Temporäre Datei für neue Cron-Jobs
    local temp_cron
    temp_cron=$(mktemp) || {
        echo >&2 "FEHLER: Temp-Datei konnte nicht erstellt werden"
        return 1
    }

    # Neue Cron-Jobs schreiben (ERSETZT alle alten)
    cat << EOF > "$temp_cron"
# === OpenSimGrid-Automatisierung ===
# Minute Stunde Tag Monat Jahr Befehl

# Server-Neustart am 1. jedes Monats
40 4 1 * * bash '$SCRIPT_DIR/osmtool.sh' cacheclean
45 4 1 * * bash '$SCRIPT_DIR/osmtool.sh' reboot

# Taegliche Wartung
55 4 * * * bash '$SCRIPT_DIR/osmtool.sh' logclean
0 5 * * * bash '$SCRIPT_DIR/osmtool.sh' autorestart

# Ueberwachung alle 30 Minuten
*/30 * * * * bash '$SCRIPT_DIR/osmtool.sh' check_screens
EOF

    # Cron-Jobs installieren
    if crontab "$temp_cron"; then
        rm -f "$temp_cron"
        echo "Cron-Jobs wurden ERFOLGREICH ersetzt:"
        crontab -l | grep -v '^#' | sed '/^$/d'
        return 0
    else
        echo >&2 "FEHLER: Installation fehlgeschlagen. Prüfe $temp_cron manuell."
        return 1
    fi
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Upgrade des OpenSimulators Grids
#?──────────────────────────────────────────────────────────────────────────────────────────

# Upgrade ist eigentlich nur ein entpacken eines OpenSimulator und umbenennen des Ordners in opensim.
# Dann das stoppen des Grids, neues OpenSim kopieren und alles neu starten.

function opensimupgrade() {
    echo -e "\n\033[33mDer OpenSimulator muss zuerst im Verzeichnis 'opensim' vorliegen!\033[0m"
    echo "Möchten Sie den OpenSimulator aktualisieren? ([no]/yes)"
    read -r user_choice
    user_choice=${user_choice:-no}

    # Prüfe, ob das Verzeichnis vorhanden ist
    if [[ ! -d "opensim" ]]; then
        echo -e "\033[31m❗Fehler: Das Verzeichnis 'opensim' existiert nicht\033[0m"
        return 1
    fi

    # Prüfe, ob im Verzeichnis 'opensim/bin' die Dateien OpenSim.dll und Robust.dll vorhanden sind
    if [[ ! -f "opensim/bin/OpenSim.dll" || ! -f "opensim/bin/Robust.dll" ]]; then
        echo -e "\033[36m❗Fehler: Benötigte Dateien (OpenSim.dll und/oder Robust.dll) fehlen im Verzeichnis 'opensim/bin'\033[0m"
        echo -e "\n\033[33m❓Haben Sie vergessen den OpenSimulator zuerst zu Kompilieren\033[0m"
        return 1
    fi

    if [[ "$user_choice" == "yes" ]]; then
        echo "OpenSimulator wird gestoppt..."
        opensimstop
        sleep 30

        echo "OpenSimulator wird kopiert..."
        opensimcopy

        echo "OpenSimulator wird gestartet..."
        opensimstart

        echo "✔ Upgrade abgeschlossen."
    else
        echo "Upgrade vom Benutzer abgebrochen."
    fi
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Bereinigen des OpenSimulators Grids
#?──────────────────────────────────────────────────────────────────────────────────────────

function dataclean() {
    echo -e "\033[32m"
    #file_types=("*.log" "*.dll" "*.exe" "*.so" "*.xml" "*.dylib" "*.example" "*.sample" "*.txt" "*.config" "*.py" "*.old" "*.pdb")

    # RobustServer bereinigen
    if [[ -d "robust/bin" ]]; then
        echo "✓ Lösche Dateien im RobustServer..."
        find "robust/bin" -maxdepth 1 -type f \( -name "*.log" -o -name "*.dll" -o -name "*.exe" -o -name "*.so" -o -name "*.xml" -o -name "*.dylib" -o -name "*.example" -o -name "*.sample" -o -name "*.txt" -o -name "*.config" -o -name "*.py" -o -name "*.old" -o -name "*.pdb" \) -delete
    fi

    # Alle simX-Server bereinigen
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" ]]; then
            echo "✓ Lösche Dateien in $sim_dir..."
            find "$sim_dir" -maxdepth 1 -type f \( -name "*.log" -o -name "*.dll" -o -name "*.exe" -o -name "*.so" -o -name "*.xml" -o -name "*.dylib" -o -name "*.example" -o -name "*.sample" -o -name "*.txt" -o -name "*.config" -o -name "*.py" -o -name "*.old" -o -name "*.pdb" \) -delete
        fi
    done
    echo -e "\033[0m"
}

function pathclean() {
    echo -e "\033[32m"
    directories=("assetcache" "maptiles" "MeshCache" "j2kDecodeCache" "ScriptEngines" "bakes" "addon-modules")
    wildcard_dirs=("addin-db-*")  # Separate Liste für Wildcard-Verzeichnisse

    # RobustServer bereinigen
    if [[ -d "robust/bin" ]]; then
        echo "✓ Lösche komplette Verzeichnisse im RobustServer..."
        
        # Normale Verzeichnisse
        for dir in "${directories[@]}"; do
            target="robust/bin/$dir"
            if [[ -d "$target" ]]; then
                rm -rf "$target"
                echo "  Verzeichnis gelöscht: $target"
            fi
        done
        
        # Wildcard-Verzeichnisse
        for pattern in "${wildcard_dirs[@]}"; do
            for target in robust/bin/$pattern; do
                if [[ -d "$target" ]]; then
                    rm -rf "$target"
                    echo "  Verzeichnis gelöscht: $target"
                fi
            done
        done
    fi

    # Alle simX-Server bereinigen
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" ]]; then
            echo "✓ Lösche komplette Verzeichnisse in $sim_dir..."
            
            # Normale Verzeichnisse
            for dir in "${directories[@]}"; do
                target="$sim_dir/$dir"
                if [[ -d "$target" ]]; then
                    rm -rf "$target"
                    echo "  Verzeichnis gelöscht: $target"
                fi
            done
            
            # Wildcard-Verzeichnisse
            for pattern in "${wildcard_dirs[@]}"; do
                for target in $sim_dir/$pattern; do
                    if [[ -d "$target" ]]; then
                        rm -rf "$target"
                        echo "  Verzeichnis gelöscht: $target"
                    fi
                done
            done
        fi
    done
    echo -e "\033[0m"
}

function cacheclean() {
    echo -e "\033[32m"
    cache_dirs=("assetcache" "maptiles" "MeshCache" "j2kDecodeCache" "ScriptEngines")

    # RobustServer bereinigen
    if [[ -d "robust/bin" ]]; then
        echo "✓ Leere Cache-Verzeichnisse im RobustServer..."
        for dir in "${cache_dirs[@]}"; do
            target="robust/bin/$dir"
            if [[ -d "$target" ]]; then
                find "$target" -mindepth 1 -delete
                echo "  Inhalt geleert: $target"
            fi
        done
    fi

    # Alle simX-Server bereinigen
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" ]]; then
            echo "✓ Leere Cache-Verzeichnisse in $sim_dir..."
            for dir in "${cache_dirs[@]}"; do
                target="$sim_dir/$dir"
                if [[ -d "$target" ]]; then
                    find "$target" -mindepth 1 -delete
                    echo "  Inhalt geleert: $target"
                fi
            done
        fi
    done
    echo -e "\033[0m"
}


function logclean() {
    echo -e "\033[32m"
    
    # RobustServer bereinigen
    if [[ -d "robust/bin" ]]; then
        echo "✓ Lösche Log-Dateien im RobustServer..."
        rm -f robust/bin/*.log
    fi

    # Alle simX-Server bereinigen (sim1 bis sim999)
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" ]]; then
            echo "✓ Lösche Log-Dateien in $sim_dir..."
            rm -f "$sim_dir"/*.log
        fi
    done
    
    echo -e "\033[0m"
}

function mapclean() {
    echo -e "\033[32m"
    
    # Sicherheitscheck für robust/bin/maptiles
    if [[ -d "robust/bin/maptiles" ]]; then
        rm -rf -- "robust/bin/maptiles/"*
        echo "✓ robust/bin/maptiles geleert"
    fi

    # Sicherheitscheck für alle simX/bin/maptiles
    for ((i=1; i<=999; i++)); do
        local sim_dir="sim$i/bin/maptiles"
        if [[ -d "$sim_dir" ]]; then
            # shellcheck disable=SC2115
            rm -rf -- "${sim_dir}/"*
            echo "✓ ${sim_dir} geleert"
        fi
    done

    echo -e "mapclean abgeschlossen.\033[0m"
}

function autoallclean() {
    local confirm

    # Warnung in Gelb (konsistenter mit \e anstelle von \033)
    echo -e "\e[33m"
    cat >&2 <<'WARNUNG'
=== WARNUNG: Alle Daten-, Verzeichnis-, Cache-, Log- und Map-Daten werden bereinigt! ===
=== DIESE OPERATION KANN NICHT RÜCKGÄNGIG GEMACHT WERDEN! ===
=== DER OPENSIMULATOR MUSS IM ANSCHLUSS NEU INSTALLIERT WERDEN! ===
WARNUNG
    echo -e "\e[0m"

    # Bestätigung mit Timeout (10 Sekunden) für Sicherheit
    read -t 30 -r -p "Fortfahren? (ja/NEIN): " confirm || {
        echo -e "\n\e[31mTimeout: Keine Bestätigung erhalten. Abbruch.\e[0m" >&2
        return 1
    }

    case "${confirm,,}" in
        ja|j|y|yes)
            echo -e "\e[32mBereinigung wird gestartet...\e[0m" >&2
            # Jede Clean-Funktion mit Fehlerprüfung
            local clean_functions=(dataclean pathclean cacheclean logclean mapclean)
            for func in "${clean_functions[@]}"; do
                if ! command -v "$func" &>/dev/null; then
                    echo -e "\e[31mFehler: '$func' ist keine gültige Funktion!\e[0m" >&2
                    return 1
                fi
                "$func" || {
                    echo -e "\e[31mFehler bei $func!\e[0m" >&2
                    return 1
                }
            done
            echo -e "\e[32mBereinigung abgeschlossen.\e[0m" >&2
            ;;
        *)
            echo -e "\e[33mAbbruch: Bereinigung wurde nicht durchgeführt.\e[0m" >&2
            return 1
            ;;
    esac
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Konfigurationen
#?──────────────────────────────────────────────────────────────────────────────────────────

# Funktion zur Generierung von UUIDs
function generate_uuid() {
    uuidgen | tr '[:upper:]' '[:lower:]'
}

# Funktion zur Generierung von Zufallsnamen
function generate_name() {
    local adjectives=(
        # Mystisch & Magisch (25)
        "Mystic" "Arcane" "Eldritch" "Enigmatic" "Esoteric" "Occult" "Cryptic" "Celestial" "Astral" "Ethereal" 
        "Luminous" "Radiant" "Prismatic" "Iridescent" "Phantasmal" "Spectral" "Otherworldly" "Transcendent" "Timeless" "Unearthly"
        "Enchanted" "Charmed" "Bewitched" "Mythic" "Legendary"
        
        # Natürlich & Elementar (25)
        "Verdant" "Sylvan" "Petrified" "Thundering" "Whispering" "Howling" "Roaring" "Rumbling" "Crystalline" "Obsidian"
        "Amber" "Jade" "Sapphire" "Emerald" "Ruby" "Topaz" "Opaline" "Pearlescent" "Gilded" "Argent"
        "Solar" "Lunar" "Stellar" "Nebular" "Galactic"
    )    
    local nouns=(
        # Natürliche Orte (25)
        "Forest" "Grove" "Copse" "Thicket" "Wildwood" "Jungle" "Rainforest" "Mangrove" "Taiga" "Tundra"
        "Mountain" "Peak" "Summit" "Cliff" "Crag" "Bluff" "Mesa" "Plateau" "Canyon" "Ravine"
        "Valley" "Dale" "Glen" "Hollow" "Basin"
        
        # Gewässer (15)
        "River" "Stream" "Brook" "Creek" "Fjord" "Lagoon" "Estuary" "Delta" "Bayou" "Wetland"
        "Oasis" "Geyser" "Spring" "Well" "Aquifer"
        
        # Künstliche Strukturen (10)
        "Observatory" "Planetarium" "Orrery" "Reflectory" "Conservatory" "Atrium" "Rotunda" "Gazebo" "Pavilion" "Terrace"
    )    
    echo "${adjectives[$RANDOM % 50]}${nouns[$RANDOM % 50]}$((RANDOM % 900 + 100))"
}

# Hauptfunktion
function regionsconfig() {
    # Konstanten
    local center_x=4000
    local center_y=4000
    local base_port=9000
    
    # Variablen
    local regions_per_sim
    local system_ip
    local sim_num
    local region_num
    local sim_dir
    local offset
    local pos_x
    local pos_y
    local location
    local port
    local region_name
    local region_uuid
    local config_file
    declare -A used_locations  # Assoziatives Array für bereits verwendete Positionen

    # Überprüfen, ob crudini installiert ist
    if ! command -v crudini &> /dev/null; then
        echo -e "\e[31mFehler: crudini ist nicht installiert. Bitte installieren Sie es zuerst.\e[0m" >&2
        return 1
    fi

    # Benutzereingabe
    echo "Wie viele Zufallsregionen sollen pro Simulator erstellt werden?"
    read -r regions_per_sim

    # Eingabeprüfung
    if ! [[ "$regions_per_sim" =~ ^[1-9][0-9]*$ ]]; then
        echo -e "\e[31mUngültige Eingabe: Bitte eine positive Zahl eingeben\e[0m" >&2
        return 1
    fi

    system_ip=$(hostname -I | awk '{print $1}')

    echo -e "\e[33mStarte Regionserstellung...\e[0m"
    echo "--------------------------"

    # Simulatoren durchlaufen
    for ((sim_num=1; sim_num<=999; sim_num++)); do
        sim_dir="sim${sim_num}/bin/Regions"
        
        if [[ -d "$sim_dir" ]]; then
            echo -e "\e[33mSimulator $sim_num: Erstelle $regions_per_sim Region(en)\e[0m" >&2
            
            # Regionen erstellen
            for ((region_num=1; region_num<=regions_per_sim; region_num++)); do
                # Position berechnen und sicherstellen, dass sie eindeutig ist
                local attempts=0
                local max_attempts=100
                
                while true; do
                    # Position berechnen
                    offset=$(( (RANDOM % 2000) - 1000 ))  # Zufälliger Offset zwischen -1000 und +1000
                    pos_x=$((center_x + offset))
                    
                    offset=$(( (RANDOM % 2000) - 1000 ))  # Unabhängiger Offset für Y
                    pos_y=$((center_y + offset))
                    
                    location="$pos_x,$pos_y"
                    
                    # Prüfen, ob die Position bereits verwendet wurde
                    if [[ -z "${used_locations[$location]}" ]]; then
                        used_locations[$location]=1
                        break
                    fi
                    
                    attempts=$((attempts + 1))
                    if (( attempts >= max_attempts )); then
                        echo -e "\e[31mFehler: Konnte nach $max_attempts Versuchen keine eindeutige Position finden\e[0m" >&2
                        return 1
                    fi
                done
                
                port=$((base_port + sim_num * 100 + region_num))
                
                # Eindeutige Werte
                region_name=$(generate_name)
                region_uuid=$(generate_uuid)
                config_file="${sim_dir}/${region_name}.ini"
                
                # Config-Datei mit crudini erstellen
                crudini --set "$config_file" "$region_name" "RegionUUID" "$region_uuid"
                crudini --set "$config_file" "$region_name" "Location" "$location"
                crudini --set "$config_file" "$region_name" "SizeX" "256"
                crudini --set "$config_file" "$region_name" "SizeY" "256"
                crudini --set "$config_file" "$region_name" "SizeZ" "256"
                crudini --set "$config_file" "$region_name" "InternalPort" "$port"
                crudini --set "$config_file" "$region_name" "ExternalHostName" "$system_ip"
                crudini --set "$config_file" "$region_name" "MaxPrims" "15000"
                crudini --set "$config_file" "$region_name" "MaxAgents" "40"
                crudini --set "$config_file" "$region_name" "MaptileStaticUUID" "$region_uuid"
                crudini --set "$config_file" "$region_name" "InternalAddress" "0.0.0.0"
                crudini --set "$config_file" "$region_name" "AllowAlternatePorts" "False"
                crudini --set "$config_file" "$region_name" "NonPhysicalPrimMax" "512"
                crudini --set "$config_file" "$region_name" "PhysicalPrimMax" "128"
                
                # Optionale Parameter als Kommentare
                crudini --set "$config_file" "$region_name" ";RegionType" "Estate"
                crudini --set "$config_file" "$region_name" ";MasterAvatarFirstName" "System"
                crudini --set "$config_file" "$region_name" ";MasterAvatarLastName" "Admin"
                crudini --set "$config_file" "$region_name" ";MasterAvatarSandboxPassword" "$(openssl rand -base64 12)"
                
                echo -e "\e[36m ✓ ${region_name} (${location}, Port ${port})\e[0m" >&2
            done
        fi
    done

    echo "--------------------------"
    echo -e "\e[32mRegionserstellung abgeschlossen!\e[0m"
    return 0
}

function regionsclean() {
    echo -e "\033[33mWARNUNG: Dies wird ALLE Regionskonfigurationen in allen Simulatoren löschen!\033[0m"
    echo "Sicher fortfahren? (j/N): " 
    read -r confirm
    
    if [[ "$confirm" =~ ^[jJ] ]]; then
        echo "Starte Bereinigung..."
        deleted_count=0
        
        # Durch alle Simulatoren iterieren
        for ((sim_num=1; sim_num<=999; sim_num++)); do
            sim_dir="sim${sim_num}/bin/Regions"
            
            if [[ -d "$sim_dir" ]]; then
                echo -e "\033[33m ✓ Überprüfe $sim_dir...\033[0m"
                
                # Lösche nur .ini-Dateien (keine anderen Dateitypen)
                while IFS= read -r -d $'\0' config_file; do
                    if [[ "$config_file" == *.ini ]]; then
                        rm -v "$config_file"
                        ((deleted_count++))
                    fi
                done < <(find "$sim_dir" -maxdepth 1 -type f -name "*.ini" -print0)
            fi
        done
        
        echo -e "\033[32mFertig! Gelöschte Regionen: $deleted_count\033[0m"
    else
        echo "Abbruch: Keine Dateien wurden gelöscht."
    fi
}

function renamefiles() {
    timestamp=$(date +"%Y%m%d_%H%M%S")

    if [ ! -d "$SCRIPT_DIR" ]; then
        echo -e "${RED}Fehler: Verzeichnis $SCRIPT_DIR nicht gefunden!${RESET}"
        return 1
    fi

    echo -e "${CYAN}Starte Umbenennung aller *.example Dateien in ${SCRIPT_DIR} und Unterverzeichnissen...${RESET}"

    # Verarbeite robust/bin zuerst
    find "$SCRIPT_DIR" -type f -name "*.example" 2>/dev/null | while read -r example_file; do
        local target_file="${example_file%.example}"  # Entfernt .example

        if [ -f "$target_file" ]; then
            local backup_file="${target_file}_${timestamp}.bak"
            mv "$target_file" "$backup_file"
            echo -e "${YELLOW}Gesichert: ${target_file} → ${backup_file}${RESET}"
        fi

        mv "$example_file" "$target_file"
        echo -e "${GREEN}Umbenannt: ${example_file} → ${target_file}${RESET}"
    done

    # Jetzt alle simX/bin Verzeichnisse durchlaufen
    for ((i=999; i>=1; i--)); do
        sim_dir="${SCRIPT_DIR}/sim$i/bin"
        if [ -d "$sim_dir" ]; then
            echo -e "${CYAN}Verarbeite: $sim_dir ${RESET}"
            find "$sim_dir" -type f -name "*.example" 2>/dev/null | while read -r example_file; do
                local target_file="${example_file%.example}"  

                if [ -f "$target_file" ]; then
                    local backup_file="${target_file}_${timestamp}.bak"
                    mv "$target_file" "$backup_file"
                    echo -e "${YELLOW}Gesichert: ${target_file} → ${backup_file}${RESET}"
                fi

                mv "$example_file" "$target_file"
                echo -e "${GREEN}Umbenannt: ${example_file} → ${target_file}${RESET}"
            done
        fi
    done

    echo -e "${GREEN}Alle *.example Dateien wurden erfolgreich verarbeitet.${RESET}"
    return 0
}

# Standalone ist die erste Funktion, die funktioniert.
function standalone() {
    echo -e "\e[33m[Standalone] Setup wird durchgeführt...\e[0m"

    # Prüfen ob SCRIPT_DIR gesetzt ist
    if [ -z "${SCRIPT_DIR}" ]; then
        echo -e "\e[31mFehler: SCRIPT_DIR ist nicht gesetzt!\e[0m"
        return 1
    fi

    local opensim_bin="${SCRIPT_DIR}/opensim/bin"
    local renamed=0
    local skipped=0

    # Sicherstellen, dass das Verzeichnis existiert
    if [ ! -d "${opensim_bin}" ]; then
        echo -e "\e[31mFehler: Verzeichnis ${opensim_bin} nicht gefunden!\e[0m"
        return 1
    fi

    # Verarbeite alle .example Dateien
    while IFS= read -r -d '' file; do
        target="${file%.example}"
        
        if [ -e "${target}" ]; then
            echo -e "\e[33mÜbersprungen: ${target} existiert bereits\e[0m"
            ((skipped++))
        else
            if mv "${file}" "${target}"; then
                echo -e "\e[32mUmbenannt: ${file} → ${target}\e[0m"
                ((renamed++))
            else
                echo -e "\e[31mFehler beim Umbenennen von ${file}\e[0m"
                ((skipped++))
            fi
        fi
    done < <(find "${opensim_bin}" -type f -name "*.example" -print0)

    echo -e "\n\e[36mZusammenfassung:\e[0m"
    echo -e "\e[32mUmbenannte Dateien: ${renamed}\e[0m"
    echo -e "\e[33mÜbersprungene Dateien: ${skipped}\e[0m"
    echo -e "\e[32mStandalone-Konfiguration abgeschlossen!\e[0m"
}

# Helper to clean config files (remove leading spaces/tabs)
clean_config() {
    local file=$1
    sed -i 's/^[ \t]*//' "$file"
}

function setrobusthg() {
    local robust_ini="${SCRIPT_DIR}/robust/bin/Robust.HG.ini.example"
    local target_ini="${SCRIPT_DIR}/robust/bin/Robust.ini"
    local backup_file="${SCRIPT_DIR}/robust/bin/Robust.ini.bak"

    # Prüfe, ob Robust.ini existiert und erstelle ein Backup
    if [ -f "$target_ini" ]; then
        echo "Sichere bestehende Datei: $target_ini -> $backup_file"
        mv "$target_ini" "$backup_file"
    fi

    # Kopiere Robust.HG.ini nach Robust.ini
    if [ -f "$robust_ini" ]; then
        cp "$robust_ini" "$target_ini"
        echo "$robust_ini wurde nach $target_ini kopiert."
    else
        echo "Warnung: $robust_ini nicht gefunden!"
        return 1
    fi

    # Bereinige die Datei, damit crudini korrekt arbeitet
    clean_config "$target_ini"

    # Basis-Konfiguration
    crudini --set "$target_ini" Const BaseHostname "\"$system_ip\""
    crudini --set "$target_ini" Const BaseURL "\"http://\${Const|BaseHostname}\""
    crudini --set "$target_ini" Const PublicPort "\"8002\""
    crudini --set "$target_ini" Const PrivatePort "\"8003\""

    # Dienste aktivieren (ServiceList)
    services=(
        "OfflineIMServiceConnector"
        "GroupsServiceConnector"
        "BakedTextureService"
        "UserProfilesServiceConnector"
        "HGGroupsServiceConnector"
    )
    for service in "${services[@]}"; do
        sed -i "/^; *$service/s/^;//" "$target_ini"
    done

    # Hypergrid Konfiguration
    crudini --set "$target_ini" Hypergrid HomeURI "\"\${Const|BaseURL}:\${Const|PublicPort}\""
    crudini --set "$target_ini" Hypergrid GatekeeperURI "\"\${Const|BaseURL}:\${Const|PublicPort}\""

    # Access Control - Verbotene Clients
    crudini --set "$target_ini" AccessControl DeniedClients "\"Imprudence|CopyBot|Twisted|Crawler|Cryolife|darkstorm|DarkStorm|Darkstorm|hydrastorm viewer|kinggoon copybot|goon squad copybot|copybot pro|darkstorm viewer|copybot club|darkstorm second life|copybot download|HydraStorm Copybot Viewer|Copybot|Firestorm Pro|DarkStorm v3|DarkStorm v2|ShoopedStorm|HydraStorm|hydrastorm|kinggoon|goon squad|goon|copybot|Shooped|ShoopedStorm|Triforce|Triforce Viewer|Firestorm Professional|ShoopedLife|Sombrero|Sombrero Firestorm|GoonSquad|Solar|SolarStorm\""

    # Datenbank-Konfiguration
    crudini --set "$target_ini" DatabaseService ConnectionString "\"Data Source=localhost;Database=opensim;User ID=opensim;Password=$DB_PASSWORD;Old Guids=true;SslMode=None;\""

    # Grid-Dienste
    crudini --set "$target_ini" GridService MapTileDirectory "\"./maptiles\""
    crudini --set "$target_ini" GridService Region_Welcome_Area "\"DefaultRegion, DefaultHGRegion\""

    # Login-Service
    crudini --set "$target_ini" LoginService DestinationGuide "\"\${Const|BaseURL}/guide.php\""
    crudini --set "$target_ini" LoginService GridSearch "\"\${Const|BaseURL}/searchservice.php\""

    # Map-Bild-Service
    crudini --set "$target_ini" MapImageService TilesStoragePath "\"maptiles\""
    crudini --set "$target_ini" MapImageService GridService "\"OpenSim.Services.GridService.dll:GridService\""

    # Grid-Info-Service
    crudini --set "$target_ini" GridInfoService welcome "\${Const|BaseURL}/welcomesplashpage.php"
    crudini --set "$target_ini" GridInfoService economy "\${Const|BaseURL}:8008/"
    crudini --set "$target_ini" GridInfoService about "\${Const|BaseURL}/aboutinformation.php"
    crudini --set "$target_ini" GridInfoService register "\${Const|BaseURL}/createavatar.php"
    crudini --set "$target_ini" GridInfoService help "\${Const|BaseURL}/help.php"
    crudini --set "$target_ini" GridInfoService password "\${Const|BaseURL}/passwordreset.php"
    crudini --set "$target_ini" GridInfoService partner "\${Const|BaseURL}/partner.php"
    crudini --set "$target_ini" GridInfoService GridStatus "\${Const|BaseURL}:\${Const|PublicPort}/gridstatus.php"
    crudini --set "$target_ini" GridInfoService GridStatusRSS "\${Const|BaseURL}:\${Const|PublicPort}/gridstatusrss.php"

    # User-Agent-Service
    crudini --set "$target_ini" UserAgentService LevelOutsideContacts "0"
    crudini --set "$target_ini" UserAgentService ShowUserDetailsInHGProfile "True"

    # Bereinige die Datei (entferne führende Leerzeichen)
    clean_config "$target_ini"
    
    echo "Konfiguration von Robust.ini erfolgreich abgeschlossen."
}

function setopensim() {
    local base_dir="${SCRIPT_DIR}/"
    
    # Durchsuche alle vorhandenen simX-Ordner (sim1 bis sim999)
    for i in {1..999}; do
        local sim_dir="${base_dir}sim$i/bin"
        local opensim_example="$sim_dir/OpenSim.ini.example"
        local opensim_ini="$sim_dir/OpenSim.ini"
        local backup_ini="$sim_dir/OpenSim.ini.bak"

        # Prüfen, ob das Verzeichnis existiert
        if [ -d "$sim_dir" ]; then
            echo "Konfiguriere OpenSim.ini für $sim_dir"

            # Falls OpenSim.ini existiert, sichere sie zuerst
            if [ -f "$opensim_ini" ]; then
                echo "Sichere bestehende Datei: $opensim_ini -> $backup_ini"
                mv "$opensim_ini" "$backup_ini"
            fi

            # Kopiere OpenSim.ini.example nach OpenSim.ini
            if [ -f "$opensim_example" ]; then
                cp "$opensim_example" "$opensim_ini"
                echo "$opensim_example wurde nach $opensim_ini kopiert."
            else
                echo "Warnung: $opensim_example nicht gefunden! Überspringe sim$i."
                continue
            fi

            # Bereinige die Datei, damit crudini korrekt arbeitet
            clean_config "$opensim_ini"

            # Konfiguration mit crudini setzen

            #Const-Konfiguration
            crudini --set "$opensim_ini" Const BaseHostname "\"$system_ip\""
            crudini --set "$opensim_ini" Const BaseURL "\"http://\${Const|BaseHostname}\""
            #crudini --set "$opensim_ini" Const PublicPort "\"9000\""
            crudini --set "$opensim_ini" Const PublicPort "\"8002\""
            crudini --set "$opensim_ini" Const PrivURL "\"\${Const|BaseURL}\""
            crudini --set "$opensim_ini" Const PrivatePort "\"8003\""

            # Startup-Einstellungen
            crudini --set "$opensim_ini" Startup async_call_method "SmartThreadPool"
            crudini --set "$opensim_ini" Startup MaxPoolThreads "300"
            crudini --set "$opensim_ini" Startup MinPoolThreads "32"
            crudini --set "$opensim_ini" Startup CacheSculptMaps "false"
            crudini --set "$opensim_ini" Startup DefaultScriptEngine "\"YEngine\""

            # Map-Konfiguration
            crudini --set "$opensim_ini" Map MaptileStaticUUID "\"00000000-0000-0000-0000-000000000000\""

            # Berechtigungen
            crudini --set "$opensim_ini" Permissions automatic_gods "false"
            crudini --set "$opensim_ini" Permissions implicit_gods "false"
            crudini --set "$opensim_ini" Permissions allow_grid_gods "true"

            # Netzwerk-Konfiguration
            crudini --set "$opensim_ini" Network http_listener_port "9010"
            crudini --set "$opensim_ini" Network shard "\"OpenSim\""
            crudini --set "$opensim_ini" Network user_agent "\"OpenSim LSL (Mozilla Compatible)\""

            # BulletSim-Einstellungen
            crudini --set "$opensim_ini" BulletSim AvatarToAvatarCollisionsByDefault "true"
            crudini --set "$opensim_ini" BulletSim UseSeparatePhysicsThread "true"
            crudini --set "$opensim_ini" BulletSim TerrainImplementation "0"

            # Materialeinstellungen
            crudini --set "$opensim_ini" Materials MaxMaterialsPerTransaction "250"

            # Benutzerprofile
            crudini --set "$opensim_ini" UserProfiles ProfileServiceURL "\"http://services.osgrid.org\""

            # Skript-Engines
            crudini --set "$opensim_ini" YEngine Enabled "true"
            crudini --set "$opensim_ini" XEngine Enabled "false"

            # OSSL-Einstellungen
            crudini --set "$opensim_ini" OSSL Include-osslDefaultEnable "\"config-include/osslDefaultEnable.ini\""

            # NPC-Einstellungen
            crudini --set "$opensim_ini" NPC Enabled "true"

            # Terrain-Konfiguration
            crudini --set "$opensim_ini" Terrain InitialTerrain "\"flat\""

            # XBakes-Konfiguration
            crudini --set "$opensim_ini" XBakes URL "\"\${Const|PrivURL}:\${Const|PrivatePort}\""

            # Architektur
            crudini --set "$opensim_ini" Architecture Include-Architecture "\"config-include/GridHypergrid.ini\""

            echo "Konfiguration von OpenSim.ini erfolgreich abgeschlossen."
        fi
    done
}

function setgridcommon() {
    local base_dir="${SCRIPT_DIR}/"

    for i in {1..999}; do
        local sim_dir="${base_dir}sim$i/bin/config-include"
        local gridcommon_example="$sim_dir/GridCommon.ini.example"
        local gridcommon_ini="$sim_dir/GridCommon.ini"
        local backup_ini="$sim_dir/GridCommon.ini.bak"

        if [ -d "$sim_dir" ]; then
            echo "Konfiguriere GridCommon.ini für $sim_dir"

            if [ -f "$gridcommon_ini" ]; then
                echo "Sichere bestehende Datei: $gridcommon_ini -> $backup_ini"
                mv "$gridcommon_ini" "$backup_ini"
            fi

            if [ -f "$gridcommon_example" ]; then
                # 1. Erstelle neue GridCommon.ini mit Const-Bereich
                echo "[Const]" > "$gridcommon_ini"
                crudini --set "$gridcommon_ini" Const BaseHostname "\"$system_ip\""
                crudini --set "$gridcommon_ini" Const BaseURL "\"http://\${Const|BaseHostname}\""
                crudini --set "$gridcommon_ini" Const PublicPort "\"8002\""
                crudini --set "$gridcommon_ini" Const PrivatePort "\"8003\""
                
                # 2. Füge eine Leerzeile ein für bessere Lesbarkeit
                echo "" >> "$gridcommon_ini"
                
                # 3. Füge den kompletten Inhalt der Beispiel-Datei hinzu
                cat "$gridcommon_example" >> "$gridcommon_ini"
                
                echo "GridCommon.ini wurde erstellt mit Const-Bereich und Inhalt von $gridcommon_example."
            else
                echo "Warnung: $gridcommon_example nicht gefunden! Überspringe sim$i."
                continue
            fi

            clean_config "$gridcommon_ini"
            echo "Konfiguration von GridCommon.ini für $sim_dir erfolgreich abgeschlossen."
        fi
    done
}

function setflotsamcache() {
    local base_dir="${SCRIPT_DIR}/"

    # Durchsuche alle existierenden simX-Ordner (sim1 bis sim999)
    for i in {1..999}; do
        local sim_dir="${base_dir}sim$i/bin/config-include"
        local flotsam_ini="$sim_dir/FlotsamCache.ini"
        local backup_ini="$sim_dir/FlotsamCache.ini.bak"

        # Prüfe, ob das Sim-Verzeichnis existiert
        if [ -d "$sim_dir" ]; then
            echo "Erstelle FlotsamCache.ini für $sim_dir"

            # Falls die Datei existiert, sichere sie zuerst
            if [ -f "$flotsam_ini" ]; then
                echo "Sichere bestehende Datei: $flotsam_ini -> $backup_ini"
                mv "$flotsam_ini" "$backup_ini"
            fi

            # Ersetze den kompletten Inhalt mit der neuen Konfiguration
            cat > "$flotsam_ini" << EOF
[AssetCache]
CacheDirectory = ./assetcache
LogLevel = 0
HitRateDisplay = 100
MemoryCacheEnabled = false
UpdateFileTimeOnCacheHit = false
NegativeCacheEnabled = true
NegativeCacheTimeout = 120
NegativeCacheSliding = false
FileCacheEnabled = true
MemoryCacheTimeout = .016
FileCacheTimeout = 48
FileCleanupTimer = 1.0
EOF

            # Bereinige die Datei
            clean_config "$flotsam_ini"

            echo "Konfiguration von FlotsamCache.ini für $sim_dir abgeschlossen."
        fi
    done
}

# setwelcome - Sets the Welcome_Area.ini
function setwelcome() {
    local welcome_ini="${SCRIPT_DIR}/sim1/bin/Regions/Welcome_Area.ini"
    region_uuid=$(uuidgen)
    
    cat > "$welcome_ini" << EOF
[Welcome Area]
RegionUUID = $region_uuid
Location = 3000,3000
SizeX = 256
SizeY = 256
SizeZ = 256
InternalPort = 9010
ExternalHostName = "$system_ip"
MaxPrims = 15000
MaxAgents = 40
MaptileStaticUUID = $region_uuid
InternalAddress = 0.0.0.0
AllowAlternatePorts = False
;NonPhysicalPrimMax = 512
;PhysicalPrimMax = 128
;MasterAvatarSandboxPassword = "$(openssl rand -base64 12)"
;MasterAvatarLastName = Admin
;MasterAvatarFirstName = System
;RegionType = Estate
EOF

    clean_config "$welcome_ini"
    echo "Welcome_Area.ini configuration completed"
}

function setosslenable() {
    local base_dir="${SCRIPT_DIR}/"

    for i in {1..999}; do
        local sim_dir="${base_dir}sim$i/bin/config-include"
        local osslenable_ini="$sim_dir/osslEnable.ini"
        local backup_ini="$sim_dir/osslEnable.ini.bak"

        # Prüfen, ob das Sim-Verzeichnis existiert
        if [ -d "$sim_dir" ]; then
            echo "Erstelle osslEnable.ini für $sim_dir"

            # Falls die Datei existiert, sichere sie zuerst
            if [ -f "$osslenable_ini" ]; then
                echo "Sichere bestehende Datei: $osslenable_ini -> $backup_ini"
                mv "$osslenable_ini" "$backup_ini"
            fi

            # Ersetze den kompletten Inhalt mit der neuen Konfiguration
            cat > "$osslenable_ini" << EOF
[OSSL]
AllowOSFunctions = true
AllowMODFunctions = true
AllowLightShareFunctions = true
PermissionErrorToOwner = false
OSFunctionThreatLevel = High
osslParcelO = "PARCEL_OWNER,"
osslParcelOG = "PARCEL_GROUP_MEMBER,PARCEL_OWNER,"
osslNPC = \${OSSL|osslParcelOG}ESTATE_MANAGER,ESTATE_OWNER
EOF

            echo "Konfiguration von osslEnable.ini für $sim_dir abgeschlossen."
        fi
    done
}

function clean_comments_and_empty_lines() {
    echo -e "\e[33mBereinige Kommentare und Leerzeilen in allen Konfigurationsdateien...\e[0m"
    
    # Durch alle simX-Verzeichnisse iterieren
    for ((i=999; i>=1; i--)); do
        sim_dir="sim$i"
        
        if [ -d "$sim_dir" ]; then
            echo -e "\e[36mVerarbeite $sim_dir...\e[0m"
            
            # Liste aller relevanten Konfigurationsdateien
            config_files=(
                "${sim_dir}/bin/Robust.ini.example"
                "${sim_dir}/bin/Robust.HG.ini.example"
                "${sim_dir}/bin/OpenSim.ini.example"
                "${sim_dir}/bin/config-include/FlotsamCache.ini.example"
                "${sim_dir}/bin/config-include/GridCommon.ini.example"
                "${sim_dir}/bin/config-include/osslEnable.ini.example"
                "${sim_dir}/bin/config-include/StandaloneCommon.ini.example"
            )
            
            # Jede Konfigurationsdatei bearbeiten
            for config_file in "${config_files[@]}"; do
                if [[ -f "$config_file" ]]; then
                    echo -e "\e[34mBearbeite $config_file\e[0m"
                    
                    # Vorher-Nachher-Vergleich
                    original_lines=$(wc -l < "$config_file")
                    
                    # 1. Behalte nur Zeilen mit = oder gültigen Sektionen
                    # 2. Entferne führende/trailing Whitespace
                    # 3. Lösche leere Zeilen
                    perl -i.bak -ne '
                        if (/^\s*\[.+\]\s*$/ || /=/) {
                            s/^\s+//;   # Entferne führende Leerzeichen/Tabs
                            s/\s+$//;   # Entferne trailing Leerzeichen
                            print "$_\n";
                        }
                    ' "$config_file"
                    
                    # Nachher-Zeilenanzahl
                    cleaned_lines=$(wc -l < "$config_file")
                    
                    # Veränderungen anzeigen
                    removed=$((original_lines - cleaned_lines))
                    
                    if [[ $removed -gt 0 ]]; then
                        echo -e "\e[32m✓ Entfernt $removed Zeilen aus $config_file\e[0m"
                        echo -e "\e[37mVorher/Nachher Beispiel:\e[0m"
                        diff --unchanged-line-format= --old-line-format='- %L' --new-line-format='+ %L' \
                            "${config_file}.bak" "$config_file" | head -5
                    else
                        echo -e "\e[35mℹ Keine Änderungen in $config_file\e[0m"
                    fi
                fi
            done
        fi
    done
    
    echo -e "\e[32mBereinigung abgeschlossen!\e[0m"
}

function cleandoublecomments() {
    echo -e "\e[33mBereinige doppelt kommentierte Zeilen in allen Konfigurationsdateien...\e[0m"
    
    # Durch alle simX-Verzeichnisse iterieren
    for ((i=999; i>=1; i--)); do
        sim_dir="sim$i"
        
        if [ -d "$sim_dir" ]; then
            echo -e "\e[36mVerarbeite $sim_dir...\e[0m"
            
            # Liste aller relevanten Konfigurationsdateien
            config_files=(
                "${sim_dir}/bin/Robust.ini"
                "${sim_dir}/bin/Robust.HG.ini"
                "${sim_dir}/bin/OpenSim.ini"
            )
            
            # Jede Konfigurationsdatei bearbeiten
            for config_file in "${config_files[@]}"; do
                if [[ -f "$config_file" ]]; then
                    echo -e "\e[34mBearbeite $config_file\e[0m"
                    
                    # Vorher-Nachher-Vergleich
                    original_lines=$(wc -l < "$config_file")
                    
                    # Doppelt kommentierte Zeilen mit führenden Leerzeichen/Tabs entfernen
                    perl -i.bak -ne 'print unless /^\s*;;|^\s*;#/' "$config_file"
                    
                    # Nachher-Zeilenanzahl
                    cleaned_lines=$(wc -l < "$config_file")
                    
                    # Veränderungen anzeigen
                    removed=$((original_lines - cleaned_lines))
                    
                    if [[ $removed -gt 0 ]]; then
                        echo -e "\e[32m✓ Entfernt $removed Zeilen aus $config_file\e[0m"
                        echo -e "\e[37mErste entfernte Zeile:\e[0m"
                        diff "${config_file}.bak" "$config_file" | grep '^<' | head -1
                    else
                        echo -e "\e[35mℹ Keine doppelt kommentierten Zeilen in $config_file gefunden\e[0m"
                        # Debug-Ausgabe
                        echo -e "\e[37mBeispielzeilen:\e[0m"
                        grep -m 2 '^\s*[;#]' "$config_file" || echo "Keine kommentierten Zeilen gefunden"
                    fi
                fi
            done
        fi
    done
    
    echo -e "\e[32mBereinigung abgeschlossen!\e[0m"
}

function cleanall() {
    echo "Möchtest du OpenSim komplett mit Konfigurationen entfernen? (ja/nein)"
    read -r answer

    if [ "$answer" = "ja" ]; then
        echo "Lösche OpenSim vollständig..."
        
        # robust/bin Verzeichnis leeren, falls vorhanden
        if [ -d "robust/bin" ]; then
            rm -rf robust/bin/*
        fi

        # Überprüfen, welche simX/bin Verzeichnisse existieren und leeren
        for i in {1..999}; do
            dir="sim$i/bin"
            if [ -d "$dir" ]; then
                rm -rf "${dir:?}/"*
            fi
        done

        echo "Alle bin-Verzeichnisse wurden geleert."

    elif [ "$answer" = "nein" ]; then
        echo "OpenSim bleibt erhalten."

    else
        echo "Ungültige Eingabe. Bitte 'ja' oder 'nein' eingeben."
    fi
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#*          ZUSAMMENFASSUNG DER FUNKTIONEN NACH PAKETGRUPPEN          
#?──────────────────────────────────────────────────────────────────────────────────────────
#!  Jede Gruppe kapselt logisch zusammenhängende Aufgaben.
#!  Aufrufreihenfolge ist teilweise kritisch (z.B. muss 'opensimbuild' vor 'opensimcopy').
#?──────────────────────────────────────────────────────────────────────────────────────────

#! ┌─────────────────────────────────────────────────────────────────┐
#! │ [1] SYSTEMVORBEREITUNG                                          │
#! └─────────────────────────────────────────────────────────────────┘
#   ├── servercheck     : Prüft Systemvoraussetzungen (RAM, CPU, Distro)
#   ├── createdirectory : Legt Basisverzeichnisstruktur an
#   └── sqlsetup        : Konfiguriert Datenbank (MySQL/PostgreSQL)

#! ┌─────────────────────────────────────────────────────────────────┐
#! │ [2] QUELLCODE-MANAGEMENT                                        │
#! └─────────────────────────────────────────────────────────────────┘
#   ├── opensimgit      : Klont OpenSimulator-Quellcode (Git)
#   └── moneygit        : Klont Währungssystem-Plugin (falls benötigt)

#! ┌─────────────────────────────────────────────────────────────────┐
#! │ [3] BUILD-PROZESS                                               │
#! └─────────────────────────────────────────────────────────────────┘
#   └── opensimbuild    : Kompiliert OpenSimulator (Mono/XBuild)

#! ┌─────────────────────────────────────────────────────────────────┐
#! │ [4] KONFIGURATION                                               │
#! └─────────────────────────────────────────────────────────────────┘
#   ├── regionsconfig   : Erstellt Basis-Regionenkonfiguration
#   ├── setwelcome      : Setzt Willkommensnachricht
#   ├── setrobusthg     : Konfiguriert Robust-Service für HG
#   ├── setopensim      : Server-Port-Konfiguration (TODO: pro Sim)
#   ├── setgridcommon   : Grid-Kernparameter (TODO: DB-Separierung)
#   ├── setflotsamcache : Cache-Einstellungen
#   └── setosslenable   : Aktiviert OSSL (TODO: Grundeinstellungen)

#! ┌─────────────────────────────────────────────────────────────────┐
#! │ [5] DEPLOYMENT                                                  │
#! └─────────────────────────────────────────────────────────────────┘
#   └── opensimcopy     : Kopiert Binaries an Zielorte

#! ┌─────────────────────────────────────────────────────────────────┐
#! │ [6] AUTOMATISIERUNG                                             │
#! └─────────────────────────────────────────────────────────────────┘
#   └── setcrontab      : Richtet Auto-Start ein (Cronjob)

#?──────────────────────────────────────────────────────────────────────────────────────────
#*  NUTZUNGSHINWEISE:
#!  1. Einzelaufruf   : bash osmtool.sh –funktion [FUNKTIONSNAME]
#!  2. Komplettlauf   : bash osmtool.sh autosetinstall (fragt Bestätigung ab)
#?──────────────────────────────────────────────────────────────────────────────────────────

# ---

#! ┌─────────────────────────────────────────────────────────────────┐
#! │ [1] NEUSTART-FUNKTIONEN                                        │
#! └─────────────────────────────────────────────────────────────────┘

# Standalone-Service-Neustart (ohne Logbereinigung)
function standalonerestart() {
    standalonestop
    sleep 30  # Wartezeit für sauberen Shutdown
    standalonestart
}

# Kompletter OpenSim-Neustart mit Logrotation
function opensimrestart() {
    opensimstop
    sleep 30  # Wartezeit für Dienst-Stopp
    logclean   # Logbereinigung
    sleep 15  # Wartezeit vor Neustart
    opensimstart
    echo -e "\033[36mAktive Screen-Sessions:\033[0m"
    screen -ls || echo "Keine Screen-Sessions gefunden"
}

#! ┌─────────────────────────────────────────────────────────────────┐
#! │ [2] KONFIGURATIONS-PAKETE                                      │
#! └─────────────────────────────────────────────────────────────────┘

# Basis-Konfiguration für alle Dienste
function configall() {
    setrobusthg      # Hypergrid-Konfig
    setopensim       # Regionsserver
    setgridcommon    # Grid-weite Einstellungen
    setflotsamcache  # Cache-System
    setosslenable    # OSSL-Funktionen
    setwelcome       # Startregion
    echo -e "\033[32mAlle Konfigurationen wurden angewendet.\033[0m"
}

#! ┌─────────────────────────────────────────────────────────────────┐
#! │ [3] INSTALLATIONSROUTINEN                                      │
#! └─────────────────────────────────────────────────────────────────┘

# Vollautomatische Installation
function autosetinstall() {
    # Sicherheitsabfrage
    echo -e "\033[1;33m⚠ WARNUNG: Komplette Serverinstallation!\033[0m"
    read -rp "Fortfahren? (j/N): " antwort
    
    [[ "${antwort,,}" != "j" ]] && {
        echo -e "\033[31m✖ Abbruch durch Benutzer\033[0m"
        return 1
    }

    # Installationsphasen
    echo -e "\033[1;34m\n[Phase 1] Systemchecks\033[0m"
    servercheck || return $?

    echo -e "\033[1;34m\n[Phase 2] Quellcode\033[0m"
    opensimgit && moneygit || return $?

    echo -e "\033[1;34m\n[Phase 3] Build-Prozess\033[0m"
    opensimbuild || return $?

    echo -e "\033[1;34m\n[Phase 4] Deployment\033[0m"
    createdirectory
    sqlsetup
    opensimcopy

    echo -e "\033[1;34m\n[Phase 5] Konfiguration\033[0m"
    regionsconfig
    setwelcome
    configall  # Nutzt die oben definierte Gruppenfunktion

    echo -e "\033[1;34m\n[Phase 6] Automatisierung\033[0m"
    setcrontab

    echo -e "\033[1;32m\n✔ Installation abgeschlossen! Auto-Start in 30 Min.\033[0m"
}

#! ┌─────────────────────────────────────────────────────────────────┐
#! │ [4] SYSTEMOPERATIONEN                                          │
#! └─────────────────────────────────────────────────────────────────┘

# Server-Reboot mit Vorbereitung
function reboot() {
    echo -e "\033[1;33m⚠ Server-Neustart wird eingeleitet...\033[0m"
    
    # Graceful Shutdown
    opensimstop
    sleep 30
    
    # Bestätigungscheck funktioniert nicht bei cronjobs
    # read -rp "Sicher, dass der Server jetzt neustarten soll? (j/N): " antwort
    # [[ "${antwort,,}" == "j" ]] || {
    #     echo -e "\033[32m✔ Abbruch durch Benutzer\033[0m"
    #     return 0
    # }
    
    shutdown -r now
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Hilfefunktionen
#?──────────────────────────────────────────────────────────────────────────────────────────

function help () {
    echo -e "\e[36mOpenSim Grid Starten Stoppen und Restarten:\e[0m"
    echo -e "\e[32mopensimstart\e[0m # OpenSim starten.\e[0m"
    echo -e "\e[32mopensimstop\e[0m # OpenSim stoppen.\e[0m"
    echo -e "\e[32mopensimrestart\e[0m # OpenSim neu starten.\e[0m"    
    echo -e "\e[32mcheck_screens\e[0m # Laufende OpenSim Prozesse prüfen und restarten.\e[0m"
    echo " "

    # Das folgende ist implementiert aber ich bin am überlegen ob es wirklich gebraucht wird?
    # echo -e "\e[36mOpenSim Standalone Starten Stoppen und Restarten:\e[0m"
    # echo -e "\e[32mstandalonestart\e[0m # OpenSim starten.\e[0m"
    # echo -e "\e[32mstandalonestop\e[0m # OpenSim stoppen.\e[0m"
    # echo -e "\e[32mstandalonerestart\e[0m # OpenSim neu starten.\e[0m"
    # echo " "

    echo -e "\e[36mEin OpenSim Grid erstellen oder aktualisieren:\e[0m"
    echo -e "\e[32mservercheck\e[0m # Zuerst nachsehen ob der Server bereit für OpenSim ist."
    echo -e "\e[32mcreatedirectory\e[0m # Verzeichnisse erstellen."
    echo -e "\e[32mmariasetup\e[0m # MariaDB Datenbanken erstellen."
    echo -e "\e[32msqlsetup\e[0m # SQL Datenbanken erstellen."
    echo -e "\e[32msetcrontab\e[0m # set crontab automatisierungen."
    echo " "

    echo -e "\e[36mGit Downloads:\e[0m"
    echo -e "\e[32mopensimgitcopy\e[0m # OpenSim aus dem Git herunterladen."
    echo -e "\e[32mmoneygitcopy\e[0m # MoneyServer aus dem Git herunterladen."
    echo -e "\e[32mruthrothgit\e[0m # ruth roth aus dem Git herunterladen als IAR. ⚡ \033[31mVorsicht\033[0m"
    echo -e "\e[32mavatarassetsgit\e[0m # ruth roth aus dem Git herunterladen als Assets. ⚡ \033[31mVorsicht\033[0m"
    echo -e "\e[32mosslscriptsgit\e[0m # Skripte aus dem Git herunterladen.⚡ \033[31mVorsicht\033[0m"
    echo -e "\e[32mpbrtexturesgit\e[0m # PBR Texturen aus dem Git herunterladen.⚡ \033[31mVorsicht\033[0m"
    echo " "

    echo -e "\e[32mopensimbuild\e[0m # OpenSim kompilieren."
    echo -e "\e[32mconfigall\e[0m # Vorkonfigurieren des OpenSimulators Gid Test.\e[0m⚡ \033[31mVorsicht\033[0m"  # Die automatische konfiguration zu testzwecken.
    echo -e "\e[32mopensimcopy\e[0m # OpenSim kopieren (in alle Verzeichnisse)."
    echo -e "\e[35mopensimconfig # Eine funktionsfähige konfiguration fehlt noch.\e[0m"
    echo -e "\e[32mregionsconfig\e[0m # OpenSim Regionen konfigurieren."
    echo " "    

    echo -e "\e[36mOpenSim Grid Bereinigen von alten Dateien, Verzeichnissen und Cache:\e[0m"
    echo -e "\e[32mdataclean\e[0m # Robust und sim von alten Dateien befreien \033[31m( ⚡ Neuinstallation erforderlich).\e[0m"
    echo -e "\e[32mpathclean\e[0m # Robust und sim von alten Verzeichnissen befreien \033[31m( ⚡ Neuinstallation erforderlich).\e[0m"
    echo -e "\e[32mcacheclean\e[0m # Robust und sim Cache bereinigen.\e[0m"
    echo -e "\e[32mlogclean\e[0m # Robust und sim von alten Logs befreien.\e[0m"
    echo -e "\e[32mmapclean\e[0m # Robust und sim von alten Maptile Karten befreien.\e[0m"
    echo -e "\e[32mautoallclean\e[0m # Robust und sim von alten Dateien und Verzeichnissen befreien \033[31m( ⚡ Neuinstallation erforderlich).\e[0m"
    echo -e "\e[32mregionsclean\e[0m # Löscht alle konfigurierten Regionen aus allen Simulatoren.\e[0m"    
    echo " "
}


function colortest(){
echo -e "\033[32m Symbole für Statusanzeigen\033[0m"
echo -e "Pfeile: → ← ↑ ↓ ➔ ➜ ➤ ➣ ➢ ➠"
echo -e "Kreise: ○ ● ⭘ ◯ ◎ ⚪ ⚫"
echo -e "Quadrate: ■ □ ▪ ▫ ⬛ ⬜"
echo -e "Sterne: ★ ☆ ✦ ✧ ✪ ✩ ✫ ✯ ✰"
echo -e "Haken & Kreuze: ✓ ✕ ✘ ❌ ✅ ❎"
echo -e "Uhren & Zeit: ⏳ ⌛ ⏰ 🕒 🕔 🕗"
echo -e "Zahlen in Kreisen: ➀ ➁ ➂ ➃ ➄ ➅ ➆ ➇ ➈ ➉"
echo -e "Punkte & Marker: • ◦ ∙ ☐ ☒"
echo -e "Wetter/Status (optional): ⚡ ☔"
echo -e "Fortschritt (Balken-Stil): ▄ █"
echo -e "Linien/Trenner: ─ ━ │ ┃ ┄ ┅ ┆ ┇ ┈ ┉ ┊ ┋"
echo " "
echo -e "✓ \033[32mErfolgreich abgeschlossen!\033[0m"
echo -e "✘ \033[31mFehler aufgetreten.\033[0m"
echo -e "⏳ \033[33mBitte warten...\033[0m"
echo -e "⚡ \033[31mVorsicht\033[0m"
echo -e "\033[31m( ⚡ Neuinstallation erforderlich).\e[0m"

echo " "
echo -e "\033[1m Textfarben \033[0m"
echo -e "\033[30m Schwarz\033[0m"
echo -e "\033[31m Rot\033[0m"
echo -e "\033[32m Grün\033[0m"
echo -e "\033[33m Gelb\033[0m"
echo -e "\033[34m Blau\033[0m"
echo -e "\033[35m Magenta\033[0m"
echo -e "\033[36m Cyan\033[0m"
echo -e "\033[37m Weiß\033[0m"
echo " "
echo -e "\033[1m Hintergrundfarben \033[0m"
echo -e "\033[40m Schwarzer Hintergrund\033[0m"
echo -e "\033[41m Roter Hintergrund\033[0m"
echo -e "\033[42m Grüner Hintergrund\033[0m"
echo -e "\033[43m Gelber Hintergrund\033[0m"
echo -e "\033[44m Blauer Hintergrund\033[0m"
echo -e "\033[45m Magenta Hintergrund\033[0m"
echo -e "\033[46m Cyan Hintergrund\033[0m"
echo -e "\033[47m Weißer Hintergrund\033[0m"
echo " "
echo -e "\033[1m Formatierungen \033[0m"
echo -e "\033[1m Fett (bold)\033[0m"
echo -e "\033[2m Schwach (dim)\033[0m"
echo -e "\033[3m Kursiv (italic, nicht überall unterstützt)\033[0m"
echo -e "\033[4m Unterstrichen (underline)\033[0m"
echo -e "\033[7m Negativ (invert colors)\033[0m"
echo -e "\033[0m Zurücksetzen (reset)"
echo " "
echo -e "\033[1m Textfarben \033[0m"
echo -e "\033[30m Schwarz\033[0m        \033[90m Hellgrau (Bright-Schwarz)\033[0m"
echo -e "\033[31m Rot\033[0m           \033[91m Hellrot (Bright-Rot)\033[0m"
echo -e "\033[32m Grün\033[0m         \033[92m Hellgrün (Bright-Grün)\033[0m"
echo -e "\033[33m Gelb\033[0m         \033[93m Hellgelb (Bright-Gelb)\033[0m"
echo -e "\033[34m Blau\033[0m         \033[94m Hellblau (Bright-Blau)\033[0m"
echo -e "\033[35m Magenta\033[0m      \033[95m Hellmagenta (Bright-Magenta)\033[0m"
echo -e "\033[36m Cyan\033[0m         \033[96m Hellcyan (Bright-Cyan)\033[0m"
echo -e "\033[37m Weiß\033[0m         \033[97m Hellweiß (Bright-Weiß)\033[0m"
echo " "
echo -e "\n\033[1m Hintergrundfarben \033[0m"
echo -e "\033[40m Schwarzer Hintergrund\033[0m      \033[100m Heller schwarzer Hintergrund\033[0m"
echo -e "\033[41m Roter Hintergrund\033[0m         \033[101m Heller roter Hintergrund\033[0m"
echo -e "\033[42m Grüner Hintergrund\033[0m       \033[102m Heller grüner Hintergrund\033[0m"
echo -e "\033[43m Gelber Hintergrund\033[0m       \033[103m Heller gelber Hintergrund\033[0m"
echo -e "\033[44m Blauer Hintergrund\033[0m       \033[104m Heller blauer Hintergrund\033[0m"
echo -e "\033[45m Magenta Hintergrund\033[0m     \033[105m Heller magenta Hintergrund\033[0m"
echo -e "\033[46m Cyan Hintergrund\033[0m         \033[106m Heller cyan Hintergrund\033[0m"
echo -e "\033[47m Weißer Hintergrund\033[0m       \033[107m Heller weißer Hintergrund\033[0m"
echo " "
echo -e "\n\033[1m Kombinationen \033[0m"
echo -e "\033[1;91;44m HELLROTER TEXT AUF BLAUEM HINTERGRUND \033[0m"
echo -e "\033[4;93;105m UNTERSTRICHEN + HELLGELB AUF HELLMAGENTA \033[0m"
echo " "
}


#?──────────────────────────────────────────────────────────────────────────────────────────
#* Eingabeauswertung
#?──────────────────────────────────────────────────────────────────────────────────────────
case $KOMMANDO in
    servercheck) servercheck ;;
	createdirectory) createdirectory ;;
    mariasetup) mariasetup ;;
    sqlsetup) sqlsetup ;;
    setcrontab) setcrontab ;;
    
    opensimgitcopy|opensimgit) opensimgit ;;
    moneygitcopy|moneygit) moneygit ;;
    ruthrothgit) ruthrothgit ;;
    avatarassetsgit) avatarassetsgit ;;
    osslscriptsgit) osslscriptsgit ;;
    pbrtexturesgit) pbrtexturesgit ;;

    opensimbuild) opensimbuild ;;
    opensimcopy) opensimcopy ;;

    opensimupgrade) opensimupgrade ;;

    config_menu|configure|configureopensim) config_menu ;; # Die automatische konfiguration zu testzwecken.
    cleandoublecomments) cleandoublecomments ;;
    configclean|clean_comments_and_empty_lines) clean_comments_and_empty_lines ;;
    regionsconfig) regionsconfig ;;
    generatename|generate_name) generate_name ;;

    cleanconfig) clean_config "$2" ;;
    setrobusthg) setrobusthg ;; # Die automatische konfiguration zu testzwecken.
    setopensim) setopensim ;; # Die automatische konfiguration zu testzwecken.
    setgridcommon) setgridcommon ;; # Die automatische konfiguration zu testzwecken.
    setflotsamcache) setflotsamcache ;; # Die automatische konfiguration zu testzwecken.
    setosslenable) setosslenable ;; # Die automatische konfiguration zu testzwecken.
    setwelcome) setwelcome ;; # Die automatische konfiguration zu testzwecken.

    configall) configall ;; # Die automatische konfiguration zu testzwecken.
    autosetinstall) autosetinstall ;;

    start|opensimstart) opensimstart ;;
    stop|opensimstop) opensimstop ;;
    osrestart|autorestart|restart|opensimrestart) opensimrestart ;;

    standalone) standalone ;;
    standalonestart) standalonestart ;;
    standalonestop) standalonestop ;;
    standalonerestart) standalonerestart ;;

    reboot) reboot ;;
    check_screens) check_screens ;;
    dataclean) dataclean ;;
    pathclean) pathclean ;;
    cacheclean) cacheclean ;;
    logclean) logclean ;;
    mapclean) mapclean ;;
    autoallclean) autoallclean ;;
    regionsclean) regionsclean ;;
    cleanall) cleanall ;;
    renamefiles) renamefiles ;;  # Die automatische konfiguration zu testzwecken.
    colortest) colortest ;;
	h|help|hilfe|*) help ;;
esac

# Programm Ende
echo -e "\e[36m${SCRIPTNAME}\e[0m ${VERSION} wurde beendet $(date +'%Y-%m-%d %H:%M:%S')" >&2
exit 0
