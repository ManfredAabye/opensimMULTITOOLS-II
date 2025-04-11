#!/bin/bash

#──────────────────────────────────────────────────────────────────────────────────────────
#* Informationen
#──────────────────────────────────────────────────────────────────────────────────────────

SCRIPTNAME="opensimMULTITOOL II"
VERSION="V25.4.31.53"
echo "$SCRIPTNAME $VERSION"
tput reset # Bildschirmausgabe loeschen inklusive dem Scrollbereich.

echo -e "\e[36m$SCRIPTNAME\e[0m $VERSION"
echo "Dies ist ein Tool welches der Verwaltung von OpenSim Servern dient."
echo "Bitte beachten Sie, dass die Anwendung auf eigene Gefahr und Verantwortung erfolgt."
echo -e "\e[33mZum Abbrechen bitte STRG+C oder CTRL+C drücken.\e[0m"
echo " "

#──────────────────────────────────────────────────────────────────────────────────────────
#* Variablen
#──────────────────────────────────────────────────────────────────────────────────────────

# Hauptpfad des Skripts automatisch setzen
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
cd "$SCRIPT_DIR" || exit 1
echo "Arbeitsverzeichnis ist: $SCRIPT_DIR"
echo " "

KOMMANDO=$1 # Eingabeauswertung fuer Funktionen.
MONEYCOPY="yes" # MoneyServer Installieren.

#──────────────────────────────────────────────────────────────────────────────────────────
#* Abhängigkeiten installieren
#──────────────────────────────────────────────────────────────────────────────────────────

# Fehlende Abhängigkeiten installieren
function servercheck() {
    # Direkt kompatible Distributionen:
    # Debian 11+ (Bullseye, Bookworm) – Offiziell unterstützt für .NET 8
    # Ubuntu 18.04, 20.04, 22.04 – Microsoft bietet direkt kompatible Pakete
    # Linux Mint (basierend auf Ubuntu 20.04 oder 22.04)
    # Pop!_OS (System76, basiert auf Ubuntu)
    # MX Linux (Debian-basiert, integriert Ubuntu-Funktionen)
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
    else
        echo "✘ Keine unterstützte Version für .NET gefunden!"
        return 1
    fi

    # Prüfen, ob .NET bereits installiert ist
    if ! dpkg -s "$required_dotnet" >/dev/null 2>&1; then
        echo "Installiere $required_dotnet..."
        
        # Prüfen, ob die Microsoft-Paketquelle bereits existiert
        if ! dpkg -l | grep -q "packages-microsoft-prod"; then
            echo "Microsoft-Paketquelle hinzufügen..."
            wget https://packages.microsoft.com/config/"$os_id"/"$os_version"/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
            sudo dpkg -i packages-microsoft-prod.deb
            rm packages-microsoft-prod.deb
            sudo apt-get update
        fi
        
        # .NET installieren
        sudo apt-get install -y "$required_dotnet"
        echo "✓ $required_dotnet wurde erfolgreich installiert."
    else
        echo "✘ $required_dotnet ist bereits installiert."
    fi

    # Fehlende Pakete prüfen und installieren
    required_packages=("libc6" "libgcc-s1" "libgssapi-krb5-2" "libicu70" "liblttng-ust1" "libssl3" "libstdc++6" "libunwind8" "zlib1g" "libgdiplus" "zip" "screen")

    echo "Überprüfe fehlende Pakete..."
    for package in "${required_packages[@]}"; do
        if ! dpkg -s "$package" >/dev/null 2>&1; then
            echo "✓ Installiere $package..."
            sudo apt-get install -y "$package"
        fi
    done

    echo "✓ Alle benötigten Pakete wurden installiert."
}

#──────────────────────────────────────────────────────────────────────────────────────────
#* Start Stop Restart
#──────────────────────────────────────────────────────────────────────────────────────────

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

# OpenSim neu starten
function opensimrestart() {
    opensimstop
    sleep 30  # Kurze Pause, um sicherzustellen, dass alles gestoppt wurde
    opensimstart
    echo "Welche sim Regionen sind gestartet?:"
    screen -ls
}

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

function reboot() {
    echo "Server wird jetzt heruntergefahren und neu gestartet!"
    
    # Stoppen des ganzen OpenSim Grids.
    opensimstop

    # Starte den Server neu.
    shutdown -r now
}

#──────────────────────────────────────────────────────────────────────────────────────────
#* Erstellen eines OpenSimulators
#──────────────────────────────────────────────────────────────────────────────────────────

function opensimgitcopy() {
    echo "Möchten Sie den OpenSimulator vom GitHub verwenden? ([ja]/nein)"
    read -r user_choice

    user_choice=${user_choice:-ja}

    if [[ "$user_choice" == "ja" ]]; then
        # Falls eine alte Version existiert, diese entfernen
        if [[ -d "opensim" ]]; then
            echo "Vorhandene OpenSimulator-Version wird gelöscht..."
            rm -rf opensim
            echo "✓ Alte OpenSimulator-Version wurde erfolgreich entfernt."
        fi

        echo "OpenSimulator wird von GitHub geholt..."
        git clone git://opensimulator.org/git/opensim opensim
        echo "✓ OpenSimulator wurde erfolgreich heruntergeladen."

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
    else
        echo "✘ Abbruch: OpenSimulator wird nicht von GitHub geholt."
    fi
}

function moneygitcopy() {
    # Falls MONEYCOPY nicht gesetzt oder "no" ist, nichts tun
    if [[ -z "$MONEYCOPY" || "$MONEYCOPY" == "no" ]]; then
        return
    fi

    if [[ "$MONEYCOPY" == "yes" ]]; then
        echo "MONEYSERVER: MoneyServer wird vom GIT geholt"
        git clone https://github.com/ManfredAabye/opensimcurrencyserver-dotnet.git opensimcurrencyserver

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
    else
        echo "✘ MONEYSERVER: MoneyServer nicht vorhanden"
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

#──────────────────────────────────────────────────────────────────────────────────────────
#* Erstellen eines OpenSimulators Grids
#──────────────────────────────────────────────────────────────────────────────────────────

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
    if [[ -d "robust" ]]; then
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

#──────────────────────────────────────────────────────────────────────────────────────────
#* Upgrade des OpenSimulators Grids
#──────────────────────────────────────────────────────────────────────────────────────────


#──────────────────────────────────────────────────────────────────────────────────────────
#* Bereinigen des OpenSimulators Grids
#──────────────────────────────────────────────────────────────────────────────────────────

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

#──────────────────────────────────────────────────────────────────────────────────────────
#* Konfigurationen
#──────────────────────────────────────────────────────────────────────────────────────────

# Funktion zur Generierung von UUIDs
function generate_uuid() {
    uuidgen | tr '[:upper:]' '[:lower:]'
}

# Funktion zur Generierung von Zufallsnamen
function generate_name() {
    local adjectives=("Mystic" "Golden" "Silent" "Emerald" "Crystal" "Ancient" "Floating" "Hidden" "Lost" "Secret")
    local nouns=("Forest" "Island" "Sanctuary" "Realm" "Valley" "Garden" "Haven" "Retreat" "Domain" "Shore")
    echo "${adjectives[$RANDOM % 10]}-${nouns[$RANDOM % 10]}-$((RANDOM % 900 + 100))"
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
    #local maptile_uuid
    local config_file

    # Benutzereingabe
    echo "Wie viele Zufallsregionen sollen pro Simulator erstellt werden?"
    read -r regions_per_sim

    # Eingabeprüfung
    if ! [[ "$regions_per_sim" =~ ^[1-9][0-9]*$ ]]; then
        echo "Ungültige Eingabe: Bitte eine positive Zahl eingeben" >&2
        return 1
    fi

    system_ip=$(hostname -I | awk '{print $1}')

    echo "Starte Regionserstellung..."
    echo "--------------------------"

    # Simulatoren durchlaufen
    for ((sim_num=1; sim_num<=999; sim_num++)); do
        sim_dir="sim${sim_num}/bin/Regions"
        
        if [[ -d "$sim_dir" ]]; then
            #echo "Simulator $sim_num: Erstelle $regions_per_sim Region(en)"
            echo -e "\e[33mSimulator $sim_num: Erstelle $regions_per_sim Region(en)\e[0m" >&2
            
            # Regionen erstellen
            for ((region_num=1; region_num<=regions_per_sim; region_num++)); do
                # Position berechnen
                offset=$((region_num * 100))
                [[ $((RANDOM % 2)) -eq 0 ]] && offset=$((offset * -1))
                
                pos_x=$((center_x + offset))
                pos_y=$((center_y + offset))
                location="$pos_x,$pos_y"
                port=$((base_port + sim_num * 100 + region_num))
                
                # Eindeutige Werte
                region_name=$(generate_name)
                region_uuid=$(generate_uuid)
                #maptile_uuid=$(generate_uuid)
                
                # Config-Datei
                config_file="${sim_dir}/${region_name}.ini"
                
                # Datei erstellen
                if ! cat > "$config_file" <<EOF
[${region_name}]
RegionUUID = ${region_uuid}
Location = ${location}
SizeX = 256
SizeY = 256
SizeZ = 256
InternalPort = ${port}
ExternalHostName = ${system_ip}
MaxPrims = 15000
MaxAgents = 40
MaptileStaticUUID = ${region_uuid}
InternalAddress = 0.0.0.0
AllowAlternatePorts = False
NonPhysicalPrimMax = 512
PhysicalPrimMax = 128
;RegionType = Estate
;MasterAvatarFirstName = System
;MasterAvatarLastName = Admin
;MasterAvatarSandboxPassword = $(openssl rand -base64 12)
EOF
                then
                    #echo "Fehler beim Erstellen der Config für ${region_name}" >&2
                    echo -e "\e[31mFehler beim Erstellen der Config für ${region_name}\e[0m" >&2
                    continue
                fi
                
                #echo " - ${region_name} (${location}, Port ${port})"
                echo -e "\e[36m ✓ ${region_name} (${location}, Port ${port})\e[0m" >&2
            done
        fi
    done

    echo "--------------------------"
    echo "Regionserstellung abgeschlossen!"
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

#──────────────────────────────────────────────────────────────────────────────────────────
#* Funktion zur Konfiguration von OpenSimulator
#──────────────────────────────────────────────────────────────────────────────────────────

function configureopensim() {
    # Funktion für sichere Eingabeaufforderung
    prompt() {
        echo -n -e "${CYAN}$1${RESET}"
        read -r
    }

    # Funktion zur Vorbereitung der Konfigurationsdateien
    prepare_config_files() {
        local target_dir=$1
        
        if [ ! -d "$target_dir" ]; then
            echo -e "${RED}Fehler: Verzeichnis $target_dir nicht gefunden!${RESET}"
            return 1
        fi

        # In bin/config-include alle .example Dateien kopieren
        if [ -d "${target_dir}/bin/config-include" ]; then
            for example_file in "${target_dir}"/bin/config-include/*.example; do
                if [ -f "$example_file" ]; then
                    local target_file="${example_file%.example}"
                    if [ ! -f "$target_file" ]; then
                        cp "$example_file" "$target_file"
                        echo -e "${GREEN}Erstellt: ${target_file}${RESET}"
                    fi
                fi
            done
        fi

        # OpenSim.ini.example kopieren falls benötigt
        if [ -f "${target_dir}/bin/OpenSim.ini.example" ] && [ ! -f "${target_dir}/bin/OpenSim.ini" ]; then
            cp "${target_dir}/bin/OpenSim.ini.example" "${target_dir}/bin/OpenSim.ini"
            echo -e "${GREEN}Erstellt: ${target_dir}/bin/OpenSim.ini${RESET}"
        fi

        return 0
    }

    # Funktion für Robust-Konfiguration
function configure_robust() {
        local config_type=$1
        local robust_ini="${SCRIPT_DIR}/robust/bin/Robust.ini"
        
        if [ ! -f "$robust_ini" ]; then
            echo -e "${RED}Fehler: Robust.ini nicht gefunden!${RESET}"
            return 1
        fi

        # Sicherungskopie erstellen
        cp "$robust_ini" "${robust_ini}.bak"

        # Hostname setzen
        local hostname="Netzwerkadresse"
        [[ "$config_type" == *"Hypergrid"* ]] && hostname="Externe IP"
        
        sed -i "s/^BaseHostname = .*/BaseHostname = \"${hostname}\"/" "$robust_ini"
        sed -i "s/^;BaseHostname = .*/BaseHostname = \"${hostname}\"/" "$robust_ini"

        # Hypergrid-Einstellungen für Hypergrid-Modi
        if [[ "$config_type" == *"Hypergrid"* ]]; then
            sed -i 's/^;HomeURI =/HomeURI =/' "$robust_ini"
            sed -i 's/^;GatekeeperURI =/GatekeeperURI =/' "$robust_ini"
        fi

        # Datenbankeinstellungen
        db_password=$(grep "robust" "${SCRIPT_DIR}/mariadb_passwords.txt" | cut -d'=' -f2)
        if [ -n "$db_password" ]; then
            sed -i "s/^ConnectionString = .*/ConnectionString = \"Data Source=localhost;Database=robust;User ID=opensim;Password=${db_password};Old Guids=true;SslMode=None;\"/" "$robust_ini"
        else
            echo -e "${YELLOW}Warnung: Passwort für robust-Datenbank nicht gefunden!${RESET}"
        fi

        echo -e "${GREEN}Robust.ini erfolgreich konfiguriert${RESET}"
        return 0
    }

    # Funktion für GridCommon-Konfiguration
function configure_gridcommon() {
        local config_type=$1
        local gridcommon_ini="${SCRIPT_DIR}/opensim/bin/config-include/GridCommon.ini"
        
        if [ ! -f "$gridcommon_ini" ]; then
            echo -e "${RED}Fehler: GridCommon.ini nicht gefunden!${RESET}"
            return 1
        fi

        # Sicherungskopie erstellen
        cp "$gridcommon_ini" "${gridcommon_ini}.bak"

        # Const-Einstellungen aus der Grid.ini übernehmen
        const_settings=$(grep -A10 "^\[Const\]" "${SCRIPT_DIR}/opensim/bin/config-include/${config_type}.ini")
        
        # Vor [DatabaseService] einfügen
        sed -i "/^\[DatabaseService\]/i $const_settings" "$gridcommon_ini"

        # Datenbankeinstellungen
        db_password=$(grep "opensim" "${SCRIPT_DIR}/mariadb_passwords.txt" | cut -d'=' -f2)
        if [ -n "$db_password" ]; then
            sed -i "/^\[DatabaseService\]/,/^\[/ s/^StorageProvider = .*/StorageProvider = \"OpenSim.Data.MySQL.dll\"/" "$gridcommon_ini"
            sed -i "/^\[DatabaseService\]/,/^\[/ s/^ConnectionString = .*/ConnectionString = \"Data Source=localhost;Database=opensim;User ID=opensim;Password=${db_password};Old Guids=true;SslMode=None;\"/" "$gridcommon_ini"
        else
            echo -e "${YELLOW}Warnung: Passwort für opensim-Datenbank nicht gefunden!${RESET}"
        fi

        echo -e "${GREEN}GridCommon.ini erfolgreich konfiguriert${RESET}"
        return 0
    }

    # Hauptkonfigurationsfunktion
function do_configuration() {
        clear
        echo -e "${LIGHT_BLUE}=== OpenSimulator Konfiguration ===${RESET}"
        echo -e "${YELLOW}Warnung: Diese Aktion wird Konfigurationsdateien ändern!${RESET}"
        echo
        
        # Konfigurationsoptionen anzeigen
        echo -e "${LIGHT_CYAN}Verfügbare Modi:${RESET}"
        echo -e "1) Standalone (localhost)"
        echo -e "2) Standalone mit Hypergrid (externe IP)"
        echo -e "3) Grid (Netzwerk)"
        echo -e "4) Grid mit Hypergrid (externe IP)"
        echo -e "0) Abbrechen"
        echo
        
        prompt "Auswahl [1-4, 0 zum Abbrechen]: "
        case $REPLY in
            1) config_type="Standalone" ;;
            2) config_type="StandaloneHypergrid" ;;
            3) config_type="Grid" ;;
            4) config_type="GridHypergrid" ;;
            0) return ;;
            *) echo -e "${RED}Ungültige Auswahl!${RESET}"; return 1 ;;
        esac

        # Verzeichnisse vorbereiten
        case $config_type in
            "Standalone"|"StandaloneHypergrid")
                prepare_config_files "${SCRIPT_DIR}/opensim"
                ;;
            "Grid"|"GridHypergrid")
                prepare_config_files "${SCRIPT_DIR}/robust"
                configure_robust "$config_type"
                
                # Alle Simulator-Instanzen konfigurieren
                for sim_dir in "${SCRIPT_DIR}"/sim*; do
                    if [ -d "$sim_dir" ]; then
                        prepare_config_files "$sim_dir"
                    fi
                done
                
                configure_gridcommon "$config_type"
                ;;
        esac

        echo -e "${GREEN}Konfiguration abgeschlossen für ${config_type}-Modus${RESET}"
        prompt "Drücken Sie Enter um fortzufahren..."
    }

    do_configuration
}

#──────────────────────────────────────────────────────────────────────────────────────────
#* Automatischer Test
#──────────────────────────────────────────────────────────────────────────────────────────

function automatic () {
    servercheck # Zuerst nachsehen ob der Server bereit für OpenSim ist.
    createdirectory # Verzeichnisse erstellen.
    opensimgitcopy # OpenSim aus dem Git herunterladen.

    # Money und andere bestandteile herunterladen und in das opensim Verzeichnis kopieren.
    moneygitcopy

    opensimbuild # OpenSim kompilieren.
    opensimcopy # OpenSim kopieren in alle Verzeichnisse also robust und sim1 bis sim999 halt soviele wie vorhanden.
    # OpenSim konfigurieren.
    # opensimstart # OpenSim starten.
    # opensimstop # OpenSim stoppen.
    # opensimrestart # OpenSim neu starten.
    # check_screens # Laufende OpenSim Prozesse prüfen.

    # dataclean # RobustServer und simX-Server von alten Dateien befreien (Neuinstallation erforderlich).
    # pathclean # RobustServer und simX-Server von alten Verzeichnissen befreien (Neuinstallation erforderlich).
    # cacheclean # RobustServer und simX-Server Cache bereinigen.
    # logclean # RobustServer und simX-Server von alten Log´s befreien.
    # mapclean # RobustServer und simX-Server von alten Maptile befreien.
    # autoallclean # RobustServer und simX-Server von alten Dateien und Verzeichnissen befreien (Neuinstallation erforderlich).
}

#──────────────────────────────────────────────────────────────────────────────────────────
#* Hilfefunktionen
#──────────────────────────────────────────────────────────────────────────────────────────

function help () {
    echo -e "\e[36mOpenSim Grid Starten Stoppen und Restarten:\e[0m"
    echo -e "\e[32mopensimstart\e[0m # OpenSim starten.\e[0m"
    echo -e "\e[32mopensimstop\e[0m # OpenSim stoppen.\e[0m"
    echo -e "\e[32mopensimrestart\e[0m # OpenSim neu starten.\e[0m"
    echo -e "\e[32mcheck_screens\e[0m # Laufende OpenSim Prozesse prüfen und restarten.\e[0m"
    echo " "

    echo -e "\e[36mEin OpenSim Grid erstellen oder aktualisieren:\e[0m"
    echo -e "\e[32mservercheck\e[0m # Zuerst nachsehen ob der Server bereit für OpenSim ist."
    echo -e "\e[32mcreatedirectory\e[0m # Verzeichnisse erstellen."
    echo -e "\e[32mmariasetup\e[0m # MariaDB Datenbanken erstellen."
    echo -e "\e[32msqlsetup\e[0m # SQL Datenbanken erstellen."
    echo -e "\e[32mopensimgitcopy\e[0m # OpenSim aus dem Git herunterladen."
    echo -e "\e[32mmoneygitcopy\e[0m # MoneyServer aus dem Git herunterladen."
    echo -e "\e[32mopensimbuild\e[0m # OpenSim kompilieren."
    echo -e "\e[32mconfigureopensim\e[0m # Vorkonfigurieren des OpenSimulators.\e[0m"
    echo -e "\e[32mopensimcopy\e[0m # OpenSim kopieren (in alle Verzeichnisse)."
    echo -e "\e[35mopensimconfig # Eine funktionsfähige konfiguration fehlt noch.\e[0m"
    echo -e "\e[32mregionsconfig\e[0m # OpenSim Regionen konfigurieren."
    echo " "    

    echo -e "\e[36mOpenSim Grid Bereinigen von alten Dateien, Verzeichnissen und Cache:\e[0m"
    echo -e "\e[32mdataclean\e[0m # Robust und simX von alten Dateien befreien (Neuinstallation erforderlich).\e[0m"
    echo -e "\e[32mpathclean\e[0m # Robust und simX von alten Verzeichnissen befreien (Neuinstallation erforderlich).\e[0m"
    echo -e "\e[32mcacheclean\e[0m # Robust und simX Cache bereinigen.\e[0m"
    echo -e "\e[32mlogclean\e[0m # Robust und simX von alten Logs befreien.\e[0m"
    echo -e "\e[32mmapclean\e[0m # Robust und simX von alten Maptile Karten befreien.\e[0m"
    echo -e "\e[32mautoallclean\e[0m # Robust und simX von alten Dateien und Verzeichnissen befreien (Neuinstallation erforderlich).\e[0m"
    echo -e "\e[32mregionsclean\e[0m # Löscht alle konfigurierten Regionen aus allen Simulatoren.\e[0m"    
    echo " "
}

#──────────────────────────────────────────────────────────────────────────────────────────
#* Eingabeauswertung
#──────────────────────────────────────────────────────────────────────────────────────────
case $KOMMANDO in
    servercheck) servercheck ;;
	createdirectory) createdirectory ;;
    mariasetup) mariasetup ;;
    sqlsetup) sqlsetup ;;
    opensimgitcopy) opensimgitcopy ;;
    moneygitcopy) moneygitcopy ;;
    opensimbuild) opensimbuild ;;
    opensimcopy) opensimcopy ;;
    configure|configureopensim) configureopensim ;; # Die automatische konfiguration zu testzwecken.
    regionsconfig) regionsconfig ;;
    start|opensimstart) opensimstart ;;
    stop|opensimstop) opensimstop ;;
    osrestart|autorestart|restart|opensimrestart) opensimrestart ;;
    reboot) reboot ;;
    check_screens) check_screens ;;
    dataclean) dataclean ;;
    pathclean) pathclean ;;
    cacheclean) cacheclean ;;
    logclean) logclean ;;
    mapclean) mapclean ;;
    autoallclean) autoallclean ;;
    regionsclean) regionsclean ;;
    automatic) automatic ;; # Die automatische Installation zu testzwecken.
	h|help|hilfe|*) help ;;
esac

# Programm Ende
echo -e "\e[36m${SCRIPTNAME}\e[0m ${VERSION} wurde beendet $(date +'%Y-%m-%d %H:%M:%S')" >&2
exit 0
