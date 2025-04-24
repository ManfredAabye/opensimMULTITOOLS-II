#!/bin/bash

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Informationen Kopfzeile
#?──────────────────────────────────────────────────────────────────────────────────────────
# https://github.com/ManfredAabye/opensimMULTITOOLS-II/blob/main/osmtool.sh

tput reset # Bildschirmausgabe loeschen inklusive dem Scrollbereich.
SCRIPTNAME="opensimMULTITOOL II"
VERSION="V25.4.65.193"
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
COLOR_VALUE='\e[36m'       # Cyan für Werte
COLOR_ACTION='\e[92m'      # Hellgrün für Aktionen
COLOR_RESET='\e[0m'        # Farbreset

#* SYMBOLDEFINITIONEN
SYM_OK="${COLOR_OK}✓${COLOR_RESET}"
SYM_BAD="${COLOR_BAD}✗${COLOR_RESET}"
SYM_INFO="${COLOR_VALUE}☛${COLOR_RESET}"  # Alternative: ▲ ● ◆ ☛ ⚑ ⓘ 
SYM_WAIT="${COLOR_VALUE}⏳${COLOR_RESET}"
SYM_LOG="${COLOR_VALUE}📋${COLOR_RESET}"
COLOR_SECTION='\e[0;35m'  # Magenta für Sektionsnamen
COLOR_FILE='\e[0;33m'     # Gelb für Dateipfade

SYM_SYNC="${COLOR_VALUE}🔄${COLOR_RESET}"        # Synchronisieren, Aktualisieren
SYM_TOOLS="${COLOR_VALUE}🛠️${COLOR_RESET}"       # Werkzeuge, Einstellungen, Reparatur
SYM_FOLDER="${COLOR_VALUE}📂${COLOR_RESET}"      # Verzeichnis, Dateien, Dokumente
SYM_CONFIG="${COLOR_VALUE}⚙️${COLOR_RESET}"      # Einstellungen, System, Konfiguration
SYM_SCRIPT="${COLOR_VALUE}📜${COLOR_RESET}"      # Skript, Dokument, Notizen
# shellcheck disable=SC2034
SYM_FILE="${COLOR_VALUE}📄${COLOR_RESET}"        # Datei, Bericht
SYM_SERVER="${COLOR_VALUE}🖥️${COLOR_RESET}"      # Server, Computer
SYM_CLEAN="${COLOR_VALUE}🧹${COLOR_RESET}"       # Bereinigung, Aufräumen, Löschen
# shellcheck disable=SC2034
SYM_WARNING="${COLOR_VALUE}⚠${COLOR_RESET}"     # Achtung, Gefahr, Hinweis


#* WARTEZEITEN muessen leider sein damit der Server nicht überfordert wird.
Simulator_Start_wait=15 # Sekunden
MoneyServer_Start_wait=30 # Sekunden
RobustServer_Start_wait=30 # Sekunden
Simulator_Stop_wait=15 # Sekunden
MoneyServer_Stop_wait=30 # Sekunden
RobustServer_Stop_wait=30 # Sekunden

function blankline() { echo " ";}

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
        echo -e "${SYM_BAD} ${COLOR_WARNING}Keine unterstützte Version für .NET gefunden!${COLOR_RESET}"
        return 1
    fi

    # .NET-Installationsstatus prüfen
    echo -e "${COLOR_HEADING}🔄 .NET Runtime-Überprüfung:${COLOR_RESET}"
    
    if [[ "$os_id" == "arch" || "$os_id" == "manjaro" ]]; then
        if ! pacman -Qi "$required_dotnet" >/dev/null 2>&1; then
            echo -e "${SYM_OK} ${COLOR_ACTION}Installiere ${COLOR_SERVER}$required_dotnet${COLOR_RESET}..."
            sudo pacman -S --noconfirm "$required_dotnet"
            echo -e "${SYM_OK} ${COLOR_SERVER}$required_dotnet${COLOR_RESET} ${COLOR_ACTION}wurde erfolgreich installiert.${COLOR_RESET}"
        else
            echo -e "${SYM_OK} ${COLOR_SERVER}$required_dotnet${COLOR_RESET} ${COLOR_ACTION}ist bereits installiert.${COLOR_RESET}"
        fi
    else
        if ! dpkg -s "$required_dotnet" >/dev/null 2>&1; then
            echo -e "${SYM_OK} ${COLOR_ACTION}Installiere ${COLOR_SERVER}$required_dotnet${COLOR_RESET}..."
            sudo apt-get install -y "$required_dotnet"
            echo -e "${SYM_OK} ${COLOR_SERVER}$required_dotnet${COLOR_RESET} ${COLOR_ACTION}wurde erfolgreich installiert.${COLOR_RESET}"
        else
            echo -e "${SYM_OK} ${COLOR_SERVER}$required_dotnet${COLOR_RESET} ${COLOR_ACTION}ist bereits installiert.${COLOR_RESET}"
        fi
    fi

    # Fehlende Pakete prüfen und installieren
    required_packages=("git" "libc6" "libgcc-s1" "libgssapi-krb5-2" "libicu70" "liblttng-ust1" "libssl3" "libstdc++6" "libunwind8" "zlib1g" "libgdiplus" "zip" "screen")

    echo -e "${COLOR_HEADING}📦 Überprüfe fehlende Pakete...${COLOR_RESET}"
    for package in "${required_packages[@]}"; do
        if [[ "$os_id" == "arch" || "$os_id" == "manjaro" ]]; then
            if ! pacman -Qi "$package" >/dev/null 2>&1; then
                echo -e "${SYM_OK} ${COLOR_ACTION}Installiere ${COLOR_SERVER}$package${COLOR_RESET}..."
                sudo pacman -S --noconfirm "$package"
            fi
        else
            if ! dpkg -s "$package" >/dev/null 2>&1; then
                echo -e "${SYM_OK} ${COLOR_ACTION}Installiere ${COLOR_SERVER}$package${COLOR_RESET}..."
                sudo apt-get install -y "$package"
            fi
        fi
    done

    echo -e "${SYM_OK} ${COLOR_HEADING}Alle benötigten Pakete wurden installiert.${COLOR_RESET}"
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
    echo -e "${SYM_WAIT} ${COLOR_START}Starte das Grid!${COLOR_RESET}"

    # RobustServer starten
    if [[ -d "robust/bin" && -f "robust/bin/Robust.dll" ]]; then
        echo -e "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}RobustServer${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}robust/bin...${COLOR_RESET}"
        cd robust/bin || exit 1
        screen -fa -S robustserver -d -U -m dotnet Robust.dll
        cd - >/dev/null 2>&1 || exit 1
        sleep $RobustServer_Start_wait
    else
        echo -e "${SYM_BAD} ${COLOR_SERVER}RobustServer: ${COLOR_BAD}Robust.dll nicht gefunden.${COLOR_RESET} ${COLOR_START}Überspringe Start.${COLOR_RESET}"
    fi

    # MoneyServer starten
    if [[ -f "robust/bin/MoneyServer.dll" ]]; then
        echo -e "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}MoneyServer${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}robust/bin...${COLOR_RESET}"
        cd robust/bin || exit 1
        screen -fa -S moneyserver -d -U -m dotnet MoneyServer.dll
        cd - >/dev/null 2>&1 || exit 1
        sleep $MoneyServer_Start_wait
    else
        echo -e "${SYM_BAD} ${COLOR_SERVER}MoneyServer: ${COLOR_BAD}MoneyServer.dll nicht gefunden.${COLOR_RESET} ${COLOR_START}Überspringe Start.${COLOR_RESET}"
    fi

    # Sim-Regionen starten
    
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" && -f "$sim_dir/OpenSim.dll" ]]; then
            echo -e "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}sim$i${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
            cd "$sim_dir" || continue
            screen -fa -S "sim$i" -d -U -m dotnet OpenSim.dll
            cd - >/dev/null 2>&1 || continue
            sleep $Simulator_Start_wait
        fi
    done
    echo "OpenSim starten abgeschlossen."
    blankline
}

#* OpenSim stoppen (sim999 bis sim1 → money → robust)
function opensimstop() {
    echo -e "${SYM_WAIT} ${COLOR_STOP}Stoppe das Grid!${COLOR_RESET}"

    # Sim-Regionen stoppen
    for ((i=999; i>=1; i--)); do
        sim_dir="sim$i"
        if screen -list | grep -q "$sim_dir"; then
            screen -S "sim$i" -p 0 -X stuff "shutdown^M"
            echo -e "${SYM_OK} ${COLOR_STOP}Stoppe ${COLOR_SERVER}sim$i${COLOR_RESET} ${COLOR_STOP}...${COLOR_RESET}"
            sleep $Simulator_Stop_wait
        fi
    done

    # MoneyServer stoppen
    if screen -list | grep -q "moneyserver"; then
        echo -e "${SYM_OK} ${COLOR_STOP}Stoppe ${COLOR_SERVER}MoneyServer${COLOR_RESET} ${COLOR_STOP}...${COLOR_RESET}"
        screen -S moneyserver -p 0 -X stuff "shutdown^M"
        sleep $MoneyServer_Stop_wait
    else
        echo -e "${SYM_BAD} ${COLOR_SERVER}MoneyServer: ${COLOR_BAD}Läuft nicht.${COLOR_RESET} ${COLOR_STOP}Überspringe Stopp.${COLOR_RESET}"
    fi

    # RobustServer stoppen
    if screen -list | grep -q "robust"; then
        echo -e "${SYM_OK} ${COLOR_STOP}Stoppe ${COLOR_SERVER}RobustServer${COLOR_RESET} ${COLOR_STOP}...${COLOR_RESET}"
        screen -S robustserver -p 0 -X stuff "shutdown^M"
        sleep $RobustServer_Stop_wait
    else
        echo -e "${SYM_BAD} ${COLOR_SERVER}RobustServer: ${COLOR_BAD}Läuft nicht.${COLOR_RESET} ${COLOR_STOP}Überspringe Stopp.${COLOR_RESET}"
    fi
     echo "OpenSim stoppen abgeschlossen."
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

    # Überprüfen, ob andere Regionen (sim2 bis sim999) einzeln neu gestartet werden müssen
    for ((i=2; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" && -f "$sim_dir/OpenSim.dll" ]]; then
            screenSim=$(screen -ls | grep -w "sim$i")
            if [[ -z "$screenSim" ]]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - Sim$i läuft nicht und wird einzeln neu gestartet." >> ProblemRestarts.log
                cd "$sim_dir" || continue
                screen -fa -S "sim$i" -d -U -m dotnet OpenSim.dll
                cd - >/dev/null 2>&1 || continue
                sleep $Simulator_Start_wait
            fi
        fi
    done
    blankline
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Erstellen eines OpenSimulators
#?──────────────────────────────────────────────────────────────────────────────────────────

function opensimgitcopy() {
    echo -e "${COLOR_HEADING}🔄 OpenSimulator GitHub-Verwaltung${COLOR_RESET}"
    
    echo -e "${COLOR_LABEL}Möchten Sie den OpenSimulator vom GitHub verwenden oder aktualisieren? (${COLOR_OK}[upgrade]${COLOR_LABEL}/new)${COLOR_RESET}"
    read -r user_choice
    user_choice=${user_choice:-upgrade}

    if [[ "$user_choice" == "new" ]]; then
        # Falls eine alte Version existiert, wird sie gelöscht
        if [[ -d "opensim" ]]; then
            echo -e "${COLOR_ACTION}Vorhandene OpenSimulator-Version wird gelöscht...${COLOR_RESET}"
            rm -rf opensim
            echo -e "${SYM_OK} ${COLOR_ACTION}Alte OpenSimulator-Version wurde erfolgreich entfernt.${COLOR_RESET}"
        fi

        echo -e "${COLOR_ACTION}OpenSimulator wird von GitHub geholt...${COLOR_RESET}"
        git clone git://opensimulator.org/git/opensim opensim
        echo -e "${SYM_OK} ${COLOR_ACTION}OpenSimulator wurde erfolgreich heruntergeladen.${COLOR_RESET}"

    elif [[ "$user_choice" == "upgrade" ]]; then
        if [[ -d "opensim/.git" ]]; then
            echo -e "${SYM_OK} ${COLOR_ACTION}Repository gefunden. Aktualisiere mit 'git pull'...${COLOR_RESET}"
            cd opensim || { echo -e "${SYM_BAD} ${COLOR_ERROR}Fehler: Kann nicht ins Verzeichnis wechseln!${COLOR_RESET}"; return 1; }
            git pull origin master && echo -e "${COLOR_OK}✅ ${COLOR_ACTION}OpenSimulator erfolgreich aktualisiert!${COLOR_RESET}"
            cd ..
        else
            echo -e "${COLOR_WARNING}⚠ ${COLOR_ACTION}OpenSimulator-Verzeichnis nicht gefunden. Klone Repository neu...${COLOR_RESET}"
            git clone git://opensimulator.org/git/opensim opensim && echo -e "${COLOR_OK}✅ ${COLOR_ACTION}OpenSimulator erfolgreich heruntergeladen!${COLOR_RESET}"
        fi
    else
        echo -e "${SYM_BAD} ${COLOR_ERROR}Abbruch: Keine Aktion durchgeführt.${COLOR_RESET}"
        return 1
    fi

    # .NET-Version auswählen
    echo -e "${COLOR_LABEL}Möchten Sie diese Version mit .NET 6 oder .NET 8 betreiben? (${COLOR_OK}[8]${COLOR_LABEL}/6)${COLOR_RESET}"
    read -r dotnet_version
    dotnet_version=${dotnet_version:-8}

    if [[ "$dotnet_version" == "6" ]]; then
        echo -e "${COLOR_ACTION}Wechsle zu .NET 6-Version...${COLOR_RESET}"
        cd opensim || { echo -e "${SYM_BAD} ${COLOR_ERROR}Fehler: Verzeichnis 'opensim' nicht gefunden.${COLOR_RESET}"; return 1; }
        git checkout dotnet6
        echo -e "${SYM_OK} ${COLOR_ACTION}OpenSimulator wurde für .NET 6 umgebaut.${COLOR_RESET}"
    else
        echo -e "${SYM_OK} ${COLOR_ACTION}Standardmäßig wird .NET 8 verwendet.${COLOR_RESET}"
    fi
    blankline
}

function moneygitcopy() {
    echo -e "${COLOR_HEADING}💰 MoneyServer GitHub-Verwaltung${COLOR_RESET}"
    
    echo -e "${COLOR_LABEL}Möchten Sie den MoneyServer vom GitHub verwenden oder aktualisieren? (${COLOR_OK}[upgrade]${COLOR_LABEL}/new)${COLOR_RESET}"
    read -r user_choice
    user_choice=${user_choice:-upgrade}

    if [[ "$user_choice" == "new" ]]; then
        if [[ -d "opensimcurrencyserver" ]]; then
            echo -e "${COLOR_ACTION}Vorhandene MoneyServer-Version wird gelöscht...${COLOR_RESET}"
            rm -rf opensimcurrencyserver
            echo -e "${SYM_OK} ${COLOR_ACTION}Alte MoneyServer-Version wurde erfolgreich entfernt.${COLOR_RESET}"
        fi
        echo -e "${COLOR_ACTION}MONEYSERVER: MoneyServer wird vom GIT geholt...${COLOR_RESET}"
        git clone https://github.com/ManfredAabye/opensimcurrencyserver-dotnet.git opensimcurrencyserver
        echo -e "${SYM_OK} ${COLOR_ACTION}MoneyServer wurde erfolgreich heruntergeladen.${COLOR_RESET}"
    elif [[ "$user_choice" == "upgrade" ]]; then
        if [[ -d "opensimcurrencyserver/.git" ]]; then
            echo -e "${SYM_OK} ${COLOR_ACTION}Repository gefunden. Aktualisiere mit 'git pull'...${COLOR_RESET}"
            cd opensimcurrencyserver || { echo -e "${SYM_BAD} ${COLOR_ERROR}Fehler: Kann nicht ins Verzeichnis wechseln!${COLOR_RESET}"; return 1; }
            
            # Automatische Branch-Erkennung
            branch_name=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
            git pull origin "$branch_name" && echo -e "${COLOR_OK}✅ ${COLOR_ACTION}MoneyServer erfolgreich aktualisiert!${COLOR_RESET}"
            
            cd ..
        else
            echo -e "${COLOR_WARNING}⚠ ${COLOR_ACTION}MoneyServer-Verzeichnis nicht gefunden. Klone Repository neu...${COLOR_RESET}"
            git clone https://github.com/ManfredAabye/opensimcurrencyserver-dotnet.git opensimcurrencyserver && echo -e "${COLOR_OK}✅ ${COLOR_ACTION}MoneyServer erfolgreich heruntergeladen!${COLOR_RESET}"
        fi
    else
        echo -e "${SYM_BAD} ${COLOR_ERROR}Abbruch: Keine Aktion durchgeführt.${COLOR_RESET}"
        return 1
    fi

    # Prüfen, ob das Verzeichnis existiert, bevor es kopiert wird
    if [[ -d "opensimcurrencyserver/addon-modules" ]]; then
        cp -r opensimcurrencyserver/addon-modules opensim/
        echo -e "${SYM_OK} ${COLOR_ACTION}MONEYSERVER: addon-modules wurde nach opensim kopiert${COLOR_RESET}"
    else
        echo -e "${SYM_BAD} ${COLOR_ERROR}MONEYSERVER: addon-modules existiert nicht${COLOR_RESET}"
    fi

    if [[ -d "opensimcurrencyserver/bin" ]]; then
        cp -r opensimcurrencyserver/bin opensim/
        echo -e "${SYM_OK} ${COLOR_ACTION}MONEYSERVER: bin wurde nach opensim kopiert${COLOR_RESET}"
    else
        echo -e "${SYM_BAD} ${COLOR_ERROR}MONEYSERVER: bin existiert nicht${COLOR_RESET}"
    fi
    
    blankline
    return 0
}

#* Das ist erst halb fertig.
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
        cp "$target_dir/Artifacts/IAR/"*.iar "$base_dir/" 2>/dev/null && echo -e "    ${SYM_OK} IAR-Dateien von ${COLOR_SERVER}$avatar${COLOR_RESET} kopiert.${COLOR_RESET}"
    done

    # Kopiere das updatelibrary.py-Skript ins Hauptverzeichnis ruthroth
    echo -e "  ${COLOR_ACTION}➜ Kopiere updatelibrary.py nach ${COLOR_DIR}$base_dir${COLOR_ACTION}...${COLOR_RESET}"
    cp "updatelibrary.py" "$base_dir/" && echo -e "    ${SYM_OK} updatelibrary.py wurde kopiert.${COLOR_RESET}"

    echo "Verzeichniswechsel in $base_dir"

    # Wechsel ins ruthroth-Verzeichnis
    cd "$base_dir" || { echo -e "${SYM_BAD} Fehler beim Wechsel ins Verzeichnis ${COLOR_DIR}$base_dir${COLOR_RESET}"; return 1; }

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
    cd ..
    # Schritt 3 das kopieren der Daten. Das einfügen der Daten in den Dateien ähnlich wie bei PBR.

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
            echo -e "${SYM_OK} ${COLOR_ACTION}Alte Version wurde erfolgreich entfernt.${COLOR_RESET}"
        fi
        echo -e "${COLOR_ACTION}Beispiel-Skripte werden vom GitHub heruntergeladen...${COLOR_RESET}"
        git clone "$repo_url" "$repo_name" && echo -e "${SYM_OK} ${COLOR_ACTION}Repository wurde erfolgreich heruntergeladen.${COLOR_RESET}"
    elif [[ "$user_choice" == "upgrade" ]]; then
        if [[ -d "$repo_name/.git" ]]; then
            echo -e "${SYM_OK} ${COLOR_ACTION}Repository gefunden. Aktualisiere mit 'git pull'...${COLOR_RESET}"
            cd "$repo_name" || { echo -e "${SYM_BAD} ${COLOR_ERROR}Fehler beim Wechsel ins Verzeichnis!${COLOR_RESET}"; return 1; }
            branch_name=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
            git pull origin "$branch_name" && echo -e "${COLOR_OK}✅ ${COLOR_ACTION}Repository erfolgreich aktualisiert.${COLOR_RESET}"
            cd ..
        else
            echo -e "${COLOR_WARNING}⚠ ${COLOR_ACTION}Verzeichnis nicht gefunden oder kein Git-Repo. Klone Repository neu...${COLOR_RESET}"
            git clone "$repo_url" "$repo_name" && echo -e "${COLOR_OK}✅ ${COLOR_ACTION}Repository wurde erfolgreich heruntergeladen.${COLOR_RESET}"
        fi
    else
        echo -e "${SYM_BAD} ${COLOR_ERROR}Abbruch: Keine Aktion durchgeführt.${COLOR_RESET}"
        return 1
    fi

    # Zielverzeichnisse erstellen falls nicht vorhanden
    mkdir -p opensim/bin/assets/
    mkdir -p opensim/bin/inventory/

    # Kopieren der Verzeichnisse
    if [[ -d "$repo_name/ScriptsAssetSet" ]]; then
        cp -r "$repo_name/ScriptsAssetSet" opensim/bin/assets/
        echo -e "${SYM_OK} ${COLOR_ACTION}ScriptsAssetSet wurde nach opensim/bin/assets kopiert.${COLOR_RESET}"
    else
        echo -e "${SYM_BAD} ${COLOR_ERROR}ScriptsAssetSet Verzeichnis nicht gefunden!${COLOR_RESET}"
    fi

    if [[ -d "$repo_name/inventory/ScriptsLibrary" ]]; then
        cp -r "$repo_name/inventory/ScriptsLibrary" opensim/bin/inventory/
        echo -e "${SYM_OK} ${COLOR_ACTION}ScriptsLibrary wurde nach opensim/bin/inventory kopiert.${COLOR_RESET}"
    else
        echo -e "${SYM_BAD} ${COLOR_ERROR}ScriptsLibrary Verzeichnis nicht gefunden!${COLOR_RESET}"
    fi
    
    blankline
    return 0
}

# Es werden die Konfiguartionen jetzt auch geändert.
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
            echo -e "${SYM_BAD} ${COLOR_ERROR}Fehler beim Herunterladen der Texturen!${COLOR_RESET}"
            return 1
        fi
        echo -e "${SYM_OK} ${COLOR_ACTION}Download abgeschlossen: ${COLOR_DIR}$zip_file${COLOR_RESET}"
    else
        echo -e "${SYM_OK} ${COLOR_ACTION}ZIP-Datei bereits vorhanden: ${COLOR_DIR}$zip_file${COLOR_RESET}"
    fi

    # Entpacken, wenn Verzeichnis noch nicht existiert
    if [[ ! -d "$unpacked_dir" ]]; then
        echo -e "${COLOR_ACTION}Entpacke Texturen nach ${COLOR_DIR}$unpacked_dir${COLOR_ACTION}...${COLOR_RESET}"
        unzip -q "$zip_file" -d .
        echo -e "${SYM_OK} ${COLOR_ACTION}Entpackt.${COLOR_RESET}"
    else
        echo -e "${SYM_OK} ${COLOR_ACTION}Verzeichnis ${COLOR_DIR}$unpacked_dir${COLOR_ACTION} existiert bereits – überspringe Entpacken.${COLOR_RESET}"
    fi

    # Kopieren nach opensim/bin
    if [[ -d "$unpacked_dir/bin" ]]; then
        echo -e "${COLOR_ACTION}Kopiere Texturen nach ${COLOR_DIR}$target_dir${COLOR_ACTION}...${COLOR_RESET}"
        cp -r "$unpacked_dir/bin" "$target_dir"
        echo -e "${SYM_OK} ${COLOR_ACTION}Texturen erfolgreich installiert in ${COLOR_DIR}$target_dir${COLOR_RESET}"
    else
        echo -e "${SYM_BAD} ${COLOR_ERROR}Verzeichnis ${COLOR_DIR}$unpacked_dir/bin${COLOR_ERROR} nicht gefunden!${COLOR_RESET}"
        return 1
    fi

    local asset_sets_file="opensim/bin/assets/AssetSets.xml"
    local libraries_file="opensim/bin/inventory/Libraries.xml"
    
    # Funktion zur Überprüfung und Hinzufügung eines Eintrags
    add_xml_section() {
        local file="$1"
        local section_name="$2"
        local content="$3"
        
        # Überprüfen ob der Abschnitt bereits existiert
        if ! grep -q "<Section Name=\"$section_name\">" "$file"; then
            # Abschnitt vor </Nini> einfügen
            sed -i "s|</Nini>|  <Section Name=\"$section_name\">\n$content\n  </Section>\n</Nini>|" "$file"
            echo "Added $section_name to $file"
        else
            echo "$section_name already exists in $file - no changes made"
        fi
    }
    
    # AssetSets.xml bearbeiten
    add_xml_section "$asset_sets_file" "PBR Textures AssetSet" \
    "    <Key Name=\"file\" Value=\"PBRTexturesAssetSet/PBRTexturesAssetSet.xml\"/>"
    
    # Libraries.xml bearbeiten
    add_xml_section "$libraries_file" "PBRTextures Library" \
    "    <Key Name=\"foldersFile\" Value=\"PBRTexturesLibrary/PBRTexturesLibraryFolders.xml\"/>\n    <Key Name=\"itemsFile\" Value=\"PBRTexturesLibrary/PBRTexturesLibraryItems.xml\"/>"

    blankline
    return 0
}

function versionrevision() {
    file="opensim/OpenSim/Framework/VersionInfo.cs"

    if [[ ! -f "$file" ]]; then
        echo -e "${SYM_BAD} ${COLOR_ERROR}Datei nicht gefunden: ${COLOR_DIR}$file${COLOR_RESET}"
        return 1
    fi

    echo -e "${SYM_OK} ${COLOR_ACTION}Bearbeite Datei: ${COLOR_DIR}$file${COLOR_RESET}"

    # Ändere Flavour.Dev zu Flavour.Extended
    sed -i 's/public const Flavour VERSION_FLAVOUR = Flavour\.Dev;/public const Flavour VERSION_FLAVOUR = Flavour.Extended;/' "$file"

    # Entferne "Nessie" aus dem Versions-String
    sed -i 's/OpenSim {versionNumber} Nessie {flavour}/OpenSim {versionNumber} {flavour}/' "$file"

    echo -e "${SYM_OK} ${COLOR_ACTION}Änderungen wurden erfolgreich vorgenommen.${COLOR_RESET}"
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
            cd opensim || { echo -e "${SYM_BAD} ${COLOR_ERROR}Fehler: Verzeichnis 'opensim' nicht gefunden.${COLOR_RESET}"; return 1; }
            echo -e "${COLOR_ACTION}Starte Prebuild-Skript...${COLOR_RESET}"
            bash runprebuild.sh
            echo -e "${COLOR_ACTION}Baue OpenSimulator...${COLOR_RESET}"
            dotnet build --configuration Release OpenSim.sln
            echo -e "${SYM_OK} ${COLOR_ACTION}OpenSimulator wurde erfolgreich erstellt.${COLOR_RESET}"
        else
            echo -e "${SYM_BAD} ${COLOR_ERROR}Fehler: Das Verzeichnis 'opensim' existiert nicht.${COLOR_RESET}"
            return 1
        fi
    else
        echo -e "${SYM_BAD} ${COLOR_ERROR}Abbruch: OpenSimulator wird nicht erstellt.${COLOR_RESET}"
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
        echo -e "${SYM_OK} ${COLOR_ACTION}Robust Verzeichnis wurde erstellt.${COLOR_RESET}"

        # Nach der Erstellung des Gridservers auch die Regionsserver erstellen lassen
        echo -e "${COLOR_LABEL}Wie viele Regionsserver benötigen Sie?${COLOR_RESET}"
        read -r num_regions
    elif [[ "$server_type" == "region" ]]; then
        echo -e "${COLOR_LABEL}Wie viele Regionsserver benötigen Sie?${COLOR_RESET}"
        read -r num_regions
    else
        echo -e "${SYM_BAD} ${COLOR_ERROR}Ungültige Eingabe. Bitte geben Sie 'grid' oder 'region' ein.${COLOR_RESET}"
        return 1
    fi

    # Überprüfen, ob die Anzahl der Regionsserver bis 999 geht
    if [[ "$num_regions" =~ ^[0-9]+$ && "$num_regions" -le 999 ]]; then
        for ((i=1; i<=num_regions; i++)); do
            dir_name="sim$i"
            if [[ ! -d "$dir_name" ]]; then
                mkdir -p "$dir_name/bin"
                echo -e "${SYM_OK} ${COLOR_DIR}$dir_name${COLOR_RESET} ${COLOR_ACTION}wurde erstellt.${COLOR_RESET}"
            else
                echo -e "${SYM_OK} ${COLOR_DIR}$dir_name${COLOR_RESET} ${COLOR_WARNING}existiert bereits und wird übersprungen.${COLOR_RESET}"
            fi
        done
    else
        echo -e "${SYM_BAD} ${COLOR_ERROR}Ungültige Anzahl an Regionsserver. Bitte geben Sie eine gültige Zahl zwischen 1 und 999 ein.${COLOR_RESET}"
    fi
    blankline
}

function opensimcopy() {
    echo -e "${COLOR_HEADING}📦 OpenSim Dateikopie${COLOR_RESET}"
    
    # Prüfen, ob das Verzeichnis "opensim" existiert
    if [[ ! -d "opensim" ]]; then
        echo -e "${SYM_BAD} ${COLOR_ERROR}Fehler: Das Verzeichnis 'opensim' existiert nicht.${COLOR_RESET}"
        return 1
    fi

    # Prüfen, ob das Unterverzeichnis "opensim/bin" existiert
    if [[ ! -d "opensim/bin" ]]; then
        echo -e "${SYM_BAD} ${COLOR_ERROR}Fehler: Das Verzeichnis 'opensim/bin' existiert nicht.${COLOR_RESET}"
        return 1
    fi

    # Prüfen, ob das Verzeichnis "robust" existiert und Dateien kopieren
    if [[ -d "robust/bin" ]]; then
        cp -r opensim/bin/* robust/bin
        echo -e "${SYM_OK} ${COLOR_ACTION}Dateien aus ${COLOR_DIR}opensim/bin${COLOR_RESET} ${COLOR_ACTION}wurden nach ${COLOR_DIR}robust/bin${COLOR_RESET} ${COLOR_ACTION}kopiert.${COLOR_RESET}"
    else
        echo -e "${COLOR_WARNING}⚠ ${COLOR_ACTION}Hinweis: 'robust' Verzeichnis nicht gefunden, keine Kopie durchgeführt.${COLOR_RESET}"
    fi

    # Alle simX-Verzeichnisse suchen und Dateien kopieren
    for sim_dir in sim*; do
        if [[ -d "$sim_dir/bin" ]]; then
            cp -r opensim/bin/* "$sim_dir/bin/"
            echo -e "${SYM_OK} ${COLOR_ACTION}Dateien aus ${COLOR_DIR}opensim/bin${COLOR_RESET} ${COLOR_ACTION}wurden nach ${COLOR_DIR}$sim_dir/bin${COLOR_RESET} ${COLOR_ACTION}kopiert.${COLOR_RESET}"
        fi
    done

    blankline
}

function database_setup() {
    echo -e "${COLOR_SECTION}=== MariaDB/MySQL Datenbank-Setup ===${COLOR_RESET}"
    
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
    supported_distros=("debian" "ubuntu" "linuxmint" "pop" "mx" "kali" "zorin" "elementary" "raspbian" "centos" "fedora")

    # 2. Support-Check
    if ! printf '%s\n' "${supported_distros[@]}" | grep -q "^${current_distro}$"; then
        echo -e "${SYM_BAD} ${COLOR_BAD}Nicht unterstützte Distribution: '${current_distro}'${COLOR_RESET}"
        echo -e "${SYM_INFO} Unterstützt: ${supported_distros[*]}"
        return 1
    fi

    # 3. Installation Check
    if ! command -v mariadb &> /dev/null && ! command -v mysql &> /dev/null; then
        echo -e "${SYM_WAIT} ${COLOR_WARNING}MariaDB/MySQL ist nicht installiert${COLOR_RESET}"
        read -rp "$(echo -e "${COLOR_ACTION}MariaDB installieren? (j/n) ${COLOR_RESET}")" install_choice
        [[ "$install_choice" =~ ^[jJ] ]] || { echo -e "${SYM_BAD} Installation abgebrochen"; return 0; }
        
        case $current_distro in
            debian|ubuntu|*mint|pop|zorin|elementary|kali|mx|raspbian)
                echo -e "${SYM_INFO} ${COLOR_ACTION}Installiere MariaDB...${COLOR_RESET}"
                sudo apt-get update && sudo apt-get install -y mariadb-server ;;
            centos|fedora)
                echo -e "${SYM_INFO} ${COLOR_ACTION}Installiere MariaDB...${COLOR_RESET}"
                sudo yum install -y mariadb-server
                sudo systemctl start mariadb
                sudo systemctl enable mariadb ;;
            *) echo -e "${SYM_BAD} ${COLOR_BAD}Automatische Installation nicht verfügbar${COLOR_RESET}"; return 1 ;;
        esac
        sudo mysql_secure_installation
    else
        echo -e "${SYM_OK} ${COLOR_OK}MariaDB/MySQL ist bereits installiert${COLOR_RESET}"
    fi

    # 4. Benutzeranmeldedaten
    echo -e "\n${COLOR_SECTION}=== Datenbank-Zugangsdaten ===${COLOR_RESET}"
    read -rp "$(echo -e "${COLOR_ACTION}Standard-Zugangsdaten verwenden? (j/n) ${COLOR_RESET}")" default_cred_choice
    if [[ "$default_cred_choice" =~ ^[jJ] ]]; then
        db_user="simuser"
        db_pass=$(tr -dc 'A-Za-z0-9!@#$%^&*()' < /dev/urandom | head -c 16)
        echo -e "${SYM_INFO} ${COLOR_LABEL}Generiertes Passwort: ${COLOR_VALUE}${db_pass}${COLOR_RESET}"
    else
        read -rp "$(echo -e "${COLOR_ACTION}Benutzername: ${COLOR_RESET}")" db_user
        read -rsp "$(echo -e "${COLOR_ACTION}Passwort: ${COLOR_RESET}")" db_pass
        echo
    fi

    # 5. Datenbankeinrichtung
    echo -e "\n${COLOR_SECTION}=== Datenbank-Konfiguration ===${COLOR_RESET}"
    
    # RobustServer DB
    if [[ -d "robust" ]]; then
        if ! sudo mysql -e "USE robust" &> /dev/null; then
            sudo mysql -e "CREATE DATABASE robust CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
            echo -e "${SYM_OK} ${COLOR_VALUE}robust${COLOR_RESET} Datenbank angelegt"
        else
            echo -e "${SYM_INFO} ${COLOR_WARNING}robust-Datenbank existiert bereits${COLOR_RESET}"
        fi
    fi

    # simX Server DBs
    for ((i=1; i<=1000; i++)); do
        if [[ -d "sim${i}" ]]; then
            db_name="sim${i}"
            if ! sudo mysql -e "USE ${db_name}" &> /dev/null; then
                sudo mysql -e "CREATE DATABASE ${db_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
                echo -e "${SYM_OK} ${COLOR_VALUE}${db_name}${COLOR_RESET} Datenbank angelegt"
            else
                echo -e "${SYM_INFO} ${COLOR_WARNING}${db_name}-Datenbank existiert bereits${COLOR_RESET}"
            fi
        fi
    done

    # Benutzerverwaltung
    if ! sudo mysql -e "SELECT user FROM mysql.user WHERE user='${db_user}' AND host='localhost'" | grep -q "${db_user}"; then
        sudo mysql -e "CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}'"
        echo -e "${SYM_OK} ${COLOR_VALUE}${db_user}${COLOR_RESET} Benutzer angelegt"
    else
        echo -e "${SYM_INFO} ${COLOR_WARNING}Benutzer ${db_user} existiert bereits${COLOR_RESET}"
    fi

    # Rechte vergeben
    [[ -d "robust" ]] && sudo mysql -e "GRANT ALL PRIVILEGES ON robust.* TO '${db_user}'@'localhost'"
    for ((i=1; i<=1000; i++)); do
        [[ -d "sim${i}" ]] && sudo mysql -e "GRANT ALL PRIVILEGES ON sim${i}.* TO '${db_user}'@'localhost'"
    done
    sudo mysql -e "FLUSH PRIVILEGES"

    # 6. Zusammenfassung
    echo -e "\n${COLOR_SECTION}=== Zusammenfassung ===${COLOR_RESET}"
    echo -e "${COLOR_LABEL}Benutzername: ${COLOR_VALUE}${db_user}${COLOR_RESET}"
    echo -e "${COLOR_LABEL}Passwort: ${COLOR_VALUE}${db_pass}${COLOR_RESET}"
    
    if sudo mysql -e "SELECT user FROM mysql.user WHERE user='${db_user}' AND host='localhost'" | grep -q "${db_user}"; then
        echo -e "${COLOR_LABEL}Berechtigungen:${COLOR_RESET}"
        sudo mysql -e "SHOW GRANTS FOR '${db_user}'@'localhost'"
    else
        echo -e "${SYM_BAD} ${COLOR_WARNING}Benutzerberechtigungen nicht verfügbar${COLOR_RESET}"
    fi
    
    # Zugangsdaten speichern
    echo -e "\n${SYM_LOG} ${COLOR_LABEL}Zugangsdaten gespeichert in: ${COLOR_FILE}${SCRIPT_DIR}/mariadb_passwords.txt${COLOR_RESET}"
    echo "Benutzername: ${db_user} Passwort: ${db_pass}" | sudo tee "${SCRIPT_DIR}/mariadb_passwords.txt" >/dev/null
}

function setcrontab() {
    # Strict Mode: Fehler sofort erkennen
    set -euo pipefail

    echo -e "${COLOR_HEADING}⏰ Cron-Job Einrichtung${COLOR_RESET}"

    # Sicherheitsabfrage: Nur als root/sudo ausführen
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${SYM_BAD} ${COLOR_ERROR}FEHLER: Dieses Skript benötigt root-Rechte! (sudo verwenden)${COLOR_RESET}" >&2
        return 1
    fi

    # Prüfen, ob SCRIPT_DIR gesetzt und gültig ist
    if [ -z "${SCRIPT_DIR:-}" ]; then
        echo -e "${SYM_BAD} ${COLOR_ERROR}FEHLER: 'SCRIPT_DIR' muss gesetzt sein!${COLOR_RESET}" >&2
        return 1
    fi

    if [ ! -d "$SCRIPT_DIR" ]; then
        echo -e "${SYM_BAD} ${COLOR_ERROR}FEHLER: Verzeichnis '${COLOR_DIR}$SCRIPT_DIR${COLOR_ERROR}' existiert nicht!${COLOR_RESET}" >&2
        return 1
    fi

    # Temporäre Datei für neue Cron-Jobs
    local temp_cron
    temp_cron=$(mktemp) || {
        echo -e "${SYM_BAD} ${COLOR_ERROR}FEHLER: Temp-Datei konnte nicht erstellt werden${COLOR_RESET}" >&2
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
        echo -e "${SYM_OK} ${COLOR_ACTION}Cron-Jobs wurden ERFOLGREICH ersetzt:${COLOR_RESET}"
        crontab -l | grep -v '^#' | sed '/^$/d' | while read -r line; do
            echo -e "${COLOR_DIR}$line${COLOR_RESET}"
        done
        return 0
    else
        echo -e "${SYM_BAD} ${COLOR_ERROR}FEHLER: Installation fehlgeschlagen. Prüfe $temp_cron manuell.${COLOR_RESET}" >&2
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
        echo -e "${SYM_BAD} ${COLOR_ERROR}Fehler: Das Verzeichnis '${COLOR_DIR}opensim${COLOR_ERROR}' existiert nicht${COLOR_RESET}"
        return 1
    fi

    # Prüfe, ob im Verzeichnis 'opensim/bin' die Dateien OpenSim.dll und Robust.dll vorhanden sind
    if [[ ! -f "opensim/bin/OpenSim.dll" || ! -f "opensim/bin/Robust.dll" ]]; then
        echo -e "${SYM_BAD} ${COLOR_ERROR}Fehler: Benötigte Dateien (OpenSim.dll und/oder Robust.dll) fehlen im Verzeichnis '${COLOR_DIR}opensim/bin${COLOR_ERROR}'${COLOR_RESET}"
        echo -e "\n${COLOR_WARNING}❓ Haben Sie vergessen den OpenSimulator zuerst zu Kompilieren?${COLOR_RESET}"
        return 1
    fi

    if [[ "$user_choice" == "yes" ]]; then
        echo -e "${COLOR_ACTION}OpenSimulator wird gestoppt...${COLOR_RESET}"
        opensimstop
        sleep $Simulator_Stop_wait

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
        echo -e "${SYM_OK} ${COLOR_ACTION}Lösche Dateien im RobustServer...${COLOR_RESET}"
        find "robust/bin" -maxdepth 1 -type f \( -name "*.log" -o -name "*.dll" -o -name "*.exe" -o -name "*.so" -o -name "*.xml" -o -name "*.dylib" -o -name "*.example" -o -name "*.sample" -o -name "*.txt" -o -name "*.config" -o -name "*.py" -o -name "*.old" -o -name "*.pdb" \) -delete
    fi

    # Alle simX-Server bereinigen
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" ]]; then
            echo -e "${SYM_OK} ${COLOR_ACTION}Lösche Dateien in ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
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
        echo -e "${SYM_OK} ${COLOR_ACTION}Lösche komplette Verzeichnisse im RobustServer...${COLOR_RESET}"
        
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
            echo -e "${SYM_OK} ${COLOR_ACTION}Lösche komplette Verzeichnisse in ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
            
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
        echo -e "${SYM_OK} ${COLOR_ACTION}Leere Cache-Verzeichnisse im RobustServer...${COLOR_RESET}"
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
            echo -e "${SYM_OK} ${COLOR_ACTION}Leere Cache-Verzeichnisse in ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
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
    echo -e "${SYM_LOG}${COLOR_HEADING} Log-Bereinigung wird durchgeführt...${COLOR_RESET}"

    # RobustServer bereinigen
    if [[ -d "robust/bin" ]]; then
        echo -e "${SYM_OK} ${COLOR_ACTION}Lösche Log-Dateien in ${COLOR_DIR}robust/bin...${COLOR_RESET}"
        rm -f robust/bin/*.log
    fi

    # Alle simX-Server bereinigen (sim1 bis sim999)
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" ]]; then
            echo -e "${SYM_OK} ${COLOR_ACTION}Lösche Log-Dateien in ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
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
        echo -e "${SYM_OK} ${COLOR_ACTION}robust/bin/maptiles geleert${COLOR_RESET}"
    fi

    # Sicherheitscheck für alle simX/bin/maptiles
    for ((i=1; i<=999; i++)); do
        local sim_dir="sim$i/bin/maptiles"
        if [[ -d "$sim_dir" ]]; then
            # shellcheck disable=SC2115
            rm -rf -- "${sim_dir}/"*
            echo -e "${SYM_OK} ${COLOR_ACTION}${COLOR_DIR}$sim_dir${COLOR_RESET} ${COLOR_ACTION}geleert${COLOR_RESET}"
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

function clean_linux_logs() {
    local log_files=()
    echo -e "${COLOR_SECTION}${SYM_LOG} Suche nach alten Log-Dateien...${COLOR_RESET}"
    
    # Find and list files to be deleted
    while IFS= read -r -d $'\0' file; do
        log_files+=("$file")
        echo -e "${COLOR_FILE}${SYM_INFO} ${COLOR_LABEL}Gelöscht wird:${COLOR_RESET} ${COLOR_VALUE}$file${COLOR_RESET}"
    done < <(find "/var/log" -name "*.log" -type f -mtime +7 -print0)
    
    if [ ${#log_files[@]} -eq 0 ]; then
        echo -e "${SYM_OK} ${COLOR_LABEL}Keine alten Log-Dateien gefunden.${COLOR_RESET}"
        return 0
    fi
    
    echo -e "${COLOR_WARNING}${#log_files[@]} Log-Dateien werden gelöscht. Fortfahren? (j/N) ${COLOR_RESET}" 
    read -r confirm
    case "${confirm,,}" in
        j|ja|y|yes)
            find "/var/log" -name "*.log" -type f -mtime +7 -delete
            echo -e "${SYM_OK} ${COLOR_OK}${#log_files[@]} Log-Dateien wurden gelöscht.${COLOR_RESET}"
            ;;
        *)
            echo -e "${SYM_BAD} ${COLOR_BAD}Bereinigung abgebrochen.${COLOR_RESET}"
            return 1
            ;;
    esac
}

function delete_opensim() {
    echo -e "${COLOR_HEADING}🗺️ Das komplette löschen vom OpenSimulator wird durchgeführt...${COLOR_RESET}"

    # Sicherheitsabfrage hinzufügen
    read -rp "Sind Sie sicher, dass Sie ALLE OpenSimulator-Daten löschen möchten? (j/N) " answer
    [[ ${answer,,} != "j" ]] && { echo "Abbruch."; return 1; }

    # Robust-Verzeichnis sicher löschen
    if [[ -d "robust" ]]; then
        rm -rf -- "robust"  # Keine Wildcard mehr
        echo -e "${SYM_OK} ${COLOR_ACTION}robust geleert${COLOR_RESET}"
    fi

    # Simulator-Verzeichnisse sicher löschen
    for ((i=1; i<=999; i++)); do
        local sim_dir="sim$i"
        if [[ -d "$sim_dir" ]]; then
            rm -rf -- "$sim_dir"  # Keine Wildcard mehr
            echo -e "${SYM_OK} ${COLOR_ACTION}${COLOR_DIR}$sim_dir${COLOR_RESET} ${COLOR_ACTION}geleert${COLOR_RESET}"
        fi
    done

    echo -e "${COLOR_HEADING}✅ Das komplette löschen vom OpenSimulator abgeschlossen${COLOR_RESET}"
    blankline
}


#?──────────────────────────────────────────────────────────────────────────────────────────
#* Konfigurationen
#?──────────────────────────────────────────────────────────────────────────────────────────

function verify_ini_section() {
    local file="$1"
    local section="$2"
    
    if [ ! -f "$file" ]; then
        echo -e "${SYM_BAD} Error: File ${file} does not exist" >&2
        return 2
    fi
    
    if grep -q "^\[${section}\]" "$file"; then
        echo -e "${SYM_OK} Section [${section}] exists in ${file}"
        return 0
    else
        echo -e "${SYM_BAD} Section [${section}] not found in ${file}"
        return 1
    fi
}

function verify_ini_key() {
    local file="$1"
    local section="$2"
    local key="$3"
    
    if [ ! -f "$file" ]; then
        echo -e "${SYM_BAD} Error: File ${file} does not exist" >&2
        return 2
    fi
    
    # Finde den Abschnitt und dann den Key darin
    if awk -v section="[${section}]" -v key="^${key}=" '
        $0 == section { in_section=1; next }
        in_section && /^\[/ { in_section=0; next }
        in_section && $0 ~ key { found=1; exit }
        END { exit !found }' "$file"; then
        echo -e "${SYM_OK} Key ${key} in section [${section}] exists in ${file}"
        return 0
    else
        echo -e "${SYM_BAD} Key ${key} in section [${section}] not found in ${file}"
        return 1
    fi
}

function add_ini_section() {
    local file="$1"
    local section="$2"
    
    if verify_ini_section "$file" "$section" >/dev/null; then
        return 0
    fi
    
    echo -e "${SYM_INFO} Adding section [${section}] to ${file}"
    
    # Abschnitt am Ende der Datei hinzufügen
    if printf "\n[%s]\n" "$section" >> "$file"; then
        echo -e "${SYM_OK} Successfully added section [${section}] to ${file}"
        return 0
    else
        echo -e "${SYM_BAD} Failed to add section [${section}] to ${file}" >&2
        return 1
    fi
}

function set_ini_key() {
    local file="$1" section="$2" key="$3" value="$4"
    local temp_file
    temp_file=$(mktemp) || {
        echo -e "${COLOR_BAD}Fehler beim Erstellen der temporären Datei${COLOR_RESET}" >&2
        return 1
    }

    # Key für Regex absichern
    local key_escaped
    key_escaped=$(printf '%s\n' "$key" | sed 's/[]\/$*.^[]/\\&/g')

    awk -v section="[$section]" -v key="$key" -v value="$value" -v key_re="$key_escaped" '
    BEGIN { in_section = 0; key_set = 0 }

    {
        trimmed = $0
        sub(/^[[:space:]]+/, "", trimmed)
        if (trimmed == section) {
            print
            in_section = 1
            next
        }

        if (in_section && trimmed ~ /^\[.*\]/) {
            if (!key_set) {
                printf "%s = %s\n\n", key, value
                key_set = 1
            }
            in_section = 0
        }

        if (in_section && $0 ~ "^[[:blank:]]*" key_re "[[:blank:]]*=") {
            printf "%s = %s\n", key, value
            key_set = 1
            next
        }

        print
    }

    END {
        if (in_section && !key_set) {
            printf "%s = %s\n", key, value
        } else if (!key_set) {
            printf "\n[%s]\n%s = %s\n", section, key, value
        }
    }' "$file" > "$temp_file" || {
        echo -e "${COLOR_BAD}AWK-Verarbeitung fehlgeschlagen${COLOR_RESET}" >&2
        rm -f "$temp_file"
        return 1
    }

    if ! mv "$temp_file" "$file"; then
        echo -e "${COLOR_BAD}Konnte Datei ${COLOR_FILE}${file}${COLOR_RESET} nicht aktualisieren" >&2
        rm -f "$temp_file"
        return 1
    fi

    echo -e "${COLOR_OK}Gesetzt: ${COLOR_KEY}${key} = ${COLOR_VALUE}${value}${COLOR_OK} in [${section}]${COLOR_RESET}"
    return 0
}

# Datei, section [section], Key = Value
function add_ini_key() {
    local file="$1" section="$2" key="$3" value="$4"
    local temp_file
    temp_file=$(mktemp) || { 
        echo -e "${COLOR_BAD}Failed to create temp file${COLOR_RESET}" >&2
        return 1
    }

    # Verarbeitung mit awk
    if ! awk -v section="[${section}]" -v key="$key" -v value="$value" '
        BEGIN { in_section = 0; modified = 0 }
        $0 == section { in_section = 1; print; next }
        in_section && /^\[/ { 
            # Neue Sektion beginnt, Key einfügen (mit Leerzeichen um das =)
            printf "%s = %s\n\n", key, value
            modified = 1
            in_section = 0
        }
        in_section && $0 ~ "^[[:blank:]]*" key "[[:blank:]]*=" {
            # Existierenden Key ersetzen (mit Leerzeichen um das =)
            printf "%s = %s\n", key, value
            modified = 1
            in_section = 0
            next
        }
        { print }
        END {
            if (!modified && in_section) {
                # Am Ende der Sektion einfügen (mit Leerzeichen um das =)
                printf "%s = %s\n", key, value
            } else if (!modified) {
                # Neue Sektion am Dateiende (mit Leerzeichen um das =)
                printf "\n[%s]\n%s = %s\n", section, key, value
            }
        }
    ' "$file" > "$temp_file"; then
        echo -e "${COLOR_BAD}AWK processing failed${COLOR_RESET}" >&2
        rm -f "$temp_file"
        return 1
    fi

    if ! mv "$temp_file" "$file"; then
        echo -e "${COLOR_BAD}Failed to update ${COLOR_FILE}${file}${COLOR_RESET}" >&2
        return 1
    fi

    echo -e "${COLOR_OK}Set ${COLOR_KEY}${key} = ${COLOR_VALUE}${value}${COLOR_OK} in [${section}]${COLOR_RESET}"
    return 0
}

function del_ini_section() {
    local file="$1"
    local section="$2"
    
    # Verifizieren ob der Abschnitt existiert (still, ohne Ausgabe)
    if ! verify_ini_section "$file" "$section" >/dev/null; then
        echo -e "${SYM_INFO} Section [${section}] not found in ${COLOR_FILE}${file}${COLOR_RESET}"
        return 0
    fi
    
    echo -e "${SYM_INFO} Removing section [${COLOR_SECTION}${section}${COLOR_RESET}] from ${COLOR_FILE}${file}${COLOR_RESET}"
    
    # Temporäre Datei mit Fehlerbehandlung
    local temp_file
    temp_file=$(mktemp) || {
        echo -e "${SYM_BAD} Failed to create temporary file" >&2
        return 1
    }
    
    # Abschnitt entfernen
    if awk -v section="[${section}]" '
        $0 == section { skip=1; next }
        skip && /^\[/ { skip=0 }
        !skip { print }
    ' "$file" > "$temp_file"; then
        
        if mv "$temp_file" "$file"; then
            echo -e "${SYM_OK} Successfully removed section [${COLOR_SECTION}${section}${COLOR_RESET}]"
            return 0
        else
            echo -e "${SYM_BAD} Failed to update ${COLOR_FILE}${file}${COLOR_RESET}" >&2
            rm -f "$temp_file"
            return 1
        fi
        
    else
        echo -e "${SYM_BAD} AWK processing failed" >&2
        rm -f "$temp_file"
        return 1
    fi
}

function uncomment_ini_line() {
    local file="$1"
    local search_key="$2"
    
    # Sicherheitsprüfungen
    [ ! -f "$file" ] && { echo -e "${COLOR_BAD}Datei nicht gefunden: ${file}${COLOR_RESET}" >&2; return 1; }
    [ -z "$search_key" ] && { echo -e "${COLOR_BAD}Suchschlüssel darf nicht leer sein${COLOR_RESET}" >&2; return 1; }

    # Temporäre Datei erstellen
    local temp_file
    temp_file=$(mktemp) || { echo -e "${COLOR_BAD}Temp-Datei konnte nicht erstellt werden${COLOR_RESET}" >&2; return 1; }

    # Entkommentieren der Zeile
    sed -E "/^[[:space:]]*;[[:space:]]*${search_key}[[:space:]]*=/s/^[[:space:]]*;//" "$file" > "$temp_file" || {
        rm -f "$temp_file"
        echo -e "${COLOR_BAD}Sed-Verarbeitung fehlgeschlagen${COLOR_RESET}" >&2
        return 1
    }

    # Originaldatei ersetzen
    if mv "$temp_file" "$file"; then
        echo -e "${COLOR_OK}Zeile '${search_key}' erfolgreich entkommentiert${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_BAD}Datei konnte nicht aktualisiert werden${COLOR_RESET}" >&2
        return 1
    fi
}

function uncomment_ini_section_line() {
    local file="$1"
    local section="$2"
    local search_key="$3"

    # Sicherheitsprüfungen
    [ ! -f "$file" ] && { echo -e "${COLOR_BAD}Datei nicht gefunden: ${file}${COLOR_RESET}" >&2; return 1; }
    [ -z "$section" ] && { echo -e "${COLOR_BAD}Sektion darf nicht leer sein${COLOR_RESET}" >&2; return 1; }
    [ -z "$search_key" ] && { echo -e "${COLOR_BAD}Suchschlüssel darf nicht leer sein${COLOR_RESET}" >&2; return 1; }

    # Temporäre Datei erstellen
    local temp_file
    temp_file=$(mktemp) || { echo -e "${COLOR_BAD}Temp-Datei konnte nicht erstellt werden${COLOR_RESET}" >&2; return 1; }

    # Entkommentieren der Zeile in der richtigen Sektion
    awk -v section="[$section]" -v key="$search_key" '
    BEGIN { in_section = 0 }
    $0 ~ "^\\[" section "\\]" { in_section = 1; print; next }
    in_section && /^\[/ { in_section = 0 } # Sektion beendet
    in_section && /^[[:space:]]*;[[:space:]]*"key"[[:space:]]*=[[:space:]]*/ {
        sub(/^[[:space:]]*;/, "", $0)
    }
    { print }
    ' "$file" > "$temp_file" || {
        rm -f "$temp_file"
        echo -e "${COLOR_BAD}AWK-Verarbeitung fehlgeschlagen${COLOR_RESET}" >&2
        return 1
    }

    # Originaldatei ersetzen
    if mv "$temp_file" "$file"; then
        echo -e "${COLOR_OK}Zeile '${search_key}' in Sektion '${section}' erfolgreich entkommentiert${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_BAD}Datei konnte nicht aktualisiert werden${COLOR_RESET}" >&2
        return 1
    fi
}

function comment_ini_line() {
    local file="$1"
    local section="$2"
    local search_key="$3"

    # Sicherheitsprüfungen
    [ ! -f "$file" ] && { echo -e "${COLOR_BAD}Datei nicht gefunden: ${file}${COLOR_RESET}" >&2; return 1; }
    [ -z "$section" ] && { echo -e "${COLOR_BAD}Sektion darf nicht leer sein${COLOR_RESET}" >&2; return 1; }
    [ -z "$search_key" ] && { echo -e "${COLOR_BAD}Suchschlüssel darf nicht leer sein${COLOR_RESET}" >&2; return 1; }

    # Temporäre Datei erstellen
    local temp_file
    temp_file=$(mktemp) || { echo -e "${COLOR_BAD}Temp-Datei konnte nicht erstellt werden${COLOR_RESET}" >&2; return 1; }

    # Zeile in der richtigen Sektion kommentieren
    awk -v section="[$section]" -v key="$search_key" '
    BEGIN { in_section = 0 }
    $0 ~ "^\\[" section "\\]" { in_section = 1; print; next }
    in_section && /^\[/ { in_section = 0 }
    in_section && $0 ~ key {
        # Einfach Semikolon vor die Zeile setzen
        print ";" $0
        next
    }
    { print }
    ' "$file" > "$temp_file" || {
        rm -f "$temp_file"
        echo -e "${COLOR_BAD}AWK-Verarbeitung fehlgeschlagen${COLOR_RESET}" >&2
        return 1
    }

    # Originaldatei ersetzen
    if mv "$temp_file" "$file"; then
        echo -e "${COLOR_OK}Zeile '${search_key}' in Sektion '${section}' erfolgreich kommentiert${COLOR_RESET}"
        return 0
    else
        echo -e "${COLOR_BAD}Datei konnte nicht aktualisiert werden${COLOR_RESET}" >&2
        return 1
    fi
}

#* #################################################################################################

function database_set_iniconfig() {
    local password_file="${SCRIPT_DIR}/mariadb_passwords.txt"
    local section="DatabaseService"    

    # Zugangsdaten auslesen
    local db_user db_pass
    db_user=$(grep -oP 'Benutzername:\s*\K\S+' "$password_file")
    db_pass=$(grep -oP 'Passwort:\s*\K\S+' "$password_file")

    if [[ -z "$db_user" || -z "$db_pass" ]]; then
        echo -e "${COLOR_BAD}Benutzername oder Passwort fehlt in mariadb_passwords.txt${COLOR_RESET}"
        return 1
    fi

    # === Robust-Datenbanken ===
    local db_database="robust"
    local robust_conn="Data Source=localhost;Database=${db_database};User ID=${db_user};Password=${db_pass};Old Guids=true;SslMode=None;"

    # Robust.HG.ini
    local robust_hg_ini="robust/bin/Robust.HG.ini"
    if [[ -f "$robust_hg_ini" ]]; then
        add_ini_key "$robust_hg_ini" "$section" "ConnectionString" "\"$robust_conn\""
    else
        echo -e "${COLOR_WARNING}Datei nicht gefunden: $robust_hg_ini${COLOR_RESET}"
    fi

    # Robust.ini
    local robust_ini="robust/bin/Robust.ini"
    if [[ -f "$robust_ini" ]]; then
        add_ini_key "$robust_ini" "$section" "ConnectionString" "\"$robust_conn\""
    else
        echo -e "${COLOR_WARNING}Datei nicht gefunden: $robust_ini${COLOR_RESET}"
    fi

    # === simX-Datenbanken ===
    for ((i=1; i<=1000; i++)); do
        local sim_ini="${SCRIPT_DIR}/sim${i}/bin/config-include/GridCommon.ini"
        if [[ -f "$sim_ini" ]]; then
            local sim_conn="Data Source=localhost;Database=sim${i};User ID=${db_user};Password=${db_pass};Old Guids=true;SslMode=None;"
            add_ini_key "$sim_ini" "$section" "ConnectionString" "\"$sim_conn\""
        fi
    done
}

# welcomeiniconfig - Sets the Welcome_Area.ini
function welcomeiniconfig() {
    ip="$1"
    local gridname="$2"
    
    local welcome_ini="${SCRIPT_DIR}/sim1/bin/Regions/$gridname.ini"
    region_uuid=$(uuidgen)
    
    cat > "$welcome_ini" << EOF
[$gridname]
RegionUUID = $region_uuid
Location = 3000,3000
SizeX = 256
SizeY = 256
SizeZ = 256
InternalPort = 9010
ExternalHostName = "$ip"
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

    # Namen in der Robust.HG.ini und Robust.ini einfügen: Region_Welcome_Area = "DefaultRegion, DefaultHGRegion".
    set_ini_key "robust/bin/Robust.HG.ini" "GridService" "Region_$gridname" "DefaultRegion, DefaultHGRegion"
    set_ini_key "robust/bin/Robust.ini" "GridService" "Region_$gridname" "DefaultRegion"

    clean_config "$welcome_ini"
    echo "Welcome_Area.ini configuration completed"
    blankline
}

# Konfiguriert MoneyServer.ini im robust/bin Verzeichnis
function moneyserveriniconfig() {
    local ip="$1"
    local gridname="$2"
    
    # Passwort
    local password_file="${SCRIPT_DIR}/mariadb_passwords.txt"

    # Benutzername und Passwort auslesen (vorausgesetzt die Datei ist im Format: Benutzername: <user> Passwort: <pass>)
    local db_user db_pass
    db_user=$(grep -oP 'Benutzername:\s*\K\S+' "$password_file")
    db_pass=$(grep -oP 'Passwort:\s*\K\S+' "$password_file")

    # Falls Werte nicht gelesen wurden, abbrechen
    if [[ -z "$db_user" || -z "$db_pass" ]]; then
        echo "Fehler: Benutzername oder Passwort konnten nicht ausgelesen werden."
        return 1
    fi

    local dir="$SCRIPT_DIR/robust/bin"
    local file="$dir/MoneyServer.ini"

    mkdir -p "$dir"
    #[[ -f "$file.example" ]] && cp "$file.example" "$file" || touch "$file"

    if [[ -f "$file.example" ]]; then
        cp "$file.example" "$file"
    else
        touch "$file"
    fi
    # [MySql]
    set_ini_key "$file" "MySql" "database" "robust"
    set_ini_key "$file" "MySql" "username" "$db_user"
    set_ini_key "$file" "MySql" "password" "$db_pass"

    # [MoneyServer]
    set_ini_key "$file" "MoneyServer" "MoneyServerIPaddress" "http://$ip:8008"
    set_ini_key "$file" "MoneyServer" "MoneyScriptIPaddress" "$ip"

    echo "Weitere Infos: https://github.com/ManfredAabye/opensimcurrencyserver-dotnet"
}

# Konfiguriert OpenSim.ini für alle sim1 bis sim99-Verzeichnisse
function opensiminiconfig() {
    # 24.04.2025
    local ip="$1"
    local gridname="$2"
    local base_port=9010
    local sim_counter=1

    # Iteration über alle sim1 bis sim99 Verzeichnisse
    for i in $(seq 1 99); do
        sim_dir="$SCRIPT_DIR/sim$i"
        if [[ -d "$sim_dir/bin" ]]; then
            local dir="$sim_dir/bin"
            local file="$dir/OpenSim.ini"

            mkdir -p "$dir"
            #[[ -f "$file.example" ]] && cp "$file.example" "$file" || touch "$file"
            if [[ -f "$file.example" ]]; then
                cp "$file.example" "$file"
            else
                touch "$file"
            fi

            # Portberechnung pro Instanz
            local public_port=$((base_port + (sim_counter - 1) * 100))

            # Werte setzen
            # [Const]
            set_ini_key "$file" "Const" "BaseHostname" "$ip"            
            set_ini_key "$file" "Const" "PublicPort" "8002"
            # [Startup]

            # [Estates]
            set_ini_key "$file" "Estates" "DefaultEstateName" "$gridname Estate"
            # DefaultEstateOwnerName = FirstName LastName
            uncomment_ini_line "$file" "DefaultEstateOwnerUUID"
            # DefaultEstateOwnerPassword = password

            # [Network]
            # http_listener_port = 9010
            uncomment_ini_section_line "$file" "Network" "http_listener_port"
            set_ini_key "$file" "Network" "http_listener_port" "$public_port"

            # [SimulatorFeatures]
            uncomment_ini_line "$file" "SearchServerURI"

            # [ClientStack.LindenUDP] Begrenzt die Viewer damit sie die Server leistung nicht kippen können.
            set_ini_key "$file" "ClientStack.LindenUDP" "DisableFacelights" "true"
            set_ini_key "$file" "ClientStack.LindenUDP" "client_throttle_max_bps" "350000"
            set_ini_key "$file" "ClientStack.LindenUDP" "scene_throttle_max_bps" "70000000"

            # [SimulatorFeatures]
            set_ini_key "$file" "SimulatorFeatures" "SearchServerURI" "\${Const|BaseURL}:\${Const|PublicPort}"
            set_ini_key "$file" "SimulatorFeatures" "DestinationGuideURI" "\${Const|BaseURL}:\${Const|PublicPort}"

            # [Messaging]
            set_ini_key "$file" "Messaging" "OfflineMessageModule" "Offline Message Module V2"
            set_ini_key "$file" "Messaging" "OfflineMessageURL" "\${Const|PrivURL}:\${Const|PrivatePort}"
            set_ini_key "$file" "Messaging" "StorageProvider" "OpenSim.Data.MySQL.dll"
            set_ini_key "$file" "Messaging" "MuteListModule" "MuteListModule"
            set_ini_key "$file" "Messaging" "ForwardOfflineGroupMessages" "true"            

            # [Materials]
            set_ini_key "$file" "Materials" "MaxMaterialsPerTransaction" "250"

            # [DataSnapshot]
            set_ini_key "$file" "DataSnapshot" "gridname" "$gridname"

            # [Economy]
            set_ini_key "$file" "Economy" "SellEnabled" "true"
            set_ini_key "$file" "Economy" "EconomyModule" "DTLNSLMoneyModule" 
            set_ini_key "$file" "Economy" "CurrencyServer" "\${Const|BaseURL}:8008/" 
            set_ini_key "$file" "Economy" "UserServer" "\${Const|BaseURL}:8002/" 
            set_ini_key "$file" "Economy" "CheckServerCert" "false" 
            set_ini_key "$file" "Economy" "PriceUpload" "0" 
            set_ini_key "$file" "Economy" "MeshModelUploadCostFactor" "1.0" 
            set_ini_key "$file" "Economy" "MeshModelUploadTextureCostFactor" "1.0" 
            set_ini_key "$file" "Economy" "MeshModelMinCostFactor" "1.0" 
            set_ini_key "$file" "Economy" "PriceGroupCreate" "0" 

            # [Groups]
            set_ini_key "$file" "Groups" "Enabled" "true"
            set_ini_key "$file" "Groups" "LevelGroupCreate" "0"
            set_ini_key "$file" "Groups" "Module" "\"Groups Module V2\""
            set_ini_key "$file" "Groups" "StorageProvider" "OpenSim.Data.MySQL.dll"
            set_ini_key "$file" "Groups" "ServicesConnectorModule" "\"Groups HG Service Connector\""
            set_ini_key "$file" "Groups" "LocalService" "remote"
            set_ini_key "$file" "Groups" "GroupsServerURI" "\${Const|BaseURL}:\${Const|PrivatePort}"
            set_ini_key "$file" "Groups" "HomeURI" "\"\${Const|BaseURL}:\${Const|PublicPort}\""
            set_ini_key "$file" "Groups" "MessagingEnabled" "true"
            set_ini_key "$file" "Groups" "MessagingModule" "\"Groups Messaging Module V2\""
            set_ini_key "$file" "Groups" "NoticesEnabled" "true"
            set_ini_key "$file" "Groups" "MessageOnlineUsersOnly" "true"
            set_ini_key "$file" "Groups" "XmlRpcServiceReadKey" "1234"
            set_ini_key "$file" "Groups" "XmlRpcServiceWriteKey" "1234"

            # [InterestManagement]
            set_ini_key "$file" "InterestManagement" "UpdatePrioritizationScheme" "BestAvatarResponsiveness"
            set_ini_key "$file" "InterestManagement" "ObjectsCullingByDistance" "true"

            # [MediaOnAPrim]
            set_ini_key "$file" "MediaOnAPrim" "Enabled" "true"

            # [NPC]
            set_ini_key "$file" "NPC" "Enabled" "true"
            set_ini_key "$file" "NPC" "MaxNumberNPCsPerScene" "40"
            set_ini_key "$file" "NPC" "AllowNotOwned" "true"
            set_ini_key "$file" "NPC" "AllowSenseAsAvatar" "true"
            set_ini_key "$file" "NPC" "AllowCloneOtherAvatars" "true"
            set_ini_key "$file" "NPC" "NoNPCGroup" "true"

            # [Terrain]
            set_ini_key "$file" "Terrain" "InitialTerrain" "\"flat\""

            # [LandManagement]
            set_ini_key "$file" "LandManagement" "ShowParcelBansLines" "true"

            # [UserProfiles]
            set_ini_key "$file" "UserProfiles" "ProfileServiceURL" "\${Const|BaseURL}:\${Const|PublicPort}"
            set_ini_key "$file" "UserProfiles" "AllowUserProfileWebURLs" "true"

            # [XBakes]
            set_ini_key "$file" "XBakes" "URL" "\${Const|PrivURL}:\${Const|PrivatePort}"

            # [Architecture]
            set_ini_key "$file" "Architecture" "Include-Architecture" "\"config-include/GridHypergrid.ini\""

            ((sim_counter++))
        fi
    done
}

# Konfiguration von Robust.HG.ini im robust/bin Verzeichnis
function robusthginiconfig() {
    # 23.04.2025
    local ip="$1"
    local gridname="$2"
    local dir="$SCRIPT_DIR/robust/bin"
    local file="$dir/Robust.HG.ini"
    # Pfad: /robust/bin/Robust.HG.ini  /robust/bin/Robust.ini und $SCRIPT_DIR/sim$i/bin/config-include/GridCommon.ini

    mkdir -p "$dir"
    #[[ -f "$file.example" ]] && cp "$file.example" "$file" || touch "$file"
    if [[ -f "$file.example" ]]; then
        cp "$file.example" "$file"
    else
        touch "$file"
    fi

    # [Const]
    set_ini_key "$file" "Const" "BaseHostname" "$ip"
    # [ServiceList]
    uncomment_ini_line "$file" "OfflineIMServiceConnector"
    uncomment_ini_line "$file" "GroupsServiceConnector"
    uncomment_ini_line "$file" "BakedTextureService"
    uncomment_ini_line "$file" "UserProfilesServiceConnector"
    uncomment_ini_line "$file" "HGGroupsServiceConnector"
    
    # [Hypergrid]
    uncomment_ini_line "$file" "HomeURI"
    uncomment_ini_line "$file" "GatekeeperURI"
    
    # [DatabaseService]
    # ConnectionString = "Data Source=localhost;Database=opensim;User ID=opensim;Password=*****;Old Guids=true;SslMode=None;"
    
    # [GridService] für osWebinterface
    # Der Regionsname wird von welcomeiniconfig geschrieben.
    uncomment_ini_line "$file" "MapTileDirectory"

    
    # [LoginService] für osWebinterface etc.
    set_ini_key "$file" "LoginService" "Currency" "OS$"
    # ; SearchURL = "${Const|BaseURL}:${Const|PublicPort}/";
    # ; DestinationGuide = "${Const|BaseURL}/guide"
    # ; AvatarPicker = "${Const|BaseURL}/avatars"
    
    # [GridInfoService]
    set_ini_key "$file" "GridInfoService" "gridname" "$gridname"
    set_ini_key "$file" "GridInfoService" "gridnick" "$gridname"
    #welcome = ${Const|BaseURL}/welcome
    #economy = ${Const|BaseURL}/economy
    #about = ${Const|BaseURL}/about
    #register = ${Const|BaseURL}/register
    #help = ${Const|BaseURL}/help
    #password = ${Const|BaseURL}/password
    #GridStatusRSS = ${Const|BaseURL}:${Const|PublicPort}/GridStatusRSS
    #web_profile_url = http://webprofilesurl:ItsPort?name=[AGENT_NAME]

}

# Konfiguration von Robust.ini im robust/bin Verzeichnis
function robustiniconfig() {
    local ip="$1"
    local gridname="$2"
    local dir="$SCRIPT_DIR/robust/bin"
    local file="$dir/Robust.ini"

    mkdir -p "$dir"
    #[[ -f "$file.example" ]] && cp "$file.example" "$file" || touch "$file"
    if [[ -f "$file.example" ]]; then
        cp "$file.example" "$file"
    else
        touch "$file"
    fi

    # [Const]
    set_ini_key "$file" "Const" "BaseHostname" "$ip"
    
    # [ServiceList]
    uncomment_ini_line "$file" "OfflineIMServiceConnector"
    uncomment_ini_line "$file" "GroupsServiceConnector"
    uncomment_ini_line "$file" "BakedTextureService"
    uncomment_ini_line "$file" "UserProfilesServiceConnector"
    
    # [DatabaseService]
    # ConnectionString = "Data Source=localhost;Database=opensim;User ID=opensim;Password=*****;Old Guids=true;SslMode=None;"
    
    # [GridService] für osWebinterface
    # Der Regionsname wird von welcomeiniconfig geschrieben.
    
    # [LoginService] für osWebinterface etc.
    # ; SearchURL = "${Const|BaseURL}:${Const|PublicPort}/";
    # ; DestinationGuide = "${Const|BaseURL}/guide"
    # ; AvatarPicker = "${Const|BaseURL}/avatars"
    
    # [GridInfoService]
    set_ini_key "$file" "GridInfoService" "gridname" "$gridname"
    set_ini_key "$file" "GridInfoService" "gridnick" "$gridname"
    #welcome = ${Const|BaseURL}/welcome
    #economy = ${Const|BaseURL}/economy
    #about = ${Const|BaseURL}/about
    #register = ${Const|BaseURL}/register
    #help = ${Const|BaseURL}/help
    #password = ${Const|BaseURL}/password
    #GridStatusRSS = ${Const|BaseURL}:${Const|PublicPort}/GridStatusRSS
    #web_profile_url = http://webprofilesurl:ItsPort?name=[AGENT_NAME]
}

# Erstellt FlotsamCache.ini komplett neu in allen simX/config-include Verzeichnissen
function flotsaminiconfig() {
    for i in $(seq 1 99); do
        local config_dir="$SCRIPT_DIR/sim$i/bin/config-include"
        local file="$config_dir/FlotsamCache.ini"

        if [[ -d "$config_dir" ]]; then
            echo -e "${COLOR_FILE}Erstelle $file${COLOR_RESET}"

            mkdir -p "$config_dir"

            cat > "$file" <<EOF
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
            echo -e "${COLOR_OK}→ FlotsamCache.ini neu geschrieben für sim$i${COLOR_RESET}"
        fi
    done
}

# Erstellt GridCommon.ini mit [Const]-Sektion zuerst, dann Inhalt aus .example-Datei
function gridcommoniniconfig() {
    # 23.04.2025
    local ip="$1"
    local gridname="$2"

    for i in $(seq 1 99); do
        local config_dir="$SCRIPT_DIR/sim$i/bin/config-include"
        local file="$config_dir/GridCommon.ini"
        local example_file="$config_dir/GridCommon.ini.example"
        # Pfad: $SCRIPT_DIR/sim$i/bin/config-include/GridCommon.ini

        if [[ -d "$config_dir" ]]; then
            mkdir -p "$config_dir"

            # Erstellt neue GridCommon.ini mit [Const]-Werten
            cat > "$file" <<EOF
[Const]

    BaseHostname = "$ip"
    BaseURL = "http://$ip"

    ; The public port of the Robust server
    PublicPort = "8002"

    ; The private port of the Robust server
    PrivatePort = "8003"

    PrivURL = "http://$ip"


EOF

            # Hängt Inhalt der .example-Datei an (wenn vorhanden)
            if [[ -f "$example_file" ]]; then
                #echo -e "\n# --- Inhalte aus .example Datei ---\n" >> "$file"
                cat "$example_file" >> "$file"
            fi

            # Weitere Einstellungen:
            #echo "Weitere Einstellungen: $file"
            # [DatabaseService]
            # comment_ini_line "$file" "DatabaseService" "Include-Storage"
            sed -i '/^[[:space:]]*Include-Storage[[:space:]]*=.*/d' $file
            set_ini_key "$file" "DatabaseService" "StorageProvider" "OpenSim.Data.MySQL.dll"

            # [Hypergrid]
            set_ini_key "$file" "Hypergrid" "GatekeeperURI" "\${Const|BaseURL}:\${Const|PublicPort}"

            echo -e "${COLOR_OK}→ GridCommon.ini erstellt in sim$i${COLOR_RESET}"            
        fi
    done
}


# Erstellt osslEnable.ini komplett neu in allen simX/config-include Verzeichnissen
function osslenableiniconfig() {
    for i in $(seq 1 99); do
        local config_dir="$SCRIPT_DIR/sim$i/bin/config-include"
        local file="$config_dir/osslEnable.ini"

        if [[ -d "$config_dir" ]]; then
            echo -e "${COLOR_FILE}Erstelle $file${COLOR_RESET}"

            mkdir -p "$config_dir"

            cat > "$file" <<EOF
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
            echo -e "${COLOR_OK}→ osslEnable.ini neu geschrieben für sim$i${COLOR_RESET}"
        fi
    done
}

# Erstellt StandaloneCommon.ini mit [Const] zuerst, dann .example-Inhalte, dann HG-Settings
function standalonecommoniniconfig() {
    local ip="$1"
    local gridname="$2"

    for i in $(seq 1 99); do
        local config_dir="$SCRIPT_DIR/sim$i/bin/config-include"
        local file="$config_dir/StandaloneCommon.ini"
        local example_file="$config_dir/StandaloneCommon.ini.example"

        if [[ -d "$config_dir" ]]; then
            mkdir -p "$config_dir"

            # Erstellt neue StandaloneCommon.ini mit [Const]-Sektion
            cat > "$file" <<EOF
[Const]
BaseHostname = "$ip"
BaseURL = "http://$ip"
PublicPort = "9000"
PrivatePort = "9003"
PrivURL = "http://$ip:9003"
EOF

            # Hängt .example-Inhalte an, falls vorhanden
            if [[ -f "$example_file" ]]; then
                echo -e "\n# --- Inhalte aus .example Datei ---\n" >> "$file"
                cat "$example_file" >> "$file"
            fi

            # Fügt Hypergrid- und GridInfo-Werte danach ein
            set_ini_key "$file" "Hypergrid" "GatekeeperURI" "http://$ip:8002"
            set_ini_key "$file" "Hypergrid" "HomeURI" "http://$ip:8002"
            set_ini_key "$file" "GridInfoService" "GridName" "$gridname"
            set_ini_key "$file" "GridInfoService" "GridLoginURI" "http://$ip:8002"

            echo -e "${COLOR_OK}→ StandaloneCommon.ini erstellt in sim$i${COLOR_RESET}"
        fi
    done
}

# Hauptfunktion, fragt Benutzer nach IP & Gridnamen und ruft alle Teilfunktionen auf
function iniconfig() {
    echo "Das Arbeitsverzeichnis ist: $SCRIPT_DIR"

    echo "Wie ist Ihre IP oder DNS-Adresse? ($system_ip)"
    read -r ip

    # Falls die IP leer bleibt, wird system_ip verwendet
    if [[ -z "$ip" ]]; then
        ip=$system_ip
    fi

    echo "Wie heißt Ihr Grid?"
    read -r gridname

    # Falls der Gridname leer bleibt, wird eine generierte Name verwendet
    if [[ -z "$gridname" ]]; then
        gridname=$(generate_name)
    fi

    echo "Verwendete IP: $ip"
    echo "Gridname: $gridname"

    #! ⚠️ **Wichtige Sicherheitsinformation!**
    # Zur Kontrolle wird der Benutzername und das Passwort in der Datei:
    # `mariadb_passwords.txt` gespeichert.
    # Diese Konfiguration benötigt diese `mariadb_passwords.txt` Datei um die Datenbanken einzutragen.
    # Diese Datei **solltet ihr danach unbedingt von eurem Server löschen** und stattdessen **sicher auf eurem PC aufbewahren**.
    
    # Konfigurationsfunktionen für verschiedene Komponenten aufrufen
    echo "Starte moneyserveriniconfig ..."
    moneyserveriniconfig "$ip" "$gridname"
    echo "Starte opensiminiconfig ..."
    opensiminiconfig "$ip" "$gridname"
    echo "Starte robusthginiconfig ..."
    robusthginiconfig "$ip" "$gridname"
    echo "Starte robustiniconfig ..."
    robustiniconfig "$ip" "$gridname"
    echo "Starte gridcommoniniconfig ..."
    gridcommoniniconfig "$ip" "$gridname"
    echo "Starte standalonecommoniniconfig ..."
    standalonecommoniniconfig "$ip" "$gridname"
    echo "Starte flotsaminiconfig ..."
    flotsaminiconfig "$ip" "$gridname"
    echo "Starte osslenableiniconfig ..."
    osslenableiniconfig "$ip" "$gridname"
    echo "Starte welcomeiniconfig ..."
    welcomeiniconfig "$ip" "$gridname"
    echo "Starte database_set_iniconfig ..."
    database_set_iniconfig
}

#* #################################################################################################

# shellcheck disable=SC2317
function verify_xml_section() {
    
    local file="$1"
    local section_name="$2"
    
    if [ ! -f "$file" ]; then
        echo -e "${SYM_BAD} ${COLOR_BAD}Error: File ${COLOR_DIR}${file}${COLOR_BAD} does not exist${COLOR_RESET}" >&2
        return 2
    fi
    
    if grep -q "<Section Name=\"$section_name\">" "$file"; then
        echo -e "${SYM_OK} ${COLOR_LABEL}Section ${COLOR_VALUE}'$section_name'${COLOR_LABEL} exists in ${COLOR_DIR}${file}${COLOR_RESET}"
        return 0
    else
        echo -e "${SYM_BAD} ${COLOR_LABEL}Section ${COLOR_VALUE}'$section_name'${COLOR_LABEL} not found in ${COLOR_DIR}${file}${COLOR_RESET}"
        return 1
    fi
}

# shellcheck disable=SC2317
function add_xml_section() {
    local file="$1"
    local section_name="$2"
    local content="$3"
    local closing_tag="${4:-</Nini>}"  # Standard ist </Nini>, kann überschrieben werden
    
    # Verifizieren ob der Abschnitt bereits existiert
    if verify_xml_section "$file" "$section_name" >/dev/null; then
        return 0
    fi
    
    # Temporäre Datei für Sicherheitskopie
    local temp_file
    temp_file=$(mktemp)
    
    echo -e "${SYM_INFO} ${COLOR_ACTION}Adding section ${COLOR_VALUE}'$section_name'${COLOR_ACTION} to ${COLOR_DIR}${file}${COLOR_RESET}"
    
    # Abschnitt vor dem schließenden Tag einfügen
    if sed "s|$closing_tag|  <Section Name=\"$section_name\">\n$content\n  </Section>\n$closing_tag|" "$file" > "$temp_file"; then
        if mv "$temp_file" "$file"; then
            echo -e "${SYM_OK} ${COLOR_OK}Successfully added section ${COLOR_VALUE}'$section_name'${COLOR_OK} to ${COLOR_DIR}${file}${COLOR_RESET}"
            return 0
        fi
    fi
    
    echo -e "${SYM_BAD} ${COLOR_BAD}Failed to add section ${COLOR_VALUE}'$section_name'${COLOR_BAD} to ${COLOR_DIR}${file}${COLOR_RESET}" >&2
    return 1
}

# shellcheck disable=SC2317
function del_xml_section() {
    local file="$1"
    local section_name="$2"
    
    # Verifizieren ob der Abschnitt existiert
    if ! verify_xml_section "$file" "$section_name" >/dev/null; then
        return 0  # Abschnitt existiert nicht - nichts zu tun
    fi
    
    # Temporäre Datei für Sicherheitskopie
    local temp_file
    temp_file=$(mktemp)
    
    echo -e "${SYM_INFO} ${COLOR_ACTION}Removing section ${COLOR_VALUE}'$section_name'${COLOR_ACTION} from ${COLOR_DIR}${file}${COLOR_RESET}"
    
    # Abschnitt entfernen (inklusive aller Zeilen zwischen Section-Tags)
    if sed "/<Section Name=\"$section_name\">/,/<\/Section>/d" "$file" > "$temp_file"; then
        if mv "$temp_file" "$file"; then
            echo -e "${SYM_OK} ${COLOR_OK}Successfully removed section ${COLOR_VALUE}'$section_name'${COLOR_OK} from ${COLOR_DIR}${file}${COLOR_RESET}"
            return 0
        fi
    fi
    
    echo -e "${SYM_BAD} ${COLOR_BAD}Failed to remove section ${COLOR_VALUE}'$section_name'${COLOR_BAD} from ${COLOR_DIR}${file}${COLOR_RESET}" >&2
    return 1
}

#* Beispiel Implementierung für PBR Textures ohne Test eingefügt.
function configure_pbr_textures() {
    local asset_sets_file="opensim/bin/assets/AssetSets.xml"
    local libraries_file="opensim/bin/inventory/Libraries.xml"
    
    echo -e "\n${COLOR_HEADING}=== Configuring PBR Textures ===${COLOR_RESET}"
    
    # AssetSets.xml bearbeiten
    add_xml_section "$asset_sets_file" "PBR Textures AssetSet" \
    "    <Key Name=\"file\" Value=\"PBRTexturesAssetSet/PBRTexturesAssetSet.xml\"/>" || return 1
    
    # Libraries.xml bearbeiten
    add_xml_section "$libraries_file" "PBRTextures Library" \
    "    <Key Name=\"foldersFile\" Value=\"PBRTexturesLibrary/PBRTexturesLibraryFolders.xml\"/>\n    <Key Name=\"itemsFile\" Value=\"PBRTexturesLibrary/PBRTexturesLibraryItems.xml\"/>" || return 1
    
    echo -e "${SYM_OK} ${COLOR_OK}PBR Textures configuration completed successfully${COLOR_RESET}"

}

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

function regionsiniconfig() {
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
                
                # Komplette Config-Datei neu erstellen
                cat > "$config_file" <<EOF
[$region_name]
RegionUUID = $region_uuid
Location = $location
SizeX = 256
SizeY = 256
SizeZ = 256
InternalPort = $port
ExternalHostName = $system_ip
MaxPrims = 15000
MaxAgents = 40
MaptileStaticUUID = $region_uuid
InternalAddress = 0.0.0.0
AllowAlternatePorts = False
NonPhysicalPrimMax = 512
PhysicalPrimMax = 128
;RegionType = Estate
;MasterAvatarFirstName = System
;MasterAvatarLastName = Admin
;MasterAvatarSandboxPassword = $(openssl rand -base64 12)
EOF
                
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



# cleanall - Removes OpenSim completely
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
    sleep $Simulator_Stop_wait  # Wartezeit für sauberen Shutdown
    standalonestart
}

# Kompletter OpenSim-Neustart mit Logrotation
function opensimrestart() {
    opensimstop
    sleep $Simulator_Stop_wait  # Wartezeit für Dienst-Stopp
    logclean   # Logbereinigung
    sleep $Simulator_Start_wait  # Wartezeit vor Neustart
    opensimstart
    echo -e "\033[36mAktive Screen-Sessions:\033[0m"
    screen -ls || echo "Keine Screen-Sessions gefunden"
}

# Server-Reboot mit Vorbereitung
function reboot() {
    echo -e "\033[1;33m⚠ Server-Neustart wird eingeleitet...\033[0m"

    opensimstop
    sleep $Simulator_Stop_wait
    shutdown -r now
}

# OpenSim komplett herunterladen ⚡ Vorsicht
function downloadallgit() {
    # Downloads aus dem Github.
    opensimgitcopy
    moneygitcopy
        #ruthrothgit        # Funktioniert nicht richtig.
        #avatarassetsgit    # Funktioniert nicht richtig.
    #osslscriptsgit
    #pbrtexturesgit
    # Versionierung des OpenSimulators.
    versionrevision
    # OpenSimulator erstellen aus dem Source Code.
    opensimbuild
}

function autoinstall() {
    # Server vorbereiten
    servercheck

    # Verzeichnisse erstellen
    createdirectory

    # mySQL installieren
    database_setup

    # Downloads aus dem Github hier OpenSim und Money.
    opensimgitcopy
    moneygitcopy

    # Versionierung des OpenSimulators.
    versionrevision

    # OpenSimulator erstellen aus dem Source Code.
    opensimbuild

    # Kleine Pause
    sleep $Simulator_Start_wait

    # OpenSimulator kopieren
    opensimcopy

    # Alles konfigurieren
    iniconfig

    # Zufallsregionen erstellen
    regionsiniconfig

    # Alles starten
    opensimrestart
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Hilfefunktionen
#?──────────────────────────────────────────────────────────────────────────────────────────

function help() {
    # Allgemeine Befehle
    echo -e "${COLOR_SECTION}${SYM_SERVER} OpenSim Grundbefehle:${COLOR_RESET}"
    echo -e "\t${COLOR_START}opensimstart${COLOR_RESET}\t\t# Startet OpenSimulator Gridserver oder Regionsserver"
    echo -e "\t${COLOR_STOP}opensimstop${COLOR_RESET}\t\t# Stoppt OpenSimulator komplett"
    echo -e "\t${COLOR_START}opensimrestart${COLOR_RESET}\t\t# Startet den OpenSimulator neu"
    echo -e "\t${COLOR_OK}check_screens${COLOR_RESET}\t\t# Prüft laufende Prozesse und handelt entsprechend"
    echo ""

    # System-Checks & Setup
    echo -e "${COLOR_SECTION}${SYM_TOOLS} System-Checks & Setup:${COLOR_RESET}"
    echo -e "\t${COLOR_OK}servercheck${COLOR_RESET}\t\t# Installiert und Prüft den Server"
    echo -e "\t${COLOR_OK}createdirectory${COLOR_RESET}\t\t# Erstellt alle benötigten Verzeichnisse"
    echo -e "\t${COLOR_OK}setcrontab${COLOR_RESET}\t\t# Richtet Crontab ein damit der Server wartungsfrei laeuft"
    echo ""

    # Git-Operationen
    echo -e "${COLOR_SECTION}${SYM_SYNC} Git-Operationen:${COLOR_RESET}"
    echo -e "\t${COLOR_OK}opensimgitcopy${COLOR_RESET}\t\t# Klont den OpenSim Code"
    echo -e "\t${COLOR_OK}moneygitcopy${COLOR_RESET}\t\t# Baut den MoneyServer in den OpenSimulator ein"
    #echo -e "\t${COLOR_OK}osslscriptsgit${COLOR_RESET}\t\t# Klont OSSL-Skripte"
    #echo -e "\t${COLOR_OK}versionrevision${COLOR_RESET}\t\t# Setzt Versionsrevision"
    echo ""

    # OpenSim Build & Deploy
    echo -e "${COLOR_SECTION}${SYM_FOLDER} OpenSim Build & Deploy:${COLOR_RESET}"
    echo -e "\t${COLOR_OK}opensimbuild${COLOR_RESET}\t\t# Kompiliert OpenSim zu ausführbaren Dateien"
    echo -e "\t${COLOR_OK}opensimcopy${COLOR_RESET}\t\t# Kopiert OpenSim in alle Verzeichnisse"
    #echo -e "\t${COLOR_OK}opensimupgrade${COLOR_RESET}\t\t# Upgradet OpenSim"
    echo -e "\t${COLOR_OK}database_setup${COLOR_RESET}\t\t# Erstellt alle Datenbanken"
    echo ""

    # Konfigurationsmanagement
    #echo -e "${COLOR_SECTION}${SYM_CONFIG} Konfigurationsmanagement:${COLOR_RESET}"
    #echo -e "\t${COLOR_WARNING}moneyserveriniconfig${COLOR_RESET}\t# Konfiguriert MoneyServer.ini (experimentell)"
    #echo -e "\t${COLOR_WARNING}opensiminiconfig${COLOR_RESET}\t# Konfiguriert OpenSim.ini (experimentell)"
    #echo -e "\t${COLOR_WARNING}regionsiniconfig${COLOR_RESET}\t# Konfiguriert Regionen (experimentell)"
    #echo ""

    # Systembereinigung
    echo -e "${COLOR_SECTION}${SYM_CLEAN} Systembereinigung:${COLOR_RESET}"
    echo -e "\t${COLOR_OK}cacheclean${COLOR_RESET}\t\t# Bereinigt Cache"
    echo -e "\t${COLOR_OK}logclean${COLOR_RESET}\t\t# Bereinigt Logs"
    echo -e "\t${COLOR_OK}mapclean${COLOR_RESET}\t\t# Bereinigt Maptiles"
    #echo -e "\t${COLOR_OK}clean_linux_logs${COLOR_RESET}\t# Bereinigt Systemlogs"
    echo ""

    # Hilfe
    echo -e "${COLOR_SECTION}${SYM_INFO} Hilfe:${COLOR_RESET}"
    echo -e "\t${COLOR_OK}help${COLOR_RESET}\t\t\t# Zeigt diese Hilfe"
    echo -e "\t${COLOR_OK}prohelp${COLOR_RESET}\t\t\t# Zeigt die Pro Hilfe"
    echo ""
}

function prohelp() {
    #* OpenSim Grundbefehle
    echo -e "${COLOR_SECTION}${SYM_SERVER} OpenSim Grundbefehle:${COLOR_RESET}"
    echo -e "\t${COLOR_START}opensimstart${COLOR_RESET} \t\t\t # OpenSim starten"
    echo -e "\t${COLOR_STOP}opensimstop${COLOR_RESET} \t\t\t # OpenSim stoppen"
    echo -e "\t${COLOR_START}opensimrestart${COLOR_RESET} \t\t\t # OpenSim neu starten"
    echo -e "\t${COLOR_OK}check_screens${COLOR_RESET} \t\t\t # Laufende OpenSim-Prozesse prüfen und neu starten"
    echo " "

    #* System-Checks & Setup
    echo -e "${COLOR_SECTION}${SYM_TOOLS} System-Checks & Setup:${COLOR_RESET}"
    echo -e "\t${COLOR_OK}servercheck${COLOR_RESET} \t\t\t # Serverbereitschaft prüfen und Abhängigkeiten installieren"
    echo -e "\t${COLOR_OK}createdirectory${COLOR_RESET} \t\t # OpenSim-Verzeichnisse erstellen"
    echo -e "\t${COLOR_OK}setcrontab${COLOR_RESET} \t\t\t # Crontab Automatisierungen einrichten"
    echo " "

    #* Git-Operationen
    echo -e "${COLOR_SECTION}${SYM_SYNC} Git-Operationen:${COLOR_RESET}"
    echo -e "\t${COLOR_OK}opensimgitcopy${COLOR_RESET} \t\t\t # OpenSim aus Git herunterladen"
    echo -e "\t${COLOR_OK}moneygitcopy${COLOR_RESET} \t\t\t # MoneyServer aus Git holen"
    echo -e "\t${COLOR_WARNING}ruthrothgit${COLOR_RESET} \t\t\t # Ruth Roth IAR Dateien ${COLOR_BAD}(Vorsicht)${COLOR_RESET}"
    echo -e "\t${COLOR_WARNING}avatarassetsgit${COLOR_RESET} \t\t # Avatar-Assets ${COLOR_BAD}(Vorsicht)${COLOR_RESET}"
    echo -e "\t${COLOR_OK}osslscriptsgit${COLOR_RESET} \t\t\t # OSSL Beispielskripte herunterladen"
    echo -e "\t${COLOR_WARNING}pbrtexturesgit${COLOR_RESET} \t\t\t # PBR-Texturen ${COLOR_BAD}(Vorsicht)${COLOR_RESET}"
    echo -e "\t${COLOR_OK}downloadallgit${COLOR_RESET} \t\t\t # Alle Git-Repos herunterladen"
    echo -e "\t${COLOR_OK}versionrevision${COLOR_RESET} \t\t # Versionsverwaltung aktivieren"
    echo " "

    #* OpenSim Build & Deployment
    echo -e "${COLOR_SECTION}${SYM_FOLDER} OpenSim Build & Deploy:${COLOR_RESET}"
    echo -e "\t${COLOR_OK}opensimbuild${COLOR_RESET} \t\t\t # OpenSim kompilieren"
    echo -e "\t${COLOR_OK}opensimcopy${COLOR_RESET} \t\t\t # OpenSim Dateien kopieren"
    echo -e "\t${COLOR_OK}opensimupgrade${COLOR_RESET} \t\t\t # OpenSim aktualisieren"
    echo -e "\t${COLOR_OK}database_setup${COLOR_RESET} \t\t\t # Datenbank für OpenSim einrichten"
    echo " "

    #* Konfigurationsmanagement
    echo -e "${COLOR_SECTION}${SYM_CONFIG} Konfigurationsmanagement:${COLOR_RESET}"
    echo -e "\t${COLOR_WARNING}moneyserveriniconfig${COLOR_RESET} \t\t # Konfiguriert MoneyServer.ini ${COLOR_BAD}(experimentell)${COLOR_RESET}"
    echo -e "\t${COLOR_WARNING}opensiminiconfig${COLOR_RESET} \t\t # Konfiguriert OpenSim.ini ${COLOR_BAD}(experimentell)${COLOR_RESET}"
    echo -e "\t${COLOR_WARNING}robusthginiconfig${COLOR_RESET} \t\t # Konfiguriert Robust.HG.ini ${COLOR_BAD}(experimentell)${COLOR_RESET}"
    echo -e "\t${COLOR_WARNING}robustiniconfig${COLOR_RESET} \t\t # Konfiguriert Robust.ini ${COLOR_BAD}(experimentell)${COLOR_RESET}"
    echo -e "\t${COLOR_WARNING}gridcommoniniconfig${COLOR_RESET} \t\t # Erstellt GridCommon.ini ${COLOR_BAD}(experimentell)${COLOR_RESET}"
    echo -e "\t${COLOR_WARNING}standalonecommoniniconfig${COLOR_RESET} \t # Erstellt StandaloneCommon.ini ${COLOR_BAD}(experimentell)${COLOR_RESET}"
    echo -e "\t${COLOR_WARNING}flotsaminiconfig${COLOR_RESET} \t\t # Erstellt FlotsamCache.ini ${COLOR_BAD}(experimentell)${COLOR_RESET}"
    echo -e "\t${COLOR_WARNING}osslenableiniconfig${COLOR_RESET} \t\t # Konfiguriert osslEnable.ini ${COLOR_BAD}(experimentell)${COLOR_RESET}"
    echo -e "\t${COLOR_WARNING}welcomeiniconfig${COLOR_RESET} \t\t # Konfiguriert Begrüßungsregion ${COLOR_BAD}(experimentell)${COLOR_RESET}"
    echo -e "\t${COLOR_WARNING}regionsiniconfig${COLOR_RESET} \t\t # Startet neue Regionen-Konfigurationen ${COLOR_BAD}(experimentell)${COLOR_RESET}"
    echo -e "\t${COLOR_WARNING}iniconfig${COLOR_RESET} \t\t\t # Startet ALLE Konfigurationen ${COLOR_BAD}(experimentell)${COLOR_RESET}"
    echo " "

    #* XML & INI-Operationen
    echo -e "${COLOR_SECTION}${SYM_SCRIPT} INI-Operationen:${COLOR_RESET}"
    echo -e "\t${COLOR_OK}verify_ini_section${COLOR_RESET} \t\t # INI-Abschnitt verifizieren"
    echo -e "\t${COLOR_OK}verify_ini_key${COLOR_RESET} \t\t\t # INI-Schlüssel verifizieren"
    echo -e "\t${COLOR_OK}add_ini_section${COLOR_RESET} \t\t # INI-Abschnitt hinzufügen"
    echo -e "\t${COLOR_OK}set_ini_key${COLOR_RESET} \t\t\t # INI-Schlüssel setzen"
    echo -e "\t${COLOR_WARNING}del_ini_section${COLOR_RESET} \t\t # INI-Abschnitt löschen ${COLOR_BAD}(Vorsicht)${COLOR_RESET}"
    echo " "

    #* XML-Operationen
    echo -e "${COLOR_SECTION}${SYM_SCRIPT} XML-Operationen:${COLOR_RESET}"
    echo -e "\t${COLOR_OK}verify_xml_section${COLOR_RESET} \t\t # XML-Abschnitt verifizieren"
    echo -e "\t${COLOR_OK}add_xml_section${COLOR_RESET} \t\t # XML-Abschnitt hinzufügen"
    echo -e "\t${COLOR_WARNING}del_xml_section${COLOR_RESET} \t\t # XML-Abschnitt löschen ${COLOR_BAD}(Vorsicht)${COLOR_RESET}"
    echo " "

    #* System-Bereinigung
    echo -e "${COLOR_SECTION}${SYM_CLEAN} Systembereinigung:${COLOR_RESET}"
    echo -e "\t${COLOR_OK}reboot${COLOR_RESET} \t\t\t\t # Server neu starten"
    echo -e "\t${COLOR_OK}cacheclean${COLOR_RESET} \t\t\t # Cache bereinigen"
    echo -e "\t${COLOR_OK}logclean${COLOR_RESET} \t\t\t # Logs bereinigen"
    echo -e "\t${COLOR_OK}mapclean${COLOR_RESET} \t\t\t # Maptiles bereinigen"
    echo -e "\t${COLOR_OK}renamefiles${COLOR_RESET} \t\t\t # Beispieldateien umbenennen"
    echo -e "\t${COLOR_OK}clean_linux_logs${COLOR_RESET} \t\t # Linux-Logs bereinigen"
    echo " "

    #* Hilfe
    echo -e "${COLOR_SECTION}${SYM_INFO} Hilfe:${COLOR_RESET}"
    echo -e "\t${COLOR_OK}help${COLOR_RESET} \t\t\t\t # Diese Hilfeseite anzeigen"
    echo " "
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Eingabeauswertung
#?──────────────────────────────────────────────────────────────────────────────────────────

case $KOMMANDO in
    # Allgemeine Befehle #
    check_screens)             check_screens ;;
    start|opensimstart)        opensimstart ;;
    stop|opensimstop)          opensimstop ;;
    osrestart|autorestart|restart|opensimrestart) opensimrestart ;;

    #  SYSTEM-CHECKS & SETUP  #
    servercheck)       servercheck ;;
    createdirectory)   createdirectory ;;
    setcrontab)        setcrontab ;;
   
    #  GIT-OPERATIONEN       #
    opensimgitcopy|opensimgit)  opensimgitcopy ;;
    moneygitcopy|moneygit)      moneygitcopy ;;
    ruthrothgit)                ruthrothgit ;;
    avatarassetsgit)            avatarassetsgit ;;
    osslscriptsgit)             osslscriptsgit ;;
    pbrtexturesgit)             pbrtexturesgit ;;
    downloadallgit)             downloadallgit ;;
    versionrevision)            versionrevision ;;

    #  OPENSIM BUILD & DEPLOY #
    opensimbuild)      opensimbuild ;;
    opensimcopy)       opensimcopy ;;
    opensimupgrade)    opensimupgrade ;;
    database_setup)    database_setup ;;
    autoinstall) autoinstall ;;

    #  KONFIGURATIONS-MGMT AUTOKONFIGURATION    #
    moneyserveriniconfig)       moneyserveriniconfig "$2" "$3" ;;
    opensiminiconfig)           opensiminiconfig "$2" "$3" ;;
    robusthginiconfig)          robusthginiconfig "$2" "$3" ;;
    robustiniconfig)            robustiniconfig "$2" "$3" ;;
    gridcommoniniconfig)        gridcommoniniconfig "$2" "$3" ;;
    standalonecommoniniconfig)  standalonecommoniniconfig "$2" "$3" ;;
    flotsaminiconfig)           flotsaminiconfig "$2" "$3" ;;
    osslenableiniconfig)        osslenableiniconfig "$2" "$3" ;;
    welcomeiniconfig)           welcomeiniconfig "$2" "$3" ;;
    database_set_iniconfig)     database_set_iniconfig ;;
    regionsiniconfig)           regionsiniconfig ;; # Alle neuen Konfigurationen starten.
    generatename|generate_name) generate_name ;;
    cleanconfig)                clean_config "$2" ;;

    #  Experimental            #
    configure_pbr_textures) configure_pbr_textures ;;

    #  INI-OPERATIONEN        #
    verify_ini_section)    verify_ini_section "$2" "$3" "$4" ;;
    verify_ini_key)        verify_ini_key "$2" "$3" "$4" ;;
    add_ini_section)       add_ini_section "$2" "$3" ;;
    set_ini_key)           set_ini_key "$2" "$3" "$4" "$5" ;;
    add_ini_key)           add_ini_key "$2" "$3" "$4" "$5" ;;
    del_ini_section)       del_ini_section "$2" "$3" ;;
    uncomment_ini_line)    uncomment_ini_line "$2" "$3" ;;
    uncomment_ini_section_line) uncomment_ini_section_line "$2" "$3" "$4" ;;
    comment_ini_line)      comment_ini_line "$2" "$3" "$4" ;;
    iniconfig)             iniconfig ;;

    #  XML-OPERATIONEN        #
    verify_xml_section)    verify_xml_section "$2" "$3" ;;
    add_xml_section)       add_xml_section "$2" "$3" "$4" ;;
    del_xml_section)       del_xml_section "$2" "$3" ;;  

    #  STANDALONE-MODUS       #
    standalone)        standalone ;;
    standalonestart)   standalonestart ;;
    standalonestop)    standalonestop ;;
    standalonerestart) standalonerestart ;;

    #  SYSTEM-BEREINIGUNG     #
    reboot)            reboot ;;
    dataclean)         dataclean ;;
    pathclean)         pathclean ;;
    cacheclean)        cacheclean ;;
    logclean)          logclean ;;
    mapclean)          mapclean ;;
    autoallclean)      autoallclean ;;
    regionsclean)      regionsclean ;;
    cleanall)          cleanall ;;
    renamefiles)       renamefiles ;;
    colortest)         colortest ;;
    clean_linux_logs)  clean_linux_logs ;;
    delete_opensim)    delete_opensim ;;

    #  HILFE & SONSTIGES      #
    prohelp)           prohelp ;;
    h|help|hilfe|*)   help ;;
esac

# Programm Ende mit Zeitstempel
blankline
echo -e "\e[36m${SCRIPTNAME}\e[0m ${VERSION} wurde beendet $(date +'%Y-%m-%d %H:%M:%S')" >&2
exit 0
