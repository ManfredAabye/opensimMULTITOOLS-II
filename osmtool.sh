#!/bin/bash

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Informationen Kopfzeile
#?──────────────────────────────────────────────────────────────────────────────────────────
# https://github.com/ManfredAabye/opensimMULTITOOLS-II/blob/main/osmtool.sh

tput reset # Bildschirmausgabe loeschen inklusive dem Scrollbereich.
SCRIPTNAME="opensimMULTITOOL II"
VERSION="V25.4.48.141"
echo -e "\e[36m$SCRIPTNAME\e[0m $VERSION"
echo "Dies ist ein Tool welches der Verwaltung von OpenSim Servern dient."
echo "Bitte beachten Sie, dass die Anwendung auf eigene Gefahr und Verantwortung erfolgt."
echo -e "\e[33mZum Abbrechen bitte STRG+C oder CTRL+C drücken.\e[0m"
echo " "

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Variablen setzen
#?──────────────────────────────────────────────────────────────────────────────────────────

#* FARBDEFINITIONEN
COLOR_OK='\e[32m'          # Grün (Haken)
COLOR_BAD='\e[31m'         # Rot (Kreuz)
COLOR_HEADING='\e[97m'     # Weiß (Überschriften)
COLOR_START='\e[92m'       # Hellgrün (Startaktionen)
COLOR_STOP='\e[91m'        # Hellrot (Stopaktionen)
COLOR_SERVER='\e[36m'      # Cyan (Server/Verzeichnisse/IPs)
COLOR_DIR='\e[90m'         # Grau (Pfade)
COLOR_LABEL='\e[97m'       # Weiß (Beschriftungen)
COLOR_WARNING='\e[33m'     # Gelb (Warnungen)
COLOR_RESET='\e[0m'        # Farbreset
COLOR_LABEL='\e[97m'       # Weiß für Beschriftungen
COLOR_VALUE='\e[36m'       # Cyan für Werte
COLOR_ACTION='\e[92m'      # Hellgrün für Aktionen

function blankline() {
    echo " "
}

# Hauptpfad des Skripts automatisch setzen
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR" || exit 1
system_ip=$(hostname -I | awk '{print $1}')
echo -e "${COLOR_LABEL}Das Arbeitsverzeichnis ist:${COLOR_RESET} ${COLOR_VALUE}$SCRIPT_DIR${COLOR_RESET}"
echo -e "${COLOR_LABEL}Ihre IP Adresse ist:${COLOR_RESET} ${COLOR_VALUE}$system_ip${COLOR_RESET}"
blankline

KOMMANDO=$1 # Eingabeauswertung fuer Funktionen.

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

    echo -e "${COLOR_HEADING}🔍 Server-Kompatibilitätscheck wird durchgeführt...${COLOR_RESET}"

    # Ermitteln der Distribution und Version
    os_id=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    os_version=$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

    echo -e "${COLOR_LABEL}Server läuft mit:${COLOR_RESET} ${COLOR_SERVER}$os_id $os_version${COLOR_RESET}"

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
        required_dotnet="dotnet-sdk-8.0"
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_WARNING}Keine unterstützte Version für .NET gefunden!${COLOR_RESET}"
        return 1
    fi

    # .NET-Installationsstatus prüfen
    echo -e "${COLOR_HEADING}🔄 .NET Runtime-Überprüfung:${COLOR_RESET}"
    
    if [[ "$os_id" == "arch" || "$os_id" == "manjaro" ]]; then
        if ! pacman -Qi "$required_dotnet" >/dev/null 2>&1; then
            echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Installiere ${COLOR_SERVER}$required_dotnet${COLOR_RESET}..."
            sudo pacman -S --noconfirm "$required_dotnet"
            echo -e "${COLOR_OK}✓ ${COLOR_SERVER}$required_dotnet${COLOR_RESET} ${COLOR_ACTION}wurde erfolgreich installiert.${COLOR_RESET}"
        else
            echo -e "${COLOR_OK}✓ ${COLOR_SERVER}$required_dotnet${COLOR_RESET} ${COLOR_ACTION}ist bereits installiert.${COLOR_RESET}"
        fi
    else
        if ! dpkg -s "$required_dotnet" >/dev/null 2>&1; then
            echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Installiere ${COLOR_SERVER}$required_dotnet${COLOR_RESET}..."
            sudo apt-get install -y "$required_dotnet"
            echo -e "${COLOR_OK}✓ ${COLOR_SERVER}$required_dotnet${COLOR_RESET} ${COLOR_ACTION}wurde erfolgreich installiert.${COLOR_RESET}"
        else
            echo -e "${COLOR_OK}✓ ${COLOR_SERVER}$required_dotnet${COLOR_RESET} ${COLOR_ACTION}ist bereits installiert.${COLOR_RESET}"
        fi
    fi

    # Fehlende Pakete prüfen und installieren
    required_packages=("libc6" "libgcc-s1" "libgssapi-krb5-2" "libicu70" "liblttng-ust1" "libssl3" "libstdc++6" "libunwind8" "zlib1g" "libgdiplus" "zip" "screen")

    echo -e "${COLOR_HEADING}📦 Überprüfe fehlende Pakete...${COLOR_RESET}"
    for package in "${required_packages[@]}"; do
        if [[ "$os_id" == "arch" || "$os_id" == "manjaro" ]]; then
            if ! pacman -Qi "$package" >/dev/null 2>&1; then
                echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Installiere ${COLOR_SERVER}$package${COLOR_RESET}..."
                sudo pacman -S --noconfirm "$package"
            fi
        else
            if ! dpkg -s "$package" >/dev/null 2>&1; then
                echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Installiere ${COLOR_SERVER}$package${COLOR_RESET}..."
                sudo apt-get install -y "$package"
            fi
        fi
    done

    echo -e "${COLOR_OK}✓ ${COLOR_HEADING}Alle benötigten Pakete wurden installiert.${COLOR_RESET}"
    blankline
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Start Stop Standalone
#?──────────────────────────────────────────────────────────────────────────────────────────

function standalonestart() {
    cd opensim/bin || exit 1
    screen -fa -S opensim -d -U -m dotnet OpenSim.dll
    blankline
}

function standalonestop() {
    screen -S opensim -p 0 -X stuff "shutdown^M"
    blankline
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Start Stop Grid
#?──────────────────────────────────────────────────────────────────────────────────────────

#* OpenSim starten (robust → money → sim1 bis sim999)
function opensimstart() {
    echo -e "${COLOR_HEADING}⏳ ${COLOR_START}Starte das Grid!${COLOR_RESET}"

    # RobustServer starten
    if [[ -d "robust/bin" && -f "robust/bin/Robust.dll" ]]; then
        echo -e "${COLOR_OK}✓ ${COLOR_START}Starte ${COLOR_SERVER}RobustServer${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}robust/bin...${COLOR_RESET}"
        cd robust/bin || exit 1
        screen -fa -S robustserver -d -U -m dotnet Robust.dll
        cd - >/dev/null 2>&1 || exit 1
        sleep 30
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_SERVER}RobustServer: ${COLOR_BAD}Robust.dll nicht gefunden.${COLOR_RESET} ${COLOR_START}Überspringe Start.${COLOR_RESET}"
    fi

    # MoneyServer starten
    if [[ -f "robust/bin/MoneyServer.dll" ]]; then
        echo -e "${COLOR_OK}✓ ${COLOR_START}Starte ${COLOR_SERVER}MoneyServer${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}robust/bin...${COLOR_RESET}"
        cd robust/bin || exit 1
        screen -fa -S moneyserver -d -U -m dotnet MoneyServer.dll
        cd - >/dev/null 2>&1 || exit 1
        sleep 30
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_SERVER}MoneyServer: ${COLOR_BAD}MoneyServer.dll nicht gefunden.${COLOR_RESET} ${COLOR_START}Überspringe Start.${COLOR_RESET}"
    fi

    # Sim-Regionen starten
    
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" && -f "$sim_dir/OpenSim.dll" ]]; then
            echo -e "${COLOR_OK}✓ ${COLOR_START}Starte ${COLOR_SERVER}sim$i${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
            cd "$sim_dir" || continue
            screen -fa -S "sim$i" -d -U -m dotnet OpenSim.dll
            cd - >/dev/null 2>&1 || continue
            sleep 20
        fi
    done
    blankline
}

#* OpenSim stoppen (sim999 bis sim1 → money → robust)
function opensimstop() {
    echo -e "${COLOR_HEADING}⏳ ${COLOR_STOP}Stoppe das Grid!${COLOR_RESET}"

    # Sim-Regionen stoppen
    for ((i=999; i>=1; i--)); do
        sim_dir="sim$i"
        if screen -list | grep -q "$sim_dir"; then
            screen -S "sim$i" -p 0 -X stuff "shutdown^M"
            echo -e "${COLOR_OK}✓ ${COLOR_STOP}Stoppe ${COLOR_SERVER}sim$i${COLOR_RESET} ${COLOR_STOP}...${COLOR_RESET}"
            sleep 15
        fi
    done

    # MoneyServer stoppen
    if screen -list | grep -q "moneyserver"; then
        echo -e "${COLOR_OK}✓ ${COLOR_STOP}Stoppe ${COLOR_SERVER}MoneyServer${COLOR_RESET} ${COLOR_STOP}...${COLOR_RESET}"
        screen -S moneyserver -p 0 -X stuff "shutdown^M"
        sleep 30
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_SERVER}MoneyServer: ${COLOR_BAD}Läuft nicht.${COLOR_RESET} ${COLOR_STOP}Überspringe Stopp.${COLOR_RESET}"
    fi

    # RobustServer stoppen
    if screen -list | grep -q "robust"; then
        echo -e "${COLOR_OK}✓ ${COLOR_STOP}Stoppe ${COLOR_SERVER}RobustServer${COLOR_RESET} ${COLOR_STOP}...${COLOR_RESET}"
        screen -S robustserver -p 0 -X stuff "shutdown^M"
        sleep 30
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_SERVER}RobustServer: ${COLOR_BAD}Läuft nicht.${COLOR_RESET} ${COLOR_STOP}Überspringe Stopp.${COLOR_RESET}"
    fi
    blankline
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
    blankline
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Erstellen eines OpenSimulators
#?──────────────────────────────────────────────────────────────────────────────────────────

function opensimgit() {
    echo -e "${COLOR_HEADING}🔄 OpenSimulator GitHub-Verwaltung${COLOR_RESET}"
    
    echo -e "${COLOR_LABEL}Möchten Sie den OpenSimulator vom GitHub verwenden oder aktualisieren? (${COLOR_OK}[upgrade]${COLOR_LABEL}/new)${COLOR_RESET}"
    read -r user_choice
    user_choice=${user_choice:-upgrade}

    if [[ "$user_choice" == "new" ]]; then
        # Falls eine alte Version existiert, wird sie gelöscht
        if [[ -d "opensim" ]]; then
            echo -e "${COLOR_ACTION}Vorhandene OpenSimulator-Version wird gelöscht...${COLOR_RESET}"
            rm -rf opensim
            echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Alte OpenSimulator-Version wurde erfolgreich entfernt.${COLOR_RESET}"
        fi

        echo -e "${COLOR_ACTION}OpenSimulator wird von GitHub geholt...${COLOR_RESET}"
        git clone git://opensimulator.org/git/opensim opensim
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}OpenSimulator wurde erfolgreich heruntergeladen.${COLOR_RESET}"

    elif [[ "$user_choice" == "upgrade" ]]; then
        if [[ -d "opensim/.git" ]]; then
            echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Repository gefunden. Aktualisiere mit 'git pull'...${COLOR_RESET}"
            cd opensim || { echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Fehler: Kann nicht ins Verzeichnis wechseln!${COLOR_RESET}"; return 1; }
            git pull origin master && echo -e "${COLOR_OK}✅ ${COLOR_ACTION}OpenSimulator erfolgreich aktualisiert!${COLOR_RESET}"
            cd ..
        else
            echo -e "${COLOR_WARNING}⚠ ${COLOR_ACTION}OpenSimulator-Verzeichnis nicht gefunden. Klone Repository neu...${COLOR_RESET}"
            git clone git://opensimulator.org/git/opensim opensim && echo -e "${COLOR_OK}✅ ${COLOR_ACTION}OpenSimulator erfolgreich heruntergeladen!${COLOR_RESET}"
        fi
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Abbruch: Keine Aktion durchgeführt.${COLOR_RESET}"
        return 1
    fi

    # .NET-Version auswählen
    echo -e "${COLOR_LABEL}Möchten Sie diese Version mit .NET 6 oder .NET 8 betreiben? (${COLOR_OK}[8]${COLOR_LABEL}/6)${COLOR_RESET}"
    read -r dotnet_version
    dotnet_version=${dotnet_version:-8}

    if [[ "$dotnet_version" == "6" ]]; then
        echo -e "${COLOR_ACTION}Wechsle zu .NET 6-Version...${COLOR_RESET}"
        cd opensim || { echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Fehler: Verzeichnis 'opensim' nicht gefunden.${COLOR_RESET}"; return 1; }
        git checkout dotnet6
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}OpenSimulator wurde für .NET 6 umgebaut.${COLOR_RESET}"
    else
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Standardmäßig wird .NET 8 verwendet.${COLOR_RESET}"
    fi
    blankline
}

function moneygit() {
    echo -e "${COLOR_HEADING}💰 MoneyServer GitHub-Verwaltung${COLOR_RESET}"
    
    echo -e "${COLOR_LABEL}Möchten Sie den MoneyServer vom GitHub verwenden oder aktualisieren? (${COLOR_OK}[upgrade]${COLOR_LABEL}/new)${COLOR_RESET}"
    read -r user_choice
    user_choice=${user_choice:-upgrade}

    if [[ "$user_choice" == "new" ]]; then
        if [[ -d "opensimcurrencyserver" ]]; then
            echo -e "${COLOR_ACTION}Vorhandene MoneyServer-Version wird gelöscht...${COLOR_RESET}"
            rm -rf opensimcurrencyserver
            echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Alte MoneyServer-Version wurde erfolgreich entfernt.${COLOR_RESET}"
        fi
        echo -e "${COLOR_ACTION}MONEYSERVER: MoneyServer wird vom GIT geholt...${COLOR_RESET}"
        git clone https://github.com/ManfredAabye/opensimcurrencyserver-dotnet.git opensimcurrencyserver
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}MoneyServer wurde erfolgreich heruntergeladen.${COLOR_RESET}"
    elif [[ "$user_choice" == "upgrade" ]]; then
        if [[ -d "opensimcurrencyserver/.git" ]]; then
            echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Repository gefunden. Aktualisiere mit 'git pull'...${COLOR_RESET}"
            cd opensimcurrencyserver || { echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Fehler: Kann nicht ins Verzeichnis wechseln!${COLOR_RESET}"; return 1; }
            
            # Automatische Branch-Erkennung
            branch_name=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
            git pull origin "$branch_name" && echo -e "${COLOR_OK}✅ ${COLOR_ACTION}MoneyServer erfolgreich aktualisiert!${COLOR_RESET}"
            
            cd ..
        else
            echo -e "${COLOR_WARNING}⚠ ${COLOR_ACTION}MoneyServer-Verzeichnis nicht gefunden. Klone Repository neu...${COLOR_RESET}"
            git clone https://github.com/ManfredAabye/opensimcurrencyserver-dotnet.git opensimcurrencyserver && echo -e "${COLOR_OK}✅ ${COLOR_ACTION}MoneyServer erfolgreich heruntergeladen!${COLOR_RESET}"
        fi
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Abbruch: Keine Aktion durchgeführt.${COLOR_RESET}"
        return 1
    fi

    # Prüfen, ob das Verzeichnis existiert, bevor es kopiert wird
    if [[ -d "opensimcurrencyserver/addon-modules" ]]; then
        cp -r opensimcurrencyserver/addon-modules opensim/
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}MONEYSERVER: addon-modules wurde nach opensim kopiert${COLOR_RESET}"
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}MONEYSERVER: addon-modules existiert nicht${COLOR_RESET}"
    fi

    if [[ -d "opensimcurrencyserver/bin" ]]; then
        cp -r opensimcurrencyserver/bin opensim/
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}MONEYSERVER: bin wurde nach opensim kopiert${COLOR_RESET}"
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}MONEYSERVER: bin existiert nicht${COLOR_RESET}"
    fi
    
    blankline
    return 0
}

# Versuch um die Avatar-Assets von Ruth und Roth herunterzuladen zu Bearbeiten.


# function ruthrothgit() {
#     echo -e "${COLOR_HEADING}👥 Ruth & Roth Avatar-Assets Download${COLOR_RESET}"
    
#     echo -e "${COLOR_LABEL}Möchten Sie die Ruth2 und Roth2 Avatare neu klonen oder aktualisieren? (${COLOR_OK}[upgrade]${COLOR_LABEL}/new)${COLOR_RESET}"
#     read -r user_choice
#     user_choice=${user_choice:-upgrade}

#     declare -A repos=(
#         ["Ruth2"]="https://github.com/ManfredAabye/Ruth2.git"
#         ["Roth2"]="https://github.com/ManfredAabye/Roth2.git"
#     )

#     base_dir="ruthroth"
#     mkdir -p "$base_dir"

#     for avatar in "${!repos[@]}"; do
#         repo_url="${repos[$avatar]}"
#         target_dir="$avatar"

#         echo -e "${COLOR_ACTION}➤ Bearbeite ${COLOR_SERVER}$avatar${COLOR_ACTION}...${COLOR_RESET}"

#         if [[ "$user_choice" == "new" ]]; then
#             [[ -d "$target_dir" ]] && echo -e "  ${COLOR_ACTION}➜ Lösche alte Version von ${COLOR_SERVER}$avatar${COLOR_ACTION}...${COLOR_RESET}" && rm -rf "$target_dir"
#             echo -e "  ${COLOR_ACTION}➜ Klone ${COLOR_SERVER}$avatar${COLOR_ACTION} von GitHub...${COLOR_RESET}"
#             git clone "$repo_url" "$target_dir" && echo -e "  ${COLOR_OK}✅ ${COLOR_SERVER}$avatar${COLOR_RESET} ${COLOR_ACTION}wurde neu heruntergeladen.${COLOR_RESET}"
#         elif [[ "$user_choice" == "upgrade" ]]; then
#             if [[ -d "$target_dir/.git" ]]; then
#                 echo -e "  ${COLOR_ACTION}➜ Aktualisiere ${COLOR_SERVER}$avatar${COLOR_ACTION} mit git pull...${COLOR_RESET}"
#                 cd "$target_dir" || { echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Fehler beim Wechsel in ${COLOR_DIR}$target_dir${COLOR_RESET}"; continue; }
#                 branch_name=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
#                 git pull origin "$branch_name" && echo -e "  ${COLOR_OK}✅ ${COLOR_SERVER}$avatar${COLOR_RESET} ${COLOR_ACTION}wurde aktualisiert.${COLOR_RESET}"
#                 cd ..
#             else
#                 echo -e "  ${COLOR_WARNING}⚠ ${COLOR_ACTION}Verzeichnis ${COLOR_DIR}$target_dir${COLOR_ACTION} existiert nicht oder ist kein Git-Repo. Klone neu...${COLOR_RESET}"
#                 git clone "$repo_url" "$target_dir" && echo -e "  ${COLOR_OK}✅ ${COLOR_SERVER}$avatar${COLOR_RESET} ${COLOR_ACTION}wurde neu heruntergeladen.${COLOR_RESET}"
#             fi
#         else
#             echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Ungültige Eingabe. Abbruch.${COLOR_RESET}"
#             return 1
#         fi

#         # Nur die IAR-Dateien entpacken
#         echo -e "  ${COLOR_ACTION}➜ Entpacke benötigte IAR-Dateien in ${COLOR_DIR}$base_dir${COLOR_ACTION}...${COLOR_RESET}"
#         mkdir -p "$base_dir/extracted"
#         for iar_file in "${avatar}-v1.iar" "${avatar}-v2.iar" "${avatar}-v3.iar" "${avatar}-v4.iar"; do
#             iar_path="$target_dir/Artifacts/IAR/$iar_file"
#             if [[ -f "$iar_path" ]]; then
#                 tar -xzf "$iar_path" -C "$base_dir/extracted" && echo -e "    ${COLOR_OK}✓ ${COLOR_DIR}${iar_file}${COLOR_RESET} ${COLOR_ACTION}entpackt.${COLOR_RESET}"
#             else
#                 echo -e "    ${COLOR_WARNING}⚠ IAR-Datei ${COLOR_DIR}${iar_file}${COLOR_WARNING} nicht gefunden. Überspringe...${COLOR_RESET}"
#             fi
#         done
#     done

#     echo -e "${COLOR_OK}✅ ${COLOR_ACTION}Alle benötigten Avatar-IAR-Dateien wurden entpackt und bereitgestellt.${COLOR_RESET}"

#     # Automatische Integration in OpenSim
#     echo -e "${COLOR_ACTION}Führe updatelibrary.py für alle Assets aus...${COLOR_RESET}"
#     python3 updatelibrary.py -n "Roth2-v1" -s "Roth2-v1" -a Roth2-v1 -i Roth2-v1
#     python3 updatelibrary.py -n "Roth2-v2" -s "Roth2-v2" -a Roth2-v2 -i Roth2-v2
#     python3 updatelibrary.py -n "Ruth2-v3" -s "Ruth2-v3" -a Ruth2-v3 -i Ruth2-v3
#     python3 updatelibrary.py -n "Ruth2-v4" -s "Ruth2-v4" -a Ruth2-v4 -i Ruth2-v4

#     # Verzeichnisse für Libraries erstellen
#     echo -e "${COLOR_ACTION}Erstelle Inventar-Verzeichnisse...${COLOR_RESET}"
#     mkdir -p opensim/bin/inventory/Roth2-v1Library
#     mkdir -p opensim/bin/inventory/Roth2-v2Library
#     mkdir -p opensim/bin/inventory/Ruth2-v3Library
#     mkdir -p opensim/bin/inventory/Ruth2-v4Library

#     echo -e "${COLOR_OK}✅ ${COLOR_ACTION}Verzeichnisse für Inventar-Libraries wurden erstellt.${COLOR_RESET}"
# }

function ruthrothgit() {
    # Schritt 1 das bereitstellen der Pakete zur weiteren bearbeitung.
    echo -e "${COLOR_HEADING}👥 Ruth & Roth Avatar-Assets Vorbereitung${COLOR_RESET}"

    base_dir="ruthroth"
    mkdir -p "$base_dir"

    declare -A repos=(
        ["Ruth2"]="https://github.com/ManfredAabye/Ruth2.git"
        ["Roth2"]="https://github.com/ManfredAabye/Roth2.git"
    )

    for avatar in "${!repos[@]}"; do
        repo_url="${repos[$avatar]}"
        target_dir="$avatar"

        if [[ ! -d "$target_dir" ]]; then
            echo -e "  ${COLOR_ACTION}➜ Klone ${COLOR_SERVER}$avatar${COLOR_ACTION} von GitHub...${COLOR_RESET}"
            git clone "$repo_url" "$target_dir" && echo -e "  ${COLOR_OK}✅ ${COLOR_SERVER}$avatar${COLOR_RESET} ${COLOR_ACTION}wurde heruntergeladen.${COLOR_RESET}"
        else
            echo -e "  ${COLOR_OK}✅ ${COLOR_SERVER}$avatar${COLOR_RESET} ${COLOR_ACTION}ist bereits vorhanden, überspringe Download.${COLOR_RESET}"
        fi

        # Kopiere nur die relevanten IAR-Dateien direkt nach ruthroth
        echo -e "  ${COLOR_ACTION}➜ Kopiere benötigte IAR-Dateien nach ${COLOR_DIR}$base_dir${COLOR_ACTION}...${COLOR_RESET}"
        cp "$target_dir/Artifacts/IAR/"*.iar "$base_dir/" 2>/dev/null && echo -e "    ${COLOR_OK}✓ IAR-Dateien von ${COLOR_SERVER}$avatar${COLOR_RESET} kopiert.${COLOR_RESET}"
    done

    # Kopiere das updatelibrary.py-Skript ins Hauptverzeichnis ruthroth
    echo -e "  ${COLOR_ACTION}➜ Kopiere updatelibrary.py nach ${COLOR_DIR}$base_dir${COLOR_ACTION}...${COLOR_RESET}"
    cp "updatelibrary.py" "$base_dir/" && echo -e "    ${COLOR_OK}✓ updatelibrary.py wurde kopiert.${COLOR_RESET}"

    echo "Verzeichniswechsel in $base_dir"

    # Wechsel ins ruthroth-Verzeichnis
    cd "$base_dir" || { echo -e "${COLOR_BAD}✘ Fehler beim Wechsel ins Verzeichnis ${COLOR_DIR}$base_dir${COLOR_RESET}"; return 1; }

    # Entpacke die IAR-Dateien direkt in ruthroth
    echo -e "  ${COLOR_ACTION}➜ Entpacke IAR-Pakete in ${COLOR_DIR}$base_dir${COLOR_ACTION}...${COLOR_RESET}"
    for iar_file in *.iar; do
        if [[ -f "$iar_file" ]]; then
            target_dir="${iar_file%.iar}"  # Erstellt Verzeichnisname basierend auf Dateiname ohne .iar
            mkdir -p "$target_dir"
            tar -xzf "$iar_file" -C "$target_dir/" && echo -e "    ✓ ${iar_file} entpackt nach ${target_dir}"
        else
            echo -e "    ⚠ IAR-Datei ${iar_file} nicht gefunden. Überspringe..."
        fi
    done

    echo -e "${COLOR_OK}✅ ${COLOR_ACTION}Grundlage für die OpenSimulator-Pakete wurde erfolgreich erstellt!${COLOR_RESET}"

    # Schritt 2 die verwendung von updatelibrary.py.
    cd ruthroth
    python3 updatelibrary.py -n "Roth2-v1" -s "Roth2-v1" -a Roth2-v1 -i Roth2-v1
    python3 updatelibrary.py -n "Roth2-v2" -s "Roth2-v2" -a Roth2-v2 -i Roth2-v2
    python3 updatelibrary.py -n "Ruth2-v3" -s "Ruth2-v3" -a Ruth2-v3 -i Ruth2-v3
    python3 updatelibrary.py -n "Ruth2-v4" -s "Ruth2-v4" -a Ruth2-v4 -i Ruth2-v4

    # Schritt 3 das kopieren der Daten. Das einfügen der Daten in den Dateien

}


function osslscriptsgit() {
    echo -e "${COLOR_HEADING}📜 OSSL Beispiel-Skripte GitHub-Verwaltung${COLOR_RESET}"
    
    echo -e "${COLOR_LABEL}Möchten Sie die OpenSim OSSL Beispiel-Skripte vom GitHub verwenden oder aktualisieren? (${COLOR_OK}[upgrade]${COLOR_LABEL}/new)${COLOR_RESET}"
    read -r user_choice
    user_choice=${user_choice:-upgrade}

    repo_name="opensim-ossl-example-scripts"
    repo_url="https://github.com/ManfredAabye/opensim-ossl-example-scripts.git"

    if [[ "$user_choice" == "new" ]]; then
        if [[ -d "$repo_name" ]]; then
            echo -e "${COLOR_ACTION}Vorhandene Version wird gelöscht...${COLOR_RESET}"
            rm -rf "$repo_name"
            echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Alte Version wurde erfolgreich entfernt.${COLOR_RESET}"
        fi
        echo -e "${COLOR_ACTION}Beispiel-Skripte werden vom GitHub heruntergeladen...${COLOR_RESET}"
        git clone "$repo_url" "$repo_name" && echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Repository wurde erfolgreich heruntergeladen.${COLOR_RESET}"
    elif [[ "$user_choice" == "upgrade" ]]; then
        if [[ -d "$repo_name/.git" ]]; then
            echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Repository gefunden. Aktualisiere mit 'git pull'...${COLOR_RESET}"
            cd "$repo_name" || { echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Fehler beim Wechsel ins Verzeichnis!${COLOR_RESET}"; return 1; }
            branch_name=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
            git pull origin "$branch_name" && echo -e "${COLOR_OK}✅ ${COLOR_ACTION}Repository erfolgreich aktualisiert.${COLOR_RESET}"
            cd ..
        else
            echo -e "${COLOR_WARNING}⚠ ${COLOR_ACTION}Verzeichnis nicht gefunden oder kein Git-Repo. Klone Repository neu...${COLOR_RESET}"
            git clone "$repo_url" "$repo_name" && echo -e "${COLOR_OK}✅ ${COLOR_ACTION}Repository wurde erfolgreich heruntergeladen.${COLOR_RESET}"
        fi
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Abbruch: Keine Aktion durchgeführt.${COLOR_RESET}"
        return 1
    fi

    # Zielverzeichnisse erstellen falls nicht vorhanden
    mkdir -p opensim/bin/assets/
    mkdir -p opensim/bin/inventory/

    # Kopieren der Verzeichnisse
    if [[ -d "$repo_name/ScriptsAssetSet" ]]; then
        cp -r "$repo_name/ScriptsAssetSet" opensim/bin/assets/
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}ScriptsAssetSet wurde nach opensim/bin/assets kopiert.${COLOR_RESET}"
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}ScriptsAssetSet Verzeichnis nicht gefunden!${COLOR_RESET}"
    fi

    if [[ -d "$repo_name/inventory/ScriptsLibrary" ]]; then
        cp -r "$repo_name/inventory/ScriptsLibrary" opensim/bin/inventory/
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}ScriptsLibrary wurde nach opensim/bin/inventory kopiert.${COLOR_RESET}"
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}ScriptsLibrary Verzeichnis nicht gefunden!${COLOR_RESET}"
    fi
    
    blankline
    return 0
}

function pbrtexturesgit() {
    echo -e "${COLOR_HEADING}🎨 PBR Texturen Installation${COLOR_RESET}"
    
    textures_zip_url="https://github.com/ManfredAabye/OpenSim_PBR_Textures/releases/download/PBR/OpenSim_PBR_Textures.zip"
    zip_file="OpenSim_PBR_Textures.zip"
    unpacked_dir="OpenSim_PBR_Textures"
    target_dir="opensim"

    # ZIP herunterladen, wenn nicht vorhanden
    if [[ ! -f "$zip_file" ]]; then
        echo -e "${COLOR_ACTION}Lade OpenSim PBR Texturen herunter...${COLOR_RESET}"
        if ! wget -q --show-progress -O "$zip_file" "$textures_zip_url"; then
            echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Fehler beim Herunterladen der Texturen!${COLOR_RESET}"
            return 1
        fi
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Download abgeschlossen: ${COLOR_DIR}$zip_file${COLOR_RESET}"
    else
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}ZIP-Datei bereits vorhanden: ${COLOR_DIR}$zip_file${COLOR_RESET}"
    fi

    # Entpacken, wenn Verzeichnis noch nicht existiert
    if [[ ! -d "$unpacked_dir" ]]; then
        echo -e "${COLOR_ACTION}Entpacke Texturen nach ${COLOR_DIR}$unpacked_dir${COLOR_ACTION}...${COLOR_RESET}"
        unzip -q "$zip_file" -d .
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Entpackt.${COLOR_RESET}"
    else
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Verzeichnis ${COLOR_DIR}$unpacked_dir${COLOR_ACTION} existiert bereits – überspringe Entpacken.${COLOR_RESET}"
    fi

    # Kopieren nach opensim/bin
    if [[ -d "$unpacked_dir/bin" ]]; then
        echo -e "${COLOR_ACTION}Kopiere Texturen nach ${COLOR_DIR}$target_dir${COLOR_ACTION}...${COLOR_RESET}"
        cp -r "$unpacked_dir/bin" "$target_dir"
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Texturen erfolgreich installiert in ${COLOR_DIR}$target_dir${COLOR_RESET}"
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Verzeichnis ${COLOR_DIR}$unpacked_dir/bin${COLOR_ERROR} nicht gefunden!${COLOR_RESET}"
        return 1
    fi
    
    blankline
    return 0
}

function versionrevision() {
    file="opensim/OpenSim/Framework/VersionInfo.cs"

    if [[ ! -f "$file" ]]; then
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Datei nicht gefunden: ${COLOR_DIR}$file${COLOR_RESET}"
        return 1
    fi

    echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Bearbeite Datei: ${COLOR_DIR}$file${COLOR_RESET}"

    # Ändere Flavour.Dev zu Flavour.Extended
    sed -i 's/public const Flavour VERSION_FLAVOUR = Flavour\.Dev;/public const Flavour VERSION_FLAVOUR = Flavour.Extended;/' "$file"

    # Entferne "Nessie" aus dem Versions-String
    sed -i 's/OpenSim {versionNumber} Nessie {flavour}/OpenSim {versionNumber} {flavour}/' "$file"

    echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Änderungen wurden erfolgreich vorgenommen.${COLOR_RESET}"
    blankline
    return 0
}

function opensimbuild() {
    echo -e "${COLOR_HEADING}🏗️  OpenSimulator Build-Prozess${COLOR_RESET}"
    
    echo -e "${COLOR_LABEL}Möchten Sie den OpenSimulator jetzt erstellen? (${COLOR_OK}[ja]${COLOR_LABEL}/nein)${COLOR_RESET}"
    read -r user_choice

    user_choice=${user_choice:-ja}

    if [[ "$user_choice" == "ja" ]]; then
        if [[ -d "opensim" ]]; then
            cd opensim || { echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Fehler: Verzeichnis 'opensim' nicht gefunden.${COLOR_RESET}"; return 1; }
            echo -e "${COLOR_ACTION}Starte Prebuild-Skript...${COLOR_RESET}"
            bash runprebuild.sh
            echo -e "${COLOR_ACTION}Baue OpenSimulator...${COLOR_RESET}"
            dotnet build --configuration Release OpenSim.sln
            echo -e "${COLOR_OK}✓ ${COLOR_ACTION}OpenSimulator wurde erfolgreich erstellt.${COLOR_RESET}"
        else
            echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Fehler: Das Verzeichnis 'opensim' existiert nicht.${COLOR_RESET}"
            return 1
        fi
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Abbruch: OpenSimulator wird nicht erstellt.${COLOR_RESET}"
    fi
    blankline
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Erstellen eines OpenSimulators Grids
#?──────────────────────────────────────────────────────────────────────────────────────────

function createdirectory() {
    echo -e "${COLOR_HEADING}📂 Verzeichniserstellung${COLOR_RESET}"
    
    echo -e "${COLOR_LABEL}Möchten Sie einen Gridserver oder einen Regionsserver erstellen? (${COLOR_OK}[grid]${COLOR_LABEL}/region)${COLOR_RESET}"
    read -r server_type

    # Standardmäßig Gridserver wählen, falls keine Eingabe erfolgt
    server_type=${server_type:-grid}

    if [[ "$server_type" == "grid" ]]; then
        echo -e "${COLOR_ACTION}Erstelle robust Verzeichnis...${COLOR_RESET}"
        mkdir -p robust/bin
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Robust Verzeichnis wurde erstellt.${COLOR_RESET}"

        # Nach der Erstellung des Gridservers auch die Regionsserver erstellen lassen
        echo -e "${COLOR_LABEL}Wie viele Regionsserver benötigen Sie?${COLOR_RESET}"
        read -r num_regions
    elif [[ "$server_type" == "region" ]]; then
        echo -e "${COLOR_LABEL}Wie viele Regionsserver benötigen Sie?${COLOR_RESET}"
        read -r num_regions
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Ungültige Eingabe. Bitte geben Sie 'grid' oder 'region' ein.${COLOR_RESET}"
        return 1
    fi

    # Überprüfen, ob die Anzahl der Regionsserver bis 999 geht
    if [[ "$num_regions" =~ ^[0-9]+$ && "$num_regions" -le 999 ]]; then
        for ((i=1; i<=num_regions; i++)); do
            dir_name="sim$i"
            if [[ ! -d "$dir_name" ]]; then
                mkdir -p "$dir_name/bin"
                echo -e "${COLOR_OK}✓ ${COLOR_DIR}$dir_name${COLOR_RESET} ${COLOR_ACTION}wurde erstellt.${COLOR_RESET}"
            else
                echo -e "${COLOR_OK}✓ ${COLOR_DIR}$dir_name${COLOR_RESET} ${COLOR_WARNING}existiert bereits und wird übersprungen.${COLOR_RESET}"
            fi
        done
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Ungültige Anzahl an Regionsserver. Bitte geben Sie eine gültige Zahl zwischen 1 und 999 ein.${COLOR_RESET}"
    fi
    blankline
}

function opensimcopy() {
    echo -e "${COLOR_HEADING}📦 OpenSim Dateikopie${COLOR_RESET}"
    
    # Prüfen, ob das Verzeichnis "opensim" existiert
    if [[ ! -d "opensim" ]]; then
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Fehler: Das Verzeichnis 'opensim' existiert nicht.${COLOR_RESET}"
        return 1
    fi

    # Prüfen, ob das Unterverzeichnis "opensim/bin" existiert
    if [[ ! -d "opensim/bin" ]]; then
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Fehler: Das Verzeichnis 'opensim/bin' existiert nicht.${COLOR_RESET}"
        return 1
    fi

    # Prüfen, ob das Verzeichnis "robust" existiert und Dateien kopieren
    if [[ -d "robust/bin" ]]; then
        cp -r opensim/bin/* robust/bin
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Dateien aus ${COLOR_DIR}opensim/bin${COLOR_RESET} ${COLOR_ACTION}wurden nach ${COLOR_DIR}robust/bin${COLOR_RESET} ${COLOR_ACTION}kopiert.${COLOR_RESET}"
    else
        echo -e "${COLOR_WARNING}⚠ ${COLOR_ACTION}Hinweis: 'robust' Verzeichnis nicht gefunden, keine Kopie durchgeführt.${COLOR_RESET}"
    fi

    # Alle simX-Verzeichnisse suchen und Dateien kopieren
    for sim_dir in sim*; do
        if [[ -d "$sim_dir/bin" ]]; then
            cp -r opensim/bin/* "$sim_dir/bin/"
            echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Dateien aus ${COLOR_DIR}opensim/bin${COLOR_RESET} ${COLOR_ACTION}wurden nach ${COLOR_DIR}$sim_dir/bin${COLOR_RESET} ${COLOR_ACTION}kopiert.${COLOR_RESET}"
        fi
    done

    blankline
}

# mariasetup und sqlsetup werden in einer Funktion zusammengefasst, kombiniert und funktional erweitert.
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
    blankline
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
    blankline
}

setcrontab() {
    # Strict Mode: Fehler sofort erkennen
    set -euo pipefail

    echo -e "${COLOR_HEADING}⏰ Cron-Job Einrichtung${COLOR_RESET}"

    # Sicherheitsabfrage: Nur als root/sudo ausführen
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}FEHLER: Dieses Skript benötigt root-Rechte! (sudo verwenden)${COLOR_RESET}" >&2
        return 1
    fi

    # Prüfen, ob SCRIPT_DIR gesetzt und gültig ist
    if [ -z "${SCRIPT_DIR:-}" ]; then
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}FEHLER: 'SCRIPT_DIR' muss gesetzt sein!${COLOR_RESET}" >&2
        return 1
    fi

    if [ ! -d "$SCRIPT_DIR" ]; then
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}FEHLER: Verzeichnis '${COLOR_DIR}$SCRIPT_DIR${COLOR_ERROR}' existiert nicht!${COLOR_RESET}" >&2
        return 1
    fi

    # Temporäre Datei für neue Cron-Jobs
    local temp_cron
    temp_cron=$(mktemp) || {
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}FEHLER: Temp-Datei konnte nicht erstellt werden${COLOR_RESET}" >&2
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
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Cron-Jobs wurden ERFOLGREICH ersetzt:${COLOR_RESET}"
        crontab -l | grep -v '^#' | sed '/^$/d' | while read -r line; do
            echo -e "${COLOR_DIR}$line${COLOR_RESET}"
        done
        return 0
    else
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}FEHLER: Installation fehlgeschlagen. Prüfe $temp_cron manuell.${COLOR_RESET}" >&2
        return 1
    fi
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Upgrade des OpenSimulators Grids
#?──────────────────────────────────────────────────────────────────────────────────────────

function opensimupgrade() {
    echo -e "\n${COLOR_WARNING}⚠ Der OpenSimulator muss zuerst im Verzeichnis 'opensim' vorliegen!${COLOR_RESET}"
    echo -e "${COLOR_LABEL}Möchten Sie den OpenSimulator aktualisieren? (${COLOR_BAD}[no]${COLOR_LABEL}/yes)${COLOR_RESET}"
    read -r user_choice
    user_choice=${user_choice:-no}

    # Prüfe, ob das Verzeichnis vorhanden ist
    if [[ ! -d "opensim" ]]; then
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Fehler: Das Verzeichnis '${COLOR_DIR}opensim${COLOR_ERROR}' existiert nicht${COLOR_RESET}"
        return 1
    fi

    # Prüfe, ob im Verzeichnis 'opensim/bin' die Dateien OpenSim.dll und Robust.dll vorhanden sind
    if [[ ! -f "opensim/bin/OpenSim.dll" || ! -f "opensim/bin/Robust.dll" ]]; then
        echo -e "${COLOR_BAD}✘ ${COLOR_ERROR}Fehler: Benötigte Dateien (OpenSim.dll und/oder Robust.dll) fehlen im Verzeichnis '${COLOR_DIR}opensim/bin${COLOR_ERROR}'${COLOR_RESET}"
        echo -e "\n${COLOR_WARNING}❓ Haben Sie vergessen den OpenSimulator zuerst zu Kompilieren?${COLOR_RESET}"
        return 1
    fi

    if [[ "$user_choice" == "yes" ]]; then
        echo -e "${COLOR_ACTION}OpenSimulator wird gestoppt...${COLOR_RESET}"
        opensimstop
        sleep 30

        echo -e "${COLOR_ACTION}OpenSimulator wird kopiert...${COLOR_RESET}"
        opensimcopy

        echo -e "${COLOR_ACTION}OpenSimulator wird gestartet...${COLOR_RESET}"
        opensimstart

        echo -e "${COLOR_OK}✔ ${COLOR_ACTION}Upgrade abgeschlossen.${COLOR_RESET}"
    else
        echo -e "${COLOR_WARNING}Upgrade vom Benutzer abgebrochen.${COLOR_RESET}"
    fi
    blankline
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Bereinigen des OpenSimulators Grids
#?──────────────────────────────────────────────────────────────────────────────────────────

function dataclean() {
    echo -e "${COLOR_HEADING}🧹 Datenbereinigung wird durchgeführt...${COLOR_RESET}"

    # RobustServer bereinigen
    if [[ -d "robust/bin" ]]; then
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Lösche Dateien im RobustServer...${COLOR_RESET}"
        find "robust/bin" -maxdepth 1 -type f \( -name "*.log" -o -name "*.dll" -o -name "*.exe" -o -name "*.so" -o -name "*.xml" -o -name "*.dylib" -o -name "*.example" -o -name "*.sample" -o -name "*.txt" -o -name "*.config" -o -name "*.py" -o -name "*.old" -o -name "*.pdb" \) -delete
    fi

    # Alle simX-Server bereinigen
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" ]]; then
            echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Lösche Dateien in ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
            find "$sim_dir" -maxdepth 1 -type f \( -name "*.log" -o -name "*.dll" -o -name "*.exe" -o -name "*.so" -o -name "*.xml" -o -name "*.dylib" -o -name "*.example" -o -name "*.sample" -o -name "*.txt" -o -name "*.config" -o -name "*.py" -o -name "*.old" -o -name "*.pdb" \) -delete
        fi
    done
    echo -e "${COLOR_HEADING}✅ Datenbereinigung abgeschlossen${COLOR_RESET}"
    blankline
}

function pathclean() {
    directories=("assetcache" "maptiles" "MeshCache" "j2kDecodeCache" "ScriptEngines" "bakes" "addon-modules")
    wildcard_dirs=("addin-db-*")  # Separate Liste für Wildcard-Verzeichnisse

    echo -e "${COLOR_HEADING}🗂️ Verzeichnisbereinigung wird durchgeführt...${COLOR_RESET}"

    # RobustServer bereinigen
    if [[ -d "robust/bin" ]]; then
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Lösche komplette Verzeichnisse im RobustServer...${COLOR_RESET}"
        
        # Normale Verzeichnisse
        for dir in "${directories[@]}"; do
            target="robust/bin/$dir"
            if [[ -d "$target" ]]; then
                rm -rf "$target"
                echo -e "  ${COLOR_ACTION}Verzeichnis gelöscht: ${COLOR_DIR}$target${COLOR_RESET}"
            fi
        done
        
        # Wildcard-Verzeichnisse
        for pattern in "${wildcard_dirs[@]}"; do
            for target in robust/bin/$pattern; do
                if [[ -d "$target" ]]; then
                    rm -rf "$target"
                    echo -e "  ${COLOR_WARNING}Verzeichnis gelöscht: ${COLOR_DIR}$target${COLOR_RESET}"
                fi
            done
        done
    fi

    # Alle simX-Server bereinigen
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" ]]; then
            echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Lösche komplette Verzeichnisse in ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
            
            # Normale Verzeichnisse
            for dir in "${directories[@]}"; do
                target="$sim_dir/$dir"
                if [[ -d "$target" ]]; then
                    rm -rf "$target"
                    echo -e "  ${COLOR_ACTION}Verzeichnis gelöscht: ${COLOR_DIR}$target${COLOR_RESET}"
                fi
            done
            
            # Wildcard-Verzeichnisse
            for pattern in "${wildcard_dirs[@]}"; do
                for target in $sim_dir/$pattern; do
                    if [[ -d "$target" ]]; then
                        rm -rf "$target"
                        echo -e "  ${COLOR_WARNING}Verzeichnis gelöscht: ${COLOR_DIR}$target${COLOR_RESET}"
                    fi
                done
            done
        fi
    done
    echo -e "${COLOR_HEADING}✅ Verzeichnisbereinigung abgeschlossen${COLOR_RESET}"
    blankline
}

function cacheclean() {
    cache_dirs=("assetcache" "maptiles" "MeshCache" "j2kDecodeCache" "ScriptEngines")

    echo -e "${COLOR_HEADING}♻️ Cache-Bereinigung wird durchgeführt...${COLOR_RESET}"

    # RobustServer bereinigen
    if [[ -d "robust/bin" ]]; then
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Leere Cache-Verzeichnisse im RobustServer...${COLOR_RESET}"
        for dir in "${cache_dirs[@]}"; do
            target="robust/bin/$dir"
            if [[ -d "$target" ]]; then
                find "$target" -mindepth 1 -delete
                echo -e "  ${COLOR_ACTION}Inhalt geleert: ${COLOR_DIR}$target${COLOR_RESET}"
            fi
        done
    fi

    # Alle simX-Server bereinigen
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" ]]; then
            echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Leere Cache-Verzeichnisse in ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
            for dir in "${cache_dirs[@]}"; do
                target="$sim_dir/$dir"
                if [[ -d "$target" ]]; then
                    find "$target" -mindepth 1 -delete
                    echo -e "  ${COLOR_ACTION}Inhalt geleert: ${COLOR_DIR}$target${COLOR_RESET}"
                fi
            done
        fi
    done
    echo -e "${COLOR_HEADING}✅ Cache-Bereinigung abgeschlossen${COLOR_RESET}"
    blankline
}

function logclean() {
    echo -e "${COLOR_HEADING}📋 Log-Bereinigung wird durchgeführt...${COLOR_RESET}"

    # RobustServer bereinigen
    if [[ -d "robust/bin" ]]; then
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Lösche Log-Dateien in ${COLOR_DIR}robust/bin...${COLOR_RESET}"
        rm -f robust/bin/*.log
    fi

    # Alle simX-Server bereinigen (sim1 bis sim999)
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" ]]; then
            echo -e "${COLOR_OK}✓ ${COLOR_ACTION}Lösche Log-Dateien in ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
            rm -f "$sim_dir"/*.log
        fi
    done
    
    echo -e "${COLOR_HEADING}Log-Bereinigung abgeschlossen${COLOR_RESET}"
    blankline
}

function mapclean() {
    echo -e "${COLOR_HEADING}🗺️ Map-Tile-Bereinigung wird durchgeführt...${COLOR_RESET}"

    # Sicherheitscheck für robust/bin/maptiles
    if [[ -d "robust/bin/maptiles" ]]; then
        rm -rf -- "robust/bin/maptiles/"*
        echo -e "${COLOR_OK}✓ ${COLOR_ACTION}robust/bin/maptiles geleert${COLOR_RESET}"
    fi

    # Sicherheitscheck für alle simX/bin/maptiles
    for ((i=1; i<=999; i++)); do
        local sim_dir="sim$i/bin/maptiles"
        if [[ -d "$sim_dir" ]]; then
            # shellcheck disable=SC2115
            rm -rf -- "${sim_dir}/"*
            echo -e "${COLOR_OK}✓ ${COLOR_ACTION}${COLOR_DIR}$sim_dir${COLOR_RESET} ${COLOR_ACTION}geleert${COLOR_RESET}"
        fi
    done

    echo -e "${COLOR_HEADING}✅ Map-Tile-Bereinigung abgeschlossen${COLOR_RESET}"
    blankline
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
    blankline
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
    blankline
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
    blankline
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
    blankline
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
    blankline
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
    blankline
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
    blankline
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
    blankline
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
    blankline
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
    blankline
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
    blankline
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
    blankline
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
    blankline
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
    blankline
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#*          ZUSAMMENFASSUNG DER FUNKTIONEN IN LOGISCHE GRUPPEN          
#?──────────────────────────────────────────────────────────────────────────────────────────

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

# Basis-Konfiguration für alle Dienste ⚡ Vorsicht
function configall() {
    setrobusthg      # Hypergrid-Konfig
    setopensim       # Regionsserver
    setgridcommon    # Grid-weite Einstellungen
    setflotsamcache  # Cache-System
    setosslenable    # OSSL-Funktionen
    setwelcome       # Startregion
    echo -e "\033[32mAlle Konfigurationen wurden angewendet.\033[0m"
}

# Vollautomatische Installation ⚡ Vorsicht
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

# Server-Reboot mit Vorbereitung
function reboot() {
    echo -e "\033[1;33m⚠ Server-Neustart wird eingeleitet...\033[0m"

    opensimstop
    sleep 30
    shutdown -r now
}

# OpenSim komplett herunterladen ⚡ Vorsicht
function downloadallgit() {
    # Downloads aus dem Github.
    opensimgit
    moneygit
        #ruthrothgit        # Funktioniert nicht richtig.
        #avatarassetsgit    # Funktioniert nicht richtig.
    osslscriptsgit
    pbrtexturesgit
    # Versionierung des OpenSimulators.
    versionrevision
    # OpenSimulator erstellen aus dem Source Code.
    opensimbuild
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Hilfefunktionen
#?──────────────────────────────────────────────────────────────────────────────────────────

function help() {
    # Überschriften
    echo -e "${COLOR_SERVER}OpenSim Grid Starten Stoppen und Restarten:${COLOR_RESET}"
    echo -e "${COLOR_START}opensimstart${COLOR_RESET}   # OpenSim starten"
    echo -e "${COLOR_STOP}opensimstop${COLOR_RESET}    # OpenSim stoppen"
    echo -e "${COLOR_START}opensimrestart${COLOR_RESET} # OpenSim neu starten"    
    echo -e "${COLOR_OK}check_screens${COLOR_RESET}  # Laufende OpenSim Prozesse prüfen und restarten"
    echo " "

    # Erstellung/Aktualisierung
    echo -e "${COLOR_SERVER}Ein OpenSim Grid erstellen oder aktualisieren:${COLOR_RESET}"
    echo -e "${COLOR_OK}servercheck${COLOR_RESET}    # Serverbereitschaft prüfen"
    echo -e "${COLOR_OK}createdirectory${COLOR_RESET} # Verzeichnisse erstellen"
    echo -e "${COLOR_OK}mariasetup${COLOR_RESET}     # MariaDB einrichten"
    echo -e "${COLOR_OK}sqlsetup${COLOR_RESET}       # SQL Datenbanken erstellen"
    echo -e "${COLOR_OK}setcrontab${COLOR_RESET}     # Crontab Automatisierungen"
    echo " "

    # Git Downloads
    echo -e "${COLOR_SERVER}Git Downloads:${COLOR_RESET}"
    echo -e "${COLOR_OK}opensimgitcopy${COLOR_RESET}  # OpenSim herunterladen"
    echo -e "${COLOR_OK}moneygitcopy${COLOR_RESET}    # MoneyServer herunterladen"
    echo -e "${COLOR_WARNING}ruthrothgit${COLOR_RESET}   # Ruth Roth als IAR ${COLOR_BAD}(Vorsicht)${COLOR_RESET}"
    echo -e "${COLOR_WARNING}avatarassetsgit${COLOR_RESET} # Ruth Roth Assets ${COLOR_BAD}(Vorsicht)${COLOR_RESET}"
    echo -e "${COLOR_WARNING}osslscriptsgit${COLOR_RESET} # Skripte ${COLOR_BAD}(Vorsicht)${COLOR_RESET}"
    echo -e "${COLOR_WARNING}pbrtexturesgit${COLOR_RESET} # PBR Texturen ${COLOR_BAD}(Vorsicht)${COLOR_RESET}"
    echo " "

    # Konfiguration
    echo -e "${COLOR_OK}opensimbuild${COLOR_RESET}   # OpenSim kompilieren"
    echo -e "${COLOR_WARNING}configall${COLOR_RESET}     # Testkonfiguration ${COLOR_BAD}(Vorsicht)${COLOR_RESET}"
    echo -e "${COLOR_OK}opensimcopy${COLOR_RESET}    # OpenSim kopieren"
    echo -e "${COLOR_WARNING}opensimconfig${COLOR_RESET}  # Konfiguration (in Entwicklung)"
    echo -e "${COLOR_OK}regionsconfig${COLOR_RESET}  # Regionen konfigurieren"
    echo " "    

    # Bereinigung
    echo -e "${COLOR_SERVER}OpenSim Grid Bereinigen:${COLOR_RESET}"
    echo -e "${COLOR_WARNING}dataclean${COLOR_RESET}     # Alte Dateien ${COLOR_BAD}(⚡ Neuinstallation)${COLOR_RESET}"
    echo -e "${COLOR_WARNING}pathclean${COLOR_RESET}     # Alte Verzeichnisse ${COLOR_BAD}(⚡ Neuinstallation)${COLOR_RESET}"
    echo -e "${COLOR_OK}cacheclean${COLOR_RESET}    # Cache bereinigen"
    echo -e "${COLOR_OK}logclean${COLOR_RESET}      # Logs bereinigen"
    echo -e "${COLOR_OK}mapclean${COLOR_RESET}      # Maptiles bereinigen"
    echo -e "${COLOR_WARNING}autoallclean${COLOR_RESET}  # Komplettbereinigung ${COLOR_BAD}(⚡ Neuinstallation)${COLOR_RESET}"
    echo -e "${COLOR_WARNING}regionsclean${COLOR_RESET}  # Regionen löschen"    
    echo " "
    
    # Hilfe
    echo -e "${COLOR_OK}help${COLOR_RESET}          # Diese Hilfeseite"
    echo " "
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Eingabeauswertung
#?──────────────────────────────────────────────────────────────────────────────────────────

case $KOMMANDO in
    # System-Checks und Verwaltung
    servercheck) servercheck ;;
    createdirectory) createdirectory ;;
    setcrontab) setcrontab ;;

    # Datenbank-Setup
    mariasetup) mariasetup ;;
    sqlsetup) sqlsetup ;;

    # Git-Repository-Operationen
    opensimgitcopy|opensimgit) opensimgit ;;
    moneygitcopy|moneygit) moneygit ;;
    ruthrothgit) ruthrothgit ;;
    avatarassetsgit) avatarassetsgit ;;
    osslscriptsgit) osslscriptsgit ;;
    pbrtexturesgit) pbrtexturesgit ;;
    downloadallgit) downloadallgit ;;
    versionrevision) versionrevision ;;

    # OpenSim-Build & Deployment
    opensimbuild) opensimbuild ;;
    opensimcopy) opensimcopy ;;
    opensimupgrade) opensimupgrade ;;

    # Konfigurationsmanagement
    config_menu|configure|configureopensim) config_menu ;; # Automatische Konfiguration für Testzwecke
    cleandoublecomments) cleandoublecomments ;;
    configclean|clean_comments_and_empty_lines) clean_comments_and_empty_lines ;;
    regionsconfig) regionsconfig ;;
    generatename|generate_name) generate_name ;;
    cleanconfig) clean_config "$2" ;;
    
    # Automatische Konfiguration
    setrobusthg) setrobusthg ;;
    setopensim) setopensim ;;
    setgridcommon) setgridcommon ;;
    setflotsamcache) setflotsamcache ;;
    setosslenable) setosslenable ;;
    setwelcome) setwelcome ;;
    configall) configall ;;
    autosetinstall) autosetinstall ;;
    
    # OpenSim Steuerung
    start|opensimstart) opensimstart ;;
    stop|opensimstop) opensimstop ;;
    osrestart|autorestart|restart|opensimrestart) opensimrestart ;;

    # OpenSim Standalone-Modus
    standalone) standalone ;;
    standalonestart) standalonestart ;;
    standalonestop) standalonestop ;;
    standalonerestart) standalonerestart ;;

    # System- und Datenbereinigung
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
    renamefiles) renamefiles ;; # Automatische Konfiguration für Testzwecke
    colortest) colortest ;;

    # Hilfe-Optionen
    h|help|hilfe|*) help ;;
esac

# Programm Ende mit Zeitstempel
echo -e "\e[36m${SCRIPTNAME}\e[0m ${VERSION} wurde beendet $(date +'%Y-%m-%d %H:%M:%S')" >&2
exit 0
