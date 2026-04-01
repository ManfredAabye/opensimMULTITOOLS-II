#!/bin/bash

#* WARTEZEITEN muessen leider sein damit der Server nicht überfordert wird.
Simulator_Start_wait=15 # Sekunden
MoneyServer_Start_wait=30 # Sekunden
RobustServer_Start_wait=30 # Sekunden
Simulator_Stop_wait=15 # Sekunden
MoneyServer_Stop_wait=30 # Sekunden
RobustServer_Stop_wait=30 # Sekunden

#?──────────────────────────────────────────────────────────────────────────────────────────
#* Start Stop Grid
#?──────────────────────────────────────────────────────────────────────────────────────────

function opensimstart() {
    echo "${SYM_WAIT} ${COLOR_START}Starte das Grid!${COLOR_RESET}"
    
    # 1. RobustServer (muss zuerst laufen)
    if [[ -d "robust/bin" && -f "robust/bin/Robust.dll" ]]; then
        echo "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}RobustServer ${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}robust/bin...${COLOR_RESET}"
        (cd robust/bin && screen -fa -S robustserver -d -U -m dotnet Robust.dll)
        sleep "$RobustServer_Start_wait"
    else
        echo "${SYM_BAD} ${COLOR_SERVER}RobustServer: ${COLOR_BAD}Robust.dll nicht gefunden.${COLOR_RESET} ${COLOR_START}Überspringe Start.${COLOR_RESET}"
    fi

    # 2. MoneyServer (optional)
    if [[ -f "robust/bin/MoneyServer.dll" ]]; then
        echo "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}MoneyServer${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}robust/bin...${COLOR_RESET}"
        (cd robust/bin && screen -fa -S moneyserver -d -U -m dotnet MoneyServer.dll)
        sleep "$MoneyServer_Start_wait"
    fi

    # 3. SIM1 ZUERST (sequentiell)
    if [[ -d "sim1/bin" && -f "sim1/bin/OpenSim.dll" ]]; then
        echo "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}sim1${COLOR_RESET} ${COLOR_START}(primäre Region)...${COLOR_RESET}"
        (cd sim1/bin && screen -fa -S sim1 -d -U -m dotnet OpenSim.dll)
        sleep "$Simulator_Start_wait"
    else
        echo "${SYM_BAD} ${COLOR_SERVER}sim1: ${COLOR_BAD}OpenSim.dll nicht gefunden.${COLOR_RESET}"
    fi

    # 4. SIM2-SIM99 PARALLEL
    echo "${SYM_INFO} ${COLOR_START}Starte sekundäre Simulatoren parallel...${COLOR_RESET}"
    
    # Maximal 10 parallele Jobs
    MAX_JOBS=10
    for ((i=2; i<=99; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" && -f "$sim_dir/OpenSim.dll" ]]; then
            
            # Warten falls zu viele Jobs laufen
            while (( $(jobs -p | wc -l) >= MAX_JOBS )); do
                sleep 1
            done
            
            echo "${SYM_OK} ${COLOR_START}Starte ${COLOR_SERVER}sim$i${COLOR_RESET} ${COLOR_START}aus ${COLOR_DIR}$sim_dir...${COLOR_RESET}"
            (cd "$sim_dir" && screen -fa -S "sim$i" -d -U -m dotnet OpenSim.dll) &
        fi
    done
    
    wait # Warte auf alle Hintergrundjobs
    echo "${SYM_OK} ${COLOR_START}Alle Simulatoren gestartet.${COLOR_RESET}"
    echo .
}

function opensimstop() {
    echo "${SYM_WAIT} ${COLOR_STOP}Stoppe das Grid!${COLOR_RESET}"
    local MAX_PARALLEL=10  # Maximale parallele Stopp-Vorgänge

    # 1. Paralleles Stoppen von sim999 bis sim2
    echo "${SYM_INFO} ${COLOR_STOP}Stoppe sekundäre Simulatoren parallel...${COLOR_RESET}"
    for ((i=999; i>=2; i--)); do
        sim_name="sim$i"
        
        # Warten falls zu viele parallele Jobs laufen
        #while [ $(jobs -p | wc -l) -ge $MAX_PARALLEL ]; do
        while [ "$(jobs -p | wc -l)" -ge $MAX_PARALLEL ]; do
            sleep 0.5
        done
        
        if screen -list | grep -q "$sim_name"; then
            echo "${SYM_OK} ${COLOR_STOP}Stoppe ${COLOR_SERVER}$sim_name${COLOR_RESET}"
            (
                screen -S "$sim_name" -p 0 -X stuff "shutdown^M"
                sleep $Simulator_Stop_wait
            ) &
        fi
    done
    wait  # Warte auf alle parallelen Stopp-Vorgänge

    # 2. Sim1 sequentiell stoppen
    if screen -list | grep -q "sim1"; then
        echo "${SYM_OK} ${COLOR_STOP}Stoppe ${COLOR_SERVER}sim1${COLOR_RESET} ${COLOR_STOP}(primäre Region)...${COLOR_RESET}"
        screen -S "sim1" -p 0 -X stuff "shutdown^M"
        sleep $Simulator_Stop_wait
    fi

    # 3. MoneyServer stoppen
    if screen -list | grep -q "moneyserver"; then
        echo "${SYM_OK} ${COLOR_STOP}Stoppe ${COLOR_SERVER}MoneyServer${COLOR_RESET} ${COLOR_STOP}...${COLOR_RESET}"
        screen -S moneyserver -p 0 -X stuff "shutdown^M"
        sleep $MoneyServer_Stop_wait
    else
        echo "${SYM_BAD} ${COLOR_SERVER}MoneyServer: ${COLOR_BAD}Läuft nicht.${COLOR_RESET}"
    fi

    # 4. RobustServer stoppen (zuletzt)
    if screen -list | grep -q "robustserver"; then
        echo "${SYM_OK} ${COLOR_STOP}Stoppe ${COLOR_SERVER}RobustServer${COLOR_RESET} ${COLOR_STOP}...${COLOR_RESET}"
        screen -S robustserver -p 0 -X stuff "shutdown^M"
        sleep $RobustServer_Stop_wait
    else
        echo "${SYM_BAD} ${COLOR_SERVER}RobustServer: ${COLOR_BAD}Läuft nicht.${COLOR_RESET}"
    fi

    echo "${SYM_OK} ${COLOR_STOP}Alle Dienste gestoppt.${COLOR_RESET}"
    echo .
}

# check_screens ist eine Grid Funktion und funktioniert nicht im Standalone.
# bash osmtool_backup.sh check_screens
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
    echo .
}

# Neu Test
function check_screens_neu() {
    echo "${SYM_WAIT} ${COLOR_START}Überprüfe laufende OpenSim-Prozesse...${COLOR_RESET}"
    restart_all=false
    log_file="ProblemRestarts.log"

    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    # Funktion zum Screen-Check
    function screen_running() {
        screen -ls | grep -qw "$1"
    }

    # RobustServer prüfen
    if [[ -d "robust/bin" && -f "robust/bin/Robust.dll" ]]; then
        if ! screen_running "robustserver"; then
            echo "$timestamp - RobustServer läuft nicht." >> "$log_file"
            restart_all=true
        fi
    fi

    # MoneyServer prüfen
    if [[ -f "robust/bin/MoneyServer.dll" ]]; then
        if ! screen_running "moneyserver"; then
            echo "$timestamp - MoneyServer läuft nicht." >> "$log_file"
            restart_all=true
        fi
    fi

    # sim1 prüfen
    if [[ -d "sim1/bin" && -f "sim1/bin/OpenSim.dll" ]]; then
        if ! screen_running "sim1"; then
            echo "$timestamp - sim1 läuft nicht." >> "$log_file"
            restart_all=true
        fi
    fi

    # Falls kritische Komponenten fehlen → kompletten Neustart
    if [[ "$restart_all" == true ]]; then
        echo "$timestamp - Kritische Komponenten fehlen. Starte das gesamte Grid neu." >> "$log_file"
        opensimrestart
        return 0
    fi

    # sim2 bis sim999 einzeln prüfen und ggf. neu starten
    for ((i=2; i<=999; i++)); do
        sim_dir="sim$i/bin"
        if [[ -d "$sim_dir" && -f "$sim_dir/OpenSim.dll" ]]; then
            if ! screen_running "sim$i"; then
                echo "$timestamp - sim$i läuft nicht. Starte Region neu." >> "$log_file"
                cd "$sim_dir" || continue
                screen -fa -S "sim$i" -d -U -m dotnet OpenSim.dll
                cd - >/dev/null 2>&1 || continue
                sleep $Simulator_Start_wait
            fi
        fi
    done

    echo "${SYM_OK} ${COLOR_START}Überprüfung abgeschlossen.${COLOR_RESET}"
    screen -ls || echo "Keine Screen-Sessions gefunden"
}


function opensimrestart() {
    opensimstop
    sleep $Simulator_Stop_wait  # Wartezeit für Dienst-Stopp
    opensimstart
    screen -ls || echo "Keine Screen-Sessions gefunden"
}


KOMMANDO="$1"

case $KOMMANDO in
    "start")
        opensimstart
        ;;
    "stop")
        opensimstop
        ;;
    "restart")
        opensimrestart
        ;;
    "check_screens")
        check_screens_neu
        ;;
    *)
        opensimrestart
        ;;
esac
# Ende des Skripts