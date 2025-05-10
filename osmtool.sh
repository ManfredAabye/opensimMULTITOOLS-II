#!/bin/bash

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Debug in log Datei
#! ACHTUNG das loggen speichert alles auch vertrauliche Daten.
#?──────────────────────────────────────────────────────────────────────────────────────────

#* Debug-Log-System

# 1. Logging ein/aus schalten
#LOG_ENABLED=false   # Logging ist AUS
LOG_ENABLED=true  # Logging ist AKTIV (Standard)

# 2. Alte Log-Datei löschen
OLD_LOG_DEL=true    # Löscht alte Log-Datei vor Start (Standard)
# OLD_LOG_DEL=false # Behält alte Log-Datei und fügt neue Einträge an

# 3. Log-Datei Name und Ort
DEBUG_LOG="osmtool_debug.log"  # Speicherort der Log-Datei

# Logdatei vorbereiten
if [[ "$LOG_ENABLED" == "true" ]]; then
    if [[ "$OLD_LOG_DEL" == "true" ]]; then
        rm "$DEBUG_LOG" 2>/dev/null
    fi
    touch "$DEBUG_LOG" 2>/dev/null || echo "Kann Logdatei nicht erstellen" >&2
fi

# Verbesserte Funktion zum Entfernen von ANSI-Codes
function clean_ansi() {
    echo -e "$1" | sed -E 's/\x1B\[([0-9]{1,3}(;[0-9]{1,3})*)?[mGK]//g'
}

# Log-Funktion
# function log() {
#     local message="$1"
#     local level="${2:-INFO}"
#     timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
#     # Zur Konsole (mit Farben)
#     echo -e "$message"
    
#     # Zur Logdatei (ohne Farbcodes)
#     if $LOG_ENABLED; then
#         clean_message=$(clean_ansi "$message")
#         echo "[${timestamp}] [${level}] ${clean_message}" >> "$DEBUG_LOG"
#     fi
# }

# Log-Funktion
function log() {
    local message="$1"
    local level="${2:-INFO}"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Zur Konsole (mit Farben)
    echo -e "$message"
    
    # Zur Logdatei (ohne Farbcodes)
    if [[ "$LOG_ENABLED" == "true" ]]; then
        local clean_message
        clean_message=$(clean_ansi "$message")
        echo "[${timestamp}] [${level}] ${clean_message}" >> "$DEBUG_LOG"
    fi
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Informationen Kopfzeile
#?──────────────────────────────────────────────────────────────────────────────────────────

# Quelle:
# https://github.com/ManfredAabye/opensimMULTITOOLS-II/blob/main/osmtool.sh

tput reset # Bildschirmausgabe loeschen inklusive dem Scrollbereich.
SCRIPTNAME="opensimMULTITOOL II"

#testmodus=1 # Testmodus: 1=aktiviert, 0=deaktiviert

# Versionsnummer besteht aus: Jahr.Monat.Funktionsanzahl.Eigentliche_Version
VERSION="V25.5.102.416"
log "\e[36m$SCRIPTNAME\e[0m $VERSION"
echo "Dies ist ein Tool welches der Verwaltung von OpenSim Servern dient."
echo "Bitte beachten Sie, dass die Anwendung auf eigene Gefahr und Verantwortung erfolgt."
log "\e[33mZum Abbrechen bitte STRG+C oder CTRL+C drücken.\e[0m"
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
SYM_WARNING="${COLOR_VALUE}⚠${COLOR_RESET}"      # Achtung, Gefahr, Hinweis
SYM_PUZZLE="${COLOR_VALUE}🧩${COLOR_RESET}"      # Rätsel, Aufgabe, Aufgabenstellung
SYM_PACKAGE="${COLOR_VALUE}📦${COLOR_RESET}"     # Package
SYM_OKN="${COLOR_VALUE}✔️${COLOR_RESET}"         # OK
SYM_FORWARD="${COLOR_VALUE}⏭️${COLOR_RESET}"     # Weiter
SYM_OKNN="${COLOR_VALUE}✅${COLOR_RESET}"        # OK
SYM_VOR="${COLOR_VALUE}●${COLOR_RESET}"  # Alternative: ▲ ● ◆ ☛ ⚑ ⓘ ${SYM_VOR}

#* WARTEZEITEN muessen leider sein damit der Server nicht überfordert wird.
Simulator_Start_wait=15 # Sekunden
MoneyServer_Start_wait=30 # Sekunden
RobustServer_Start_wait=30 # Sekunden
Simulator_Stop_wait=15 # Sekunden
MoneyServer_Stop_wait=30 # Sekunden
RobustServer_Stop_wait=30 # Sekunden

function blankline() { sleep 0.5; echo " ";}

# Hauptpfad des Skripts automatisch setzen
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR" || exit 1
system_ip=$(hostname -I | awk '{print $1}')
log "${COLOR_LABEL}Das Arbeitsverzeichnis ist:${COLOR_RESET} ${COLOR_VALUE}$SCRIPT_DIR${COLOR_RESET}"
log "${COLOR_LABEL}Ihre IP Adresse ist:${COLOR_RESET} ${COLOR_VALUE}$system_ip${COLOR_RESET}"
blankline

# Soll im Hypergrid Modus gearbeitet werden oder in einem Geschlossenen Grid?
function hypergrid() {
    local modus="$1"
    local robust_dir="$SCRIPT_DIR/robust/bin"  # Korrekter Pfad zu Robust-Dateien
    
    echo "Modus Einstellung"
    
    if [[ "$modus" == "hypergrid" ]]; then
        echo "Hypergrid Modus aktiviert."
        
        # Prüfen ob Robust.HG.ini existiert
        if [[ ! -f "$robust_dir/Robust.HG.ini" ]]; then
            log "${COLOR_BAD}FEHLER: Robust.HG.ini nicht gefunden in $robust_dir${COLOR_RESET}" >&2
            return 1
        fi
        
        cp "$robust_dir/Robust.HG.ini" "$robust_dir/Robust.ini" || {
            log "${COLOR_BAD}FEHLER: Konnte Robust.HG.ini nicht kopieren${COLOR_RESET}" >&2
            return 1
        }
        
    else
        echo "Geschlossener Grid Modus aktiviert."
        
        # Prüfen ob Robust.local.ini existiert
        if [[ ! -f "$robust_dir/Robust.local.ini" ]]; then
            log "${COLOR_BAD}FEHLER: Robust.local.ini nicht gefunden in $robust_dir${COLOR_RESET}" >&2
            return 1
        fi
        
        cp "$robust_dir/Robust.local.ini" "$robust_dir/Robust.ini" || {
            log "${COLOR_BAD}FEHLER: Konnte Robust.local.ini nicht kopieren${COLOR_RESET}" >&2
            return 1
        }
    fi
    
    log "${COLOR_OK}Modus erfolgreich auf $modus gesetzt${COLOR_RESET}"
    return 0
}


KOMMANDO=$1 # Eingabeauswertung fuer Funktionen.

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Abhängigkeiten installieren
#?──────────────────────────────────────────────────────────────────────────────────────────

# Nach git clone/pull prüfen
check_repo_integrity() {
    local repo_dir=${1:-.}
    
    pushd "$repo_dir" > /dev/null || return 1
    
    if ! git fsck --no-progress; then
        log "${SYM_BAD} ${COLOR_ERROR}Repository-Prüfung fehlgeschlagen!${COLOR_RESET}"
        popd > /dev/null
        return 1
    fi
    
    if [ "$(git status --porcelain)" ]; then
        log "${COLOR_WARNING}Uncommittete Änderungen vorhanden.${COLOR_RESET}"
    fi
    
    popd > /dev/null
    log "${SYM_OK} ${COLOR_ACTION}Repository-Integrität OK.${COLOR_RESET}"
    return 0
}

function servercheck() {
    # Direkt kompatible Distributionen:
    # Debian 11+ (Bullseye, Bookworm) – Offiziell unterstützt für .NET 8
    # Ubuntu 20.04, 22.04, 24.04 – Microsoft bietet direkt kompatible Pakete
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

    log "${COLOR_HEADING}🔍 Server-Kompatibilitätscheck wird durchgeführt...${COLOR_RESET}"

    # Ermitteln der Distribution und Version
    os_id=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    os_version=$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    os_codename=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"')

    log "${COLOR_LABEL}Server läuft mit:${COLOR_RESET} ${COLOR_SERVER}$os_id $os_version ($os_codename)${COLOR_RESET}"

    # Paketnamen für verschiedene Distributionen definieren
    declare -A dotnet_pkg=(
        ["ubuntu"]="dotnet-sdk-8.0"
        ["debian"]="dotnet-sdk-8.0"
        ["linuxmint"]="dotnet-sdk-8.0"
        ["pop_os"]="dotnet-sdk-8.0"
        ["arch"]="dotnet-sdk"
        ["manjaro"]="dotnet-sdk"
        ["raspbian"]="dotnet-sdk-8.0"
    )

    # Abhängigkeiten für verschiedene Distributionen
    declare -A required_packages=(
        ["ubuntu"]="git libc6 libgcc-s1 libgssapi-krb5-2 libicu70 liblttng-ust1 libssl3 libstdc++6 libunwind8 zlib1g libgdiplus zip screen"
        ["debian"]="git libc6 libgcc1 libgssapi-krb5-2 libicu67 liblttng-ust1 libssl3 libstdc++6 libunwind8 zlib1g libgdiplus zip screen"
        ["linuxmint"]="git libc6 libgcc-s1 libgssapi-krb5-2 libicu70 liblttng-ust1 libssl3 libstdc++6 libunwind8 zlib1g libgdiplus zip screen"
        ["pop_os"]="git libc6 libgcc-s1 libgssapi-krb5-2 libicu70 liblttng-ust1 libssl3 libstdc++6 libunwind8 zlib1g libgdiplus zip screen"
        ["arch"]="git glibc gcc-libs krb5 icu lttng-ust openssl libunwind zlib gdiplus zip screen"
        ["manjaro"]="git glibc gcc-libs krb5 icu lttng-ust openssl libunwind zlib gdiplus zip screen"
        ["raspbian"]="git libc6 libgcc1 libgssapi-krb5-2 libicu67 liblttng-ust0 libssl1.1 libstdc++6 libunwind8 zlib1g libgdiplus zip screen"
    )

    # Prüfen, welche .NET-Version installiert werden muss
    if [[ "$os_id" == "ubuntu" || "$os_id" == "linuxmint" || "$os_id" == "pop_os" ]]; then
        if [[ "$os_version" == "18.04" ]]; then
            required_dotnet="dotnet-sdk-6.0"
        elif dpkg --compare-versions "$os_version" ge "20.04"; then
            required_dotnet=${dotnet_pkg[$os_id]}
            
            # Spezialfall Ubuntu 24.04 (verwendet jammy Repository)
            if [[ "$os_version" == "24.04" ]]; then
                log "${SYM_INFO} Ubuntu 24.04 verwendet das .NET Repository für Ubuntu 22.04 (jammy)"
            fi
        else
            log "${SYM_BAD} ${COLOR_WARNING}Nicht unterstützte Ubuntu-Version: $os_version!${COLOR_RESET}"
            return 1
        fi
    elif [[ "$os_id" == "debian" ]]; then
        if [[ "$os_version" -ge "11" ]]; then
            required_dotnet=${dotnet_pkg[$os_id]}
        else
            log "${SYM_BAD} ${COLOR_WARNING}Debian Version $os_version wird nicht unterstützt (mindestens Debian 11 erforderlich)!${COLOR_RESET}"
            return 1
        fi
    elif [[ "$os_id" == "arch" || "$os_id" == "manjaro" ]]; then
        required_dotnet=${dotnet_pkg[$os_id]}
    elif [[ "$os_id" == "raspbian" ]]; then
        if [[ "$os_version" -ge "11" ]]; then
            required_dotnet=${dotnet_pkg[$os_id]}
            log "${SYM_INFO} Raspberry Pi OS erfordert möglicherweise manuelle Anpassungen für .NET 8.0"
        else
            log "${SYM_BAD} ${COLOR_WARNING}Raspberry Pi OS Version $os_version wird nicht unterstützt!${COLOR_RESET}"
            return 1
        fi
    else
        log "${SYM_BAD} ${COLOR_WARNING}Keine unterstützte Distribution für .NET gefunden!${COLOR_RESET}"
        return 1
    fi

    # .NET-Installationsstatus prüfen
    log "${COLOR_HEADING}🔄 .NET Runtime-Überprüfung:${COLOR_RESET}"
    
    if [[ "$os_id" == "arch" || "$os_id" == "manjaro" ]]; then
        if ! pacman -Qi "$required_dotnet" >/dev/null 2>&1; then
            log "${SYM_OK} ${COLOR_ACTION}Installiere ${COLOR_SERVER}$required_dotnet${COLOR_RESET}..."
            sudo pacman -S --noconfirm "$required_dotnet"
            log "${SYM_OK} ${COLOR_SERVER}$required_dotnet${COLOR_RESET} ${COLOR_ACTION}wurde erfolgreich installiert.${COLOR_RESET}"
        else
            log "${SYM_OK} ${COLOR_SERVER}$required_dotnet${COLOR_RESET} ${COLOR_ACTION}ist bereits installiert.${COLOR_RESET}"
        fi
    else
        #if ! dpkg -s "$required_dotnet" >/dev/null 2>&1; then
        # dpkg-query -W hat eine bessere Fehlerabfrage
        if ! dpkg-query -W "$required_dotnet" >/dev/null 2>&1; then
            log "${SYM_OK} ${COLOR_ACTION}Installiere ${COLOR_SERVER}$required_dotnet${COLOR_RESET}..."
            
            # Microsoft Repository hinzufügen für Debian/Ubuntu-basierte Systeme
            if [[ "$os_id" == "ubuntu" || "$os_id" == "debian" || "$os_id" == "linuxmint" || "$os_id" == "pop_os" || "$os_id" == "raspbian" ]]; then
                log "${SYM_INFO} Füge Microsoft Repository hinzu..."
                wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
                sudo dpkg -i packages-microsoft-prod.deb
                rm packages-microsoft-prod.deb
                sudo apt-get update
            fi
            
            sudo apt-get install -y "$required_dotnet"
            log "${SYM_OK} ${COLOR_SERVER}$required_dotnet${COLOR_RESET} ${COLOR_ACTION}wurde erfolgreich installiert.${COLOR_RESET}"
        else
            log "${SYM_OK} ${COLOR_SERVER}$required_dotnet${COLOR_RESET} ${COLOR_ACTION}ist bereits installiert.${COLOR_RESET}"
        fi
    fi

    # Fehlende Pakete prüfen und installieren
    log "${COLOR_HEADING}${SYM_PACKAGE} Überprüfe fehlende Pakete...${COLOR_RESET}"
    
    # Paketliste basierend auf Distribution auswählen
    if [[ -n "${required_packages[$os_id]}" ]]; then
        IFS=' ' read -r -a pkg_list <<< "${required_packages[$os_id]}"
    else
        # Fallback für nicht aufgeführte Distributionen
        pkg_list=("git" "libc6" "libgcc-s1" "libgssapi-krb5-2" "libicu70" "libssl3" "libstdc++6" "zlib1g" "zip" "screen")
    fi

    for package in "${pkg_list[@]}"; do
        if [[ "$os_id" == "arch" || "$os_id" == "manjaro" ]]; then
            if ! pacman -Qi "$package" >/dev/null 2>&1; then
                log "${SYM_OK} ${COLOR_ACTION}Installiere ${COLOR_SERVER}$package${COLOR_RESET}..."
                sudo pacman -S --noconfirm "$package"
            fi
        else
            #if ! dpkg -s "$package" >/dev/null 2>&1; then
            # dpkg-query -W hat eine bessere Fehlerabfrage
            if ! dpkg-query -W "$package" >/dev/null 2>&1; then
                log "${SYM_OK} ${COLOR_ACTION}Installiere ${COLOR_SERVER}$package${COLOR_RESET}..."
                sudo apt-get install -y "$package"
            fi
        fi
    done

    log "${SYM_OK} ${COLOR_HEADING}Alle benötigten Pakete wurden installiert.${COLOR_RESET}"
    blankline
}

function setup_webserver() {
    log "${COLOR_SECTION}=== Web Server Setup (Apache/PHP) ===${COLOR_RESET}"

    # 1. Paketlisten mit erweiterten PHP-Modulen
    declare -A web_packages=(
        ["ubuntu"]="apache2 php libapache2-mod-php php-mysql php-gd php-curl php-mbstring php-xml php-zip"
        ["debian"]="apache2 php libapache2-mod-php php-mysql php-gd php-curl php-mbstring php-xml php-zip"
        ["arch"]="apache php php-apache php-gd php-curl php-mysql mariadb-libs php-mbstring php-xml"
        ["manjaro"]="apache php php-apache php-gd php-curl php-mysql mariadb-libs php-mbstring php-xml"
        ["centos"]="httpd php php-mysqlnd php-gd php-curl php-mbstring php-xml"
        ["fedora"]="httpd php php-mysqlnd php-gd php-curl php-mbstring php-xml"
    )

    # 2. Installation
    case $current_distro in
        ubuntu|debian|linuxmint|pop|raspbian)
            log "${SYM_INFO} ${COLOR_ACTION}Installiere Apache/PHP (apt)...${COLOR_RESET}"
            sudo apt-get update
            sudo apt-get install -y "${web_packages[ubuntu]}" || {
                log "${SYM_BAD} ${COLOR_ERROR}Installation fehlgeschlagen!${COLOR_RESET}";
                return 1;
            }
            sudo a2enmod rewrite
            sudo systemctl restart apache2
            ;;

        arch|manjaro)
            log "${SYM_INFO} ${COLOR_ACTION}Installiere Apache/PHP (pacman)...${COLOR_RESET}"
            sudo pacman -Sy --noconfirm "${web_packages[arch]}" || {
                log "${SYM_BAD} ${COLOR_ERROR}Installation fehlgeschlagen!${COLOR_RESET}";
                return 1;
            }
            
            # Apache-Konfiguration für PHP
            sudo sed -i 's/LoadModule mpm_event_module/#LoadModule mpm_event_module/' /etc/httpd/conf/httpd.conf
            sudo sed -i 's/#LoadModule mpm_prefork_module/LoadModule mpm_prefork_module/' /etc/httpd/conf/httpd.conf
            echo -e "\n# PHP-Konfiguration\nLoadModule php_module modules/libphp.so\nAddHandler php-script .php\nInclude conf/extra/php_module.conf" | sudo tee -a /etc/httpd/conf/httpd.conf >/dev/null
            
            sudo systemctl restart httpd
            ;;

        centos|fedora)
            log "${SYM_INFO} ${COLOR_ACTION}Installiere Apache/PHP (yum/dnf)...${COLOR_RESET}"
            [[ "$current_distro" == "centos" ]] && sudo yum install -y epel-release
            sudo yum install -y "${web_packages[centos]}" || {
                log "${SYM_BAD} ${COLOR_ERROR}Installation fehlgeschlagen!${COLOR_RESET}";
                return 1;
            }
            sudo systemctl restart httpd
            sudo firewall-cmd --permanent --add-service=http
            sudo firewall-cmd --reload
            ;;
    esac

    # 3. PHP-Check (OHNE Dateianlage)
    log "${SYM_INFO} ${COLOR_ACTION}Prüfe PHP-Konfiguration...${COLOR_RESET}"
    php_check() {
        echo -e "${COLOR_HEADING}=== PHP-Status ===${COLOR_RESET}"
        echo -e "Version: ${COLOR_VALUE}$(php -r 'echo PHP_VERSION;')${COLOR_RESET}"
        
        declare -A modules=(
            ["mysqli"]="MySQL-Datenbank"
            ["gd"]="GD-Grafikbibliothek"
            ["curl"]="cURL"
            ["xml"]="XML-Unterstützung"
            ["mbstring"]="Multibyte-Strings"
        )
        
        for mod in "${!modules[@]}"; do
            if php -m | grep -q "^$mod$"; then
                echo -e "${SYM_OK} ${COLOR_OK}${modules[$mod]} (${mod})${COLOR_RESET}"
            else
                echo -e "${SYM_BAD} ${COLOR_ERROR}Fehlend: ${modules[$mod]} (${mod})${COLOR_RESET}"
            fi
        done
    }
    
    # Führe Check aus und protokolliere Ausgabe
    php_check | while IFS= read -r line; do log "$line"; done

    # 4. osWebinterface Deployment
    if [[ -d "oswebinterface" ]]; then
        log "${SYM_INFO} ${COLOR_ACTION}Kopiere osWebinterface...${COLOR_RESET}"
        sudo cp -r oswebinterface/* /var/www/html/
        sudo chown -R www-data:www-data /var/www/html 2>/dev/null || sudo chown -R apache:apache /var/www/html
        
        log "${SYM_OK} ${COLOR_OK}osWebinterface erfolgreich deployt${COLOR_RESET}"
    fi

    log "${COLOR_SUCCESS}Webserver-Setup abgeschlossen!${COLOR_RESET}"
    blankline
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Start Stop Standalone und einzelne Instanzen
#?──────────────────────────────────────────────────────────────────────────────────────────

function standalonestart() {
    cd opensim/bin || exit 1
    screen -fa -S opensim -d -U -m dotnet OpenSim.dll
    echo "OpenSim starten abgeschlossen."
    blankline
}

function standalonestop() {
    screen -S opensim -p 0 -X stuff "shutdown^M"
    echo "OpenSim stoppen abgeschlossen."
    blankline
}

function validate_sim_name() {
    local sim_name=$1
    # Überprüfe ob der Name dem Muster sim[1-99] entspricht (case-sensitive)
    if [[ ! "$sim_name" =~ ^sim([1-9]|[1-9][0-9])$ ]]; then
        log "${SYM_BAD} ${COLOR_WARNING}Ungültiger Sim-Name! Bitte verwende sim1 bis sim99.${COLOR_RESET}"
        return 1
    fi
    return 0
}

function simstart() {
    local simstart=$1
    if ! validate_sim_name "$simstart"; then
        exit 1
    fi
    
    log "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}$ $simstart ${COLOR_RESET}"
    sim_dir="$simstart/bin"
    cd "$sim_dir" || {
        log "${SYM_BAD} ${COLOR_WARNING}Verzeichnis $sim_dir nicht gefunden!${COLOR_RESET}"
        exit 1
    }
    screen -fa -S "$simstart" -d -U -m dotnet OpenSim.dll
    cd "$SCRIPT_DIR" || exit
    sleep $Simulator_Start_wait
    echo "OpenSim starten abgeschlossen."    
    blankline
}

function simstop() {
    local simstop=$1
    if ! validate_sim_name "$simstop"; then
        exit 1
    fi
    
    log "${SYM_OK} ${COLOR_STOP}Stoppe ${COLOR_SERVER} $simstop${COLOR_RESET}"
    screen -S "$simstop" -p 0 -X stuff "shutdown^M"
    sleep $Simulator_Stop_wait
    echo "OpenSim stoppen abgeschlossen."    
    blankline
}

function simrestart() {
    local simrestart=$1
    if ! validate_sim_name "$simrestart"; then
        exit 1
    fi
    
    simstop "$simrestart"
    simstart "$simrestart"
    echo
    echo "OpenSim Restart abgeschlossen."
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Start Stop Grid
#?──────────────────────────────────────────────────────────────────────────────────────────

#* OpenSim starten (robust → money → sim1 bis sim999)
function opensimstart() {
    log "${SYM_WAIT} ${COLOR_START}Starte das Grid!${COLOR_RESET}"
    
    # RobustServer starten
    if [[ -d "robust/bin" && -f "robust/bin/Robust.dll" ]]; then
        log "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}RobustServer ${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}robust/bin...${COLOR_RESET}"
        cd robust/bin || exit 1
        #  -inifile=Robust.HG.ini

        screen -fa -S robustserver -d -U -m dotnet Robust.dll
        cd - >/dev/null 2>&1 || exit 1
        sleep $RobustServer_Start_wait
    else
        log "${SYM_BAD} ${COLOR_SERVER}RobustServer: ${COLOR_BAD}Robust.dll nicht gefunden.${COLOR_RESET} ${COLOR_START}Überspringe Start.${COLOR_RESET}"
    fi

    # MoneyServer starten
    if [[ -f "robust/bin/MoneyServer.dll" ]]; then
        log "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}MoneyServer${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}robust/bin...${COLOR_RESET}"
        cd robust/bin || exit 1
        screen -fa -S moneyserver -d -U -m dotnet MoneyServer.dll
        cd - >/dev/null 2>&1 || exit 1
        sleep $MoneyServer_Start_wait
    else
        log "${SYM_BAD} ${COLOR_SERVER}MoneyServer: ${COLOR_BAD}MoneyServer.dll nicht gefunden.${COLOR_RESET} ${COLOR_START}Überspringe Start.${COLOR_RESET}"
    fi

    # Sim-Regionen starten    
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" && -f "$sim_dir/OpenSim.dll" ]]; then
            log "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}sim$i${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
            cd "$sim_dir" || continue
            screen -fa -S "sim$i" -d -U -m dotnet OpenSim.dll
            cd - >/dev/null 2>&1 || continue
            sleep $Simulator_Start_wait
        fi
    done
    echo "OpenSim starten abgeschlossen."
    blankline
}
# Test OpenSim starten Parallel
function opensimstartParallel() {
    log "${SYM_WAIT} ${COLOR_START}Starte das Grid!${COLOR_RESET}"
    
    # 1. RobustServer (muss zuerst laufen)
    if [[ -d "robust/bin" && -f "robust/bin/Robust.dll" ]]; then
        log "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}RobustServer ${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}robust/bin...${COLOR_RESET}"
        (cd robust/bin && screen -fa -S robustserver -d -U -m dotnet Robust.dll)
        sleep "$RobustServer_Start_wait"
    else
        log "${SYM_BAD} ${COLOR_SERVER}RobustServer: ${COLOR_BAD}Robust.dll nicht gefunden.${COLOR_RESET} ${COLOR_START}Überspringe Start.${COLOR_RESET}"
    fi

    # 2. MoneyServer (optional)
    if [[ -f "robust/bin/MoneyServer.dll" ]]; then
        log "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}MoneyServer${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}robust/bin...${COLOR_RESET}"
        (cd robust/bin && screen -fa -S moneyserver -d -U -m dotnet MoneyServer.dll)
        sleep "$MoneyServer_Start_wait"
    fi

    # 3. SIM1 ZUERST (sequentiell)
    if [[ -d "sim1/bin" && -f "sim1/bin/OpenSim.dll" ]]; then
        log "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}sim1${COLOR_RESET} ${COLOR_START}(primäre Region)...${COLOR_RESET}"
        (cd sim1/bin && screen -fa -S sim1 -d -U -m dotnet OpenSim.dll)
        sleep "$Simulator_Start_wait"
    else
        log "${SYM_BAD} ${COLOR_SERVER}sim1: ${COLOR_BAD}OpenSim.dll nicht gefunden.${COLOR_RESET}"
    fi

    # 4. SIM2-SIM99 PARALLEL
    log "${SYM_INFO} ${COLOR_START}Starte sekundäre Simulatoren parallel...${COLOR_RESET}"
    
    # Maximal 10 parallele Jobs
    MAX_JOBS=10
    for ((i=2; i<=99; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" && -f "$sim_dir/OpenSim.dll" ]]; then
            
            # Warten falls zu viele Jobs laufen
            while (( $(jobs -p | wc -l) >= MAX_JOBS )); do
                sleep 1
            done
            
            log "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}sim$i${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
            (cd "$sim_dir" && screen -fa -S "sim$i" -d -U -m dotnet OpenSim.dll) &
        fi
    done
    
    wait # Warte auf alle Hintergrundjobs
    log "${SYM_OK} ${COLOR_START}Alle Simulatoren gestartet.${COLOR_RESET}"
    blankline
}

#* OpenSim stoppen (sim999 bis sim1 → money → robust)
function opensimstop() {
    log "${SYM_WAIT} ${COLOR_STOP}Stoppe das Grid!${COLOR_RESET}"

    # Sim-Regionen stoppen
    for ((i=999; i>=1; i--)); do
        sim_dir="sim$i"
        if screen -list | grep -q "$sim_dir"; then
            screen -S "sim$i" -p 0 -X stuff "shutdown^M"
            log "${SYM_OK} ${COLOR_STOP}Stoppe ${COLOR_SERVER}sim$i${COLOR_RESET} ${COLOR_STOP}...${COLOR_RESET}"
            sleep $Simulator_Stop_wait
        fi
    done

    # MoneyServer stoppen
    if screen -list | grep -q "moneyserver"; then
        log "${SYM_OK} ${COLOR_STOP}Stoppe ${COLOR_SERVER}MoneyServer${COLOR_RESET} ${COLOR_STOP}...${COLOR_RESET}"
        screen -S moneyserver -p 0 -X stuff "shutdown^M"
        sleep $MoneyServer_Stop_wait
    else
        log "${SYM_BAD} ${COLOR_SERVER}MoneyServer: ${COLOR_BAD}Läuft nicht.${COLOR_RESET} ${COLOR_STOP}Überspringe Stopp.${COLOR_RESET}"
    fi

    # RobustServer stoppen
    if screen -list | grep -q "robust"; then
        log "${SYM_OK} ${COLOR_STOP}Stoppe ${COLOR_SERVER}RobustServer${COLOR_RESET} ${COLOR_STOP}...${COLOR_RESET}"
        screen -S robustserver -p 0 -X stuff "shutdown^M"
        sleep $RobustServer_Stop_wait
    else
        log "${SYM_BAD} ${COLOR_SERVER}RobustServer: ${COLOR_BAD}Läuft nicht.${COLOR_RESET} ${COLOR_STOP}Überspringe Stopp.${COLOR_RESET}"
    fi
     echo "OpenSim stoppen abgeschlossen."
    blankline
}

# Das parallele Stoppen in der Reihenfolge sim999 → sim2 parallel, dann sim1 → MoneyServer → RobustServer
function opensimstopParallel() {
    log "${SYM_WAIT} ${COLOR_STOP}Stoppe das Grid!${COLOR_RESET}"
    local MAX_PARALLEL=10  # Maximale parallele Stopp-Vorgänge

    # 1. Paralleles Stoppen von sim999 bis sim2
    log "${SYM_INFO} ${COLOR_STOP}Stoppe sekundäre Simulatoren parallel...${COLOR_RESET}"
    for ((i=999; i>=2; i--)); do
        sim_name="sim$i"
        
        # Warten falls zu viele parallele Jobs laufen
        #while [ $(jobs -p | wc -l) -ge $MAX_PARALLEL ]; do
        while [ "$(jobs -p | wc -l)" -ge $MAX_PARALLEL ]; do
            sleep 0.5
        done
        
        if screen -list | grep -q "$sim_name"; then
            log "${SYM_OK} ${COLOR_STOP}Stoppe ${COLOR_SERVER}$sim_name${COLOR_RESET}"
            (
                screen -S "$sim_name" -p 0 -X stuff "shutdown^M"
                sleep $Simulator_Stop_wait
            ) &
        fi
    done
    wait  # Warte auf alle parallelen Stopp-Vorgänge

    # 2. Sim1 sequentiell stoppen
    if screen -list | grep -q "sim1"; then
        log "${SYM_OK} ${COLOR_STOP}Stoppe ${COLOR_SERVER}sim1${COLOR_RESET} ${COLOR_STOP}(primäre Region)...${COLOR_RESET}"
        screen -S "sim1" -p 0 -X stuff "shutdown^M"
        sleep $Simulator_Stop_wait
    fi

    # 3. MoneyServer stoppen
    if screen -list | grep -q "moneyserver"; then
        log "${SYM_OK} ${COLOR_STOP}Stoppe ${COLOR_SERVER}MoneyServer${COLOR_RESET} ${COLOR_STOP}...${COLOR_RESET}"
        screen -S moneyserver -p 0 -X stuff "shutdown^M"
        sleep $MoneyServer_Stop_wait
    else
        log "${SYM_BAD} ${COLOR_SERVER}MoneyServer: ${COLOR_BAD}Läuft nicht.${COLOR_RESET}"
    fi

    # 4. RobustServer stoppen (zuletzt)
    if screen -list | grep -q "robustserver"; then
        log "${SYM_OK} ${COLOR_STOP}Stoppe ${COLOR_SERVER}RobustServer${COLOR_RESET} ${COLOR_STOP}...${COLOR_RESET}"
        screen -S robustserver -p 0 -X stuff "shutdown^M"
        sleep $RobustServer_Stop_wait
    else
        log "${SYM_BAD} ${COLOR_SERVER}RobustServer: ${COLOR_BAD}Läuft nicht.${COLOR_RESET}"
    fi

    log "${SYM_OK} ${COLOR_STOP}Alle Dienste gestoppt.${COLOR_RESET}"
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

opensim_clone() {
    # Stille Klon-Funktion mit automatischem Fallback
    local max_retries=3
    local retry_delay=2
    
    for ((i=1; i<=max_retries; i++)); do
        # 1. Versuch: HTTPS (standard)
        if git clone https://opensimulator.org/git/opensim opensim --quiet 2>/dev/null; then
            return 0
        fi
        
        # 2. Versuch: Git-Protokoll (falls HTTPS blockiert)
        if git clone git://opensimulator.org/git/opensim opensim --quiet 2>/dev/null; then
            return 0
        fi

        # Bei Fehler temporäres Verzeichnis bereinigen
        rm -rf opensim &>/dev/null
        sleep $retry_delay
    done
    
    return 1
}

function opensimgitcopy() {
    log "${SYM_SYNC}${COLOR_HEADING} OpenSimulator GitHub-Verwaltung${COLOR_RESET}"
    
    # Zuerst versuchen, ein einfaches git pull durchzuführen, falls Repository existiert
    if [[ -d "opensim/.git" ]]; then
        log "${SYM_WAIT} ${COLOR_ACTION}Versuche einfaches Update via git pull...${COLOR_RESET}"
        cd opensim || {
            log "${SYM_BAD} ${COLOR_ERROR}Verzeichniswechsel fehlgeschlagen!${COLOR_RESET}"
            return 1
        }
        
        old_head=$(git rev-parse HEAD)
        if git pull origin master; then
            if [ "$old_head" == "$(git rev-parse HEAD)" ]; then
                log "${SYM_OK} ${COLOR_ACTION}Keine neuen Updates verfügbar.${COLOR_RESET}"
            else
                log "${SYM_OK} ${COLOR_SUCCESS}Update erfolgreich durchgeführt!${COLOR_RESET}"
            fi
            cd ..
            
            # Nach erfolgreichem Update Kompatibilität prüfen
            check_dotnet_compatibility
            versionrevision
            log  # Leerzeile für bessere Lesbarkeit
            return 0
        else
            log "${SYM_BAD} ${COLOR_WARNING}Einfaches Update fehlgeschlagen, fahre mit Standardverfahren fort...${COLOR_RESET}"
            cd ..
        fi
    fi

    # Falls einfaches git pull nicht möglich ist, normale Abfrage durchführen
    log "${COLOR_LABEL}Möchten Sie den OpenSimulator vom GitHub verwenden oder aktualisieren? (${COLOR_OK}[upgrade]${COLOR_LABEL}/new)${COLOR_RESET}"
    read -r user_choice
    user_choice=${user_choice:-upgrade}

    if [[ "$user_choice" == "new" ]]; then
        if [[ -d "opensim" ]]; then
            log "${COLOR_ACTION}Vorhandene OpenSimulator-Version wird gelöscht...${COLOR_RESET}"
            rm -rf opensim
            log "${SYM_OK} ${COLOR_ACTION}Alte OpenSimulator-Version wurde erfolgreich entfernt.${COLOR_RESET}"
        fi

        log "${SYM_WAIT} ${COLOR_ACTION}OpenSimulator wird von GitHub geholt...${COLOR_RESET}"
        if opensim_clone; then
            log "${SYM_OK} ${COLOR_SUCCESS}Download erfolgreich!${COLOR_RESET}"
            log "${SYM_WAIT} ${COLOR_ACTION}Überprüfe Repository-Integrität...${COLOR_RESET}"
            
            if check_repo_integrity "opensim"; then
                log "${SYM_OK} ${COLOR_ACTION}Repository ist intakt.${COLOR_RESET}"
            else
                log "${SYM_BAD} ${COLOR_ERROR}Repository beschädigt!${COLOR_RESET}"
                return 1
            fi
        else
            log "${SYM_BAD} ${COLOR_ERROR}Download fehlgeschlagen!${COLOR_RESET}"
            log "${COLOR_WARNING}Bitte Netzwerkverbindung prüfen und später erneut versuchen.${COLOR_RESET}"
            return 1
        fi

    elif [[ "$user_choice" == "upgrade" ]]; then
        if [[ -d "opensim/.git" ]]; then
            # Erneuter Versuch (falls vorheriger pull fehlgeschlagen)
            cd opensim || return 1
            if git pull origin master; then
                log "${SYM_OK} ${COLOR_SUCCESS}Update erfolgreich durchgeführt!${COLOR_RESET}"
                cd ..
                
                # Nach erfolgreichem Update Kompatibilität prüfen
                check_dotnet_compatibility
                versionrevision
                log  # Leerzeile für bessere Lesbarkeit
                return 0
            else
                log "${SYM_BAD} ${COLOR_ERROR}Update fehlgeschlagen!${COLOR_RESET}"
                cd ..
                return 1
            fi
        else
            log "${COLOR_WARNING}⚠ ${COLOR_ACTION}Kein Repository gefunden. Starte Neuinstallation...${COLOR_RESET}"
            opensimgitcopy "new"
            return $?
        fi
    else
        log "${SYM_BAD} ${COLOR_ERROR}Ungültige Eingabe!${COLOR_RESET}"
        return 1
    fi

    # .NET-Kompatibilität prüfen
    check_dotnet_compatibility
    versionrevision

    blankline
}

check_dotnet_compatibility() {
    cd opensim || return 1
    local dotnet_version
    dotnet_version=$(dotnet --version 2>/dev/null | awk -F. '{print $1}')
    
    case $dotnet_version in
        6) 
            git checkout -q dotnet6
            log "${SYM_OK} ${COLOR_ACTION}Für .NET 6 konfiguriert.${COLOR_RESET}"
            ;;
        7|8)
            log "${SYM_OK} ${COLOR_ACTION}Kompatibel mit .NET $dotnet_version.${COLOR_RESET}"
            ;;
        *)
            log "${COLOR_WARNING}⚠ ${COLOR_ACTION}Keine .NET-Version erkannt. Verwende Standard.${COLOR_RESET}"
            ;;
    esac
    cd ..
}

function moneygitcopy() {
    log "${COLOR_HEADING}💰 MoneyServer GitHub-Verwaltung${COLOR_RESET}"
    
    log "${COLOR_LABEL}Möchten Sie den MoneyServer vom GitHub verwenden oder aktualisieren? (${COLOR_OK}[upgrade]${COLOR_LABEL}/new)${COLOR_RESET}"
    read -r user_choice
    user_choice=${user_choice:-upgrade}

    if [[ "$user_choice" == "new" ]]; then
        if [[ -d "opensimcurrencyserver" ]]; then
            log "${COLOR_ACTION}Vorhandene MoneyServer-Version wird gelöscht...${COLOR_RESET}"
            rm -rf opensimcurrencyserver
            log "${SYM_OK} ${COLOR_ACTION}Alte MoneyServer-Version wurde erfolgreich entfernt.${COLOR_RESET}"
        fi
        
        log "${COLOR_ACTION}MONEYSERVER: MoneyServer wird vom GIT geholt...${COLOR_RESET}"
        if ! git clone https://github.com/ManfredAabye/opensimcurrencyserver-dotnet.git opensimcurrencyserver; then
            log "${SYM_BAD} ${COLOR_ERROR}Fehler beim Klonen!${COLOR_RESET}"
            return 1
        fi
        
        if ! check_repo_integrity "opensimcurrencyserver"; then
            log "${SYM_BAD} ${COLOR_ERROR}MoneyServer-Repository beschädigt!${COLOR_RESET}"
            return 1
        fi
        
        log "${SYM_OK} ${COLOR_ACTION}MoneyServer wurde erfolgreich heruntergeladen.${COLOR_RESET}"
        
    elif [[ "$user_choice" == "upgrade" ]]; then
        if [[ -d "opensimcurrencyserver/.git" ]]; then
            log "${SYM_OK} ${COLOR_ACTION}Repository gefunden. Aktualisiere mit 'git pull'...${COLOR_RESET}"
            cd opensimcurrencyserver || { log "${SYM_BAD} ${COLOR_ERROR}Fehler: Kann nicht ins Verzeichnis wechseln!${COLOR_RESET}"; return 1; }
            
            # Branch-Erkennung mit Fehlerbehandlung
            branch_name=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
            if [ -z "$branch_name" ]; then
                branch_name="master"
                log "${COLOR_WARNING}Standard-Branch 'master' wird verwendet.${COLOR_RESET}"
            fi
            
            old_head=$(git rev-parse HEAD)
            
            if ! git pull origin "$branch_name"; then
                log "${SYM_BAD} ${COLOR_ERROR}Fehler beim Aktualisieren!${COLOR_RESET}"
                cd ..
                return 1
            fi
            
            if [ "$old_head" == "$(git rev-parse HEAD)" ]; then
                log "${COLOR_OK}${SYM_OKNN} ${COLOR_ACTION}MoneyServer ist bereits aktuell.${COLOR_RESET}"
            else
                log "${COLOR_OK}${SYM_OKNN} ${COLOR_ACTION}MoneyServer erfolgreich aktualisiert!${COLOR_RESET}"
            fi
            
            if ! check_repo_integrity; then
                log "${SYM_BAD} ${COLOR_ERROR}Repository beschädigt nach Pull!${COLOR_RESET}"
                cd ..
                return 1
            fi
            
            cd ..
        else
            log "${COLOR_WARNING}⚠ ${COLOR_ACTION}MoneyServer-Verzeichnis nicht gefunden. Klone Repository neu...${COLOR_RESET}"
            if ! git clone https://github.com/ManfredAabye/opensimcurrencyserver-dotnet.git opensimcurrencyserver; then
                log "${SYM_BAD} ${COLOR_ERROR}Fehler beim Klonen!${COLOR_RESET}"
                return 1
            fi
            log "${COLOR_OK}${SYM_OKNN} ${COLOR_ACTION}MoneyServer erfolgreich heruntergeladen!${COLOR_RESET}"
        fi
    else
        log "${SYM_BAD} ${COLOR_ERROR}Abbruch: Keine Aktion durchgeführt.${COLOR_RESET}"
        return 1
    fi

    # Verbesserte Dateikopierfunktion mit Prüfungen
    copy_with_checks() {
        local src=$1
        local dest=$2
        
        if [ ! -d "$src" ]; then
            log "${SYM_BAD} ${COLOR_ERROR}Quellverzeichnis $src nicht gefunden!${COLOR_RESET}"
            return 1
        fi
        
        mkdir -p "$dest"
        if ! cp -r "$src" "$dest"; then
            log "${SYM_BAD} ${COLOR_ERROR}Fehler beim Kopieren von $src!${COLOR_RESET}"
            return 1
        fi
        
        log "${SYM_OK} ${COLOR_ACTION}Erfolgreich kopiert: $src → $dest${COLOR_RESET}"
        return 0
    }

    # Kopiervorgänge mit Fehlerbehandlung
    copy_with_checks "opensimcurrencyserver/addon-modules" "opensim/" || return 1
    copy_with_checks "opensimcurrencyserver/bin" "opensim/" || return 1
    
    blankline
    return 0
}

function osslscriptsgit() {
    log "${COLOR_HEADING}📜 OSSL Beispiel-Skripte GitHub-Verwaltung${COLOR_RESET}"
    
    log "${COLOR_LABEL}Möchten Sie die OpenSim OSSL Beispiel-Skripte vom GitHub verwenden oder aktualisieren? (${COLOR_OK}[upgrade]${COLOR_LABEL}/new)${COLOR_RESET}"
    read -r user_choice
    user_choice=${user_choice:-upgrade}

    repo_name="opensim-ossl-example-scripts"
    repo_url="https://github.com/ManfredAabye/opensim-ossl-example-scripts.git"

    if [[ "$user_choice" == "new" ]]; then
        if [[ -d "$repo_name" ]]; then
            log "${COLOR_ACTION}Vorhandene Version wird gelöscht...${COLOR_RESET}"
            rm -rf "$repo_name"
            log "${SYM_OK} ${COLOR_ACTION}Alte Version wurde erfolgreich entfernt.${COLOR_RESET}"
        fi
        
        log "${COLOR_ACTION}Beispiel-Skripte werden vom GitHub heruntergeladen...${COLOR_RESET}"
        if ! git clone "$repo_url" "$repo_name"; then
            log "${SYM_BAD} ${COLOR_ERROR}Fehler beim Klonen!${COLOR_RESET}"
            return 1
        fi
        
        if ! check_repo_integrity "$repo_name"; then
            log "${SYM_BAD} ${COLOR_ERROR}Repository beschädigt!${COLOR_RESET}"
            return 1
        fi
        
        log "${SYM_OK} ${COLOR_ACTION}Repository wurde erfolgreich heruntergeladen.${COLOR_RESET}"
        
    elif [[ "$user_choice" == "upgrade" ]]; then
        if [[ -d "$repo_name/.git" ]]; then
            log "${SYM_OK} ${COLOR_ACTION}Repository gefunden. Aktualisiere mit 'git pull'...${COLOR_RESET}"
            cd "$repo_name" || { log "${SYM_BAD} ${COLOR_ERROR}Fehler beim Wechsel ins Verzeichnis!${COLOR_RESET}"; return 1; }
            
            branch_name=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
            [ -z "$branch_name" ] && branch_name="main"
            
            old_head=$(git rev-parse HEAD)
            
            if ! git pull origin "$branch_name"; then
                log "${SYM_BAD} ${COLOR_ERROR}Fehler beim Pull!${COLOR_RESET}"
                cd ..
                return 1
            fi
            
            if [ "$old_head" != "$(git rev-parse HEAD)" ]; then
                log "${COLOR_OK}${SYM_OKNN} ${COLOR_ACTION}Neue Updates wurden installiert.${COLOR_RESET}"
            else
                log "${COLOR_OK}${SYM_OKNN} ${COLOR_ACTION}Repository ist bereits aktuell.${COLOR_RESET}"
            fi
            
            if ! check_repo_integrity; then
                log "${SYM_BAD} ${COLOR_ERROR}Repository beschädigt nach Pull!${COLOR_RESET}"
                cd ..
                return 1
            fi
            
            cd ..
        else
            log "${COLOR_WARNING}⚠ ${COLOR_ACTION}Verzeichnis nicht gefunden oder kein Git-Repo. Klone Repository neu...${COLOR_RESET}"
            if ! git clone "$repo_url" "$repo_name"; then
                log "${SYM_BAD} ${COLOR_ERROR}Fehler beim Klonen!${COLOR_RESET}"
                return 1
            fi
            log "${COLOR_OK}${SYM_OKNN} ${COLOR_ACTION}Repository wurde erfolgreich heruntergeladen.${COLOR_RESET}"
        fi
    else
        log "${SYM_BAD} ${COLOR_ERROR}Abbruch: Keine Aktion durchgeführt.${COLOR_RESET}"
        return 1
    fi

    # Verbesserte Kopierfunktion
    safe_copy() {
        local src=$1
        local dest=$2
        
        if [ ! -e "$src" ]; then
            log "${SYM_BAD} ${COLOR_ERROR}Quelle '$src' existiert nicht!${COLOR_RESET}"
            return 1
        fi
        
        mkdir -p "$(dirname "$dest")"
        if ! cp -r "$src" "$dest"; then
            log "${SYM_BAD} ${COLOR_ERROR}Fehler beim Kopieren von '$src'!${COLOR_RESET}"
            return 1
        fi
        
        log "${SYM_OK} ${COLOR_ACTION}Erfolgreich kopiert: $src → $dest${COLOR_RESET}"
        return 0
    }

    # Zielverzeichnisse erstellen mit Fehlerbehandlung
    mkdir -p opensim/bin/assets/ || { log "${SYM_BAD} ${COLOR_ERROR}Konnte Verzeichnis nicht erstellen!${COLOR_RESET}"; return 1; }
    mkdir -p opensim/bin/inventory/ || { log "${SYM_BAD} ${COLOR_ERROR}Konnte Verzeichnis nicht erstellen!${COLOR_RESET}"; return 1; }

    # Kopiervorgänge mit Fehlerbehandlung
    safe_copy "$repo_name/ScriptsAssetSet" "opensim/bin/assets/" || return 1
    safe_copy "$repo_name/inventory/ScriptsLibrary" "opensim/bin/inventory/" || return 1
    
    blankline
    return 0
}

#######################################

#* Das ist erst halb fertig.
function ruthrothgit() {
    # Schritt 1 das bereitstellen der Pakete zur weiteren bearbeitung.
    log "${COLOR_HEADING}👥 Ruth & Roth Avatar-Assets Vorbereitung${COLOR_RESET}"

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
            log "  ${COLOR_ACTION}➜ Klone ${COLOR_SERVER}$avatar${COLOR_ACTION} von GitHub...${COLOR_RESET}"
            git clone "$repo_url" "$target_dir" && log "  ${COLOR_OK}${SYM_OKNN} ${COLOR_SERVER}$avatar${COLOR_RESET} ${COLOR_ACTION}wurde heruntergeladen.${COLOR_RESET}"
        else
            log "  ${COLOR_OK}${SYM_OKNN} ${COLOR_SERVER}$avatar${COLOR_RESET} ${COLOR_ACTION}ist bereits vorhanden, überspringe Download.${COLOR_RESET}"
        fi

        # Kopiere nur die relevanten IAR-Dateien direkt nach ruthroth
        log "  ${COLOR_ACTION}➜ Kopiere benötigte IAR-Dateien nach ${COLOR_DIR}$base_dir${COLOR_ACTION}...${COLOR_RESET}"
        cp "$target_dir/Artifacts/IAR/"*.iar "$base_dir/" 2>/dev/null && log "    ${SYM_OK} IAR-Dateien von ${COLOR_SERVER}$avatar${COLOR_RESET} kopiert.${COLOR_RESET}"
    done

    # Kopiere das updatelibrary.py-Skript ins Hauptverzeichnis ruthroth
    log "  ${COLOR_ACTION}➜ Kopiere updatelibrary.py nach ${COLOR_DIR}$base_dir${COLOR_ACTION}...${COLOR_RESET}"
    cp "updatelibrary.py" "$base_dir/" && log "    ${SYM_OK} updatelibrary.py wurde kopiert.${COLOR_RESET}"

    echo "Verzeichniswechsel in $base_dir"

    # Wechsel ins ruthroth-Verzeichnis
    cd "$base_dir" || { log "${SYM_BAD} Fehler beim Wechsel ins Verzeichnis ${COLOR_DIR}$base_dir${COLOR_RESET}"; return 1; }

    # Entpacke die IAR-Dateien direkt in ruthroth
    log "  ${COLOR_ACTION}➜ Entpacke IAR-Pakete in ${COLOR_DIR}$base_dir${COLOR_ACTION}...${COLOR_RESET}"
    for iar_file in *.iar; do
        if [[ -f "$iar_file" ]]; then
            target_dir="${iar_file%.iar}"  # Erstellt Verzeichnisname basierend auf Dateiname ohne .iar
            mkdir -p "$target_dir"
            tar -xzf "$iar_file" -C "$target_dir/" && log "    ✓ ${iar_file} entpackt nach ${target_dir}"
        else
            log "    ⚠ IAR-Datei ${iar_file} nicht gefunden. Überspringe..."
        fi
    done

    log "${COLOR_OK}${SYM_OKNN} ${COLOR_ACTION}Grundlage für die OpenSimulator-Pakete wurde erfolgreich erstellt!${COLOR_RESET}"

    # Schritt 2 die verwendung von updatelibrary.py.
    cd ruthroth
    python3 updatelibrary.py -n "Roth2-v1" -s "Roth2-v1" -a Roth2-v1 -i Roth2-v1
    python3 updatelibrary.py -n "Roth2-v2" -s "Roth2-v2" -a Roth2-v2 -i Roth2-v2
    python3 updatelibrary.py -n "Ruth2-v3" -s "Ruth2-v3" -a Ruth2-v3 -i Ruth2-v3
    python3 updatelibrary.py -n "Ruth2-v4" -s "Ruth2-v4" -a Ruth2-v4 -i Ruth2-v4
    cd ..
    # Schritt 3 das kopieren der Daten. Das einfügen der Daten in den Dateien ähnlich wie bei PBR.
}

# Es werden die Konfiguartionen jetzt auch geändert.
function pbrtexturesgit() {
    log "${COLOR_HEADING}🎨 PBR Texturen Installation${COLOR_RESET}"
    
    textures_zip_url="https://github.com/ManfredAabye/OpenSim_PBR_Textures/releases/download/PBR/OpenSim_PBR_Textures.zip"
    zip_file="OpenSim_PBR_Textures.zip"
    unpacked_dir="OpenSim_PBR_Textures"
    target_dir="opensim"

    # ZIP herunterladen, wenn nicht vorhanden
    if [[ ! -f "$zip_file" ]]; then
        log "${COLOR_ACTION}Lade OpenSim PBR Texturen herunter...${COLOR_RESET}"
        if ! wget -q --show-progress -O "$zip_file" "$textures_zip_url"; then
            log "${SYM_BAD} ${COLOR_ERROR}Fehler beim Herunterladen der Texturen!${COLOR_RESET}"
            return 1
        fi
        log "${SYM_OK} ${COLOR_ACTION}Download abgeschlossen: ${COLOR_DIR}$zip_file${COLOR_RESET}"
    else
        log "${SYM_OK} ${COLOR_ACTION}ZIP-Datei bereits vorhanden: ${COLOR_DIR}$zip_file${COLOR_RESET}"
    fi

    # Entpacken, wenn Verzeichnis noch nicht existiert
    if [[ ! -d "$unpacked_dir" ]]; then
        log "${COLOR_ACTION}Entpacke Texturen nach ${COLOR_DIR}$unpacked_dir${COLOR_ACTION}...${COLOR_RESET}"
        unzip -q "$zip_file" -d .
        log "${SYM_OK} ${COLOR_ACTION}Entpackt.${COLOR_RESET}"
    else
        log "${SYM_OK} ${COLOR_ACTION}Verzeichnis ${COLOR_DIR}$unpacked_dir${COLOR_ACTION} existiert bereits – überspringe Entpacken.${COLOR_RESET}"
    fi

    # Kopieren nach opensim/bin
    if [[ -d "$unpacked_dir/bin" ]]; then
        log "${COLOR_ACTION}Kopiere Texturen nach ${COLOR_DIR}$target_dir${COLOR_ACTION}...${COLOR_RESET}"
        cp -r "$unpacked_dir/bin" "$target_dir"
        log "${SYM_OK} ${COLOR_ACTION}Texturen erfolgreich installiert in ${COLOR_DIR}$target_dir${COLOR_RESET}"
    else
        log "${SYM_BAD} ${COLOR_ERROR}Verzeichnis ${COLOR_DIR}$unpacked_dir/bin${COLOR_ERROR} nicht gefunden!${COLOR_RESET}"
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

function osWebinterfacegit() {
    log "${COLOR_HEADING}🌐 Webinterface Installation${COLOR_RESET}"

    webverzeichnis="oswebinterface"

    # Abfrage zur Installation mit Default "Nein"
    log "${COLOR_LABEL}Möchten Sie das OpenSim Webinterface installieren? ()j/N) ${COLOR_RESET} [n]"
    read -r install_webinterface
    if [[ ! "$install_webinterface" =~ ^[jJ][aA]?$ ]]; then
        log "${COLOR_INFO}Installation abgebrochen (Default: Nein)${COLOR_RESET}"
        blankline
        return 0
    fi

    setup_webserver
    
    # 1. PHP-Check mit Distro-Erkennung
    if ! command -v php &>/dev/null; then
        log "${SYM_WARNING} ${COLOR_WARNING}PHP ist nicht installiert!${COLOR_RESET}"
        
        # Distro-Erkennung
        # shellcheck source=/dev/null
        source /etc/os-release
        case $ID in
            debian|ubuntu|linuxmint|pop|mx|zorin|elementary)
                pkg_cmd="sudo apt-get install -y php php-mysql php-gd php-curl"
                ;;
            arch|manjaro)
                pkg_cmd="sudo pacman -S --noconfirm php php-gd php-curl"
                ;;
            fedora|centos|rhel)
                pkg_cmd="sudo dnf install -y php php-mysqlnd php-gd php-common"
                ;;
            opensuse|sles)
                pkg_cmd="sudo zypper install -y php7 php7-mysql php7-gd php7-curl"
                ;;
            *)
                log "${SYM_BAD} ${COLOR_ERROR}Unterstützte Distribution nicht erkannt!${COLOR_RESET}"
                echo "Manuell installieren: php php-mysql php-gd php-curl"
                return 1
                ;;
        esac

        log "PHP auf ${PRETTY_NAME} installieren? (j/n) " 
        read -r install_php
        if [[ "$install_php" =~ ^[jJ] ]]; then
            log "${COLOR_ACTION}Installiere PHP... (${pkg_cmd})${COLOR_RESET}"
            if ! eval "$pkg_cmd"; then
                log "${SYM_BAD} ${COLOR_ERROR}PHP-Installation fehlgeschlagen!${COLOR_RESET}"
                return 1
            fi
            log "${COLOR_OK}${SYM_OKNN} PHP erfolgreich installiert!${COLOR_RESET}"
        else
            log "${SYM_BAD} ${COLOR_ERROR}Abbruch: PHP ist erforderlich.${COLOR_RESET}"
            return 1
        fi
    else
        log "${COLOR_OK}${SYM_OKNN} PHP ist installiert ($(php -v | head -n 1))${COLOR_RESET}"
    fi

    # 2. Webverzeichnis-Check mit automatischer User/Group-Erkennung
    local webroot="/var/www/html"
    [[ -d "/var/www" && ! -d "$webroot" ]] && webroot="/var/www"  # Fallback für einige Distros
    
    if [[ ! -d "$webroot" ]]; then
        log "${SYM_BAD} ${COLOR_ERROR}Webroot nicht gefunden in:${COLOR_RESET}"
        echo "/var/www/html oder /var/www"
        echo "Tipp: Apache/Nginx zuerst installieren"
        return 1
    fi

    # Bestimme den richtigen Benutzer und Gruppe basierend auf existierenden Dateien
    local target_user target_group
    # Suche nach einer existierenden Datei oder Verzeichnis im Webroot
    sample_file=$(find "$webroot" -maxdepth 1 -type f -print -quit 2>/dev/null || true)
    sample_dir=$(find "$webroot" -maxdepth 1 -type d ! -path "$webroot" -print -quit 2>/dev/null || true)
    
    if [ -n "$sample_file" ]; then
        target_user=$(stat -c '%U' "$sample_file")
        target_group=$(stat -c '%G' "$sample_file")
    elif [ -n "$sample_dir" ]; then
        target_user=$(stat -c '%U' "$sample_dir")
        target_group=$(stat -c '%G' "$sample_dir")
    else
        # Fallback: Standard-Webserver-User je nach Distribution
        # shellcheck source=/dev/null
        source /etc/os-release
        case $ID in
            debian|ubuntu|linuxmint|pop|mx|zorin|elementary)
                target_user="www-data"
                target_group="www-data"
                ;;
            arch|manjaro)
                target_user="http"
                target_group="http"
                ;;
            fedora|centos|rhel)
                target_user="apache"
                target_group="apache"
                ;;
            opensuse|sles)
                target_user="wwwrun"
                target_group="www"
                ;;
            *)
                target_user="www-data"
                target_group="www-data"
                ;;
        esac
    fi

    # 3. Git-Operationen
    if [[ ! -d "oswebinterface" ]]; then
        git clone https://github.com/ManfredAabye/oswebinterface.git oswebinterface || return 1
    else
        cd oswebinterface || return 1
        git pull origin "$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')" || return 1
        cd ..
    fi

    # 4. Deployment mit korrekten Berechtigungen
    log "${COLOR_ACTION}Kopiere Webinterface nach ${webroot}/${webverzeichnis}...${COLOR_RESET}"
    if ! sudo cp -r "oswebinterface" "$webroot/$webverzeichnis"; then
        log "${SYM_BAD} ${COLOR_ERROR}Kopieren fehlgeschlagen!${COLOR_RESET}"
        return 1
    fi

    log "${COLOR_ACTION}Setze Besitzer auf ${target_user}:${target_group}...${COLOR_RESET}"
    if ! sudo chown -R "$target_user:$target_group" "$webroot/$webverzeichnis"; then
        log "${SYM_BAD} ${COLOR_ERROR}Besitzer ändern fehlgeschlagen!${COLOR_RESET}"
        return 1
    fi

    log "${COLOR_ACTION}Setze Dateiberechtigungen...${COLOR_RESET}"
    if ! sudo find "$webroot/$webverzeichnis" -type d -exec chmod 755 {} \; || \
       ! sudo find "$webroot/$webverzeichnis" -type f -exec chmod 644 {} \; ; then
        log "${SYM_BAD} ${COLOR_ERROR}Berechtigungen setzen fehlgeschlagen!${COLOR_RESET}"
        return 1
    fi

    log "${COLOR_OK}${SYM_OKNN} Erfolgreich installiert nach: ${COLOR_DIR}$webroot/$webverzeichnis${COLOR_RESET}"
    log "   Benutzer/Gruppe: ${COLOR_INFO}$target_user:$target_group${COLOR_RESET}"
    blankline
    return 0
}

function versionrevision() {
    file="opensim/OpenSim/Framework/VersionInfo.cs"

    #xflavour="Unknown"
    #xflavour="Dev"
    #xflavour="RC1"
    #xflavour="RC2"
    #xflavour="RC3"
    #xflavour="Release"
    #xflavour="Post_Fixes"
    xflavour="Extended"

    if [[ ! -f "$file" ]]; then
        log "${SYM_BAD} ${COLOR_ERROR}Datei nicht gefunden: ${COLOR_DIR}$file${COLOR_RESET}"
        return 1
    fi

    log "${SYM_OK} ${COLOR_ACTION}Bearbeite Datei: ${COLOR_DIR}$file${COLOR_RESET}"

    # Ändere Flavour.Dev
    sed -i 's/public const Flavour VERSION_FLAVOUR = Flavour\.[^;]*;/public const Flavour VERSION_FLAVOUR = Flavour.'"$xflavour"';/' "$file"

    # Entferne "Nessie" aus dem Versions-String
    sed -i 's/OpenSim {versionNumber} Nessie {flavour}/OpenSim {versionNumber} {flavour}/' "$file"

    log "${SYM_OK} ${COLOR_ACTION}Änderungen zu $xflavour wurden erfolgreich vorgenommen.${COLOR_RESET}"
    blankline
    return 0
}

function generate_name() {
    # Arrays mit Namensbestandteilen (alle einzigartig)

    local firstnames=(
        # Vornamen
        "Mystic" "Arcane" "Eldritch" "Enigmatic" "Esoteric" "Occult" "Cryptic" "Celestial" "Astral" "Ethereal" 
        "Luminous" "Radiant" "Prismatic" "Iridescent" "Phantasmal" "Spectral" "Otherworldly" "Transcendent" "Timeless" "Unearthly"
        "Enchanted" "Charmed" "Bewitched" "Mythic" "Legendary"
        "Verdant" "Sylvan" "Petrified" "Thundering" "Whispering" "Howling" "Roaring" "Rumbling" "Crystalline" "Obsidian"
        "Amber" "Jade" "Sapphire" "Emerald" "Ruby" "Topaz" "Opaline" "Pearlescent" "Gilded" "Argent"
        "Solar" "Lunar" "Stellar" "Nebular" "Galactic"
        "Aether" "Runeweaver" "Dragonheart" "Moonshadow" "Spellbinder" "Witchbloom" "Grimoire" "Shadowalker" "Starborn" "Voidwhisper"
        "Dreamwalker" "Fatesender" "Glyphborn" "Hollowveil" "Ivyroot" "Jadewhisper" "Kindlespark" "Lorekeeper" "Netherflame" "Oathbound"
        "Pixieglen" "Quicksilver" "Ravenoak" "Silvershade" "Twilightthorn"
        "Aerendyl" "Beltharion" "Celeborn" "Diorath" "Elrondar" "Faelivrin" "Galadhor" "Haldirion" "Ithilwen" "Jarathmel"
        "Kelebrind" "Lothmiriel" "Melianthar" "Nimlothiel" "Oropherion" "Pelenor" "Quelamar" "Rivendell" "Silmarion" "Thranduvar"
        "Ulmoen" "Vanyarion" "Windathar" "Xylanthir" "Yavanniel"
        "Andromeda" "Beowulf" "Cybernova" "Deusex" "Eclipse" "Frostbyte" "Gigawatt" "Hyperion" "Io" "Jupiter"
        "Krypton" "Lunarc" "Megatron" "Nebula" "Orion" "Pulsar" "Quantum" "Robodoc" "Starbuck" "Titan"
        "Uranus" "Vortex" "Warpcore" "Xenon" "Zenith"
    )
    
    local lastnames=(
        # Nachnamen
        "Forest" "Grove" "Copse" "Thicket" "Wildwood" "Jungle" "Rainforest" "Mangrove" "Taiga" "Tundra"
        "Mountain" "Peak" "Summit" "Cliff" "Crag" "Bluff" "Mesa" "Plateau" "Canyon" "Ravine"
        "Valley" "Dale" "Glen" "Hollow" "Basin"
        "River" "Stream" "Brook" "Creek" "Fjord" "Lagoon" "Estuary" "Delta" "Bayou" "Wetland"
        "Oasis" "Geyser" "Spring" "Well" "Aquifer"
        "Observatory" "Planetarium" "Orrery" "Reflectory" "Conservatory" "Atrium" "Rotunda" "Gazebo" "Pavilion" "Terrace"
        "Ashenwood" "Bramblethorn" "Cliffhaven" "Dewspark" "Emberglade" "Frostvein" "Goldleaf" "Hailstone" "Ironbark" "Jasperridge"
        "Kelpstrand" "Lavafall" "Mossgrip" "Nettlebrook" "Oakenshield" "Pinecrest" "Quartzpeak" "Rimefrost" "Stormbreak" "Tidepool"
        "Umbravale" "Vinecreep" "Willowshade" "Xylem" "Yewroot"
        "Aranel" "Beleriand" "Cirdan" "Doriath" "Eregion" "Fangorn" "Gondolin" "Hithlum" "Imladris" "Jarngard"
        "Kementari" "Lorien" "Mirkwood" "Nargothrond" "Osgiliath" "Pelargir" "Quendi" "Rhosgobel" "Sindar" "Tirion"
        "Undomiel" "Valinor" "Westfold" "Xandoria" "Yavanna"
        "Axiom" "Borg" "Coruscant" "Dyson" "Expanse" "Federation" "Genesis" "Horizon" "Infinity" "Jovian"
        "Kessel" "Lazarus" "Matrix" "Nostromo" "Outland" "Prometheus" "Quadrant" "Rapture" "Serenity" "Trifid"
        "Umbra" "Voyager" "Weyland" "Xenomorph" "Zodiac"
    )

    gennamefirst="${firstnames[$RANDOM % ${#firstnames[@]}]}" # übergebe das an generate_all_name()
    gennamesecond="${lastnames[$RANDOM % ${#lastnames[@]}]}" # übergebe das an generate_all_name()

}
function generate_all_name() {
    # Alle Namen und Bezeichnungen für die Installation erstellen das dient dazu das die Namen im gesamten Programm verwendet werden können.
    # Benutzername Vorname Nachname
    generate_name
    genFirstname="${gennamefirst}"
    generate_name
    genLastname="${gennamesecond}"
    echo "$gennamefirst"
    echo "$gennamesecond"

    generate_name
    # database_setup
    genDatabaseUserName="${gennamefirst}${gennamesecond}$((RANDOM % 900 + 100))"
    echo "$genDatabaseUserName"

    # generate_name
    # # Neue Region
    # genRegionName="${gennamefirst}${gennamesecond}$((RANDOM % 900 + 100))"
    # echo "$genRegionName"

    generate_name
    genGridName="${gennamesecond}Grid"
    echo "$genGridName"
    
    # Test Ausgabe der Variablen
    #echo "genFirstname='${genFirstname}'"
    #echo "genLastname='${genLastname}'"
    #echo "genDatabaseUserName='${genDatabaseUserName}'"
    #echo "genRegionName='${genRegionName}'"
    #echo "genGridName='${genGridName}'"
    #echo "${names[$RANDOM % ${#names[@]}]}"
}

function opensimbuild() {
    log "${COLOR_HEADING}🏗️  OpenSimulator Build-Prozess${COLOR_RESET}"
    
    log "${COLOR_LABEL}Möchten Sie den OpenSimulator jetzt erstellen? (${COLOR_OK}[ja]${COLOR_LABEL}/nein)${COLOR_RESET}"
    read -r user_choice

    user_choice=${user_choice:-ja}

    if [[ "$user_choice" == "ja" ]]; then
        if [[ -d "opensim" ]]; then
            cd opensim || { log "${SYM_BAD} ${COLOR_ERROR}Fehler: Verzeichnis 'opensim' nicht gefunden.${COLOR_RESET}"; return 1; }
            log "${COLOR_ACTION}Starte Prebuild-Skript...${COLOR_RESET}"
            bash runprebuild.sh
            log "${COLOR_ACTION}Baue OpenSimulator...${COLOR_RESET}"
            dotnet build --configuration Release OpenSim.sln
            log "${SYM_OK} ${COLOR_ACTION}OpenSimulator wurde erfolgreich erstellt.${COLOR_RESET}"
        else
            log "${SYM_BAD} ${COLOR_ERROR}OpenSim Build Fehler: Das Verzeichnis 'opensim' existiert nicht.${COLOR_RESET}"
            return 1
        fi
    else
        log "${SYM_BAD} ${COLOR_ERROR}Abbruch: OpenSimulator wird nicht erstellt.${COLOR_RESET}"
    fi
    # Wer in ein Verzeichnis wechselt sollte auch wieder zur vorherigen Verzeichnis wechseln!
    cd ..
    blankline
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Erstellen eines OpenSimulators Grids
#?──────────────────────────────────────────────────────────────────────────────────────────

function removeconfigfiles() {
    local ini_file="${SCRIPT_DIR}/UserInfo.ini"
    # Erstelle Backup wenn Datei existiert
    if [[ -f "$ini_file" ]]; then
        #echo "$(date +'%d.%m.%Y')_$(date +'%H:%M:%S')"
        backup_file="${ini_file}.$(date +'%d.%m.%Y')_$(date +'%H:%M:%S').bak"
        sudo mv -f "$ini_file" "$backup_file"
    fi
}  

function createdirectory() {
    log "${COLOR_HEADING}📂 Verzeichniserstellung${COLOR_RESET}"
    
    log "${COLOR_LABEL}Möchten Sie einen Gridserver oder einen Regionsserver erstellen? (${COLOR_OK}[grid]${COLOR_LABEL}/region)${COLOR_RESET}"
    read -r server_type

    # Standardmäßig Gridserver wählen, falls keine Eingabe erfolgt
    server_type=${server_type:-grid}

    if [[ "$server_type" == "grid" ]]; then
        log "${COLOR_ACTION}Erstelle robust Verzeichnis...${COLOR_RESET}"
        mkdir -p robust/bin
        log "${SYM_OK} ${COLOR_ACTION}Robust Verzeichnis wurde erstellt.${COLOR_RESET}"

        # Nach der Erstellung des Gridservers auch die Regionsserver erstellen lassen
        log "${COLOR_LABEL}Wie viele Regionsserver benötigen Sie? ${COLOR_OK}[1]${COLOR_RESET}"
        read -r num_regions
        # Standardmäßig 1 Region wählen, falls keine Eingabe erfolgt
        num_regions=${num_regions:-1}
        log "${SYM_OK} ${COLOR_ACTION}Sie haben $num_regions Regionsserver gew‰hlt.${COLOR_RESET}"

    elif [[ "$server_type" == "region" ]]; then
        log "${COLOR_LABEL}Wie viele Regionsserver benötigen Sie? ${COLOR_OK}[1]${COLOR_RESET}"
        read -r num_regions
        log "${SYM_OK} ${COLOR_ACTION}Sie haben $num_regions Regionsserver gew‰hlt.${COLOR_RESET}"
    else
        log "${SYM_BAD} ${COLOR_ERROR}Ungültige Eingabe. Bitte geben Sie 'grid' oder 'region' ein.${COLOR_RESET}"
        return 1
    fi

    # Überprüfen, ob die Anzahl der Regionsserver bis 999 geht
    if [[ "$num_regions" =~ ^[0-9]+$ && "$num_regions" -le 999 ]]; then
        for ((i=1; i<=num_regions; i++)); do
            dir_name="sim$i"
            if [[ ! -d "$dir_name" ]]; then
                mkdir -p "$dir_name/bin"
                log "${SYM_OK} ${COLOR_DIR}$dir_name${COLOR_RESET} ${COLOR_ACTION}wurde erstellt.${COLOR_RESET}"
                sleep 1
            else
                log "${SYM_OK} ${COLOR_DIR}$dir_name${COLOR_RESET} ${COLOR_WARNING}existiert bereits und wird übersprungen.${COLOR_RESET}"
            fi
        done
    else
        log "${SYM_BAD} ${COLOR_ERROR}Ungültige Anzahl an Regionsserver. Bitte geben Sie eine gültige Zahl zwischen 1 und 999 ein.${COLOR_RESET}"
    fi
    blankline
}

function opensimcopy() {
    log "${COLOR_HEADING}${SYM_PACKAGE} OpenSim Dateikopie${COLOR_RESET}"
    
    # Prüfen, ob das Verzeichnis "opensim" existiert
    if [[ ! -d "opensim" ]]; then
        log "${SYM_BAD} ${COLOR_ERROR}OpenSim Copy Fehler: Das Verzeichnis 'opensim' existiert nicht.${COLOR_RESET}"
        return 1
    fi

    # Prüfen, ob das Unterverzeichnis "opensim/bin" existiert
    if [[ ! -d "opensim/bin" ]]; then
        log "${SYM_BAD} ${COLOR_ERROR}OpenSim Copy Fehler: Das Verzeichnis 'opensim/bin' existiert nicht.${COLOR_RESET}"
        return 1
    fi

    # Prüfen, ob das Verzeichnis "robust" existiert und Dateien kopieren
    if [[ -d "robust/bin" ]]; then
        cp -r opensim/bin/* robust/bin
        log "${SYM_OK} ${COLOR_ACTION}Dateien aus ${COLOR_DIR}opensim/bin${COLOR_RESET} ${COLOR_ACTION}wurden nach ${COLOR_DIR}robust/bin${COLOR_RESET} ${COLOR_ACTION}kopiert.${COLOR_RESET}"
    else
        log "${COLOR_WARNING}⚠ ${COLOR_ACTION}Hinweis: 'robust' Verzeichnis nicht gefunden, keine Kopie durchgeführt.${COLOR_RESET}"
    fi

    # Alle simX-Verzeichnisse suchen und Dateien kopieren
    for sim_dir in sim*; do
        if [[ -d "$sim_dir/bin" ]]; then
            cp -r opensim/bin/* "$sim_dir/bin/"
            log "${SYM_OK} ${COLOR_ACTION}Dateien aus ${COLOR_DIR}opensim/bin${COLOR_RESET} ${COLOR_ACTION}wurden nach ${COLOR_DIR}$sim_dir/bin${COLOR_RESET} ${COLOR_ACTION}kopiert.${COLOR_RESET}"
        fi
    done

    blankline
}

function database_setup() {
    # 06.05.2025
    log "${COLOR_SECTION}=== MariaDB/MySQL Datenbank-Setup ===${COLOR_RESET}"
    
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
    #supported_distros=("debian" "ubuntu" "linuxmint" "pop" "mx" "kali" "zorin" "elementary" "raspbian" "centos" "fedora")
    supported_distros=("debian" "ubuntu" "linuxmint" "pop" "mx" "kali" "zorin" "elementary" "raspbian" "centos" "fedora" "arch" "manjaro")

    # 2. Support-Check
    if ! printf '%s\n' "${supported_distros[@]}" | grep -q "^${current_distro}$"; then
        log "${SYM_BAD} ${COLOR_BAD}Nicht unterstützte Distribution: '${current_distro}'${COLOR_RESET}"
        log "${SYM_INFO} Unterstützt: ${supported_distros[*]}"
        return 1
    fi

    # 3. Installation Check (angepasste Version)
    if ! command -v mariadb &> /dev/null && ! command -v mysql &> /dev/null; then
        log "${SYM_WAIT} ${COLOR_WARNING}MariaDB/MySQL ist nicht installiert${COLOR_RESET}"
        echo -ne "${COLOR_ACTION}MariaDB installieren? (j/n) [j] ${COLOR_RESET}"
        read -r install_choice
        install_choice=${install_choice:-j}
        
        if [[ "$install_choice" =~ ^[jJ] ]]; then
            case $current_distro in
                debian|ubuntu|*mint|pop|zorin|elementary|kali|mx|raspbian)
                    log "${SYM_INFO} ${COLOR_ACTION}Installiere MariaDB (apt)...${COLOR_RESET}"
                    sudo apt-get update && sudo apt-get install -y mariadb-server
                    ;;
                centos|fedora)
                    log "${SYM_INFO} ${COLOR_ACTION}Installiere MariaDB (yum)...${COLOR_RESET}"
                    sudo yum install -y mariadb-server
                    sudo systemctl start mariadb
                    sudo systemctl enable mariadb
                    ;;
                arch|manjaro)
                    log "${SYM_INFO} ${COLOR_ACTION}Installiere MariaDB (pacman)...${COLOR_RESET}"
                    sudo pacman -Sy --noconfirm mariadb
                    sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
                    sudo systemctl enable --now mariadb
                    ;;
                *) 
                    log "${SYM_BAD} ${COLOR_BAD}Automatische Installation nicht verfügbar${COLOR_RESET}"
                    return 1
                    ;;
            esac
            
            # Sicherheitskonfiguration für alle Distros
            log "${SYM_INFO} ${COLOR_ACTION}Führe mysql_secure_installation aus...${COLOR_RESET}"
            sudo mysql_secure_installation
        else
            log "${SYM_BAD} Installation abgebrochen"
            return 0
        fi
    else
        log "${SYM_OK} ${COLOR_OK}MariaDB/MySQL ist bereits installiert${COLOR_RESET}"
    fi

    # 4. Benutzeranmeldedaten
    log "\n${COLOR_SECTION}=== Datenbank-Zugangsdaten ===${COLOR_RESET}"
    echo -ne "${COLOR_ACTION}Zufallszugangsdaten verwenden? (j/n) [j] ${COLOR_RESET}"
    read -r default_cred_choice
    default_cred_choice=${default_cred_choice:-j}
    
    if [[ "$default_cred_choice" =~ ^[jJ] ]]; then
        db_user="${genDatabaseUserName}"
        db_pass=$(tr -dc 'A-Za-z0-9!@#$%^&*()' < /dev/urandom | head -c 16)
        log "${SYM_INFO} ${COLOR_LABEL}Generiertes Passwort: ${COLOR_VALUE}${db_pass}${COLOR_RESET}"
    else
        echo -ne "${COLOR_ACTION}DB_Benutzername: ${COLOR_RESET}"
        read -r db_user
        echo -ne "${COLOR_ACTION}DB_Passwort: ${COLOR_RESET}"
        read -rs db_pass
        echo
    fi

    # **Speicherung der Datenbank-Zugangsdaten in UserInfo.ini**
    local ini_file="${SCRIPT_DIR}/UserInfo.ini"

    if [[ ! -f "$ini_file" ]]; then
        log "${COLOR_INFO}Erstelle UserInfo.ini${COLOR_RESET}"
        sudo touch "$ini_file"
    fi

    log "\n[DatabaseData]" | sudo tee -a "$ini_file" >/dev/null
    echo "DB_Benutzername = ${db_user}" | sudo tee -a "$ini_file" >/dev/null
    echo "DB_Passwort = ${db_pass}" | sudo tee -a "$ini_file" >/dev/null


    log "${SYM_LOG} ${COLOR_LABEL}Datenbank-Zugangsdaten gespeichert in: ${COLOR_FILE}${ini_file}${COLOR_RESET}"

    # 6. Datenbankeinrichtung
    log "\n${COLOR_SECTION}=== Datenbank-Konfiguration ===${COLOR_RESET}"
    
    # RobustServer DB
    if [[ -d "robust" ]]; then
        if ! sudo mysql -e "USE robust" &> /dev/null; then
            sudo mysql -e "CREATE DATABASE robust CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
            log "${SYM_OK} ${COLOR_VALUE}robust${COLOR_RESET} Datenbank angelegt"
        else
            log "${SYM_INFO} ${COLOR_WARNING}robust-Datenbank existiert bereits${COLOR_RESET}"
        fi
    fi

    # simX Server DBs
    for ((i=1; i<=1000; i++)); do
        if [[ -d "sim${i}" ]]; then
            db_name="sim${i}"
            if ! sudo mysql -e "USE ${db_name}" &> /dev/null; then
                sudo mysql -e "CREATE DATABASE ${db_name} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
                log "${SYM_OK} ${COLOR_VALUE}${db_name}${COLOR_RESET} Datenbank angelegt"
            else
                log "${SYM_INFO} ${COLOR_WARNING}${db_name}-Datenbank existiert bereits${COLOR_RESET}"
            fi
        fi
    done

    # Benutzerverwaltung
    if ! sudo mysql -e "SELECT user FROM mysql.user WHERE user='${db_user}' AND host='localhost'" | grep -q "${db_user}"; then
        sudo mysql -e "CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}'"
        log "${SYM_OK} ${COLOR_VALUE}${db_user}${COLOR_RESET} Benutzer angelegt"
    else
        log "${SYM_INFO} ${COLOR_WARNING}Benutzer ${db_user} existiert bereits${COLOR_RESET}"
    fi

    # Rechte vergeben
    [[ -d "robust" ]] && sudo mysql -e "GRANT ALL PRIVILEGES ON robust.* TO '${db_user}'@'localhost'"
    for ((i=1; i<=1000; i++)); do
        [[ -d "sim${i}" ]] && sudo mysql -e "GRANT ALL PRIVILEGES ON sim${i}.* TO '${db_user}'@'localhost'"
    done
    sudo mysql -e "FLUSH PRIVILEGES"

    log "${COLOR_OK} Datenbank Setup abgeschlossen!${COLOR_RESET}"
}


function createmasteruser() {
    # 02.05.2025 Master Avatar MasterAvatar

    # RobustServer starten
    echo "RobustServer starten, erster start..."
    if [[ -d "robust/bin" && -f "robust/bin/Robust.dll" ]]; then
        log "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}RobustServer ${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}robust/bin...${COLOR_RESET}"
        cd robust/bin || exit 1
        #  -inifile=Robust.HG.ini

        screen -fa -S robustserver -d -U -m dotnet Robust.dll
        cd - >/dev/null 2>&1 || exit 1
        sleep $RobustServer_Start_wait
    else
        log "${SYM_BAD} ${COLOR_SERVER}RobustServer: ${COLOR_BAD}Robust.dll nicht gefunden.${COLOR_RESET} ${COLOR_START}Überspringe Start.${COLOR_RESET}"
    fi

    genPasswort=$(tr -dc 'A-Za-z0-9!@#$%^&*()' < /dev/urandom | head -c 16)
    genUserid=$(command -v uuidgen >/dev/null 2>&1 && uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$RANDOM-$RANDOM-$RANDOM-$RANDOM")
    
    VORNAME="${genFirstname}"
    NACHNAME="${genLastname}"
    local PASSWORT="${genPasswort}"
    local EMAIL="${4:-${genFirstname}@${genLastname}.com}"
    userid="${5:-$genUserid}"
    
    log "${COLOR_INFO}Master User Erstellung (Enter für generierte Werte)${COLOR_RESET}"

    echo -n "Vorname [${VORNAME}]: "
    read -r input
    VORNAME="${input:-$VORNAME}"

    echo -n "Nachname [${NACHNAME}]: "
    read -r input
    NACHNAME="${input:-$NACHNAME}"

    echo -n "Passwort [${PASSWORT}]: "
    read -r input
    PASSWORT="${input:-$PASSWORT}"

    echo -n "E-Mail [${EMAIL}]: "
    read -r input
    EMAIL="${input:-$EMAIL}"

    echo -n "UserID [${userid}]: "
    read -r input
    userid="${input:-$userid}"

    # Überprüfe ob Robust läuft
    if ! screen -list | grep -q "robustserver"; then
        log "${COLOR_BAD}CREATEUSER: Robust existiert nicht oder läuft nicht${COLOR_RESET}"
        return 1
    fi

    # Benutzer in Robust erstellen
    screen -S robustserver -p 0 -X eval "stuff 'create user'^M"
    screen -S robustserver -p 0 -X eval "stuff '$VORNAME'^M"
    screen -S robustserver -p 0 -X eval "stuff '$NACHNAME'^M"
    screen -S robustserver -p 0 -X eval "stuff '$PASSWORT'^M"
    screen -S robustserver -p 0 -X eval "stuff '$EMAIL'^M"
    screen -S robustserver -p 0 -X eval "stuff '$userid'^M"
    screen -S robustserver -p 0 -X eval "stuff 'Ruth'^M"

    log "${COLOR_OK}Masteruser $VORNAME $NACHNAME wurde erstellt${COLOR_RESET}"
    log "${COLOR_INFO}UserID: $userid${COLOR_RESET}"
    
    # **Speicherung der Benutzerdaten in UserInfo.ini** NEU
    local ini_file="${SCRIPT_DIR}/UserInfo.ini"

    if [[ ! -f "$ini_file" ]]; then
        log "${COLOR_INFO}Erstelle UserInfo.ini${COLOR_RESET}"
        sudo touch "$ini_file"
    fi

    log "\n[UserData]" | sudo tee -a "$ini_file" >/dev/null
    echo "Vorname = ${VORNAME}" | sudo tee -a "$ini_file" >/dev/null
    echo "Nachname = ${NACHNAME}" | sudo tee -a "$ini_file" >/dev/null
    echo "Passwort = ${PASSWORT}" | sudo tee -a "$ini_file" >/dev/null
    echo "E-Mail = ${EMAIL}" | sudo tee -a "$ini_file" >/dev/null
    echo "UserID = ${userid}" | sudo tee -a "$ini_file" >/dev/null


    log "${SYM_LOG} ${COLOR_LABEL}Benutzerdaten hinzugefügt in: ${COLOR_FILE}${ini_file}${COLOR_RESET}"

    blankline
}

function createmasterestate() {
    # 02.05.2025 Master Estate
    log "${COLOR_HEADING}🏡 Master Estate Erstellung${COLOR_RESET}"

    # sim1 starten
    echo "Sim1 Welcome starten, erster start..."
    if [[ -d "sim1/bin" && -f "sim1/bin/OpenSim.dll" ]]; then
        log "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}sim1 ${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}sim1/bin...${COLOR_RESET}"
        cd sim1/bin || exit 1
        screen -fa -S sim1 -d -U -m dotnet OpenSim.dll
        cd - >/dev/null 2>&1 || exit 1
        sleep 10
    else
        log "${SYM_BAD} ${COLOR_SERVER}sim1: ${COLOR_BAD}OpenSim.dll nicht gefunden.${COLOR_RESET} ${COLOR_START}Überspringe Start.${COLOR_RESET}"
    fi

    # 1. Überprüfe ob sim1 läuft
    if ! screen -list | grep -q "sim1"; then
        log "${SYM_BAD} ${COLOR_ERROR}CREATEESTATE: sim1 existiert nicht oder läuft nicht${COLOR_RESET}"
        log "${COLOR_INFO}Tipp: Starten Sie die Simulator-Instanz zuerst${COLOR_RESET}"
        return 1
    fi

    # 1. INI-Datei auslesen mit angepasstem Parsing
    local ini_file="${SCRIPT_DIR}/UserInfo.ini"
    if [[ ! -f "$ini_file" ]]; then
        log "${COLOR_BAD}UserInfo.ini nicht gefunden unter: $ini_file${COLOR_RESET}"
        return 1
    fi

    # Parsing-Funktion mit Trim und Leerzeichen im Pattern
    ini_get() {
        local section="$1" key="$2"
        awk -F ' = ' '
        /^\[/ { current_section = substr($0, 2, length($0)-2) }
        current_section == "'"$section"'" && $1 == "'"$key"'" { 
            sub(/^[ \t]+/, "", $2)  # Trim leading whitespace
            sub(/[ \t\r]+$/, "", $2) # Trim trailing whitespace
            print $2
            exit
        }
        ' "$ini_file"
    }

    # Werte auslesen
    gridname=$(ini_get "ServerData" "GridName")
    VORNAME=$(ini_get "UserData" "Vorname")
    NACHNAME=$(ini_get "UserData" "Nachname")

    # Debug-Ausgabe
    log "${COLOR_DEBUG}Gelesene Werte:"
    log "GridName: '${gridname:-NICHT GEFUNDEN}'"
    log "Vorname: '${VORNAME:-NICHT GEFUNDEN}'"
    log "Nachname: '${NACHNAME:-NICHT GEFUNDEN}'${COLOR_RESET}"

    if [[ -z "$gridname" || -z "$VORNAME" || -z "$NACHNAME" ]]; then
        log "${COLOR_BAD}Fehlende Daten in UserInfo.ini${COLOR_RESET}"
        log "Bitte überprüfen Sie folgende Einträge:"
        log "[ServerData]"
        log "GridName = ..."
        log "[UserData]"
        log "Vorname = ..."
        log "Nachname = ..."
        return 1
    fi

    # 3. Logging vor der Ausführung
    log "${COLOR_INFO}Erstelle Master Estate für:"
    log "- Grid: ${COLOR_VALUE}$gridname"
    log "- Avatar: ${COLOR_VALUE}$VORNAME $NACHNAME${COLOR_RESET}"

    # 4. Befehle an sim1 senden mit Fehlerprüfung
    if ! screen -S sim1 -p 0 -X eval "stuff '$gridname Estate'^M"; then
        log "${SYM_BAD} ${COLOR_ERROR}Fehler beim Senden des Estate-Befehls${COLOR_RESET}"
        return 1
    fi
    sleep 1  # Kurze Pause zwischen den Befehlen

    if ! screen -S sim1 -p 0 -X eval "stuff '$VORNAME'^M"; then
        log "${SYM_BAD} ${COLOR_ERROR}Fehler beim Senden des Vornamens${COLOR_RESET}"
        return 1
    fi
    sleep 1

    if ! screen -S sim1 -p 0 -X eval "stuff '$NACHNAME'^M"; then
        log "${SYM_BAD} ${COLOR_ERROR}Fehler beim Senden des Nachnamens${COLOR_RESET}"
        return 1
    fi

    # 5. Erfolgsmeldung
    log "${SYM_OK} ${COLOR_OK}Master Estate erfolgreich erstellt${COLOR_RESET}"
    log "${COLOR_INFO}Starte nun die Estate-Akzeptierung für alle Regionen...${COLOR_RESET}"
    blankline

    # 6. Alle anderen Starten und Estate akzeptieren
    if ! createmasterestateall; then
        log "${SYM_BAD} ${COLOR_ERROR}Fehler bei createmasterestateall${COLOR_RESET}"
        return 1
    fi

    return 0
}

function createmasterestateall() {
    # 02.05.2025 Master Estate Bestätigung mit Simulator-Start
    log "${COLOR_HEADING}🌍 Starte Simulatoren & bestätige Master Estate${COLOR_RESET}"

    # 1. INI-Datei auslesen mit angepasstem Parsing
    local ini_file="${SCRIPT_DIR}/UserInfo.ini"
    if [[ ! -f "$ini_file" ]]; then
        log "${COLOR_BAD}UserInfo.ini nicht gefunden unter: $ini_file${COLOR_RESET}"
        return 1
    fi

    # Parsing-Funktion mit Trim und Leerzeichen im Pattern
    ini_get() {
        local section="$1" key="$2"
        awk -F ' = ' '
        /^\[/ { current_section = substr($0, 2, length($0)-2) }
        current_section == "'"$section"'" && $1 == "'"$key"'" { 
            sub(/^[ \t]+/, "", $2)  # Trim leading whitespace
            sub(/[ \t\r]+$/, "", $2) # Trim trailing whitespace
            print $2
            exit
        }
        ' "$ini_file"
    }

    # Werte auslesen
    gridname=$(ini_get "ServerData" "GridName")
    VORNAME=$(ini_get "UserData" "Vorname")
    NACHNAME=$(ini_get "UserData" "Nachname")

    # Debug-Ausgabe
    log "${COLOR_DEBUG}Gelesene Werte:"
    log "GridName: '${gridname:-NICHT GEFUNDEN}'"
    log "Vorname: '${VORNAME:-NICHT GEFUNDEN}'"
    log "Nachname: '${NACHNAME:-NICHT GEFUNDEN}'${COLOR_RESET}"

    if [[ -z "$gridname" || -z "$VORNAME" || -z "$NACHNAME" ]]; then
        log "${COLOR_BAD}Fehlende Daten in UserInfo.ini${COLOR_RESET}"
        log "Bitte überprüfen Sie folgende Einträge:"
        log "[ServerData]"
        log "GridName = ..."
        log "[UserData]"
        log "Vorname = ..."
        log "Nachname = ..."
        return 1
    fi

    # 2. Starte alle Simulatoren
    log "${COLOR_ACTION}Starte Simulator-Instanzen...${COLOR_RESET}"
    local started_sims=0
    
    for ((i=2; i<=999; i++)); do
        sim_dir="sim$i/bin"        
        if [[ -d "$sim_dir" && -f "$sim_dir/OpenSim.dll" ]]; then
            echo -n -e "${SYM_INFO} ${COLOR_DIR}sim$i: ${COLOR_RESET}"
            
            if cd "$sim_dir" && screen -fa -S "sim$i" -d -U -m dotnet OpenSim.dll; then
                log "${COLOR_OK}gestartet${COLOR_RESET}"
                ((started_sims++))
                sleep "${Simulator_Start_wait:-5}"
            else
                log "${COLOR_ERROR}start fehlgeschlagen${COLOR_RESET}"
            fi
            cd - >/dev/null 2>&1
        fi
    done

    # 3. Estate-Bestätigung für alle Regionen
    if [[ $started_sims -gt 0 ]]; then
        log "${COLOR_ACTION}Bestätige Estate für $started_sims Simulator(en)...${COLOR_RESET}"
        
        for ((i=2; i<=999; i++)); do
            if screen -list | grep -q "sim$i"; then
                regions_dir="${SCRIPT_DIR}/sim$i/bin/Regions"
                if [[ -d "$regions_dir" ]]; then
                    # Zähle die Anzahl der Regionen-Konfigurationen
                    region_count=$(find "$regions_dir" -maxdepth 1 -name "*.ini" | wc -l)
                    log "${SYM_INFO} ${COLOR_DIR}sim$i: ${region_count} Region(en) gefunden${COLOR_RESET}"
                    
                    # Für jede Region die Bestätigung senden
                    for ((r=1; r<=region_count; r++)); do
                        echo -n -e "  ${SYM_INFO} Region ${r}: ${COLOR_RESET}"
                        
                        if ! screen -S "sim$i" -p 0 -X eval "stuff 'yes'^M"; then
                            log "${SYM_BAD} ${COLOR_ERROR}Fehler beim Senden von yes${COLOR_RESET}"
                            return 1
                        fi
                        sleep 1

                        if ! screen -S "sim$i" -p 0 -X eval "stuff '$gridname Estate'^M"; then
                            log "${SYM_BAD} ${COLOR_ERROR}Fehler beim Senden von $gridname Estate${COLOR_RESET}"
                            return 1
                        fi
                        log "${COLOR_OK}bestätigt${COLOR_RESET}"
                        sleep 1
                    done
                else
                    log "${SYM_WARNING} ${COLOR_WARNING}sim$i: Kein Regions-Verzeichnis gefunden${COLOR_RESET}"
                    sleep 1
                fi
            fi
        done
    else
        log "${SYM_WARNING} ${COLOR_WARNING}Keine Simulatoren gestartet!${COLOR_RESET}"
        return 1
    fi

    log "${SYM_OK} ${COLOR_OK}$started_sims Simulatoren gestartet & Estate für alle Regionen bestätigt${COLOR_RESET}"
    sleep 1
    blankline
    return 0
}

function firststart() {
    # 02.05.2025
    # Sind wir im Skriptverzeichnis oder noch in opensim?
    cd "$SCRIPT_DIR" || exit 1

	# Master Avatar Registrieren.
	createmasteruser

    # Estate erstellen
    createmasterestate

    # Erststart stoppen
    #opensimstop
    #killall screen

    # Regulären Start nach installation und setup.
    #opensimrestart

    blankline

}

# bash osmtool.sh setcrontab
function setcrontab() {
    # Strict Mode: Fehler sofort erkennen
    set -euo pipefail

    log "${COLOR_HEADING}⏰ Cron-Job-Einrichtung (Interaktiv)${COLOR_RESET}"

    # Sicherheitsabfrage: Nur als root/sudo ausführen
    if [ "$(id -u)" -ne 0 ]; then
        log "${SYM_BAD} ${COLOR_ERROR}FEHLER: Dieses Skript benötigt root-Rechte! (sudo verwenden)${COLOR_RESET}" >&2
        return 1
    fi

    # Prüfen, ob SCRIPT_DIR gesetzt und gültig ist
    if [ -z "${SCRIPT_DIR:-}" ]; then
        log "${SYM_BAD} ${COLOR_ERROR}FEHLER: 'SCRIPT_DIR' muss gesetzt sein!${COLOR_RESET}" >&2
        return 1
    fi

    if [ ! -d "$SCRIPT_DIR" ]; then
        log "${SYM_BAD} ${COLOR_ERROR}FEHLER: Verzeichnis '${COLOR_DIR}$SCRIPT_DIR${COLOR_ERROR}' existiert nicht!${COLOR_RESET}" >&2
        return 1
    fi

    # Temporäre Datei für neue Cron-Jobs
    local temp_cron
    temp_cron=$(mktemp) || {
        log "${SYM_BAD} ${COLOR_ERROR}FEHLER: Temp-Datei konnte nicht erstellt werden.${COLOR_RESET}" >&2
        return 1
    }

    ### Interaktive Abfragen ###
    log "\n${COLOR_VALUE}=== Wartung am 1. des Monats ===${COLOR_RESET}"
    log "Welche Aktionen sollen ausgeführt werden? (Mehrfachauswahl möglich)"
    log "  ${SYM_INFO} 1) Nichts (deaktivieren)"
    log "  ${SYM_INFO} 2) cacheclean (inkl. automatischem stop vorher)"
    log "  ${SYM_INFO} 3) mapclean (inkl. automatischem stop vorher)"
    log "  ${SYM_INFO} 4) logclean (inkl. automatischem stop vorher)"
    log "  ${SYM_INFO} 5) Vollständiger Neustart (stop → cacheclean → mapclean → logclean → reboot)"
    log "  ${SYM_INFO} 6) Nur Server neustarten (reboot)"
    read -r -p "Auswahl (z.B. '2 3' oder '5'): " -a monthly_actions

    # Abfrage ob nach clean-Operationen ein reboot erfolgen soll
    local needs_reboot=false
    if [[ " ${monthly_actions[*]} " =~ [234] ]]; then
        read -r -p "Soll nach den Clean-Operationen ein Neustart erfolgen? (j/n) " add_reboot
        [[ "$add_reboot" =~ [jJ] ]] && needs_reboot=true
    fi

    log "\n${COLOR_VALUE}=== Tägliche Wartung ===${COLOR_RESET}"
    read -r -p "Soll ein täglicher Restart durchgeführt werden? (j/n) " daily_restart
    if [[ "$daily_restart" =~ [jJ] ]]; then
        read -r -p "Uhrzeit (Stunde, 0-23): " daily_hour
        daily_hour=${daily_hour:-5} # Default: 5 Uhr
    fi

    log "\n${COLOR_VALUE}=== Überwachung ===${COLOR_RESET}"
    read -r -p "Soll die Überwachung aktiviert werden? (j/n) " enable_monitoring
    if [[ "$enable_monitoring" =~ [jJ] ]]; then
        read -r -p "Intervall in Minuten (Standard: 30): " monitor_interval
        monitor_interval=${monitor_interval:-30}
    fi

    ### Cron-Job-Generierung ###
    {
        echo "# === OpenSimGrid-Automatisierung ==="
        echo "# Bedeutung: Minute Stunde Tag Monat Jahr Befehlskette"
        echo ""

        # Monatliche Wartung (1. des Monats)
        if [[ " ${monthly_actions[*]} " =~ "1" ]]; then
            echo "# Deaktiviert: Monatliche Wartung"
        else
            echo "# Monatliche Wartung am 1. des Monats"
            
            # Berechnung der Minuten relativ zum täglichen Restart
            local restart_hour=${daily_hour:-5}
            local restart_minute=0
            
            # Stop 30 Minuten vor täglichem Restart
            if [[ " ${monthly_actions[*]} " =~ [2345] ]]; then
                stop_time=$(calculate_relative_time "$restart_hour" $restart_minute -30)
                echo "$stop_time 1 * * bash '$SCRIPT_DIR/osmtool.sh' stop"
            fi

            # Cacheclean 25 Minuten vor täglichem Restart (Option 2 oder 5)
            if [[ " ${monthly_actions[*]} " =~ [25] ]]; then
                cacheclean_time=$(calculate_relative_time "$restart_hour" $restart_minute -25)
                echo "$cacheclean_time 1 * * bash '$SCRIPT_DIR/osmtool.sh' cacheclean"
            fi

            # Mapclean 20 Minuten vor täglichem Restart (Option 3 oder 5)
            if [[ " ${monthly_actions[*]} " =~ [35] ]]; then
                mapclean_time=$(calculate_relative_time "$restart_hour" $restart_minute -20)
                echo "$mapclean_time 1 * * bash '$SCRIPT_DIR/osmtool.sh' mapclean"
            fi

            # Logclean 15 Minuten vor täglichem Restart (Option 4 oder 5)
            if [[ " ${monthly_actions[*]} " =~ [45] ]]; then
                logclean_time=$(calculate_relative_time "$restart_hour" $restart_minute -15)
                echo "$logclean_time 1 * * bash '$SCRIPT_DIR/osmtool.sh' logclean"
            fi

            # Reboot 10 Minuten vor täglichem Restart (Option 5 oder 6 oder manuelle Bestätigung)
            if [[ " ${monthly_actions[*]} " =~ [56] ]] || $needs_reboot; then
                reboot_time=$(calculate_relative_time "$restart_hour" $restart_minute -10)
                echo "$reboot_time 1 * * bash '$SCRIPT_DIR/osmtool.sh' reboot"
            fi
        fi

        # Tägliche Wartung
        if [[ "$daily_restart" =~ [jJ] ]]; then
            log "\n# Täglicher Restart"
            echo "0 ${daily_hour} * * * bash '$SCRIPT_DIR/osmtool.sh' restart"
        else
            log "\n# Deaktiviert: Täglicher Restart"
        fi

        # Überwachung
        if [[ "$enable_monitoring" =~ [jJ] ]]; then
            log "\n# Überwachung"
            echo "*/${monitor_interval} * * * * bash '$SCRIPT_DIR/osmtool.sh' check_screens"
        else
            log "\n# Deaktiviert: Überwachung"
        fi
    } > "$temp_cron"

    # Cron-Jobs installieren
    if crontab "$temp_cron"; then
        rm -f "$temp_cron"
        log "\n${SYM_OK} ${COLOR_OK}Cron-Jobs wurden aktualisiert:${COLOR_RESET}"
        crontab -l | grep -v '^#' | sed '/^$/d' | while read -r line; do
            log "${COLOR_DIR}$line${COLOR_RESET}"
        done
        return 0
    else
        log "${SYM_BAD} ${COLOR_ERROR}FEHLER: Installation fehlgeschlagen. Prüfe $temp_cron manuell.${COLOR_RESET}" >&2
        return 1
    fi
}

# Hilfsfunktion zur Berechnung relativer Zeiten
calculate_relative_time() {
    local hour=$1
    local minute=$2
    local offset=$3  # in Minuten (kann negativ sein)
    
    # Gesamtminuten berechnen
    local total_minutes=$((hour * 60 + minute + offset))
    
    # Handle negative Zeiten (vor Mitternacht)
    while (( total_minutes < 0 )); do
        total_minutes=$((total_minutes + 1440))  # 24 Stunden in Minuten
    done
    
    # Zurück in Stunden und Minuten umrechnen
    local new_hour=$((total_minutes / 60 % 24))
    local new_minute=$((total_minutes % 60))
    
    echo "$new_minute $new_hour"
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Backup und Upgrade des OpenSimulators Grids
#?──────────────────────────────────────────────────────────────────────────────────────────

function opensimupgrade() {
    log "\n${COLOR_WARNING}⚠ Der OpenSimulator muss zuerst im Verzeichnis 'opensim' vorliegen!${COLOR_RESET}"
    log "${COLOR_LABEL}Möchten Sie den OpenSimulator aktualisieren? (${COLOR_BAD}[no]${COLOR_LABEL}/yes)${COLOR_RESET}"
    read -r user_choice
    user_choice=${user_choice:-no}

    # Prüfe, ob das Verzeichnis vorhanden ist
    if [[ ! -d "opensim" ]]; then
        log "${SYM_BAD} ${COLOR_ERROR}Fehler: Das Verzeichnis '${COLOR_DIR}opensim${COLOR_ERROR}' existiert nicht${COLOR_RESET}"
        return 1
    fi

    # Prüfe, ob im Verzeichnis 'opensim/bin' die Dateien OpenSim.dll und Robust.dll vorhanden sind
    if [[ ! -f "opensim/bin/OpenSim.dll" || ! -f "opensim/bin/Robust.dll" ]]; then
        log "${SYM_BAD} ${COLOR_ERROR}Fehler: Benötigte Dateien (OpenSim.dll und/oder Robust.dll) fehlen im Verzeichnis '${COLOR_DIR}opensim/bin${COLOR_ERROR}'${COLOR_RESET}"
        log "\n${COLOR_WARNING}❓ Haben Sie vergessen den OpenSimulator zuerst zu Kompilieren?${COLOR_RESET}"
        return 1
    fi

    if [[ "$user_choice" == "yes" ]]; then
        log "${COLOR_ACTION}OpenSimulator wird gestoppt...${COLOR_RESET}"
        opensimstop
        sleep $Simulator_Stop_wait

        log "${COLOR_ACTION}OpenSimulator wird kopiert...${COLOR_RESET}"
        opensimcopy

        log "${COLOR_ACTION}OpenSimulator wird gestartet...${COLOR_RESET}"
        opensimstart

        log "${COLOR_OK}✔ ${COLOR_ACTION}Upgrade abgeschlossen.${COLOR_RESET}"
    else
        log "${COLOR_WARNING}Upgrade vom Benutzer abgebrochen.${COLOR_RESET}"
    fi
    blankline
}

function regionbackup() {
    DATUM=$(date +%Y-%m-%d_%H-%M)
    BACKUPDIR="$SCRIPT_DIR/backup"
    mkdir -p "$BACKUPDIR"

    log "${SYM_TOOLS} ${COLOR_HEADING}Starte automatisches Backup aller Regionen...${COLOR_RESET}"
    
    for ((i=1; i<=999; i++)); do
        SIMNAME="sim$i"
        SIMBIN="$SCRIPT_DIR/$SIMNAME/bin"
        REGIONSDIR="$SIMBIN/Regions"
        TARGETDIR="$BACKUPDIR/sim$i"

        if [[ -d "$REGIONSDIR" ]]; then
            mkdir -p "$TARGETDIR"
            log "${SYM_SERVER} ${COLOR_START}Backup für ${COLOR_SERVER}$SIMNAME${COLOR_RESET} wird vorbereitet (${COLOR_DIR}$SIMBIN${COLOR_RESET})..."

            # ➕ OpenSim.ini sichern
            if [[ -f "$SIMBIN/OpenSim.ini" ]]; then
                cp "$SIMBIN/OpenSim.ini" "$TARGETDIR/${DATUM}-OpenSim.ini"
                log "${SYM_CONFIG} ${COLOR_LABEL}OpenSim.ini gesichert:${COLOR_RESET} ${COLOR_FILE}${DATUM}-OpenSim.ini${COLOR_RESET}"
            fi

            # ➕ GridCommon.ini sichern
            if [[ -f "$SIMBIN/config-include/GridCommon.ini" ]]; then
                cp "$SIMBIN/config-include/GridCommon.ini" "$TARGETDIR/${DATUM}-GridCommon.ini"
                log "${SYM_CONFIG} ${COLOR_LABEL}GridCommon.ini gesichert:${COLOR_RESET} ${COLOR_FILE}${DATUM}-GridCommon.ini${COLOR_RESET}"
            fi

            for ini_file in "$REGIONSDIR"/*.ini; do
                [[ -f "$ini_file" ]] || continue
                
                region_names=$(grep -oP '^\[\K[^\]]+' "$ini_file")

                for REGIONNAME in $region_names; do
                    blankline
                    log "${SYM_FOLDER} ${COLOR_LABEL}Sichere Region:${COLOR_RESET} ${COLOR_VALUE}$REGIONNAME${COLOR_RESET}"

                    screen -S "$SIMNAME" -p 0 -X eval "stuff 'change region ${REGIONNAME//\"/}'^M"
                    sleep 1

                    screen -S "$SIMNAME" -p 0 -X eval "stuff 'save oar ${TARGETDIR}/${DATUM}-${REGIONNAME}.oar'^M"
                    log "${SYM_FILE} ${COLOR_LABEL}OAR gespeichert:${COLOR_RESET} ${COLOR_FILE}${DATUM}-${REGIONNAME}.oar${COLOR_RESET}"

                    screen -S "$SIMNAME" -p 0 -X eval "stuff 'save xml2 ${TARGETDIR}/${DATUM}-${REGIONNAME}.xml2'^M"
                    log "${SYM_FILE} ${COLOR_LABEL}XML2 gespeichert:${COLOR_RESET} ${COLOR_FILE}${DATUM}-${REGIONNAME}.xml2${COLOR_RESET}"

                    screen -S "$SIMNAME" -p 0 -X eval "stuff 'terrain save ${TARGETDIR}/${DATUM}-${REGIONNAME}.png'^M"
                    screen -S "$SIMNAME" -p 0 -X eval "stuff 'terrain save ${TARGETDIR}/${DATUM}-${REGIONNAME}.raw'^M"
                    log "${SYM_FILE} ${COLOR_LABEL}Terrain (PNG & RAW) gespeichert:${COLOR_RESET} ${COLOR_FILE}${DATUM}-${REGIONNAME}.{png,raw}${COLOR_RESET}"

                    cp "$ini_file" "$TARGETDIR/${DATUM}-$(basename "$ini_file")"
                    log "${SYM_CONFIG} ${COLOR_LABEL}Konfig gesichert:${COLOR_RESET} ${COLOR_FILE}${DATUM}-$(basename "$ini_file")${COLOR_RESET}"

                    sleep 1
                done
            done
        fi
    done

    log "${SYM_OK} ${COLOR_ACTION}Automatisches Regionen-Backup abgeschlossen.${COLOR_RESET}"
    blankline
}

# todo: Testen, ob alles funktioniert.
# Erstellt ein strukturiertes Backup der Robust-Datenbank sowie wichtiger Konfigurationsdateien.
# Aufruf:
#* robustbackup <dbuser> <dbpass>
# dbuser: SQL-Benutzername
# dbpass: Passwort des SQL-Benutzers
function robustbackup() {
    local DB_USER=$1
    local DB_PASS=$2
    local DB_NAME="robust"
    local BACKUP_YEARS=30
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local BACKUP_DIR="$SCRIPT_DIR/backup/robust"
    local ROBUST_INI_DIR="$SCRIPT_DIR/robust/bin"
    TIMESTAMP=$(date +%F_%H-%M)
    TIMESTAMP_GRENZE=$(date -d "-$BACKUP_YEARS years" +%s)
    ARCHIVIEREN="nein"

    declare -A ASSET_NAMES=(
        [-1]="NoneUnknown" [-2]="LLmaterialIAR" [0]="Texture" [1]="Sound" [2]="CallingCard" [3]="Landmark"
        [4]="Unknown4" [5]="Clothing" [6]="Object" [7]="Notecard" [8]="Folder" [9]="Unknown9"
        [10]="LSLText" [11]="LSLBytecode" [12]="TextureTGA" [13]="Bodypart" [14]="Unknown14"
        [15]="Unknown15" [16]="Unknown16" [17]="SoundWAV" [18]="ImageTGA" [19]="ImageJPEG"
        [20]="Animation" [21]="Gesture" [22]="Simstate" [23]="Unknown23" [24]="Link"
        [25]="LinkFolder" [26]="MarketplaceFolder" [49]="Mesh" [56]="Settings" [57]="Material"
    )

    mkdir -p "$BACKUP_DIR/tables" "$BACKUP_DIR/assettypen" "$BACKUP_DIR/configs"

    log "${COLOR_HEADING}${SYM_PACKAGE} Starte Robust-Datenbank-Backup mit Zeitraumfilter ($BACKUP_YEARS Jahre)${COLOR_RESET}"

    #* Reparatur
    mysqlcheck -u"$DB_USER" -p"$DB_PASS" --auto-repair "$DB_NAME"

    #* Tabellen sichern (außer assets) mit Zählung
    local tabellen
    local total_nonasset_rows=0
    tabellen=$(mysql -u"$DB_USER" -p"$DB_PASS" -N -e "SHOW TABLES IN $DB_NAME;" | grep -v '^assets$')
    for table in $tabellen; do
        row_count=$(mysql -u"$DB_USER" -p"$DB_PASS" -N -e "SELECT COUNT(*) FROM $table;" "$DB_NAME")
        ((total_nonasset_rows += row_count))
        log "${SYM_LOG} Tabelleneinträge: $table (${row_count} Einträge)${COLOR_RESET}"
        mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" "$table" | gzip > "$BACKUP_DIR/tables/${table}.sql.gz"
    done

    log "${SYM_OKN}${COLOR_INFO} Tabellen (außer assets): Insgesamt $total_nonasset_rows Einträge gesichert${COLOR_RESET}"


    #* Assettypen sichern mit Zählung
    log "${SYM_PUZZLE} Starte assetType-Datensicherung mit Zeitraumfilter ab $(date -d "@$TIMESTAMP_GRENZE")"
    
    total_found=0
    total_saved=0

    for assettype in "${!ASSET_NAMES[@]}"; do
        local name="${ASSET_NAMES[$assettype]}"
        log "${SYM_FOLDER}  Exportiere assetType=$assettype ($name)${COLOR_RESET}"

        # Anzahl Datensätze in diesem Typ und Zeitraum
        count=$(mysql -u"$DB_USER" -p"$DB_PASS" -N -e \
            "SELECT COUNT(*) FROM assets WHERE assetType = $assettype AND create_time >= $TIMESTAMP_GRENZE;" "$DB_NAME")
        
        if [[ "$count" -gt 0 ]]; then
            ((total_found += count))
            ((total_saved += count))
            mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" assets \
                --where="assetType = $assettype AND create_time >= $TIMESTAMP_GRENZE" \
                | gzip > "$BACKUP_DIR/assettypen/assets_${name}.sql.gz"
            log "${SYM_OKN} Gespeichert: $count Einträge für $name"
        else
            log "${SYM_FORWARD}  Keine Daten für assetType=$assettype ($name)"
        fi
    done

    log "${SYM_OKN}${COLOR_INFO} Asset-Sicherung abgeschlossen: $total_found gefunden, $total_saved gespeichert, Differenz: $((total_found - total_saved))${COLOR_RESET}"


    #* Konfig-Dateien sichern
    log "${SYM_LOG} Sicherung der Konfigurationsdateien im robust/bin Verzeichnis${COLOR_RESET}"
    find "$ROBUST_INI_DIR" -maxdepth 1 -type f \( \
        -name "MoneyServer.ini" -o -name "MoneyServer.ini.*" \
        -o -name "Robust.ini" -o -name "Robust.HG.*" -o -name "Robust.local.*" \) \
        -exec cp {} "$BACKUP_DIR/configs/" \;

    #* Archiv erstellen (Was passiert hier wird das unützerweise alles in einer Datei gepackt?)
    if [ "$ARCHIVIEREN" = "ja" ]; then
    log "${COLOR_HEADING}${SYM_PACKAGE} Erstelle tgz-Archiv: robustbackup_${TIMESTAMP}.tgz${COLOR_RESET}"
    tar czf "$BACKUP_DIR/robustbackup_${TIMESTAMP}.tgz" -C "$BACKUP_DIR" .
    log "${SYM_OKNN} Backup abgeschlossen: $BACKUP_DIR/robustbackup_${TIMESTAMP}.tgz${COLOR_RESET}"
    fi
}

# todo: Testen, ob alles funktioniert.
# Wiederherstellt eine Robust-Datenbank aus einer Dump-Datei.
# Aufruf:
#* restoreRobustDump <dbuser> <dbpass> <dumpfile> <targetdb>
function restoreRobustDump() {
    local DB_USER=$1
    local DB_PASS=$2
    local DUMP_FILE=$3
    local TARGET_DB=$4

    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local TMPDIR
    TMPDIR=$(mktemp -d)
    local total_tables=0

    log "${COLOR_HEADING}${SYM_PACKAGE} Starte Wiederherstellung von Dump-Datei ${COLOR_FILE}${DUMP_FILE}${COLOR_RESET} in Datenbank ${COLOR_VALUE}${TARGET_DB}${COLOR_RESET}"

    if [[ ! -f "$DUMP_FILE" ]]; then
        log "${SYM_BAD} ${COLOR_BAD}Fehler:${COLOR_RESET} Dump-Datei nicht gefunden: ${COLOR_FILE}$DUMP_FILE${COLOR_RESET}"
        return 1
    fi

    #* Datenbank vorbereiten
    log "${SYM_TOOLS} Entferne vorhandene Datenbank (falls vorhanden) und erstelle neu: ${COLOR_VALUE}$TARGET_DB${COLOR_RESET}"
    mysql -u"$DB_USER" -p"$DB_PASS" -e "DROP DATABASE IF EXISTS \`$TARGET_DB\`; CREATE DATABASE \`$TARGET_DB\`;"

    #* Dump-Datei aufteilen
    log "${SYM_SCRIPT} Zerlege Dump-Datei in einzelne Tabellen im Temp-Verzeichnis: ${COLOR_FILE}$TMPDIR${COLOR_RESET}"
    csplit -z -f "$TMPDIR/table_" -b "%03d.sql" "$DUMP_FILE" '/DROP TABLE IF EXISTS/' '{*}' > /dev/null

    #* Import der Tabellen
    for sqlfile in "$TMPDIR"/table_*.sql; do
        local tablename
        tablename=$(grep -i "CREATE TABLE" "$sqlfile" | awk -F'\`' '{print $2}')
        if [[ -n "$tablename" ]]; then
            log "${SYM_FILE} Importiere Tabelle: ${COLOR_FILE}$tablename${COLOR_RESET}"
            mysql -u"$DB_USER" -p"$DB_PASS" "$TARGET_DB" < "$sqlfile"
            ((total_tables++))
        fi
    done

    log "${SYM_OKN}${COLOR_INFO} Import abgeschlossen: $total_tables Tabellen importiert${COLOR_RESET}"

    #* Asset-Typen prüfen und reparieren
    log "${SYM_PUZZLE} Prüfe asset.assetType auf ungültige Werte..."
    invalid_count=$(mysql -u"$DB_USER" -p"$DB_PASS" -sse "SELECT COUNT(*) FROM asset WHERE assetType NOT BETWEEN 0 AND 49;" "$TARGET_DB")

    if ((invalid_count > 0)); then
        log "${SYM_WARNING} Ungültige assetType-Werte gefunden: $invalid_count — korrigiere auf 0"
        mysql -u"$DB_USER" -p"$DB_PASS" -e "UPDATE asset SET assetType = 0 WHERE assetType NOT BETWEEN 0 AND 49;" "$TARGET_DB"
    else
        log "${SYM_OK} Alle assetType-Werte sind gültig"
    fi

    #* Datenbank reparieren
    log "${SYM_TOOLS} Führe mysqlcheck mit Reparatur durch..."
    mysqlcheck -u"$DB_USER" -p"$DB_PASS" --auto-repair "$TARGET_DB"

    log "${SYM_OK} ${COLOR_OK}Wiederherstellung erfolgreich abgeschlossen für:${COLOR_RESET} ${COLOR_VALUE}$TARGET_DB${COLOR_RESET}"
}


# todo: Testen, ob alles funktioniert.
# robustrestore <dbuser> <dbpass> <all|tables|assets|assettype>
# dbuser: SQL-Benutzername
# dbpass: Passwort des SQL-Benutzers
# all: Wiederherstellung aller Nicht-Asset-Tabellen und Konfig-Dateien
# tables: Wiederherstellung aller Nicht-Asset-Tabellen
# assets: Wiederherstellung der assetType-Tabellen und Konfig-Dateien
# assettype: Wiederherstellung der angegebenen assetType-Tabellen
function robustrestore() {
    local DB_USER=$1
    local DB_PASS=$2
    local DB_NAME="robust"
    local RESTORE_SCOPE=$3  # "all", "tables", "assets" oder Asset-Typ-Name
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local BACKUP_DIR="$SCRIPT_DIR/backup/robust"

    log "${COLOR_HEADING}${SYM_PACKAGE} Starte Wiederherstellung für: ${COLOR_VALUE}${RESTORE_SCOPE}${COLOR_RESET}"

    case "$RESTORE_SCOPE" in
        all)
            log "${SYM_LOG} ${COLOR_LABEL}Wiederherstellung aller Nicht-Asset-Tabellen...${COLOR_RESET}"
            for file in "$BACKUP_DIR/tables/"*.sql.gz; do
                table_name=$(basename "$file" .sql.gz)
                log "${SYM_FILE} ${COLOR_FILE}${file}${COLOR_RESET} ${COLOR_ACTION}→ Importiere Tabelle: ${COLOR_LABEL}${table_name}${COLOR_RESET}"
                gunzip -c "$file" | mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME"
            done

            log "${SYM_LOG} ${COLOR_LABEL}Wiederherstellung aller Asset-Typen...${COLOR_RESET}"
            for file in "$BACKUP_DIR/assettypen/"*.sql.gz; do
                asset_name=$(basename "$file" .sql.gz)
                log "${SYM_FILE} ${COLOR_FILE}${file}${COLOR_RESET} ${COLOR_ACTION}→ Importiere Asset-Typ: ${COLOR_LABEL}${asset_name}${COLOR_RESET}"
                gunzip -c "$file" | mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME"
            done
            ;;
        tables)
            log "${SYM_LOG} ${COLOR_LABEL}Wiederherstellung nur der Nicht-Asset-Tabellen...${COLOR_RESET}"
            for file in "$BACKUP_DIR/tables/"*.sql.gz; do
                table_name=$(basename "$file" .sql.gz)
                log "${SYM_FILE} ${COLOR_FILE}${file}${COLOR_RESET} ${COLOR_ACTION}→ Importiere Tabelle: ${COLOR_LABEL}${table_name}${COLOR_RESET}"
                gunzip -c "$file" | mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME"
            done
            ;;
        assets)
            log "${SYM_LOG} ${COLOR_LABEL}Wiederherstellung aller Asset-Typen...${COLOR_RESET}"
            for file in "$BACKUP_DIR/assettypen/"*.sql.gz; do
                asset_name=$(basename "$file" .sql.gz)
                log "${SYM_FILE} ${COLOR_FILE}${file}${COLOR_RESET} ${COLOR_ACTION}→ Importiere Asset-Typ: ${COLOR_LABEL}${asset_name}${COLOR_RESET}"
                gunzip -c "$file" | mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME"
            done
            ;;
        *)
            local file="$BACKUP_DIR/assettypen/assets_${RESTORE_SCOPE}.sql.gz"
            if [[ -f "$file" ]]; then
                log "${SYM_FOLDER} ${COLOR_LABEL}Wiederherstellung für Asset-Typ: ${COLOR_VALUE}${RESTORE_SCOPE}${COLOR_RESET}"
                log "${SYM_FILE} ${COLOR_FILE}${file}${COLOR_RESET}"
                gunzip -c "$file" | mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME"
            else
                log "${SYM_BAD} ${COLOR_BAD}Fehler: Kein Backup für Asset-Typ '${RESTORE_SCOPE}' gefunden!${COLOR_RESET}"
                return 1
            fi
            ;;
    esac

    log "${SYM_OK} ${COLOR_OK}Wiederherstellung erfolgreich abgeschlossen für Bereich: ${COLOR_VALUE}${RESTORE_SCOPE}${COLOR_RESET}"
}

# todo: Testen, ob alles funktioniert.
# robustrepair <dbuser> <dbpass> <check|repair|truncate|dropassets|dropall>
# dbuser: SQL-Benutzername
# dbpass: Passwort des SQL-Benutzers
# check: Prüft alle Tabellen auf Fehler
# repair: Repariert alle Tabellen automatisch
# truncate: Leert alle Inhalte, behält aber Tabellenstrukturen
# dropassets: Löscht alle Assets und Asset-Typen
# dropall: Löscht alle Tabelleninhalte
function robustrepair() {
    local DB_USER=$1
    local DB_PASS=$2
    local DB_NAME="robust"
    local ACTION=$3  # "check", "repair", "truncate", "dropassets", "dropall"

    log "${COLOR_HEADING}${SYM_TOOLS} Starte Datenbankwartung: ${COLOR_VALUE}${ACTION}${COLOR_RESET}"

    case "$ACTION" in
        check)
            log "${SYM_WAIT} ${COLOR_LABEL}Überprüfe Tabellen auf Fehler...${COLOR_RESET}"
            mysqlcheck -u"$DB_USER" -p"$DB_PASS" "$DB_NAME"
            ;;
        repair)
            log "${SYM_SYNC} ${COLOR_LABEL}Repariere beschädigte Tabellen automatisch...${COLOR_RESET}"
            mysqlcheck -u"$DB_USER" -p"$DB_PASS" --auto-repair "$DB_NAME"
            ;;
        truncate)
            log "${SYM_WARNING} ${COLOR_WARNING}⚠️ Achtung: Leert alle Inhalte, behält aber Tabellenstrukturen!${COLOR_RESET}"
            echo -ne "${COLOR_BAD}Fortfahren? (ja/nein): ${COLOR_RESET}"
            read -r confirm
            if [[ "$confirm" == "ja" ]]; then
                local tables
                tables=$(mysql -u"$DB_USER" -p"$DB_PASS" -N -e "SHOW TABLES IN $DB_NAME;")
                for t in $tables; do
                    log "${SYM_CLEAN} Leere Tabelle: ${COLOR_LABEL}${t}${COLOR_RESET}"
                    mysql -u"$DB_USER" -p"$DB_PASS" -e "TRUNCATE TABLE $DB_NAME.$t;"
                done
                log "${SYM_OK} ${COLOR_OK}Alle Tabellen wurden geleert.${COLOR_RESET}"
            else
                log "${SYM_BAD} ${COLOR_BAD}Abgebrochen.${COLOR_RESET}"
            fi
            ;;
        dropassets)
            log "${SYM_WARNING} ${COLOR_WARNING}⚠️ Achtung: Löscht ALLE Einträge in der 'assets'-Tabelle!${COLOR_RESET}"
            echo -ne "${COLOR_BAD}Fortfahren? (ja/nein): ${COLOR_RESET}"
            read -r confirm
            if [[ "$confirm" == "ja" ]]; then
                mysql -u"$DB_USER" -p"$DB_PASS" -e "DELETE FROM $DB_NAME.assets;"
                log "${SYM_OK} ${COLOR_OK}Tabelle 'assets' wurde geleert.${COLOR_RESET}"
            else
                log "${SYM_BAD} ${COLOR_BAD}Abgebrochen.${COLOR_RESET}"
            fi
            ;;
        dropall)
            log "${SYM_WARNING} ${COLOR_WARNING}⚠️ Achtung: Alle Tabellen der Datenbank werden gelöscht!${COLOR_RESET}"
            echo -ne "${COLOR_BAD}Wirklich ALLE Tabellen löschen? (ja/nein): ${COLOR_RESET}"
            read -r confirm
            if [[ "$confirm" == "ja" ]]; then
                local tables
                tables=$(mysql -u"$DB_USER" -p"$DB_PASS" -N -e "SHOW TABLES IN $DB_NAME;")
                for t in $tables; do
                    log "${SYM_CLEAN} Lösche Tabelle: ${COLOR_LABEL}${t}${COLOR_RESET}"
                    mysql -u"$DB_USER" -p"$DB_PASS" -e "DROP TABLE $DB_NAME.$t;"
                done
                log "${SYM_OK} ${COLOR_OK}Alle Tabellen gelöscht.${COLOR_RESET}"
            else
                log "${SYM_BAD} ${COLOR_BAD}Abgebrochen.${COLOR_RESET}"
            fi
            ;;
        *)
            log "${SYM_BAD} ${COLOR_BAD}Unbekannte Aktion: ${ACTION}${COLOR_RESET}"
            log "${SYM_INFO} Mögliche Optionen: check | repair | truncate | dropassets | dropall"
            return 1
            ;;
    esac
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Bereinigen des OpenSimulators Grids
#?──────────────────────────────────────────────────────────────────────────────────────────

function dataclean() {
    log "${COLOR_HEADING}🧹 Datenbereinigung wird durchgeführt...${COLOR_RESET}"

    # RobustServer bereinigen
    if [[ -d "robust/bin" ]]; then
        log "${SYM_OK} ${COLOR_ACTION}Lösche Dateien im RobustServer...${COLOR_RESET}"
        find "robust/bin" -maxdepth 1 -type f \( -name "*.log" -o -name "*.dll" -o -name "*.exe" -o -name "*.so" -o -name "*.xml" -o -name "*.dylib" -o -name "*.example" -o -name "*.sample" -o -name "*.txt" -o -name "*.config" -o -name "*.py" -o -name "*.old" -o -name "*.pdb" \) -delete
    fi

    # Alle simX-Server bereinigen
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" ]]; then
            log "${SYM_OK} ${COLOR_ACTION}Lösche Dateien in ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
            find "$sim_dir" -maxdepth 1 -type f \( -name "*.log" -o -name "*.dll" -o -name "*.exe" -o -name "*.so" -o -name "*.xml" -o -name "*.dylib" -o -name "*.example" -o -name "*.sample" -o -name "*.txt" -o -name "*.config" -o -name "*.py" -o -name "*.old" -o -name "*.pdb" \) -delete
            sleep 1
        fi
    done
    log "${COLOR_HEADING}${SYM_OKNN} Datenbereinigung abgeschlossen${COLOR_RESET}"    
    blankline
}

function pathclean() {
    directories=("assetcache" "maptiles" "MeshCache" "j2kDecodeCache" "ScriptEngines" "bakes" "addon-modules")
    wildcard_dirs=("addin-db-*")  # Separate Liste für Wildcard-Verzeichnisse

    log "${COLOR_HEADING}🗂️ Verzeichnisbereinigung wird durchgeführt...${COLOR_RESET}"

    # RobustServer bereinigen
    if [[ -d "robust/bin" ]]; then
        log "${SYM_OK} ${COLOR_ACTION}Lösche komplette Verzeichnisse im RobustServer...${COLOR_RESET}"
        
        # Normale Verzeichnisse
        for dir in "${directories[@]}"; do
            target="robust/bin/$dir"
            if [[ -d "$target" ]]; then
                rm -rf "$target"
                log "  ${COLOR_ACTION}Verzeichnis gelöscht: ${COLOR_DIR}$target${COLOR_RESET}"
            fi
        done
        
        # Wildcard-Verzeichnisse
        for pattern in "${wildcard_dirs[@]}"; do
            for target in robust/bin/$pattern; do
                if [[ -d "$target" ]]; then
                    rm -rf "$target"
                    log "  ${COLOR_WARNING}Verzeichnis gelöscht: ${COLOR_DIR}$target${COLOR_RESET}"
                fi
            done
        done
    fi

    # Alle simX-Server bereinigen
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" ]]; then
            log "${SYM_OK} ${COLOR_ACTION}Lösche komplette Verzeichnisse in ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
            
            # Normale Verzeichnisse
            for dir in "${directories[@]}"; do
                target="$sim_dir/$dir"
                if [[ -d "$target" ]]; then
                    rm -rf "$target"
                    log "  ${COLOR_ACTION}Verzeichnis gelöscht: ${COLOR_DIR}$target${COLOR_RESET}"
                    sleep 1
                fi
            done
            
            # Wildcard-Verzeichnisse
            for pattern in "${wildcard_dirs[@]}"; do
                for target in $sim_dir/$pattern; do
                    if [[ -d "$target" ]]; then
                        rm -rf "$target"
                        log "  ${COLOR_WARNING}Verzeichnis gelöscht: ${COLOR_DIR}$target${COLOR_RESET}"
                    fi
                done
            done
        fi
    done
    log "${COLOR_HEADING}${SYM_OKNN} Verzeichnisbereinigung abgeschlossen${COLOR_RESET}"
    blankline
}

function cacheclean() {
    #cache_dirs=("assetcache" "maptiles" "MeshCache" "j2kDecodeCache" "ScriptEngines")
    cache_dirs=("assetcache" "MeshCache" "j2kDecodeCache" "ScriptEngines")

    log "${COLOR_HEADING}♻️ Cache-Bereinigung wird durchgeführt...${COLOR_RESET}"

    # RobustServer bereinigen
    if [[ -d "robust/bin" ]]; then
        log "${SYM_OK} ${COLOR_ACTION}Leere Cache-Verzeichnisse im RobustServer...${COLOR_RESET}"
        for dir in "${cache_dirs[@]}"; do
            target="robust/bin/$dir"
            if [[ -d "$target" ]]; then
                find "$target" -mindepth 1 -delete
                log "  ${COLOR_ACTION}Inhalt geleert: ${COLOR_DIR}$target${COLOR_RESET}"
            fi
        done
    fi

    # Alle simX-Server bereinigen
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" ]]; then
            log "${SYM_OK} ${COLOR_ACTION}Leere Cache-Verzeichnisse in ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
            for dir in "${cache_dirs[@]}"; do
                target="$sim_dir/$dir"
                if [[ -d "$target" ]]; then
                    find "$target" -mindepth 1 -delete
                    log "  ${COLOR_ACTION}Inhalt geleert: ${COLOR_DIR}$target${COLOR_RESET}"
                    sleep 1
                fi
            done
        fi
    done
    log "${COLOR_HEADING}${SYM_OKNN} Cache-Bereinigung abgeschlossen${COLOR_RESET}"
    blankline
}

function logclean() {
    log "${SYM_LOG}${COLOR_HEADING} Log-Bereinigung wird durchgeführt...${COLOR_RESET}"

    # RobustServer bereinigen
    if [[ -d "robust/bin" ]]; then
        log "${SYM_OK} ${COLOR_ACTION}Lösche Log-Dateien in ${COLOR_DIR}robust/bin...${COLOR_RESET}"
        rm -f robust/bin/*.log
    fi

    # Alle simX-Server bereinigen (sim1 bis sim999)
    for ((i=1; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" ]]; then
            log "${SYM_OK} ${COLOR_ACTION}Lösche Log-Dateien in ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
            rm -f "$sim_dir"/*.log
            sleep 1
        fi
    done
    
    log "${COLOR_HEADING}Log-Bereinigung abgeschlossen${COLOR_RESET}"
    blankline
}

function mapclean() {
    log "${COLOR_HEADING}🗺️ Map-Tile-Bereinigung wird durchgeführt...${COLOR_RESET}"

    # Sicherheitscheck für robust/bin/maptiles
    if [[ -d "robust/bin/maptiles" ]]; then
        rm -rf -- "robust/bin/maptiles/"*
        log "${SYM_OK} ${COLOR_ACTION}robust/bin/maptiles geleert${COLOR_RESET}"
    fi

    # Sicherheitscheck für alle simX/bin/maptiles
    for ((i=1; i<=999; i++)); do
        local sim_dir="sim$i/bin/maptiles"
        if [[ -d "$sim_dir" ]]; then
            # shellcheck disable=SC2115
            rm -rf -- "${sim_dir}/"*
            log "${SYM_OK} ${COLOR_ACTION}${COLOR_DIR}$sim_dir${COLOR_RESET} ${COLOR_ACTION}geleert${COLOR_RESET}"
            sleep 1
        fi
    done

    log "${COLOR_HEADING}${SYM_OKNN} Map-Tile-Bereinigung abgeschlossen${COLOR_RESET}"
    blankline
}

function autoallclean() {
    local confirm

    # Warnung in Gelb (konsistenter mit \e anstelle von \033)
    log "\e[33m"
    cat >&2 <<'WARNUNG'
=== WARNUNG: Alle Daten-, Verzeichnis-, Cache-, Log- und Map-Daten werden bereinigt! ===
=== DIESE OPERATION KANN NICHT RÜCKGÄNGIG GEMACHT WERDEN! ===
=== DER OPENSIMULATOR MUSS IM ANSCHLUSS NEU INSTALLIERT WERDEN! ===
WARNUNG
    log "\e[0m"

    # Bestätigung mit Timeout (10 Sekunden) für Sicherheit
    read -t 30 -r -p "Fortfahren? (ja/NEIN): " confirm || {
        log "\n\e[31mTimeout: Keine Bestätigung erhalten. Abbruch.\e[0m" >&2
        return 1
    }

    case "${confirm,,}" in
        ja|j|y|yes)
            log "\e[32mBereinigung wird gestartet...\e[0m" >&2
            # Jede Clean-Funktion mit Fehlerprüfung
            local clean_functions=(dataclean pathclean cacheclean logclean mapclean)
            for func in "${clean_functions[@]}"; do
                if ! command -v "$func" &>/dev/null; then
                    log "\e[31mFehler: '$func' ist keine gültige Funktion!\e[0m" >&2
                    return 1
                fi
                "$func" || {
                    log "\e[31mFehler bei $func!\e[0m" >&2
                    return 1
                }
            done
            log "\e[32mBereinigung abgeschlossen.\e[0m" >&2
            ;;
        *)
            log "\e[33mAbbruch: Bereinigung wurde nicht durchgeführt.\e[0m" >&2
            return 1
            ;;
    esac
    blankline
}

function clean_linux_logs() {
    local log_files=()
    log "${COLOR_SECTION}${SYM_LOG} Suche nach alten Log-Dateien...${COLOR_RESET}"
    
    # Find and list files to be deleted
    while IFS= read -r -d $'\0' file; do
        log_files+=("$file")
        log "${COLOR_FILE}${SYM_INFO} ${COLOR_LABEL}Gelöscht wird:${COLOR_RESET} ${COLOR_VALUE}$file${COLOR_RESET}"
    done < <(find "/var/log" -name "*.log" -type f -mtime +7 -print0)
    
    if [ ${#log_files[@]} -eq 0 ]; then
        log "${SYM_OK} ${COLOR_LABEL}Keine alten Log-Dateien gefunden.${COLOR_RESET}"
        return 0
    fi
    
    log "${COLOR_WARNING}${#log_files[@]} Log-Dateien werden gelöscht. Fortfahren? (j/N) ${COLOR_RESET}" 
    read -r confirm
    case "${confirm,,}" in
        j|ja|y|yes)
            find "/var/log" -name "*.log" -type f -mtime +7 -delete
            log "${SYM_OK} ${COLOR_OK}${#log_files[@]} Log-Dateien wurden gelöscht.${COLOR_RESET}"
            ;;
        *)
            log "${SYM_BAD} ${COLOR_BAD}Bereinigung abgebrochen.${COLOR_RESET}"
            return 1
            ;;
    esac
}

function delete_opensim() {
    log "${COLOR_HEADING}🗺️ Das komplette löschen vom OpenSimulator wird durchgeführt...${COLOR_RESET}"

    # Sicherheitsabfrage hinzufügen
    read -rp "Sind Sie sicher, dass Sie ALLE OpenSimulator-Daten löschen möchten? (ja/N) " answer
    [[ ${answer,,} != "ja" ]] && { echo "Abbruch."; return 1; }

    # Robust-Verzeichnis sicher löschen
    if [[ -d "robust" ]]; then
        rm -rf -- "robust"  # Keine Wildcard mehr
        log "${SYM_OK} ${COLOR_ACTION}robust komplett entfernt${COLOR_RESET}"
    fi

    # Simulator-Verzeichnisse sicher löschen
    for ((i=1; i<=999; i++)); do
        local sim_dir="sim$i"
        if [[ -d "$sim_dir" ]]; then
            rm -rf -- "$sim_dir"  # Keine Wildcard mehr
            log "${SYM_OK} ${COLOR_ACTION}${COLOR_DIR}$sim_dir${COLOR_RESET} ${COLOR_ACTION}komplett entfernt${COLOR_RESET}"
            sleep 1
        fi
    done

    log "${COLOR_HEADING}${SYM_OKNN} Das komplette löschen vom OpenSimulator abgeschlossen${COLOR_RESET}"
    blankline
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Konfigurationen
#?──────────────────────────────────────────────────────────────────────────────────────────

# [Abschnitt]
# 	Schlüssel = Wert
# 	; Kommentar
# [Section]
# 	Key = Value
# 	; Comment

# Überprüft, ob ein bestimmter Abschnitt (Section) in einer INI-Datei existiert, und gibt das Ergebnis als Exit-Code zurück.
# Aufruf: bash osmtool.sh verify_ini_section "test.ini" "Const"
# Letzte Prüfung am: 24.04.2025
function verify_ini_section() {
    local file="$1"
    local section="$2"
    
    if [ ! -f "$file" ]; then
        log "${SYM_BAD} Error: File ${file} does not exist" >&2
        return 2
    fi
    
    if grep -q "^\[${section}\]" "$file"; then
        log "${SYM_OK} Section [${section}] exists in ${file}"
        return 0
    else
        log "${SYM_BAD} Section [${section}] not found in ${file}"
        return 1
    fi
}

# Überprüft, ob ein bestimmten Wert (key) im Abschnitt (Section) in einer INI-Datei existiert, und gibt das Ergebnis als Exit-Code zurück.
# Aufruf: bash osmtool.sh verify_ini_key "test.ini" "DatabaseService" "Include-Storage"
# Letzte Prüfung am: 24.04.2025 Repariert: 24.04.2025
function verify_ini_key() {
    local file="$1"
    local section="$2"
    local key="$3"
    
    if [ ! -f "$file" ]; then
        log "${SYM_BAD} Error: File ${file} does not exist" >&2
        return 2
    fi
    
    # Einfacher grep-Befehl, der Leerzeichen & Kommentare ignoriert
    if grep -Eq "^[[:space:]]*\[${section}\][[:space:]]*$" "$file" && \
       grep -Eq "^[[:space:]]*${key}[[:space:]]*=" "$file"; then
        log "${SYM_OK} Key '${key}' exists in section [${section}]"
        return 0
    else
        log "${SYM_BAD} Key '${key}' NOT FOUND in section [${section}]" >&2
        return 1
    fi
}

# Fügt einene Abschnitt hinzu, wenn es noch nicht vorhanden ist am ende der Datei.
# Aufruf: bash osmtool.sh add_ini_section "test.ini" "Const"
# Letzte Prüfung am: 24.04.2025 
function add_ini_section() {
    local file="$1"
    local section="$2"
    
    if verify_ini_section "$file" "$section" >/dev/null; then
        return 0
    fi
    
    log "${SYM_INFO} Adding section [${section}] to ${file}"
    
    # Abschnitt am Ende der Datei hinzufügen
    if printf "\n[%s]\n" "$section" >> "$file"; then
        log "${SYM_OK} Successfully added section [${section}] to ${file}"
        return 0
    else
        log "${SYM_BAD} Failed to add section [${section}] to ${file}" >&2
        return 1
    fi
}

# Fügt einene Abschnitt, wenn es noch nicht vorhanden ist vor dem Zielabschnitt hinzu.
# Also [Const] wird vor [DatabaseService] hinzugefügt.
# Aufruf: bash osmtool.sh add_ini_before_section "test.ini" "Const" "DatabaseService"
function add_ini_before_section() {
    local file="$1"
    local section="$2"
    local target_section="$3"  # Neuer Parameter für den Zielabschnitt

    if verify_ini_section "$file" "$section" >/dev/null; then
        return 0
    fi

    #log "${SYM_INFO} Adding section [${section}] to ${file} before [${target_section}]"

    # Temporäre Datei erstellen
    temp_file=$(mktemp)

    # Zielabschnitt suchen und neuen Abschnitt davor einfügen
    local found=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^\[${target_section}\] ]]; then
            printf "[%s]\n\n" "$section" >> "$temp_file"
            found=1
        fi
        echo "$line" >> "$temp_file"
    done < "$file"

    # Falls Zielabschnitt nicht gefunden, am Ende einfügen (Fallback)
    if [[ $found -eq 0 ]]; then
        printf "\n[%s]\n" "$section" >> "$temp_file"
        log "${SYM_WARNING} Target section [${target_section}] not found, appended [${section}] at end of file"
    fi

    # Originaldatei ersetzen
    if mv "$temp_file" "$file"; then
        log "${SYM_OK} Successfully added section [${section}] to ${file}"
        return 0
    else
        log "${SYM_BAD} Failed to update ${file}" >&2
        return 1
    fi
}

# Setzt den Wert des Keys in der gegebenen Sektion
#     bash osmtool.sh set_ini_key "test.ini" "Const" "GridSize" "256"
#     [Const]
#     GridSize = 256
#
#     Wenn die Sektion oder der Key nicht vorhanden ist, wird er hinzugefügt.
#     Falls der Key bereits vorhanden ist, wird der Wert aktualisiert.
function set_ini_key() {
    local file="$1" section="$2" key="$3" value="$4"
    local temp_file
    temp_file=$(mktemp) || {
        log "${COLOR_BAD}Fehler beim Erstellen der temporären Datei${COLOR_RESET}" >&2
        return 1
    }

    # Key für Regex absichern
    local key_escaped
    key_escaped=$(printf '%s\n' "$key" | sed 's/[]\/$*.^[]/\\&/g')

    # Verarbeitung mit awk
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
        log "${COLOR_BAD}AWK-Verarbeitung fehlgeschlagen${COLOR_RESET}" >&2
        rm -f "$temp_file"
        return 1
    }

    if ! mv "$temp_file" "$file"; then
        log "${COLOR_BAD}Konnte Datei ${COLOR_FILE}${file}${COLOR_RESET} nicht aktualisieren" >&2
        rm -f "$temp_file"
        return 1
    fi

    log "${COLOR_OK}Gesetzt: ${COLOR_KEY}${key} = ${COLOR_VALUE}${value}${COLOR_OK} in [${section}]${COLOR_RESET}"
    return 0
}

# Setze einen Key in einer INI-Datei
# Die INI-Datei wird nach dem Schlüssel durchsucht und der Key wird
# am passenden Ort eingefügt.
function add_ini_key() {
    local file="$1" section="$2" key="$3" value="$4"
    local temp_file
    temp_file=$(mktemp) || { 
        log "${COLOR_BAD}Failed to create temp file${COLOR_RESET}" >&2
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
        log "${COLOR_BAD}AWK processing failed${COLOR_RESET}" >&2
        rm -f "$temp_file"
        return 1
    fi

    if ! mv "$temp_file" "$file"; then
        log "${COLOR_BAD}Failed to update ${COLOR_FILE}${file}${COLOR_RESET}" >&2
        return 1
    fi

    log "${COLOR_OK}Set ${COLOR_KEY}${key} = ${COLOR_VALUE}${value}${COLOR_OK} in [${section}]${COLOR_RESET}"
    return 0
}

function del_ini_section() {
    local file="$1"
    local section="$2"
    
    # Verifizieren ob der Abschnitt existiert (still, ohne Ausgabe)
    if ! verify_ini_section "$file" "$section" >/dev/null; then
        log "${SYM_INFO} Section [${section}] not found in ${COLOR_FILE}${file}${COLOR_RESET}"
        return 0
    fi
    
    log "${SYM_INFO} Removing section [${COLOR_SECTION}${section}${COLOR_RESET}] from ${COLOR_FILE}${file}${COLOR_RESET}"
    
    # Temporäre Datei mit Fehlerbehandlung
    local temp_file
    temp_file=$(mktemp) || {
        log "${SYM_BAD} Failed to create temporary file" >&2
        return 1
    }
    
    # Abschnitt entfernen
    if awk -v section="[${section}]" '
        $0 == section { skip=1; next }
        skip && /^\[/ { skip=0 }
        !skip { print }
    ' "$file" > "$temp_file"; then
        
        if mv "$temp_file" "$file"; then
            log "${SYM_OK} Successfully removed section [${COLOR_SECTION}${section}${COLOR_RESET}]"
            return 0
        else
            log "${SYM_BAD} Failed to update ${COLOR_FILE}${file}${COLOR_RESET}" >&2
            rm -f "$temp_file"
            return 1
        fi
        
    else
        log "${SYM_BAD} AWK processing failed" >&2
        rm -f "$temp_file"
        return 1
    fi
}

function uncomment_ini_line() {
    local file="$1"
    local search_key="$2"
    
    # Sicherheitsprüfungen
    [ ! -f "$file" ] && { log "${COLOR_BAD}Datei nicht gefunden: ${file}${COLOR_RESET}" >&2; return 1; }
    [ -z "$search_key" ] && { log "${COLOR_BAD}Suchschlüssel darf nicht leer sein${COLOR_RESET}" >&2; return 1; }

    # Temporäre Datei erstellen
    local temp_file
    temp_file=$(mktemp) || { log "${COLOR_BAD}Temp-Datei konnte nicht erstellt werden${COLOR_RESET}" >&2; return 1; }

    # Entkommentieren der Zeile
    sed -E "/^[[:space:]]*;[[:space:]]*${search_key}[[:space:]]*=/s/^[[:space:]]*;//" "$file" > "$temp_file" || {
        rm -f "$temp_file"
        log "${COLOR_BAD}Sed-Verarbeitung fehlgeschlagen${COLOR_RESET}" >&2
        return 1
    }

    # Originaldatei ersetzen
    if mv "$temp_file" "$file"; then
        log "${COLOR_OK}Zeile '${search_key}' erfolgreich entkommentiert${COLOR_RESET}"
        return 0
    else
        log "${COLOR_BAD}Datei konnte nicht aktualisiert werden${COLOR_RESET}" >&2
        return 1
    fi
}

function uncomment_ini_section_line() {
    local file="$1"
    local section="$2"
    local search_key="$3"

    # Sicherheitsprüfungen
    [ ! -f "$file" ] && { log "${COLOR_BAD}Datei nicht gefunden: ${file}${COLOR_RESET}" >&2; return 1; }
    [ -z "$section" ] && { log "${COLOR_BAD}Sektion darf nicht leer sein${COLOR_RESET}" >&2; return 1; }
    [ -z "$search_key" ] && { log "${COLOR_BAD}Suchschlüssel darf nicht leer sein${COLOR_RESET}" >&2; return 1; }

    # Temporäre Datei erstellen
    local temp_file
    temp_file=$(mktemp) || { log "${COLOR_BAD}Temp-Datei konnte nicht erstellt werden${COLOR_RESET}" >&2; return 1; }

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
        log "${COLOR_BAD}AWK-Verarbeitung fehlgeschlagen${COLOR_RESET}" >&2
        return 1
    }

    # Originaldatei ersetzen
    if mv "$temp_file" "$file"; then
        log "${COLOR_OK}Zeile '${search_key}' in Sektion '${section}' erfolgreich entkommentiert${COLOR_RESET}"
        return 0
    else
        log "${COLOR_BAD}Datei konnte nicht aktualisiert werden${COLOR_RESET}" >&2
        return 1
    fi
}
function comment_ini_line() {
    local file="$1"
    local section="$2"
    local search_key="$3"

    # Sicherheitsprüfungen
    [ ! -f "$file" ] && { log "${COLOR_BAD}Datei nicht gefunden: ${file}${COLOR_RESET}" >&2; return 1; }
    [ -z "$section" ] && { log "${COLOR_BAD}Sektion darf nicht leer sein${COLOR_RESET}" >&2; return 1; }
    [ -z "$search_key" ] && { log "${COLOR_BAD}Suchschlüssel darf nicht leer sein${COLOR_RESET}" >&2; return 1; }

    # Temporäre Datei erstellen
    local temp_file
    temp_file=$(mktemp) || { log "${COLOR_BAD}Temp-Datei konnte nicht erstellt werden${COLOR_RESET}" >&2; return 1; }

    # Zeile in der richtigen Sektion kommentieren
    awk -v section="[$section]" -v key="$search_key" '
    BEGIN { in_section = 0 }
    $0 ~ "^\\[" section "\\]" { in_section = 1; print; next }
    in_section && /^\[/ { in_section = 0 }
    in_section && $0 ~ key && !/^[[:space:]]*;/ {
        # Nur nicht bereits kommentierte Zeilen kommentieren
        sub(/^[[:space:]]*/, "&;", $0)
        print $0
        next
    }
    { print }
    ' "$file" > "$temp_file" || {
        rm -f "$temp_file"
        log "${COLOR_BAD}AWK-Verarbeitung fehlgeschlagen${COLOR_RESET}" >&2
        return 1
    }

    # Originaldatei ersetzen
    if mv "$temp_file" "$file"; then
        log "${COLOR_OK}Zeile '${search_key}' in Sektion '${section}' erfolgreich kommentiert${COLOR_RESET}"
        return 0
    else
        log "${COLOR_BAD}Datei konnte nicht aktualisiert werden${COLOR_RESET}" >&2
        return 1
    fi
}

function clear_ini_section() {
    local file="$1"
    local section="$2"

    # Sicherheitsprüfungen
    [ ! -f "$file" ] && { log "${COLOR_BAD}Datei nicht gefunden: ${file}${COLOR_RESET}" >&2; return 1; }
    [ -z "$section" ] && { log "${COLOR_BAD}Sektion darf nicht leer sein${COLOR_RESET}" >&2; return 1; }

    # Temporäre Datei erstellen
    local temp_file
    temp_file=$(mktemp) || { log "${COLOR_BAD}Temp-Datei konnte nicht erstellt werden${COLOR_RESET}" >&2; return 1; }

    # AWK zum Leeren der Sektion (behält Header)
    awk -v section="$section" '
    BEGIN { in_section = 0 }
    
    # Sektionsanfang erkennen
    $0 ~ "^\\[" section "\\]" {
        in_section = 1
        print $0  # Header ausgeben
        next
    }
    
    # Sektionsende erkennen
    in_section && /^\[/ {
        in_section = 0
    }
    
    # Innerhalb der Sektion: nichts ausgeben (löschen)
    in_section { next }
    
    # Außerhalb der Sektion: normale Ausgabe
    { print }
    ' "$file" > "$temp_file"

    # Originaldatei ersetzen
    if mv "$temp_file" "$file"; then
        log "${COLOR_OK}Sektion '[${section}]' erfolgreich geleert${COLOR_RESET}"
        return 0
    else
        log "${COLOR_BAD}Datei konnte nicht aktualisiert werden${COLOR_RESET}" >&2
        return 1
    fi
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Konfigurationen der einzelnen Dienste
#?──────────────────────────────────────────────────────────────────────────────────────────

# [Abschnitt]
# 	Schlüssel = Wert
# 	; Kommentar
# [Section]
# 	Key = Value
# 	; Comment


function database_set_iniconfig() {
    # 30.04.2025
    local ini_file="${SCRIPT_DIR}/UserInfo.ini"
    local section="DatabaseService"

    # Zugangsdaten auslesen
    local db_user db_pass
    # Zeilenumbrüche entfernen
    db_user=$(grep -oP '^DB_Benutzername\s*=\s*\K\S+' "$ini_file" | tr -d '\r\n')
    db_pass=$(grep -oP '^DB_Passwort\s*=\s*\K\S+' "$ini_file" | tr -d '\r\n')


    if [[ -z "$db_user" || -z "$db_pass" ]]; then
        log "${COLOR_BAD}DB_Benutzername oder DB_Passwort fehlt in UserInfo.ini${COLOR_RESET}"
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
        log "${COLOR_WARNING}Datei nicht gefunden: $robust_hg_ini${COLOR_RESET}"
    fi

    # Robust.local.ini
    local robust_ini="robust/bin/Robust.local.ini"
    if [[ -f "$robust_ini" ]]; then
        add_ini_key "$robust_ini" "$section" "ConnectionString" "\"$robust_conn\""
    else
        log "${COLOR_WARNING}Datei nicht gefunden: $robust_ini${COLOR_RESET}"
    fi

    # === simX-Datenbanken ===
    for ((i=1; i<=1000; i++)); do
        local sim_ini="${SCRIPT_DIR}/sim${i}/bin/config-include/GridCommon.ini"
        if [[ -f "$sim_ini" ]]; then
            local sim_conn="Data Source=localhost;Database=sim${i};User ID=${db_user};Password=${db_pass};Old Guids=true;SslMode=None;"
            add_ini_key "$sim_ini" "$section" "ConnectionString" "\"$sim_conn\""
        fi
    done

    log "${COLOR_OK}Datenbanken erfolgreich konfiguriert${COLOR_RESET}"
    blankline
}



# Welcome-Region konfigurieren wenn sie noch nicht existiert.
function welcomeiniconfig() {
    # 25.04.2025
    local ip="$1"
    gridname="$2"

    # Gridname bereinigen
    gridname=$(echo "$gridname" | sed -e 's/ä/ae/g' -e 's/ö/oe/g' -e 's/ü/ue/g' -e 's/[-&]/_/g' -e 's/  */_/g' -e 's/__\+/_/g')
    
    local welcome_ini="${SCRIPT_DIR}/sim1/bin/Regions/$gridname.ini"
    
    # Überprüfen ob die Welcome-Region bereits existiert
    if [[ -f "$welcome_ini" ]]; then
        log "${COLOR_INFO}Überspringe Erstellung der Welcome-Region: '$gridname.ini' existiert bereits${COLOR_RESET}"
        # Vorsichtshalber Region in Robust-Konfigurationen eintragen.
        set_ini_key "${SCRIPT_DIR}/robust/bin/Robust.HG.ini" "GridService" "Region_$gridname" "\"DefaultRegion, DefaultHGRegion, FallbackRegion\""
        set_ini_key "${SCRIPT_DIR}/robust/bin/Robust.local.ini" "GridService" "Region_$gridname" "\"DefaultRegion, FallbackRegion\""
        return
    fi
    
    # region_uuid=$(uuidgen)
    #region_uuid=$(command -v uuidgen >/dev/null && uuidgen || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$RANDOM-$RANDOM-$RANDOM-$RANDOM")
    region_uuid=$(command -v uuidgen >/dev/null 2>&1 && uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$RANDOM-$RANDOM-$RANDOM-$RANDOM")
    
    # Datei erstellen
    #touch "$welcome_ini"
    #touch "$welcome_ini" || echo "" > "$welcome_ini"
    touch "$welcome_ini" 2>/dev/null || echo "" > "$welcome_ini"
    
    # 2. Sektion hinzufügen
    add_ini_section "$welcome_ini" "$gridname"
    
    # 3. Alle Key-Value Paare setzen
    set_ini_key "$welcome_ini" "$gridname" "RegionUUID" "$region_uuid"
    set_ini_key "$welcome_ini" "$gridname" "Location" "3000,3000"
    set_ini_key "$welcome_ini" "$gridname" "SizeX" "256"
    set_ini_key "$welcome_ini" "$gridname" "SizeY" "256"
    set_ini_key "$welcome_ini" "$gridname" "SizeZ" "256"
    set_ini_key "$welcome_ini" "$gridname" "InternalPort" "9015"
    set_ini_key "$welcome_ini" "$gridname" "ExternalHostName" "$system_ip"
    set_ini_key "$welcome_ini" "$gridname" "MaxPrims" "15000"
    set_ini_key "$welcome_ini" "$gridname" "MaxAgents" "40"
    set_ini_key "$welcome_ini" "$gridname" "MaptileStaticUUID" "$region_uuid"
    set_ini_key "$welcome_ini" "$gridname" "InternalAddress" "0.0.0.0"
    set_ini_key "$welcome_ini" "$gridname" "AllowAlternatePorts" "False"
    
    set_ini_key "$welcome_ini" "$gridname" ";NonPhysicalPrimMax" "512"
    set_ini_key "$welcome_ini" "$gridname" ";PhysicalPrimMax" "128"
    set_ini_key "$welcome_ini" "$gridname" ";ClampPrimSize" "false"
    set_ini_key "$welcome_ini" "$gridname" ";MaxPrimsPerUser" "-1"
    set_ini_key "$welcome_ini" "$gridname" ";ScopeID" "$region_uuid"
    set_ini_key "$welcome_ini" "$gridname" ";RegionType" "Mainland"
    set_ini_key "$welcome_ini" "$gridname" ";RenderMinHeight" "-1"
    set_ini_key "$welcome_ini" "$gridname" ";RenderMaxHeight" "100"
    set_ini_key "$welcome_ini" "$gridname" ";MapImageModule" "Warp3DImageModule"
    set_ini_key "$welcome_ini" "$gridname" ";TextureOnMapTile" "true"
    set_ini_key "$welcome_ini" "$gridname" ";DrawPrimOnMapTile" "true"
    set_ini_key "$welcome_ini" "$gridname" ";GenerateMaptiles" "true"
    set_ini_key "$welcome_ini" "$gridname" ";MaptileRefresh" "0"
    set_ini_key "$welcome_ini" "$gridname" ";MaptileStaticFile" "path/to/SomeFile.png"
    set_ini_key "$welcome_ini" "$gridname" ";MasterAvatarFirstName" "John"
    set_ini_key "$welcome_ini" "$gridname" ";MasterAvatarLastName" "Doe"
    set_ini_key "$welcome_ini" "$gridname" ";MasterAvatarSandboxPassword" "passwd"

    # 4. Region in Robust-Konfigurationen eintragen
    # DefaultRegion, DefaultHGRegion, FallbackRegion, NoDirectLogin, Persistent, LockedOut, Reservation, NoMove, Authenticate
    set_ini_key "${SCRIPT_DIR}/robust/bin/Robust.HG.ini" "GridService" "Region_$gridname" "\"DefaultRegion, DefaultHGRegion, FallbackRegion\""
    set_ini_key "${SCRIPT_DIR}/robust/bin/Robust.local.ini" "GridService" "Region_$gridname" "\"DefaultRegion, FallbackRegion\""

    log "${COLOR_OK}Welcome_Area.ini Konfiguration abgeschlossen für $gridname${COLOR_RESET}"
    blankline
}

function moneyserveriniconfig() {
    # 30.04.2025
    local ip="$1"
    gridname="$2"

    # Gridname bereinigen
    gridname=$(echo "$gridname" | sed -e 's/ä/ae/g' -e 's/ö/oe/g' -e 's/ü/ue/g' -e 's/[-&]/_/g' -e 's/  */_/g' -e 's/__\+/_/g')
    
    # Zugangsdaten aus UserInfo.ini laden
    local ini_file="${SCRIPT_DIR}/UserInfo.ini"
    local db_user db_pass
    db_user=$(grep -oP '^DB_Benutzername\s*=\s*\K\S+' "$ini_file")
    db_pass=$(grep -oP '^DB_Passwort\s*=\s*\K\S+' "$ini_file")

    # Falls keine Benutzer- und Passwortwerte gelesen wurden, abbrechen
    if [[ -z "$db_user" || -z "$db_pass" ]]; then
        log "${COLOR_BAD}Fehler: DB_Benutzername oder DB_Passwort fehlen in UserInfo.ini${COLOR_RESET}"
        return 1
    fi

    local dir="$SCRIPT_DIR/robust/bin"
    local file="$dir/MoneyServer.ini"

    # Sicherstellen, dass die Vorlage existiert
    if [[ ! -f "$file.example" ]]; then
        log "${COLOR_BAD}FEHLER: Konfigurationsvorlage '$file.example' fehlt!${COLOR_RESET}" >&2
        exit 1  
    fi

    # Kopieren der Vorlage
    cp "$file.example" "$file" || {
        log "${COLOR_BAD}FEHLER: Konnte '$file' nicht erstellen${COLOR_RESET}" >&2
        exit 1
    }

    # [Startup]
    set_ini_key "$file" "Startup" "PIDFile" "\"/tmp/MoneyServer.exe.pid\""

    # [MySql] → Daten aus UserInfo.ini verwenden
    set_ini_key "$file" "MySql" "hostname" "\"localhost\""
    set_ini_key "$file" "MySql" "database" "\"robust\""
    set_ini_key "$file" "MySql" "username" "\"$db_user\""
    set_ini_key "$file" "MySql" "password" "\"$db_pass\""
    set_ini_key "$file" "MySql" "pooling" "\"true\""
    set_ini_key "$file" "MySql" "port" "\"3306\""
    set_ini_key "$file" "MySql" "MaxConnection" "\"25\""

    # [MoneyServer]
    set_ini_key "$file" "MoneyServer" "ServerPort" "\"8008\""
    set_ini_key "$file" "MoneyServer" "CurrencyOnOff" "\"on\""
    set_ini_key "$file" "MoneyServer" "CurrencyMaximum" "\"20000\""
    set_ini_key "$file" "MoneyServer" "MoneyServerIPaddress" "\"http://$ip:8008\""
    set_ini_key "$file" "MoneyServer" "DefaultBalance" "\"1000\""

    # [Certificate]
    set_ini_key "$file" "Certificate" "CheckClientCert" "\"false\""
    set_ini_key "$file" "Certificate" "CheckServerCert" "\"false\""

    log "${COLOR_OK}MoneyServer.ini Konfiguration abgeschlossen${COLOR_RESET}"
    blankline
}


# Konfiguriert OpenSim.ini für alle sim1 bis sim99-Verzeichnisse
function opensiminiconfig() {
    # 24.04.2025
    local ip="$1"
    local gridname="$2"
    local base_port=9010
    local sim_counter=1

    # Gridname bereinigen
    gridname=$(echo "$gridname" | sed -e 's/ä/ae/g' -e 's/ö/oe/g' -e 's/ü/ue/g' -e 's/[-&]/_/g' -e 's/  */_/g' -e 's/__\+/_/g')

    # Iteration über alle sim1 bis sim99 Verzeichnisse
    for i in $(seq 1 99); do
        sim_dir="$SCRIPT_DIR/sim$i"
        if [[ -d "$sim_dir/bin" ]]; then
            local dir="$sim_dir/bin"
            local file="$dir/OpenSim.ini"

            if [[ ! -f "$file.example" ]]; then
                echo "FEHLER: Konfigurationsvorlage '$file.example' fehlt!" >&2
                echo "Das Programm benötigt diese Datei zum Starten." >&2
                exit 1  # Programm mit Fehlercode beenden
            fi

            # Nur wenn Vorlage existiert: Kopieren
            cp "$file.example" "$file" || {
                echo "FEHLER: Konnte '$file' nicht erstellen" >&2
                exit 1
            }

            sleep 1

            log "${COLOR_INFO}Konfiguriere OpenSim.ini in $dir${COLOR_RESET}"

            # Portberechnung pro Instanz
            local public_port=$((base_port + (sim_counter - 1) * 100))

            # Werte setzen
            # [Const]
            set_ini_key "$file" "Const" "BaseHostname" "$ip"            
            set_ini_key "$file" "Const" "PublicPort" "8002"

            # [Startup]
            #uncomment_ini_section_line "$file" "Startup" "PIDFile"
            set_ini_key "$file" "Startup" "PIDFile" "\"/tmp/OpenSim.$i.exe.pid\""

            # [Estates]
            #set_ini_key "$file" "Estates" "DefaultEstateName" "$gridname Estate"
            #set_ini_key "$file" "Estates" "DefaultEstateOwnerName" "$VORNAME $NACHNAME"

            # [Network]
            # http_listener_port = 9010
            uncomment_ini_section_line "$file" "Network" "http_listener_port"
            set_ini_key "$file" "Network" "http_listener_port" "$public_port"

            # [SimulatorFeatures]
            uncomment_ini_line "$file" "SearchServerURI"

            # [ClientStack.LindenUDP] Begrenzt die Viewer damit sie die Server leistung nicht kippen können.
            set_ini_key "$file" "ClientStack.LindenUDP" "DisableFacelights" "true"
            # 10.000.000 bps = 10 Mbit/s pro Client gute Einstellung ist "350.000" bis "500.000"
            set_ini_key "$file" "ClientStack.LindenUDP" "client_throttle_max_bps" "350000"
            # 10.000.000 bps = 10 Mbit/s pro Region "70.000.000" gute Einstellung ist "70.000.000" bis "1.000.000.000"
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
            set_ini_key "$file" "Economy" "CheckServerCert" "false"
            set_ini_key "$file" "Economy" "PriceUpload" "0"
            set_ini_key "$file" "Economy" "MeshModelUploadCostFactor" "1.0"
            set_ini_key "$file" "Economy" "MeshModelUploadTextureCostFactor" "1.0"
            set_ini_key "$file" "Economy" "MeshModelMinCostFactor" "1.0"
            set_ini_key "$file" "Economy" "PriceGroupCreate" "0"
            set_ini_key "$file" "Economy" "ObjectCount" "0"
            set_ini_key "$file" "Economy" "PriceEnergyUnit" "0"
            set_ini_key "$file" "Economy" "PriceObjectClaim" "0"
            set_ini_key "$file" "Economy" "PricePublicObjectDecay" "0"
            set_ini_key "$file" "Economy" "PricePublicObjectDelete" "0"
            set_ini_key "$file" "Economy" "PriceParcelClaim" "0"
            set_ini_key "$file" "Economy" "PriceParcelClaimFactor" "1"
            set_ini_key "$file" "Economy" "PriceRentLight" "0"
            set_ini_key "$file" "Economy" "TeleportMinPrice" "0"
            set_ini_key "$file" "Economy" "TeleportPriceExponent" "2"
            set_ini_key "$file" "Economy" "EnergyEfficiency" "1"
            set_ini_key "$file" "Economy" "PriceObjectRent" "0"
            set_ini_key "$file" "Economy" "PriceObjectScaleFactor" "10"
            set_ini_key "$file" "Economy" "PriceParcelRent" "0"

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
            sleep 1
        fi
    done

    log "${COLOR_OK}${sim_counter} Simulationen konfiguriert.${COLOR_RESET}"
    blankline
}

# Konfiguration von Robust.HG.ini im robust/bin Verzeichnis
function robusthginiconfig() {
    # 23.04.2025
    local ip="$1"
    local gridname="$2"
    local dir="$SCRIPT_DIR/robust/bin"
    local file="$dir/Robust.HG.ini"
    webverzeichnis="oswebinterface"

    # Gridname bereinigen
    gridname=$(echo "$gridname" | sed -e 's/ä/ae/g' -e 's/ö/oe/g' -e 's/ü/ue/g' -e 's/[-&]/_/g' -e 's/  */_/g' -e 's/__\+/_/g')

    if [[ ! -f "$file.example" ]]; then
        echo "FEHLER: Konfigurationsvorlage '$file.example' fehlt!" >&2
        echo "Das Programm benötigt diese Datei zum Starten." >&2
        exit 1  # Programm mit Fehlercode beenden
    fi

    # Nur wenn Vorlage existiert: Kopieren
    cp "$file.example" "$file" || {
        echo "FEHLER: Konnte '$file' nicht erstellen" >&2
        exit 1
    }

    # [Const]
    set_ini_key "$file" "Const" "BaseHostname" "$ip"

    # [Startup]
    # PID-Dateien gehören grundsätzlich in /tmp warum: tmp Wird beim Neustart automatisch geleert. Keine Berechtigungsprobleme (normalerweise schreibbar für alle).
    # Standard-PID-Datei: /tmp/Robust.exe.pid
    uncomment_ini_line "$file" "PIDFile"

    # [ServiceList]
    uncomment_ini_line "$file" "OfflineIMServiceConnector"
    uncomment_ini_line "$file" "GroupsServiceConnector"
    uncomment_ini_line "$file" "BakedTextureService"
    uncomment_ini_line "$file" "UserProfilesServiceConnector"
    uncomment_ini_line "$file" "HGGroupsServiceConnector"

    # [Network]
    
    # [Hypergrid]
    uncomment_ini_line "$file" "HomeURI"
    uncomment_ini_line "$file" "GatekeeperURI"
        
    # [DatabaseService] wird in database_set_iniconfig eingetragen.

    # [GridService] für osWebinterface
    uncomment_ini_line "$file" "MapTileDirectory"
    
    # [LoginService] für osWebinterface etc. "\${Const|BaseURL}:\${Const|PublicPort}"    
    uncomment_ini_line "$file" "SearchURL"
    uncomment_ini_line "$file" "DestinationGuide"
    uncomment_ini_line "$file" "AvatarPicker"
    uncomment_ini_line "$file" "MinLoginLevel"
    uncomment_ini_line "$file" "Currency"
    uncomment_ini_line "$file" "ClassifiedFee"

    set_ini_key "$file" "LoginService" "WelcomeMessage" "\"Willkommen im $gridname!\""
    set_ini_key "$file" "LoginService" "MapTileURL" "\"\${Const|BaseURL}:\${Const|PublicPort}/\""
    set_ini_key "$file" "LoginService" "SearchURL" "\"\${Const|BaseURL}:\${Const|PublicPort}/$webverzeichnis/searchservice.php\""
	set_ini_key "$file" "LoginService" "DestinationGuide" "\"\${Const|BaseURL}/$webverzeichnis/guide.php\""
	set_ini_key "$file" "LoginService" "AvatarPicker" "\"\${Const|BaseURL}/$webverzeichnis/avatarpicker.php\""    
    set_ini_key "$file" "LoginService" "Currency" "\"OS$\""
    set_ini_key "$file" "LoginService" "DSTZone" "\"local\""

    # [GatekeeperService]
    uncomment_ini_line "$file" "ExternalName"
    
    # [GridInfoService]
    set_ini_key "$file" "GridInfoService" "gridname" "\"$gridname\""
    set_ini_key "$file" "GridInfoService" "gridnick" "\"$gridname\""
    set_ini_key "$file" "GridInfoService" "welcome" "\"\${Const|BaseURL}/$webverzeichnis/welcomesplashpage.php\""
    set_ini_key "$file" "GridInfoService" "economy" "\"\${Const|BaseURL}:8008/\""
    set_ini_key "$file" "GridInfoService" "about" "\"\${Const|BaseURL}/$webverzeichnis/aboutinformation.php\""
    set_ini_key "$file" "GridInfoService" "register" "\"\${Const|BaseURL}/$webverzeichnis/createavatar.php\""
    set_ini_key "$file" "GridInfoService" "help" "\"\${Const|BaseURL}/$webverzeichnis/help.php\""
    set_ini_key "$file" "GridInfoService" "password" "\"\${Const|BaseURL}/$webverzeichnis/passwordreset.php\""
    set_ini_key "$file" "GridInfoService" "GridStatusRSS" "\"\${Const|BaseURL}/$webverzeichnis/gridstatusrss.php\""

    # [UserAgentService]
    uncomment_ini_line "$file" "LevelOutsideContacts"
    uncomment_ini_line "$file" "ShowUserDetailsInHGProfile"

    # [Messaging]
    set_ini_key "$file" "Messaging" "MaxOfflineIMs" "250"

    # [Groups]
    set_ini_key "$file" "Groups" "MaxAgentGroups" "100"

    log "${COLOR_OK}Robust.HG.ini konfiguriert.${COLOR_RESET}"
    blankline
}

# Funktion zur Generierung eines 16-stelligen Passworts
function genPass() {
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16
}

# Funktion zum Ersetzen mit 5 Passwörtern
function replace_passwords() {
  local var_name="$1"
  local file="$2"

  # Neue Passwörter generieren
  local new_values
  new_values="\"$(genPass)\", \"$(genPass)\", \"$(genPass)\", \"$(genPass)\", \"$(genPass)\""

  # Debug (optional)
  echo "Ersetze $var_name in $file mit: [$new_values]"

  # sed: Zeile mit dem Variablennamen ersetzen (achtet auf Leerzeichen und flexible Schreibweise)
  sed -i "s|^\(\s*\$$var_name\s*=\s*\)\[.*\];|\1[$new_values];|" "$file"
}

function oswebinterfaceconfig() {
    # Konfigurationsdatei-Pfade
    webverzeichnis="oswebinterface"
    local ini_file="UserInfo.ini"  # Pfad zur INI-Datei mit Zugangsdaten
    local php_config_file="/var/www/html/$webverzeichnis/include/env.php"
    local config_example_file="/var/www/html/$webverzeichnis/include/config.example.php"
    local config_file="/var/www/html/$webverzeichnis/include/config.php"
    config_dir="$(dirname "$php_config_file")"

    # Prüfe, ob Konfigurationsverzeichnis existiert
    if [[ ! -d "$config_dir" ]]; then
        log "${SYM_BAD} ${COLOR_ERROR}Verzeichnis nicht gefunden: ${COLOR_DIR}$config_dir${COLOR_RESET}"
        return 1
    fi

    # Prüfe, ob INI-Datei existiert
    if [[ ! -f "$ini_file" ]]; then
        log "${SYM_BAD} ${COLOR_ERROR}Konfigurationsdatei nicht gefunden: ${COLOR_DIR}$ini_file${COLOR_RESET}"
        return 1
    fi

    # Zugangsdaten auslesen (mit Trimmen von Leerzeichen/Zeilenumbrüchen)
    local db_user db_pass server_ip grid_name # Daten für dev.php
    db_user=$(grep -oP '^DB_Benutzername\s*=\s*\K\S+' "$ini_file" | tr -d '\r\n')
    db_pass=$(grep -oP '^DB_Passwort\s*=\s*\K\S+' "$ini_file" | tr -d '\r\n')
    # Daten für config.php
    server_ip=$(grep -oP '^ServerIP\s*=\s*\K\S+' "$ini_file" | tr -d '\r\n')
    grid_name=$(grep -oP '^GridName\s*=\s*\K\S+' "$ini_file" | tr -d '\r\n')

    # Fallback, falls Werte leer sind
    [[ -z "$db_user" ]] && db_user="opensim_user"
    [[ -z "$db_pass" ]] && db_pass="opensim123"
    [[ -z "$server_ip" ]] && server_ip="localhost"
    [[ -z "$grid_name" ]] && grid_name="OpenSim Grid"

    # Neu generierter Name
    generate_name
    # Neue Region
    genHttpUserName="${gennamefirst}$((RANDOM % 900 + 100))"
    genHttpUserPass="${gennamesecond}$((RANDOM % 900 + 100))"
    echo "$genRegionName"
    region_name=${genRegionName}

    # PHP-Konfigurationsdatei generieren
    cat > "$php_config_file" <<EOF
<?php
define('DB_SERVER', 'localhost');
define('DB_USERNAME', '$db_user');
define('DB_PASSWORD', '$db_pass');
define('DB_NAME', 'robust');
define('DB_ASSET_NAME', 'robust');

define('REMOTEADMIN_HTTPAUTHUSERNAME', '${genHttpUserName}');
define('REMOTEADMIN_HTTPAUTHPASSWORD', '${genHttpUserPass}');
?>
EOF

    # config.example.php in config.php umbenennen, falls es existiert
    if [[ -f "$config_example_file" ]]; then
        #mv "$config_example_file" "$config_file"
        cp "$config_example_file" "$config_file"
        log "${SYM_OK} ${COLOR_ACTION}Konfigurationsdatei umbenannt: ${COLOR_DIR}$config_file${COLOR_RESET}"
        
        # Konfiguration in config.php einfügen
        if [[ -f "$config_file" ]]; then
            # BASE_URL ersetzen oder hinzufügen
            if grep -q "define('BASE_URL'" "$config_file"; then
                sed -i "s|define('BASE_URL'.*|define('BASE_URL', 'http://${server_ip}');|" "$config_file"
            else
                sed -i "/<?php/a define('BASE_URL', 'http://${server_ip}'); // Basis-URL der Webseite / Base URL of the website" "$config_file"
            fi
            
            # SITE_NAME ersetzen oder hinzufügen
            if grep -q "define('SITE_NAME'" "$config_file"; then
                sed -i "s|define('SITE_NAME'.*|define('SITE_NAME', '${grid_name}');|" "$config_file"
            else
                sed -i "/<?php/a define('SITE_NAME', '${grid_name}'); // Name des Grids / Name of the grid" "$config_file"
            fi

            # PASSWÖRTER ERSETZEN (NACH DEM BASE_URL/SITE_NAME BLOCK!)
            replace_passwords "registration_passwords_register" "$config_file"
            replace_passwords "registration_passwords_reset" "$config_file"
            replace_passwords "registration_passwords_partner" "$config_file"
            replace_passwords "registration_passwords_inventory" "$config_file"
            replace_passwords "registration_passwords_datatable" "$config_file"
            replace_passwords "registration_passwords_listinventar" "$config_file"
            replace_passwords "registration_passwords_picreader" "$config_file"
            replace_passwords "registration_passwords_mutelist" "$config_file"
            replace_passwords "registration_passwords_avatarpicker" "$config_file"
            replace_passwords "registration_passwords_economy" "$config_file"
            replace_passwords "registration_passwords_events" "$config_file"
            
            log "${SYM_OK} ${COLOR_ACTION}Konfiguration in ${COLOR_DIR}$config_file${COLOR_ACTION} eingetragen${COLOR_RESET}"
        fi
    else
        log "${SYM_INFO} ${COLOR_INFO}Konfigurationsvorlage nicht gefunden: ${COLOR_DIR}$config_example_file${COLOR_RESET}"
    fi

    # Berechtigungen anpassen (falls nötig)
    chmod 640 "$php_config_file"
    chown www-data:www-data "$php_config_file"  # Anpassen für deinen Webserver-User
    
    if [[ -f "$config_file" ]]; then
        chmod 640 "$config_file"
        chown www-data:www-data "$config_file"
    fi

    log "${SYM_OK} ${COLOR_ACTION}Konfiguration geschrieben nach: ${COLOR_DIR}$php_config_file${COLOR_RESET}"
    return 0
}

function robustiniconfig() {
    local ip="$1"
    local gridname="$2"
    local dir="$SCRIPT_DIR/robust/bin"
    local source_file="$dir/Robust.ini.example"
    local target_file="$dir/Robust.local.ini"

    # Gridname bereinigen
    gridname=$(echo "$gridname" | sed -e 's/ä/ae/g' -e 's/ö/oe/g' -e 's/ü/ue/g' -e 's/[-&]/_/g' -e 's/  */_/g' -e 's/__\+/_/g')

    if [[ ! -f "$source_file" ]]; then
        log "${COLOR_BAD}FEHLER: Konfigurationsvorlage '$source_file' fehlt!${COLOR_RESET}" >&2
        log "${COLOR_BAD}Das Programm benötigt diese Datei zum Starten.${COLOR_RESET}" >&2
        exit 1
    fi

    # Vorlage nach Robust.local.ini kopieren
    cp "$source_file" "$target_file" || {
        log "${COLOR_BAD}FEHLER: Konnte '$target_file' nicht erstellen${COLOR_RESET}" >&2
        exit 1
    }

    # [Const]
    set_ini_key "$target_file" "Const" "BaseHostname" "$ip"
    
    # [ServiceList]
    uncomment_ini_line "$target_file" "OfflineIMServiceConnector"
    uncomment_ini_line "$target_file" "GroupsServiceConnector"
    uncomment_ini_line "$target_file" "BakedTextureService"
    uncomment_ini_line "$target_file" "UserProfilesServiceConnector"
    
    # [LoginService] Konfiguration
    set_ini_key "$target_file" "LoginService" "Currency" "\"OS$\""
    set_ini_key "$target_file" "LoginService" "WelcomeMessage" "\"Willkommen im $gridname!\""
    set_ini_key "$target_file" "LoginService" "MapTileURL" "\"\${Const|BaseURL}:\${Const|PublicPort}/\""
    set_ini_key "$target_file" "LoginService" "SearchURL" "\"\${Const|BaseURL}/searchservice.php\""
    set_ini_key "$target_file" "LoginService" "DestinationGuide" "\"\${Const|BaseURL}/guide.php\""
    set_ini_key "$target_file" "LoginService" "AvatarPicker" "\"\${Const|BaseURL}/avatarpicker.php\""
    
    # [GridInfoService]
    set_ini_key "$target_file" "GridInfoService" "gridname" "\"$gridname\""
    set_ini_key "$target_file" "GridInfoService" "gridnick" "\"$gridname\""
    set_ini_key "$target_file" "GridInfoService" "welcome" "\"\${Const|BaseURL}/welcome\""
    set_ini_key "$target_file" "GridInfoService" "economy" "\"\${Const|BaseURL}:8008/\""
    set_ini_key "$target_file" "GridInfoService" "about" "\"\${Const|BaseURL}/about\""
    set_ini_key "$target_file" "GridInfoService" "register" "\"\${Const|BaseURL}/register\""
    set_ini_key "$target_file" "GridInfoService" "help" "\"\${Const|BaseURL}/help\""
    set_ini_key "$target_file" "GridInfoService" "password" "\"\${Const|BaseURL}/password\""
    set_ini_key "$target_file" "GridInfoService" "GridStatusRSS" "\"\${Const|BaseURL}:\${Const|PublicPort}/GridStatusRSS\""

    log "${COLOR_OK}Robust.local.ini erfolgreich konfiguriert.${COLOR_RESET}"
    blankline
}

# Konfiguriert die FlotsamCache.ini Dateien
# - Erstellt die Dateien in den bin/config-include Ordner der Simulatoren
# - Setzt Optimierte Parameter den FlotsamCache.ini Dateien
function flotsaminiconfig() {
    # 25.04.2025
    for i in $(seq 1 99); do
        local config_dir="$SCRIPT_DIR/sim$i/bin/config-include"
        local file="$config_dir/FlotsamCache.ini"

        if [[ -d "$config_dir" ]]; then
            log "${COLOR_FILE}Erstelle $file${COLOR_RESET}"
            mkdir -p "$config_dir"
            
            # Datei erstellen
            #touch "$welcome_ini"
            #touch "$welcome_ini" || echo "" > "$welcome_ini"
            touch "$file" 2>/dev/null || echo "" > "$file"
            
            # 2. Sektion hinzufügen
            add_ini_section "$file" "AssetCache"

            sleep 1
            
            # 3. Alle Key-Value Paare setzen
            set_ini_key "$file" "AssetCache" "CacheDirectory" "./assetcache"
            set_ini_key "$file" "AssetCache" "LogLevel" "0"
            set_ini_key "$file" "AssetCache" "HitRateDisplay" "100"
            set_ini_key "$file" "AssetCache" "MemoryCacheEnabled" "false"
            set_ini_key "$file" "AssetCache" "UpdateFileTimeOnCacheHit" "false"
            set_ini_key "$file" "AssetCache" "NegativeCacheEnabled" "true"
            set_ini_key "$file" "AssetCache" "NegativeCacheTimeout" "120"
            set_ini_key "$file" "AssetCache" "NegativeCacheSliding" "false"
            set_ini_key "$file" "AssetCache" "FileCacheEnabled" "true"
            set_ini_key "$file" "AssetCache" "MemoryCacheTimeout" ".016"
            set_ini_key "$file" "AssetCache" "FileCacheTimeout" "48"
            set_ini_key "$file" "AssetCache" "FileCleanupTimer" "1.0"

            log "${COLOR_OK}→ FlotsamCache.ini neu geschrieben für sim$i${COLOR_RESET}"
        fi
    done

    log "${COLOR_OK}FlotsamCache.ini konfiguriert.${COLOR_RESET}"
    blankline    
}

function gridcommoniniconfig() {
    local ip="$1"
    local gridname="$2"

    # Gridname bereinigen
    gridname=$(echo "$gridname" | sed -e 's/ä/ae/g' -e 's/ö/oe/g' -e 's/ü/ue/g' -e 's/[-&]/_/g' -e 's/  */_/g' -e 's/__\+/_/g')

    for i in $(seq 1 99); do
        local config_dir="$SCRIPT_DIR/sim$i/bin/config-include"
        local file="$config_dir/GridCommon.ini"
        local example_file="$config_dir/GridCommon.ini.example"

        # Strikte Prüfung - Abbruch wenn etwas fehlt
        if [[ ! -d "$config_dir" ]] || [[ ! -f "$example_file" ]]; then
            return 1
        fi

        # Vorlage kopieren
        cp "$example_file" "$file" || return 1

        sleep 1

        # [Const]
        add_ini_before_section "$file" "Const" "DatabaseService"
        set_ini_key "$file" "Const" "BaseHostname" "\"$ip\""
        set_ini_key "$file" "Const" "BaseURL" "\"http://\${Const|BaseHostname}\""
        set_ini_key "$file" "Const" "PublicPort" "\"8002\""
        set_ini_key "$file" "Const" "PrivatePort" "\"8003\""

        # [DatabaseService] wird in database_set_iniconfig eingetragen.
        clear_ini_section "$file" "DatabaseService"
        set_ini_key "$file" "DatabaseService" "StorageProvider" "\"OpenSim.Data.MySQL.dll\""

        # [Hypergrid]
        set_ini_key "$file" "Hypergrid" "GatekeeperURI" "\"\${Const|BaseURL}:\${Const|PublicPort}\""
        set_ini_key "$file" "Hypergrid" "HomeURI" "\"\${Const|BaseURL}:\${Const|PublicPort}\""

        # [Modules]
        set_ini_key "$file" "Modules" "AssetCaching" "\"FlotsamAssetCache\""
        set_ini_key "$file" "Modules" "Include-FlotsamCache" "\"config-include/FlotsamCache.ini\""
        set_ini_key "$file" "Modules" "AuthorizationServices" "\"RemoteAuthorizationServicesConnector\""

        # [AssetService]
        set_ini_key "$file" "AssetService" "DefaultAssetLoader" "\"OpenSim.Framework.AssetLoader.Filesystem.dll\""
        set_ini_key "$file" "AssetService" "AssetLoaderArgs" "\"assets/AssetSets.xml\""
        set_ini_key "$file" "AssetService" "AssetServerURI" "\"\${Const|PrivURL}:\${Const|PrivatePort}\""

        # [InventoryService]
        set_ini_key "$file" "InventoryService" "InventoryServerURI" "\"\${Const|PrivURL}:\${Const|PrivatePort}\""

        # [GridInfo]
        set_ini_key "$file" "GridInfo" "GridInfoURI" "\"\${Const|BaseURL}:\${Const|PublicPort}\""

        # [GridService]
        set_ini_key "$file" "GridService" "GridServerURI" "\"\${Const|PrivURL}:\${Const|PrivatePort}\""
        set_ini_key "$file" "GridService" "MapTileDirectory" "\"./maptiles\""
        set_ini_key "$file" "GridService" "Gatekeeper" "\"\${Const|BaseURL}:\${Const|PublicPort}\""

        # [EstateDataStore]
        set_ini_key "$file" "EstateService" "EstateServerURI" "\"\${Const|PrivURL}:\${Const|PrivatePort}\""

        # [Messaging]
        set_ini_key "$file" "Messaging" "Gatekeeper" "\"\${Const|BaseURL}:\${Const|PublicPort}\""

        # [AvatarService]
        set_ini_key "$file" "AvatarService" "AvatarServerURI" "\"\${Const|PrivURL}:\${Const|PrivatePort}\""

        # [AgentPreferencesService]
        set_ini_key "$file" "AgentPreferencesService" "AgentPreferencesServerURI" "\"\${Const|PrivURL}:\${Const|PrivatePort}\""

        # [PresenceService]
        set_ini_key "$file" "PresenceService" "PresenceServerURI" "\"\${Const|PrivURL}:\${Const|PrivatePort}\""

        # [UserAccountService]
        set_ini_key "$file" "UserAccountService" "UserAccountServerURI" "\"\${Const|PrivURL}:\${Const|PrivatePort}\""

        # [GridUserService]
        set_ini_key "$file" "GridUserService" "GridUserServerURI" "\"\${Const|PrivURL}:\${Const|PrivatePort}\""

        # [AuthenticationService]
        set_ini_key "$file" "AuthenticationService" "AuthenticationServerURI" "\"\${Const|PrivURL}:\${Const|PrivatePort}\""

        # [FriendsService]
        set_ini_key "$file" "FriendsService" "FriendsServerURI" "\"\${Const|PrivURL}:\${Const|PrivatePort}\""

        # [HGInventoryAccessModule]
        set_ini_key "$file" "HGInventoryAccessModule" "HomeURI" "\"\${Const|BaseURL}:\${Const|PublicPort}\""
        set_ini_key "$file" "HGInventoryAccessModule" "Gatekeeper" "\"\${Const|BaseURL}:\${Const|PublicPort}\""

        # [HGAssetService]
        set_ini_key "$file" "HGAssetService" "HomeURI" "\"\${Const|BaseURL}:\${Const|PublicPort}\""

        # [HGFriendsModule]
        set_ini_key "$file" "HGFriendsModule" "LevelHGFriends" "0"

        # [MapImageService]
        set_ini_key "$file" "MapImageService" "MapImageServerURI" "\"\${Const|PrivURL}:\${Const|PrivatePort}\""

        # [AuthorizationService]
        set_ini_key "$file" "AuthorizationService" "AuthorizationServerURI" "\"\${Const|PrivURL}/hgauth.php\""

        # [MuteListService]
        set_ini_key "$file" "MuteListService" "MuteListServerURI" "\"\${Const|PrivURL}:\${Const|PrivatePort}\""

        log "${COLOR_OK}✓ sim$i: GridCommon.ini erfolgreich${COLOR_RESET}"

        sleep 1
    done

    log "${COLOR_OK}GridCommon.ini konfiguriert.${COLOR_RESET}"
    blankline
}

function osslenableiniconfig() {
    # 25.04.2025
    for i in $(seq 1 99); do
        local config_dir="$SCRIPT_DIR/sim$i/bin/config-include"
        local file="$config_dir/osslEnable.ini"

        if [[ -d "$config_dir" ]]; then
            log "${COLOR_FILE}Erstelle $file${COLOR_RESET}"
            mkdir -p "$config_dir"
            
            touch "$file" 2>/dev/null || echo "" > "$file"
            
            # Sektion hinzufügen
            add_ini_section "$file" "OSSL"

            sleep 1
            
            # Basis-Key-Value Paare
            set_ini_key "$file" "OSSL" "AllowOSFunctions" "true"
            set_ini_key "$file" "OSSL" "AllowMODFunctions" "true"
            set_ini_key "$file" "OSSL" "AllowLightShareFunctions" "true"
            set_ini_key "$file" "OSSL" "PermissionErrorToOwner" "false"
            set_ini_key "$file" "OSSL" "OSFunctionThreatLevel" "VeryHigh"
            set_ini_key "$file" "OSSL" "osslParcelO" "\"PARCEL_OWNER,\""
            set_ini_key "$file" "OSSL" "osslParcelOG" "\"PARCEL_GROUP_MEMBER,PARCEL_OWNER,\""
            set_ini_key "$file" "OSSL" "osslNPC" "\${OSSL|osslParcelOG}ESTATE_MANAGER,ESTATE_OWNER"

            # Alle Allow_* Einträge
            set_ini_key "$file" "OSSL" "Allow_osGetAgents" "true"
            set_ini_key "$file" "OSSL" "Allow_osGetAvatarList" "true"
            set_ini_key "$file" "OSSL" "Allow_osGetNPCList" "true"
            set_ini_key "$file" "OSSL" "Allow_osNpcGetOwner" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osSetSunParam" "ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osTeleportOwner" "true"
            set_ini_key "$file" "OSSL" "Allow_osSetEstateSunSettings" "ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osSetRegionSunSettings" "ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osEjectFromGroup" "true"
            set_ini_key "$file" "OSSL" "Allow_osForceBreakAllLinks" "true"
            set_ini_key "$file" "OSSL" "Allow_osForceBreakLink" "true"
            set_ini_key "$file" "OSSL" "Allow_osGetWindParam" "true"
            set_ini_key "$file" "OSSL" "Allow_osInviteToGroup" "true"
            set_ini_key "$file" "OSSL" "Allow_osReplaceString" "true"
            set_ini_key "$file" "OSSL" "Allow_osSetDynamicTextureData" "true"
            set_ini_key "$file" "OSSL" "Allow_osSetDynamicTextureDataFace" "true"
            set_ini_key "$file" "OSSL" "Allow_osSetDynamicTextureDataBlend" "true"
            set_ini_key "$file" "OSSL" "Allow_osSetDynamicTextureDataBlendFace" "true"
            set_ini_key "$file" "OSSL" "Allow_osSetParcelMediaURL" "true"
            set_ini_key "$file" "OSSL" "Allow_osSetParcelMusicURL" "true"
            set_ini_key "$file" "OSSL" "Allow_osSetParcelSIPAddress" "true"
            set_ini_key "$file" "OSSL" "Allow_osSetPrimFloatOnWater" "true"
            set_ini_key "$file" "OSSL" "Allow_osSetWindParam" "true"
            set_ini_key "$file" "OSSL" "Allow_osTerrainFlush" "ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osAvatarName2Key" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osFormatString" "true"
            set_ini_key "$file" "OSSL" "Allow_osKey2Name" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osListenRegex" "true"
            set_ini_key "$file" "OSSL" "Allow_osLoadedCreationDate" "true"
            set_ini_key "$file" "OSSL" "Allow_osLoadedCreationID" "true"
            set_ini_key "$file" "OSSL" "Allow_osLoadedCreationTime" "true"
            set_ini_key "$file" "OSSL" "Allow_osMessageObject" "true"
            set_ini_key "$file" "OSSL" "Allow_osRegexIsMatch" "true"
            set_ini_key "$file" "OSSL" "Allow_osGetAvatarHomeURI" "true"
            set_ini_key "$file" "OSSL" "Allow_osNpcSetProfileAbout" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcSetProfileImage" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osDie" "true"
            set_ini_key "$file" "OSSL" "Allow_osDetectedCountry" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osDropAttachment" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osDropAttachmentAt" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osGetAgentCountry" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osGetGridCustom" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osGetGridGatekeeperURI" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osGetGridHomeURI" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osGetGridLoginURI" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osGetGridName" "true"
            set_ini_key "$file" "OSSL" "Allow_osGetGridNick" "true"
            set_ini_key "$file" "OSSL" "Allow_osGetNumberOfAttachments" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osGetRegionStats" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osGetSimulatorMemory" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osGetSimulatorMemoryKB" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osMessageAttachments" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osReplaceAgentEnvironment" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osSetSpeed" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osSetOwnerSpeed" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osRequestURL" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osRequestSecureURL" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osCauseDamage" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osCauseHealing" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osSetHealth" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osSetHealRate" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osForceAttachToAvatar" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osForceAttachToAvatarFromInventory" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osForceCreateLink" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osForceDropAttachment" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osForceDropAttachmentAt" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osGetLinkPrimitiveParams" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osGetPhysicsEngineType" "true"
            set_ini_key "$file" "OSSL" "Allow_osGetRegionMapTexture" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osGetScriptEngineName" "true"
            set_ini_key "$file" "OSSL" "Allow_osGetSimulatorVersion" "true"
            set_ini_key "$file" "OSSL" "Allow_osMakeNotecard" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osMatchString" "true"
            set_ini_key "$file" "OSSL" "Allow_osNpcCreate" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcGetPos" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcGetRot" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcLoadAppearance" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcMoveTo" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcMoveToTarget" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcPlayAnimation" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcRemove" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcSaveAppearance" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcSay" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcSayTo" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcSetRot" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcShout" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcSit" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcStand" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcStopAnimation" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcStopMoveToTarget" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcTouch" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osNpcWhisper" "\${OSSL|osslNPC}"
            set_ini_key "$file" "OSSL" "Allow_osOwnerSaveAppearance" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osParcelJoin" "ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osParcelSubdivide" "ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osRegionRestart" "ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osRegionNotice" "ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osSetProjectionParams" "true"
            set_ini_key "$file" "OSSL" "Allow_osSetRegionWaterHeight" "ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osSetTerrainHeight" "ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osSetTerrainTexture" "ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osSetTerrainTextureHeight" "ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osAgentSaveAppearance" "ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osAvatarPlayAnimation" "true"
            set_ini_key "$file" "OSSL" "Allow_osAvatarStopAnimation" "true"
            set_ini_key "$file" "OSSL" "Allow_osForceAttachToOtherAvatarFromInventory" "true"
            set_ini_key "$file" "OSSL" "Allow_osForceDetachFromAvatar" "true"
            set_ini_key "$file" "OSSL" "Allow_osForceOtherSit" "true"
            set_ini_key "$file" "OSSL" "Allow_osGetNotecard" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osGetNotecardLine" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osGetNumberOfNotecardLines" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osSetDynamicTextureURL" "ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osSetDynamicTextureURLBlend" "ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osSetDynamicTextureURLBlendFace" "ESTATE_MANAGER,ESTATE_OWNER"
            set_ini_key "$file" "OSSL" "Allow_osSetRot" "true"
            set_ini_key "$file" "OSSL" "Allow_osSetParcelDetails" "\${OSSL|osslParcelO}ESTATE_MANAGER,ESTATE_OWNER"

            log "${COLOR_OK}→ osslEnable.ini neu geschrieben für sim$i${COLOR_RESET}"

            sleep 1
        fi
    done

    log "${COLOR_OK}osslEnable.ini konfiguriert.${COLOR_RESET}"
    blankline
}

# Erstellt eine StandaloneCommon.ini
function standalonecommoniniconfig() {
    local ip="$1"
    local gridname="$2"

    # Gridname bereinigen
    gridname=$(echo "$gridname" | sed -e 's/ä/ae/g' -e 's/ö/oe/g' -e 's/ü/ue/g' -e 's/[-&]/_/g' -e 's/  */_/g' -e 's/__\+/_/g')

    local config_dir="$SCRIPT_DIR/opensim/bin/config-include"
    local file="$config_dir/StandaloneCommon.ini"
    local example_file="$config_dir/StandaloneCommon.ini.example"

    log "${COLOR_FILE}Erstelle StandaloneCommon.ini in opensim/bin${COLOR_RESET}"
    mkdir -p "$config_dir"

    # Datei erstellen
    #touch "$welcome_ini"
    #touch "$welcome_ini" || echo "" > "$welcome_ini"
    touch "$file" 2>/dev/null || echo "" > "$file"

    # 2. Const-Sektion hinzufügen
    add_ini_section "$file" "Const"

    # 3. Werte für Const-Sektion setzen
    set_ini_key "$file" "Const" "BaseHostname" "\"$ip\""
    set_ini_key "$file" "Const" "BaseURL" "http://\${Const|BaseHostname}"
    set_ini_key "$file" "Const" "PublicPort" "\"9000\""
    set_ini_key "$file" "Const" "PrivatePort" "\"9003\""
    set_ini_key "$file" "Const" "PrivURL" "http://\${Const|BaseHostname}:\${Const|PrivatePort}"

    # 4. Hypergrid- und GridInfo-Werte setzen
    set_ini_key "$file" "Hypergrid" "GatekeeperURI" "\"http://$ip:8002\""
    set_ini_key "$file" "Hypergrid" "HomeURI" "\"http://$ip:8002\""
    set_ini_key "$file" "GridInfoService" "GridName" "\"$gridname\""
    set_ini_key "$file" "GridInfoService" "GridLoginURI" "\"http://$ip:8002\""

    log "${COLOR_OK}→ StandaloneCommon.ini erfolgreich erstellt${COLOR_RESET}"
    blankline
}

# Random Position (mit Simulator-Offset)
function random_position() {
    local center_x=$1
    local center_y=$2
    local n=$3           # Region-Nummer
    local sim_offset=$4   # Simulator-Offset
    
    # Zufallsposition mit Simulator-basiertem Seed
    RANDOM=$(( n + sim_offset * 1000 ))  # Reproduzierbarer Zufall
    local offset_x=$(( (RANDOM % 200) - 100 ))  # Kleinerer Bereich (±100 Einheiten)
    local offset_y=$(( (RANDOM % 200) - 100 ))
    
    echo "$((center_x + offset_x + sim_offset * 10)),$((center_y + offset_y + sim_offset * 10))"
}

# Fibonacci Grid (mit Simulator-Offset)
function fibonacci_grid_position() {
    local center_x=$1
    local center_y=$2
    local n=$3
    local sim_offset=$4
    
    local a=0; local b=1
    for ((i=0; i<n + sim_offset; i++)); do
        local tmp=$((a + b))
        a=$b; b=$tmp
    done

    local grid_size=$((b * 10))  # Kleinere Skalierung
    local pos_x=$((center_x + (n % 2 == 0 ? grid_size : -grid_size) + sim_offset * 20))
    local pos_y=$((center_y + ((n / 2) % 2 == 0 ? grid_size : -grid_size) + sim_offset * 20))

    echo "$pos_x,$pos_y"
}

# Diamond Grid (Rautenmuster)
function diamond_position() {
    local center_x=$1
    local center_y=$2
    local n=$3
    local sim_offset=$4
    
    local ring=$(( (n / 4) + 1 ))
    local side=$(( n % 4 ))
    local grid_size=$(( ring * 100 + sim_offset * 50 ))  # Simulator-Offset integriert
    
    case $side in
        0) pos_x=$((center_x + grid_size));         pos_y=$center_y;;
        1) pos_x=$center_x;                         pos_y=$((center_y + grid_size));;
        2) pos_x=$((center_x - grid_size));         pos_y=$center_y;;
        3) pos_x=$center_x;                         pos_y=$((center_y - grid_size));;
    esac

    echo "$pos_x,$pos_y"
}

# Square Grid
function square_grid_position() {
    local center_x=$1
    local center_y=$2
    local n=$3
    local sim_offset=$4
    
    local cols=10
    local x=$(( center_x + (n % cols) * 100 + sim_offset * 5 ))  # 100m Abstand
    local y=$(( center_y + (n / cols) * 100 + sim_offset * 5 ))

    echo "$x,$y"
}

# Hex Grid (Hexagonales Muster)
function hex_grid_position() {
    local center_x=$1
    local center_y=$2
    local n=$3
    local sim_offset=$4
    
    local ring=$(( (n / 6) + 1 ))
    local side=$(( n % 6 ))
    local size=$(( 50 + sim_offset * 10 ))  # Basisgröße + Offset

    case $side in
        0) x=$(( center_x + size*2 ));      y=$center_y;;
        1) x=$(( center_x + size ));        y=$(( center_y + size*1732/1000 ));;  # sin(60°)*2
        2) x=$(( center_x - size ));        y=$(( center_y + size*1732/1000 ));;
        3) x=$(( center_x - size*2 ));      y=$center_y;;
        4) x=$(( center_x - size ));        y=$(( center_y - size*1732/1000 ));;
        5) x=$(( center_x + size ));        y=$(( center_y - size*1732/1000 ));;
    esac

    echo "$x,$y"
}
# Spiral Grid (Mit Simulator-Offset)
function spiral_grid_position() {
    local center_x=$1
    local center_y=$2
    local n=$3
    local sim_offset=$4  # Neu: Simulator-basierter Offset

    # Initialisierung mit Simulator-Offset
    local x=$(( sim_offset * 10 ))  # Jeder Simulator beginnt 10 Einheiten weiter
    local y=$(( sim_offset * 10 ))
    local step=1
    local direction=0
    local steps_in_direction=0
    local step_change=0

    for ((i=0; i<n; i++)); do
        case $direction in
            0) x=$((x + 1));;  # Rechts
            1) y=$((y + 1));;  # Oben
            2) x=$((x - 1));;  # Links
            3) y=$((y - 1));;  # Unten
        esac
        
        ((steps_in_direction++))
        
        if (( steps_in_direction == step )); then
            direction=$(( (direction + 1) % 4 ))
            steps_in_direction=0
            ((step_change++))
            
            if (( step_change % 2 == 0 )); then
                ((step++))
            fi
        fi
    done

    echo "$((center_x + x)),$((center_y + y))"
}

function regionsiniconfig() {
    # Konstanten
    local center_x=3000
    local center_y=3000
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
    declare -A used_locations
    declare -A used_ports
    local position="Spiral" # Random Fibonacci Raute Square Hexagon Spiral

    # Benutzereingabe mit Symbol und Farbe
    log "${SYM_INFO}${COLOR_LABEL} Wie viele Zufallsregionen sollen pro Simulator im $position style erstellt werden? ${COLOR_OK}[1]${COLOR_RESET}"
    read -r regions_per_sim    

    # Eingabeprüfung
    if [[ -z "$regions_per_sim" ]]; then
        regions_per_sim=1
    elif ! [[ "$regions_per_sim" =~ ^[1-9][0-9]*$ ]]; then
        log "${SYM_BAD} ${COLOR_BAD}Ungültige Eingabe: Bitte eine positive Zahl eingeben${COLOR_RESET}" >&2
        return 1
    fi

    log "${SYM_OK} ${COLOR_ACTION}Sie haben ${COLOR_OK}$regions_per_sim${COLOR_ACTION} Regionen pro Simulator gewählt.${COLOR_RESET}"

    system_ip=$(hostname -I | awk '{print $1}')

    log "\n${SYM_SERVER}${COLOR_HEADING}  Starte Regionserstellung...${COLOR_RESET}"

    # Simulatoren durchlaufen (beginnt bei 2 um sim1 für Welcome-Region freizuhalten)
    for ((sim_num=2; sim_num<=999; sim_num++)); do
        sim_dir="${SCRIPT_DIR}/sim${sim_num}/bin/Regions"
        
        if [[ -d "$sim_dir" ]]; then
            log "${SYM_FOLDER}${COLOR_SERVER} Simulator ${sim_num}:${COLOR_RESET} ${COLOR_ACTION}Erstelle ${regions_per_sim} Region(en)${COLOR_RESET}" >&2
            
            # Bestehende Ports erfassen
            local existing_port_count=0
            if [[ -d "$sim_dir" ]]; then
                for existing_file in "$sim_dir"/*.ini; do
                    if [[ -f "$existing_file" ]]; then
                        existing_port=$(grep -oP 'InternalPort\s*=\s*\K\d+' "$existing_file" 2>/dev/null)
                        if [[ -n "$existing_port" ]]; then
                            used_ports["$existing_port"]=1
                            ((existing_port_count++))
                        fi
                    fi
                done
            fi
            
            # Regionen erstellen Random Fibonacci Raute Square Hexagon Spiral Checkerboard
            for ((region_num=1; region_num<=regions_per_sim; region_num++)); do
                # Position berechnen (mit Kollisionsprüfung)
                local attempts=0
                local max_attempts=100
                
                while true; do
                    # Hier wird die entsprechende externe Funktion aufgerufen
                    if [[ "$position" == "Random" ]]; then
                        # Zufalls-Gitter:
                        location=$(random_position "$center_x" "$center_y" "$region_num" "$sim_num")
                    elif [[ "$position" == "Fibonacci" ]]; then
                        # Fibonacci-Gitter:
                        location=$(fibonacci_grid_position "$center_x" "$center_y" "$region_num" "$sim_num")
                    elif [[ "$position" == "Raute" ]]; then
                        # Rauten-Gitter:
                        location=$(diamond_position "$center_x" "$center_y" "$region_num" "$sim_num")
                    elif [[ "$position" == "Square" ]]; then
                        # Square-Gitter:
                        location=$(square_grid_position "$center_x" "$center_y" "$region_num" "$sim_num")
                    elif [[ "$position" == "Hexagon" ]]; then
                        # Hexagon-Gitter:
                        location=$(hex_grid_position "$center_x" "$center_y" "$region_num" "$sim_num")
                    elif [[ "$position" == "Spiral" ]]; then
                        # Spirale-Gitter:
                        location=$(spiral_grid_position "$center_x" "$center_y" "$region_num" "$sim_num")                       
                    else
                        # Fallback zu Random bei ungültiger Eingabe
                        location=$(random_position "$center_x" "$center_y" "$region_num" "$sim_num")
                    fi
                    
                    if [[ -z "${used_locations[$location]}" ]]; then
                        used_locations[$location]=1
                        break
                    fi
                    
                    attempts=$((attempts + 1))
                    if (( attempts >= max_attempts )); then
                        log "${SYM_BAD} ${COLOR_WARNING}Fehler: Konnte nach ${max_attempts} Versuchen keine eindeutige Position finden${COLOR_RESET}" >&2
                        return 1
                    fi
                done

                # Eindeutigen Port finden
                local port_attempts=0
                local max_port_attempts=100
                local port_base=$((base_port + sim_num * 100))  # 9100, 9200, 9300 usw.

                while true; do
                    # Port innerhalb des reservierten Blocks (9100-9199 etc.)
                    port=$((port_base + region_num + existing_port_count))
                    
                    # Sicherstellen, dass wir im Block bleiben
                    if (( port >= port_base + 100 )); then
                        log "${SYM_BAD} ${COLOR_WARNING}Fehler: Keine freien Ports mehr im Block ${port_base}-$((port_base+99))${COLOR_RESET}" >&2
                        return 1
                    fi
                    
                    # Prüfen ob Port verfügbar ist
                    if [[ -z "${used_ports[$port]}" ]] && ! nc -z localhost "$port" 2>/dev/null; then
                        used_ports["$port"]=1
                        break
                    fi
                    
                    ((existing_port_count++))
                    ((port_attempts++))
                    
                    if (( port_attempts >= max_port_attempts )); then
                        log "${SYM_BAD} ${COLOR_WARNING}Fehler: Konnte in Simulator ${sim_num} nach ${max_port_attempts} Versuchen keinen freien Port finden (Block ${port_base}-$((port_base+99))${COLOR_RESET}" >&2
                        return 1
                    fi
                done

                # Neu generierter Name
                generate_name
                genRegionName="${gennamefirst}${gennamesecond}$((RANDOM % 900 + 100))"
                echo "$genRegionName"
                region_name=${genRegionName}

                region_uuid=$(command -v uuidgen >/dev/null 2>&1 && uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$RANDOM-$RANDOM-$RANDOM-$RANDOM")

                config_file="${sim_dir}/${region_name}.ini"
                
                # Prüfen ob Region existiert
                if [[ -f "$config_file" ]]; then
                    log "${SYM_WAIT} ${COLOR_WARNING}Überspringe ${COLOR_VALUE}${region_name}${COLOR_RESET}${COLOR_WARNING} - existiert bereits${COLOR_RESET}" >&2
                    continue
                fi

                touch "$config_file" 2>/dev/null || echo "" > "$config_file"
                
                # Regionseinstellungen hinzufügen
                add_ini_section "$config_file" "$region_name"
                
                # Regionseinstellungen setzen
                set_ini_key "$config_file" "$region_name" "RegionUUID" "$region_uuid"
                set_ini_key "$config_file" "$region_name" "Location" "$location"
                set_ini_key "$config_file" "$region_name" "SizeX" "256"
                set_ini_key "$config_file" "$region_name" "SizeY" "256"
                set_ini_key "$config_file" "$region_name" "SizeZ" "256"
                set_ini_key "$config_file" "$region_name" "InternalPort" "$port"
                set_ini_key "$config_file" "$region_name" "ExternalHostName" "$system_ip"
                set_ini_key "$config_file" "$region_name" "MaxPrims" "15000"
                set_ini_key "$config_file" "$region_name" "MaxAgents" "40"
                set_ini_key "$config_file" "$region_name" "MaptileStaticUUID" "$region_uuid"
                set_ini_key "$config_file" "$region_name" "InternalAddress" "0.0.0.0"
                set_ini_key "$config_file" "$region_name" "AllowAlternatePorts" "False"
                set_ini_key "$config_file" "$region_name" "NonPhysicalPrimMax" "512"
                set_ini_key "$config_file" "$region_name" "PhysicalPrimMax" "128"
                set_ini_key "$config_file" "$region_name" ";ClampPrimSize" "false"
                set_ini_key "$config_file" "$region_name" ";MaxPrimsPerUser" "-1"
                set_ini_key "$config_file" "$region_name" ";ScopeID" "$region_uuid"
                set_ini_key "$config_file" "$region_name" ";RegionType" "Mainland"
                set_ini_key "$config_file" "$region_name" ";RenderMinHeight" "-1"
                set_ini_key "$config_file" "$region_name" ";RenderMaxHeight" "100"
                set_ini_key "$config_file" "$region_name" ";MapImageModule" "Warp3DImageModule"
                set_ini_key "$config_file" "$region_name" ";TextureOnMapTile" "true"
                set_ini_key "$config_file" "$region_name" ";DrawPrimOnMapTile" "true"
                set_ini_key "$config_file" "$region_name" ";GenerateMaptiles" "true"
                set_ini_key "$config_file" "$region_name" ";MaptileRefresh" "0"
                set_ini_key "$config_file" "$region_name" ";MaptileStaticFile" "path/to/SomeFile.png" # Bitte verwenden sie nicht den Pfad des OpenSimulators sondern ein externen Pfad!
                set_ini_key "$config_file" "$region_name" ";MasterAvatarFirstName" "John"
                set_ini_key "$config_file" "$region_name" ";MasterAvatarLastName" "Doe"
                set_ini_key "$config_file" "$region_name" ";MasterAvatarSandboxPassword" "passwd"
                
                log "${SYM_OK} ${COLOR_VALUE}${region_name} ${COLOR_DIR}(${location}, Port ${port})${COLOR_RESET}" >&2
            done
        fi
    done

    log "${SYM_OK}${COLOR_OK} Regionserstellung abgeschlossen!${COLOR_RESET}"
    blankline
    return 0
}

# Hauptfunktion, fragt Benutzer nach IP & Gridnamen und ruft alle Teilfunktionen auf
function iniconfig() {
    # 30.04.2025 - Server-Konfiguration

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
        gridname=${genGridName}
    fi

    echo "Verwendete IP: $ip"
    echo "Gridname: $gridname"

    # **Speicherung der Server-Daten in UserInfo.ini**
    local ini_file="${SCRIPT_DIR}/UserInfo.ini"

    if [[ ! -f "$ini_file" ]]; then
        log "${COLOR_INFO}Erstelle UserInfo.ini${COLOR_RESET}"
        sudo touch "$ini_file"
    fi

    log "\n[ServerData]" | sudo tee -a "$ini_file" >/dev/null
    echo "Arbeitsverzeichnis = ${SCRIPT_DIR}" | sudo tee -a "$ini_file" >/dev/null
    echo "ServerIP = ${ip}" | sudo tee -a "$ini_file" >/dev/null
    echo "GridName = ${gridname}" | sudo tee -a "$ini_file" >/dev/null

    log "${SYM_LOG} ${COLOR_LABEL}Serverdaten gespeichert in: ${COLOR_FILE}${ini_file}${COLOR_RESET}"

    #! ⚠️ **Wichtige Sicherheitsinformation!**
    # Die Datei UserInfo.ini enthält Zugangsdaten. 
    # Sie **sollte danach unbedingt von eurem Server gelöscht und sicher auf eurem PC gespeichert werden**.

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
    echo "Starte oswebinterfaceconfig ..."
    oswebinterfaceconfig

    # Auswahl des Modus Hypergrid oder Geschlossener Grid.
    hypergrid "hypergrid"
    #hypergrid "closed"
}


#?──────────────────────────────────────────────────────────────────────────────────────────
#* XML Konfigurationen für Addon Pakete wie Texturen, Avatare oder Skripte
#?──────────────────────────────────────────────────────────────────────────────────────────

# shellcheck disable=SC2317
function verify_xml_section() {
    
    local file="$1"
    local section_name="$2"
    
    if [ ! -f "$file" ]; then
        log "${SYM_BAD} ${COLOR_BAD}Error: File ${COLOR_DIR}${file}${COLOR_BAD} does not exist${COLOR_RESET}" >&2
        return 2
    fi
    
    if grep -q "<Section Name=\"$section_name\">" "$file"; then
        log "${SYM_OK} ${COLOR_LABEL}Section ${COLOR_VALUE}'$section_name'${COLOR_LABEL} exists in ${COLOR_DIR}${file}${COLOR_RESET}"
        return 0
    else
        log "${SYM_BAD} ${COLOR_LABEL}Section ${COLOR_VALUE}'$section_name'${COLOR_LABEL} not found in ${COLOR_DIR}${file}${COLOR_RESET}"
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
    
    log "${SYM_INFO} ${COLOR_ACTION}Adding section ${COLOR_VALUE}'$section_name'${COLOR_ACTION} to ${COLOR_DIR}${file}${COLOR_RESET}"
    
    # Abschnitt vor dem schließenden Tag einfügen
    if sed "s|$closing_tag|  <Section Name=\"$section_name\">\n$content\n  </Section>\n$closing_tag|" "$file" > "$temp_file"; then
        if mv "$temp_file" "$file"; then
            log "${SYM_OK} ${COLOR_OK}Successfully added section ${COLOR_VALUE}'$section_name'${COLOR_OK} to ${COLOR_DIR}${file}${COLOR_RESET}"
            return 0
        fi
    fi
    
    log "${SYM_BAD} ${COLOR_BAD}Failed to add section ${COLOR_VALUE}'$section_name'${COLOR_BAD} to ${COLOR_DIR}${file}${COLOR_RESET}" >&2
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
    
    log "${SYM_INFO} ${COLOR_ACTION}Removing section ${COLOR_VALUE}'$section_name'${COLOR_ACTION} from ${COLOR_DIR}${file}${COLOR_RESET}"
    
    # Abschnitt entfernen (inklusive aller Zeilen zwischen Section-Tags)
    if sed "/<Section Name=\"$section_name\">/,/<\/Section>/d" "$file" > "$temp_file"; then
        if mv "$temp_file" "$file"; then
            log "${SYM_OK} ${COLOR_OK}Successfully removed section ${COLOR_VALUE}'$section_name'${COLOR_OK} from ${COLOR_DIR}${file}${COLOR_RESET}"
            return 0
        fi
    fi
    
    log "${SYM_BAD} ${COLOR_BAD}Failed to remove section ${COLOR_VALUE}'$section_name'${COLOR_BAD} from ${COLOR_DIR}${file}${COLOR_RESET}" >&2
    return 1
}

#* Beispiel Implementierung für PBR Textures ohne Test eingefügt.
function configure_pbr_textures() {
    local asset_sets_file="opensim/bin/assets/AssetSets.xml"
    local libraries_file="opensim/bin/inventory/Libraries.xml"
    
    log "\n${COLOR_HEADING}=== Configuring PBR Textures ===${COLOR_RESET}"
    
    # AssetSets.xml bearbeiten
    add_xml_section "$asset_sets_file" "PBR Textures AssetSet" \
    "    <Key Name=\"file\" Value=\"PBRTexturesAssetSet/PBRTexturesAssetSet.xml\"/>" || return 1
    
    # Libraries.xml bearbeiten
    add_xml_section "$libraries_file" "PBRTextures Library" \
    "    <Key Name=\"foldersFile\" Value=\"PBRTexturesLibrary/PBRTexturesLibraryFolders.xml\"/>\n    <Key Name=\"itemsFile\" Value=\"PBRTexturesLibrary/PBRTexturesLibraryItems.xml\"/>" || return 1
    
    log "${SYM_OK} ${COLOR_OK}PBR Textures configuration completed successfully${COLOR_RESET}"

}

function regionsclean() {
    log "\033[33mWARNUNG: Dies wird ALLE Regionskonfigurationen in allen Simulatoren löschen!\033[0m"
    echo "Sicher fortfahren? (j/N): " 
    read -r confirm
    
    if [[ "$confirm" =~ ^[jJ] ]]; then
        echo "Starte Bereinigung..."
        deleted_count=0
        
        # Durch alle Simulatoren iterieren
        for ((sim_num=1; sim_num<=999; sim_num++)); do
            sim_dir="sim${sim_num}/bin/Regions"
            
            if [[ -d "$sim_dir" ]]; then
                log "\033[33m ✓ Überprüfe $sim_dir...\033[0m"
                
                # Lösche nur .ini-Dateien (keine anderen Dateitypen)
                while IFS= read -r -d $'\0' config_file; do
                    if [[ "$config_file" == *.ini ]]; then
                        rm -v "$config_file"
                        ((deleted_count++))
                    fi
                done < <(find "$sim_dir" -maxdepth 1 -type f -name "*.ini" -print0)
            fi
        done
        
        log "\033[32mFertig! Gelöschte Regionen: $deleted_count\033[0m"
    else
        echo "Abbruch: Keine Dateien wurden gelöscht."
    fi
    blankline
}

function renamefiles() {
    timestamp=$(date +"%Y%m%d_%H%M%S")

    if [ ! -d "$SCRIPT_DIR" ]; then
        log "${RED}Fehler: Verzeichnis $SCRIPT_DIR nicht gefunden!${RESET}"
        return 1
    fi

    log "${CYAN}Starte Umbenennung aller *.example Dateien in ${SCRIPT_DIR} und Unterverzeichnissen...${RESET}"

    # Verarbeite robust/bin zuerst
    find "$SCRIPT_DIR" -type f -name "*.example" 2>/dev/null | while read -r example_file; do
        local target_file="${example_file%.example}"  # Entfernt .example

        if [ -f "$target_file" ]; then
            local backup_file="${target_file}_${timestamp}.bak"
            mv "$target_file" "$backup_file"
            log "${YELLOW}Gesichert: ${target_file} → ${backup_file}${RESET}"
        fi

        mv "$example_file" "$target_file"
        log "${GREEN}Umbenannt: ${example_file} → ${target_file}${RESET}"
    done

    # Jetzt alle simX/bin Verzeichnisse durchlaufen
    for ((i=999; i>=1; i--)); do
        sim_dir="${SCRIPT_DIR}/sim$i/bin"
        if [ -d "$sim_dir" ]; then
            log "${CYAN}Verarbeite: $sim_dir ${RESET}"
            find "$sim_dir" -type f -name "*.example" 2>/dev/null | while read -r example_file; do
                local target_file="${example_file%.example}" 

                sleep 1 

                if [ -f "$target_file" ]; then
                    local backup_file="${target_file}_${timestamp}.bak"
                    mv "$target_file" "$backup_file"
                    log "${YELLOW}Gesichert: ${target_file} → ${backup_file}${RESET}"
                fi

                mv "$example_file" "$target_file"
                log "${GREEN}Umbenannt: ${example_file} → ${target_file}${RESET}"
            done
        fi
    done

    log "${GREEN}Alle *.example Dateien wurden erfolgreich verarbeitet.${RESET}"
    blankline
    return 0
}

# Standalone ist die erste Funktion, die funktioniert.
function standalone() {
    log "\e[33m[Standalone] Setup wird durchgeführt...\e[0m"

    # Prüfen ob SCRIPT_DIR gesetzt ist
    if [ -z "${SCRIPT_DIR}" ]; then
        log "\e[31mFehler: SCRIPT_DIR ist nicht gesetzt!\e[0m"
        return 1
    fi

    local opensim_bin="${SCRIPT_DIR}/opensim/bin"
    local renamed=0
    local skipped=0

    # Sicherstellen, dass das Verzeichnis existiert
    if [ ! -d "${opensim_bin}" ]; then
        log "\e[31mFehler: Verzeichnis ${opensim_bin} nicht gefunden!\e[0m"
        return 1
    fi

    # Verarbeite alle .example Dateien
    while IFS= read -r -d '' file; do
        target="${file%.example}"
        
        if [ -e "${target}" ]; then
            log "\e[33mÜbersprungen: ${target} existiert bereits\e[0m"
            ((skipped++))
        else
            if mv "${file}" "${target}"; then
                log "\e[32mUmbenannt: ${file} → ${target}\e[0m"
                ((renamed++))
            else
                log "\e[31mFehler beim Umbenennen von ${file}\e[0m"
                ((skipped++))
            fi
        fi
    done < <(find "${opensim_bin}" -type f -name "*.example" -print0)

    log "\n\e[36mZusammenfassung:\e[0m"
    log "\e[32mUmbenannte Dateien: ${renamed}\e[0m"
    log "\e[33mÜbersprungene Dateien: ${skipped}\e[0m"
    log "\e[32mStandalone-Konfiguration abgeschlossen!\e[0m"
    blankline
}

# Helper to clean config files (remove leading spaces/tabs)
function clean_config() {
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
                sleep 1
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
    log "\033[36mAktive Screen-Sessions:\033[0m"
    screen -ls || echo "Keine Screen-Sessions gefunden"
}

# Kompletter OpenSim-Neustart mit Logrotation
function opensimrestartParallel() {
    opensimstopParallel
    sleep $Simulator_Stop_wait  # Wartezeit für Dienst-Stopp
    logclean   # Logbereinigung
    sleep $Simulator_Start_wait  # Wartezeit vor Neustart
    opensimstartParallel
    log "\033[36mAktive Screen-Sessions:\033[0m"
    screen -ls || echo "Keine Screen-Sessions gefunden"
}

# Server-Reboot mit Vorbereitung
function reboot() {
    log "\033[1;33m⚠ Server-Neustart wird eingeleitet...\033[0m"

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
    #versionrevision
    # OpenSimulator erstellen aus dem Source Code.
    opensimbuild
}

function webinstall() {
# Nach database_setup()
    echo -e "${COLOR_ACTION}Webserver (Apache/PHP) installieren? (j/n) [n] ${COLOR_RESET}"
    read -r web_choice
    if [[ -n "$web_choice" && "$web_choice" =~ ^[jJ] ]]; then
        setup_webserver
    fi
}

function autoinstall() {
    # 06.05.2025

    # Server vorbereiten
    servercheck

    # Verzeichnisse erstellen. Standard: 1
    createdirectory

    # Doppelten Konfigurationsdateien entfernen
    removeconfigfiles

    # mySQL installieren. Standard: Benutzername wird generiert, dazu wird ein 16 stelliges Passwort erzeugt.
    database_setup

    # Downloads aus dem Github hier OpenSim und Money. einfach beises mit Enter bestätigen.
    opensimgitcopy
    moneygitcopy

    # PHP installieren
    #webinstall
    # Webinterface aus dem Github holen    
    osWebinterfacegit

    # Neue standartavatare einfügen
    #ruthrothgit        # Funktioniert nicht richtig.
    #avatarassetsgit    # Funktioniert nicht richtig.

    # OSSL Beispielskripte
    osslscriptsgit

    # Texturen für Normale und PBR Texturen installieren
    #pbrtexturesgit

    # Versionierung des OpenSimulators. Keine eingabe erforderlich.
    #versionrevision

    # OpenSimulator erstellen aus dem Source Code. Standard: ja.
    opensimbuild

    # Kleine Pause
    sleep $Simulator_Start_wait

    # OpenSimulator kopieren
    opensimcopy

    # Alles konfigurieren
    iniconfig

    # Zufallsregionen erstellen
    regionsiniconfig

    #Vor dem Start die letzten vorbereitungen.
    firststart

    # OpenSimulator starten
    opensimrestart

    # Eure Informationen sind gespeichert in UserInfo.ini bitte sicher verwahren.

}

function autoupgrade() {
    # 05.05.2025
    opensimgitcopy
    moneygitcopy
    osslscriptsgit
    opensimbuild

    sleep 5

    opensimstop
    opensimcopy
    opensimstart
}

function autoupgradefast() {
    # 05.05.2025
    opensimgitcopy
    moneygitcopy
    osslscriptsgit
    opensimbuild

    sleep 5

    opensimstopParallel
    opensimcopy
    opensimstartParallel
}

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Hilfefunktionen
#?──────────────────────────────────────────────────────────────────────────────────────────

function help() {
    # Allgemeine Befehle
    log "${COLOR_SECTION}${SYM_SERVER} OpenSim Grundbefehle:${COLOR_RESET}"
    log "${SYM_VOR} ${COLOR_START}opensimstart${COLOR_RESET} \t\t # Startet OpenSimulator komplett"
    log "${SYM_VOR} ${COLOR_STOP}opensimstop${COLOR_RESET} \t\t # Stoppt OpenSimulator komplett"
    log "${SYM_VOR} ${COLOR_START}opensimrestart${COLOR_RESET} \t # Startet den OpenSimulator komplett neu"
    echo
    log "${SYM_VOR} ${COLOR_START}simstart${COLOR_RESET} \t\t # simX angeben - startet einen Regionsserver"
    log "${SYM_VOR} ${COLOR_STOP}simstop${COLOR_RESET} \t\t # simX angeben - stoppt einen Regionsserver"
    log "${SYM_VOR} ${COLOR_START}simrestart${COLOR_RESET} \t\t # simX angeben - startet einen Regionsserver neu"
    echo ""

    # System-Checks & Setup
    log "${COLOR_SECTION}${SYM_TOOLS} System-Checks & Setup:${COLOR_RESET}"
    log "${SYM_VOR} ${COLOR_OK}check_screens${COLOR_RESET} \t # Prüft laufende Prozesse und handelt entsprechend"
    echo
    #log "${SYM_VOR} ${COLOR_OK}servercheck${COLOR_RESET} \t\t # Installiert und Prüft den Server"
    #log "${SYM_VOR} ${COLOR_OK}createdirectory${COLOR_RESET} \t\t # Erstellt alle benötigten Verzeichnisse"
    log "${SYM_VOR} ${COLOR_OK}autoinstall${COLOR_RESET} \t\t # OpenSimulator Automatisiert installieren und einrichten"
    log "${SYM_VOR} ${COLOR_OK}setcrontab${COLOR_RESET} \t\t # Richtet Crontab ein damit der Server wartungsfrei laeuft"
    echo ""

    # Git-Operationen
    #log "${COLOR_SECTION}${SYM_SYNC} Git-Operationen:${COLOR_RESET}"
    #log "${SYM_VOR} ${COLOR_OK}opensimgitcopy${COLOR_RESET} \t\t # Klont den OpenSim Code"
    #log "${SYM_VOR} ${COLOR_OK}moneygitcopy${COLOR_RESET} \t\t # Baut den MoneyServer in den OpenSimulator ein"
    #log "${SYM_VOR} ${COLOR_OK}osslscriptsgit${COLOR_RESET} \t\t # Klont OSSL-Skripte"
    #log "${SYM_VOR} ${COLOR_OK}versionrevision${COLOR_RESET} \t\t # Setzt Versionsrevision"
    #echo ""

    # OpenSim Build & Deploy
    #log "${COLOR_SECTION}${SYM_FOLDER} OpenSim Build & Deploy:${COLOR_RESET}"
    #log "${SYM_VOR} ${COLOR_OK}opensimbuild${COLOR_RESET} \t\t # Kompiliert OpenSim zu ausführbaren Dateien"
    #log "${SYM_VOR} ${COLOR_OK}opensimcopy${COLOR_RESET} \t\t # Kopiert OpenSim in alle Verzeichnisse"
    #log "${SYM_VOR} ${COLOR_OK}opensimupgrade${COLOR_RESET} \t\t # Upgradet OpenSim"
    #log "${SYM_VOR} ${COLOR_OK}database_setup${COLOR_RESET} \t\t # Erstellt alle Datenbanken"
    #echo ""

    # Konfigurationsmanagement
    #log "${COLOR_SECTION}${SYM_CONFIG} Konfigurationsmanagement:${COLOR_RESET}"
    #log "${SYM_VOR} ${COLOR_WARNING}moneyserveriniconfig${COLOR_RESET}\t# Konfiguriert MoneyServer.ini (experimentell)"
    #log "${SYM_VOR} ${COLOR_WARNING}opensiminiconfig${COLOR_RESET}\t# Konfiguriert OpenSim.ini (experimentell)"
    #log "${SYM_VOR} ${COLOR_WARNING}regionsiniconfig${COLOR_RESET}\t# Konfiguriert Regionen (experimentell)"
    #echo ""

    # Systembereinigung
    log "${COLOR_SECTION}${SYM_CLEAN} Systembereinigung:${COLOR_RESET}"
    log "${SYM_VOR} ${COLOR_OK}cacheclean${COLOR_RESET} \t\t # Bereinigt OpenSimulator Cache"
    log "${SYM_VOR} ${COLOR_OK}logclean${COLOR_RESET} \t\t # Bereinigt OpenSimulator Logs"
    log "${SYM_VOR} ${COLOR_OK}mapclean${COLOR_RESET} \t\t # Bereinigt OpenSimulator Maptiles"
    #log "${SYM_VOR} ${COLOR_OK}clean_linux_logs${COLOR_RESET}\t# Bereinigt Systemlogs"
    echo ""

    # Hilfe
    log "${COLOR_SECTION}${SYM_INFO} Hilfe:${COLOR_RESET}"
    log "${SYM_VOR} ${COLOR_OK}help${COLOR_RESET} \t\t\t # Zeigt diese Hilfe"
    log "${SYM_VOR} ${COLOR_OK}prohelp${COLOR_RESET} \t\t # Zeigt die Pro Hilfe"
    echo ""
}

function prohelp() {
    #* OpenSim Grundbefehle
    log "${COLOR_SECTION}${SYM_SERVER} OpenSim Grundbefehle:${COLOR_RESET}"
    log "${SYM_VOR} ${COLOR_START}opensimstart${COLOR_RESET} \t\t # OpenSim starten"
    log "${SYM_VOR} ${COLOR_STOP}opensimstop${COLOR_RESET} \t\t # OpenSim stoppen"
    log "${SYM_VOR} ${COLOR_START}opensimrestart${COLOR_RESET} \t # OpenSim neu starten"
    log "${SYM_VOR} ${COLOR_OK}check_screens${COLOR_RESET} \t # Laufende OpenSim-Prozesse prüfen und neu starten"
    log "${SYM_VOR} ${COLOR_OK}autoupgrade${COLOR_RESET} \t\t # Automatisches OpenSim upgrade"

    log "${SYM_VOR} ${COLOR_OK}opensimstartParallel${COLOR_RESET} \t # Startet alle Regionen parallel"
    log "${SYM_VOR} ${COLOR_OK}opensimstopParallel${COLOR_RESET} \t # Stoppt alle Regionen parallel"
    log "${SYM_VOR} ${COLOR_OK}opensimrestartParallel${COLOR_RESET}  # Startet alle Regionen neu (parallel)"
    echo " "

    #* System-Checks & Setup
    log "${COLOR_SECTION}${SYM_TOOLS} System-Checks & Setup:${COLOR_RESET}"
    log "${SYM_VOR} ${COLOR_OK}servercheck${COLOR_RESET} \t\t # Serverbereitschaft prüfen und Abhängigkeiten installieren"
    log "${SYM_VOR} ${COLOR_OK}createdirectory${COLOR_RESET} \t # OpenSim-Verzeichnisse erstellen"
    log "${SYM_VOR} ${COLOR_OK}setcrontab${COLOR_RESET} \t\t # Crontab Automatisierungen einrichten"
    log "${SYM_VOR} ${COLOR_OK}autoinstall${COLOR_RESET} \t\t # OpenSimulator Automatisiert installieren und einrichten"
    echo " "

    #* Git-Operationen
    log "${COLOR_SECTION}${SYM_SYNC} Git-Operationen:${COLOR_RESET}"
    log "${SYM_VOR} ${COLOR_OK}opensimgitcopy${COLOR_RESET} \t # OpenSim aus Git herunterladen"
    log "${SYM_VOR} ${COLOR_OK}moneygitcopy${COLOR_RESET} \t\t # MoneyServer aus Git holen"
    #log "${SYM_VOR} ${COLOR_WARNING}ruthrothgit${COLOR_RESET} \t\t # Ruth Roth IAR Dateien ${COLOR_BAD}(Vorsicht)${COLOR_RESET}"
    #log "${SYM_VOR} ${COLOR_WARNING}avatarassetsgit${COLOR_RESET} \t\t # Avatar-Assets ${COLOR_BAD}(Vorsicht)${COLOR_RESET}"
    log "${SYM_VOR} ${COLOR_OK}osslscriptsgit${COLOR_RESET} \t # OSSL Beispielskripte herunterladen"
    #log "${SYM_VOR} ${COLOR_WARNING}pbrtexturesgit${COLOR_RESET} \t\t # PBR-Texturen ${COLOR_BAD}(Vorsicht)${COLOR_RESET}"
    log "${SYM_VOR} ${COLOR_OK}downloadallgit${COLOR_RESET} \t # Alle Git-Repos herunterladen"
    log "${SYM_VOR} ${COLOR_OK}versionrevision${COLOR_RESET} \t # Versionsverwaltung aktivieren"
    echo " "

    #* OpenSim Build & Deployment
    log "${COLOR_SECTION}${SYM_FOLDER} OpenSim Build & Deploy:${COLOR_RESET}"
    log "${SYM_VOR} ${COLOR_OK}opensimbuild${COLOR_RESET} \t\t\t # OpenSim kompilieren"
    log "${SYM_VOR} ${COLOR_OK}opensimcopy${COLOR_RESET} \t\t\t # OpenSim Dateien kopieren"
    log "${SYM_VOR} ${COLOR_OK}opensimupgrade${COLOR_RESET} \t\t # OpenSim aktualisieren"
    log "${SYM_VOR} ${COLOR_OK}database_setup${COLOR_RESET} \t\t # Datenbank für OpenSim einrichten"
    echo " "
    log "${SYM_VOR} ${COLOR_OK}autoupgrade${COLOR_RESET} \t\t\t # Führt automatisches Update durch"
    log "${SYM_VOR} ${COLOR_OK}autoupgradefast${COLOR_RESET} \t\t # Automatisches OpenSim Parallel upgraden"

    log "${SYM_VOR} ${COLOR_OK}regionbackup${COLOR_RESET} \t\t\t # Sichert aktuelle Regionen-Daten"
    log "${SYM_VOR} ${COLOR_OK}robustbackup${COLOR_RESET} \t\t\t # Backup der Robust-Datenbank (mit Zeitraumfilter)"
    log "${SYM_VOR} ${COLOR_OK}robustrestore <user> <pass> [teil]${COLOR_RESET}  # Wiederherstellung aus robustbackup ${COLOR_BAD} experimentell${COLOR_RESET}"
    log "${SYM_VOR} ${COLOR_OK}robustrepair <user> <pass> [aktion]${COLOR_RESET} # Reparatur oder Bereinigung der Robust-DB ${COLOR_BAD} experimentell${COLOR_RESET}"    
    log "${SYM_VOR} ${COLOR_OK}restoreRobustDump <dbuser> <dbpass> <dumpfile> <targetdb>${COLOR_RESET} # Robust Wiederherstellung${COLOR_BAD} experimentell${COLOR_RESET}"
    echo " "

    #* Konfigurationsmanagement
    log "${COLOR_SECTION}${SYM_CONFIG} Konfigurationsmanagement:${COLOR_RESET}"
    log "${SYM_VOR} ${COLOR_WARNING}moneyserveriniconfig${COLOR_RESET} \t\t # Konfiguriert MoneyServer.ini"
    log "${SYM_VOR} ${COLOR_WARNING}opensiminiconfig${COLOR_RESET} \t\t # Konfiguriert OpenSim.ini"
    log "${SYM_VOR} ${COLOR_WARNING}robusthginiconfig${COLOR_RESET} \t\t # Konfiguriert Robust.HG.ini"
    log "${SYM_VOR} ${COLOR_WARNING}robustiniconfig${COLOR_RESET} \t\t # Konfiguriert Robust.local.ini"
    log "${SYM_VOR} ${COLOR_WARNING}gridcommoniniconfig${COLOR_RESET} \t\t # Erstellt GridCommon.ini"
    log "${SYM_VOR} ${COLOR_WARNING}standalonecommoniniconfig${COLOR_RESET} \t # Erstellt StandaloneCommon.ini"
    log "${SYM_VOR} ${COLOR_WARNING}flotsaminiconfig${COLOR_RESET} \t\t # Erstellt FlotsamCache.ini"
    log "${SYM_VOR} ${COLOR_WARNING}osslenableiniconfig${COLOR_RESET} \t\t # Konfiguriert osslEnable.ini"
    log "${SYM_VOR} ${COLOR_WARNING}welcomeiniconfig${COLOR_RESET} \t\t # Konfiguriert Begrüßungsregion"
    log "${SYM_VOR} ${COLOR_WARNING}regionsiniconfig${COLOR_RESET} \t\t # Startet neue Regionen-Konfigurationen"
    log "${SYM_VOR} ${COLOR_WARNING}iniconfig${COLOR_RESET} \t\t\t # Startet ALLE Konfigurationen"
    echo " "

    #* XML & INI-Operationen
    log "${COLOR_SECTION}${SYM_SCRIPT} INI-Operationen:${COLOR_RESET}"
    log "${SYM_VOR} ${COLOR_OK}verify_ini_section${COLOR_RESET} \t\t # INI-Abschnitt verifizieren"
    log "${SYM_VOR} ${COLOR_OK}verify_ini_key${COLOR_RESET} \t\t # INI-Schlüssel verifizieren"
    log "${SYM_VOR} ${COLOR_OK}add_ini_section${COLOR_RESET} \t\t # INI-Abschnitt hinzufügen"
    log "${SYM_VOR} ${COLOR_OK}set_ini_key${COLOR_RESET} \t\t\t # INI-Schlüssel setzen"
    log "${SYM_VOR} ${COLOR_WARNING}del_ini_section${COLOR_RESET} \t\t # INI-Abschnitt löschen"
    echo " "

    #* XML-Operationen
    log "${COLOR_SECTION}${SYM_SCRIPT} XML-Operationen:${COLOR_RESET}"
    log "${SYM_VOR} ${COLOR_OK}verify_xml_section${COLOR_RESET} \t\t # XML-Abschnitt verifizieren"
    log "${SYM_VOR} ${COLOR_OK}add_xml_section${COLOR_RESET} \t\t # XML-Abschnitt hinzufügen"
    log "${SYM_VOR} ${COLOR_WARNING}del_xml_section${COLOR_RESET} \t\t # XML-Abschnitt löschen"
    echo " "

    #* System-Bereinigung
    log "${COLOR_SECTION}${SYM_CLEAN} Systembereinigung:${COLOR_RESET}"
    log "${SYM_VOR} ${COLOR_OK}reboot${COLOR_RESET} \t\t # Linux Server neu starten"
    log "${SYM_VOR} ${COLOR_OK}cacheclean${COLOR_RESET} \t\t # OpenSimulator Cache bereinigen"
    log "${SYM_VOR} ${COLOR_OK}logclean${COLOR_RESET} \t\t # OpenSimulator Logs bereinigen"
    log "${SYM_VOR} ${COLOR_OK}mapclean${COLOR_RESET} \t\t # OpenSimulator Maptiles bereinigen"
    log "${SYM_VOR} ${COLOR_OK}renamefiles${COLOR_RESET} \t\t # OpenSimulator Beispieldateien umbenennen"
    log "${SYM_VOR} ${COLOR_OK}clean_linux_logs${COLOR_RESET} \t # Linux-Logs bereinigen"
    log "${SYM_VOR} ${COLOR_OK}delete_opensim${COLOR_RESET} \t # OpenSimulator mit Verzeichnisse entfernen"
    echo " "

    #* Hilfe
    log "${COLOR_SECTION}${SYM_INFO} Hilfe:${COLOR_RESET}"
    log "${SYM_VOR} ${COLOR_OK}help${COLOR_RESET} \t\t # Einfache Hilfeseite anzeigen"
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
    simstart)                  simstart "$2" ;;
    simstop)                   simstop "$2" ;;
    simrestart)                simrestart "$2" ;;
    simstatus)                 simstatus ;;
    simlist)                   simlist ;;
    simrestartall)             simrestartall ;;
    simstopall)                simstopall ;;
    simstartall)               simstartall ;;

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
    osWebinterfacegit)          osWebinterfacegit ;;

    #  OPENSIM BUILD & DEPLOY #
    opensimbuild)      opensimbuild ;;
    opensimcopy)       opensimcopy ;;
    opensimupgrade)    opensimupgrade ;;
    database_setup)    database_setup ;;
    setup_webserver)   setup_webserver ;;
    removeconfigfiles) removeconfigfiles ;;
    webinstall)        webinstall ;;
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
    cleanconfig)                clean_config "$2" ;;
    createmasteruser)           createmasteruser "$2" "$3" "$4" "$5" "$6" ;;
    oswebinterfaceconfig)       oswebinterfaceconfig ;;
    firststart)                 firststart ;;

    #  Experimental            #
    configure_pbr_textures) configure_pbr_textures ;;

    #  INI-OPERATIONEN        #
    verify_ini_section)         verify_ini_section "$2" "$3" "$4" ;;
    verify_ini_key)             verify_ini_key "$2" "$3" "$4" ;;
    add_ini_section)            add_ini_section "$2" "$3" ;;
    add_ini_before_section)     add_ini_before_section "$2" "$3" "$4" ;;
    set_ini_key)                set_ini_key "$2" "$3" "$4" "$5" ;;
    add_ini_key)                add_ini_key "$2" "$3" "$4" "$5" ;;
    del_ini_section)            del_ini_section "$2" "$3" ;;
    uncomment_ini_line)         uncomment_ini_line "$2" "$3" ;;
    uncomment_ini_section_line) uncomment_ini_section_line "$2" "$3" "$4" ;;
    comment_ini_line)           comment_ini_line "$2" "$3" "$4" ;;
    iniconfig)                  iniconfig ;;

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

    # Tests                  #
    opensimstartParallel)           opensimstartParallel ;;
    faststop|opensimstopParallel)   opensimstopParallel ;;
    opensimrestartParallel)         opensimrestartParallel ;;
    autoupgrade)                    autoupgrade ;;
    autoupgradefast)                autoupgradefast ;;
    regionbackup)                   regionbackup ;;
    robustbackup)                   robustbackup "$2" "$3";;
    robustrestore)                  robustrestore "$2" "$3" "$4" ;;
    robustrepair)                   robustrepair "$2" "$3" "$4" ;;
    restoreRobustDump)              restoreRobustDump "$2" "$3" "$4" "$5" ;;

    #  HILFE & SONSTIGES      #
    generate_all_name)  generate_all_name ;;
    prohelp)            prohelp ;;
    h|help|hilfe|*)     help ;;
esac

# Programm Ende mit Zeitstempel
blankline
log "\e[36m${SCRIPTNAME}\e[0m ${VERSION} wurde beendet $(date +'%Y-%m-%d %H:%M:%S')" >&2
exit 0

# Ein Metaversum sind viele kleine Räume, die nahtlos aneinander passen, sowie direkt sichtbar und begehbar sind, als wäre es aus einem Guss.
# Ein Metaversum besteht aus vielen kleinen, nahtlos verbundenen Räumen, die direkt sichtbar und begehbar sind – als wäre alles aus einem Guss erschaffen.
# Das Metaversum setzt sich aus zahlreichen virtuellen Räumen zusammen, die ohne Ladezeiten oder Übergänge miteinander verbunden sind und sich wie eine zusammenhängende Welt erleben lassen.
