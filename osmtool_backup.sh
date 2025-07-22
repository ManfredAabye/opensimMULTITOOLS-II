#!/bin/bash

STARTVERZEICHNIS="/opt" # Startverzeichnis
ROBUSTVERZEICHNIS="Robust" # Robust Verzeichnis
REGIONSDATEI="osmregionlist.ini" # Regionsdatei
SIMDATEI="osmsimlist.ini" # Simulationsdatei
BACKUPWARTEZEIT=60 # Wartezeit in Sekunden zwischen den Backups

KOMMANDO=$1

#──────────────────────────────────────────────────────────────────────────────────────────
#* Informationen
#──────────────────────────────────────────────────────────────────────────────────────────
#

## * makeverzeichnisliste 
	# Eine Funktion zum Erstellen einer Liste von Verzeichnissen aus einer Datei.
	#? Verwendung: makeverzeichnisliste
	# Diese Funktion liest Zeilen aus der angegebenen SIMDATEI im STARTVERZEICHNIS und erstellt eine
	# Liste von Verzeichnissen. Die Liste wird in der globalen Variable VERZEICHNISSLISTE gespeichert.
	# Die Anzahl der Einträge in der Liste wird in der globalen Variable ANZAHLVERZEICHNISSLISTE gespeichert.
	#? Argumente:
	#   STARTVERZEICHNIS - Das Verzeichnis, in dem sich die SIMDATEI befindet.
	#   SIMDATEI - Die Datei, aus der die Verzeichnisse gelesen werden sollen.
	#? Beispielaufruf
	# makeverzeichnisliste
##
function makeverzeichnisliste() {
	# Letzte Bearbeitung 27.09.2023

    # Initialisieren der Verzeichnisliste
	VERZEICHNISSLISTE=()

	 # Schleife zum Lesen der Zeilen aus der SIMDATEI und Hinzufügen zum Array
	while IFS= read -r line; do
		VERZEICHNISSLISTE+=("$line")
	done </$STARTVERZEICHNIS/$SIMDATEI

	# Anzahl der Einträge in der Verzeichnisliste
	ANZAHLVERZEICHNISSLISTE=${#VERZEICHNISSLISTE[*]}

	# Erfolgreiche Ausführung
	return 0
}

## * makeregionsliste 
	# Eine Funktion zum Erstellen einer Liste von Regionen aus einer Datei.
	#? Verwendung: makeregionsliste
	# Diese Funktion liest Zeilen aus der angegebenen REGIONSDATEI im STARTVERZEICHNIS und erstellt eine
	# Liste von Regionen. Die Liste wird in der globalen Variable REGIONSLISTE gespeichert.
	# Die Anzahl der Einträge in der Liste wird in der globalen Variable ANZAHLREGIONSLISTE gespeichert.
	#? Argumente:
	#   STARTVERZEICHNIS - Das Verzeichnis, in dem sich die REGIONSDATEI befindet.
	#   REGIONSDATEI - Die Datei, aus der die Regionen gelesen werden sollen.
	#? Beispiel:
	# makeregionsliste
##
function makeregionsliste() {
	# Letzte Bearbeitung 27.09.2023

    # Initialisieren der Regionenliste
	REGIONSLISTE=()

	# Schleife zum Lesen der Zeilen aus der REGIONSDATEI und Hinzufügen zum Array
	while IFS= read -r line; do
		REGIONSLISTE+=("$line")
	done </$STARTVERZEICHNIS/$REGIONSDATEI

	# Anzahl der Einträge in der Regionenliste
	ANZAHLREGIONSLISTE=${#REGIONSLISTE[*]} # Anzahl der Eintraege.

	# Erfolgreiche Ausführung
	return 0
}

## * regionsiniteilen
	# Diese Funktion nimmt drei Argumente entgegen: das Verzeichnis, aus dem die Werte gelesen werden sollen ($INIVERZEICHNIS),
	# den Namen der Region, für die die Werte gespeichert werden sollen ($RTREGIONSNAME), und den Pfad zur Haupt-Regions.ini-Datei
	# ($INI_FILE). Die Funktion überprüft, ob die Haupt-Regions.ini-Datei vorhanden ist, und wenn nicht, werden die Werte für die
	# angegebene Region in eine separate INI-Datei geschrieben.
	#? Parameter:
	#   - $1: Das Verzeichnis, aus dem die Werte gelesen werden sollen.
	#   - $2: Der Name der Region, für die die Werte gespeichert werden sollen.
	#   - $3: Der Pfad zur Haupt-Regions.ini-Datei.
	#? Rückgabewert:
	#   - 0: Erfolgreiche Ausführung der Funktion
	#? Verwendungsbeispiel:
	#   regionsiniteilen "MeinVerzeichnis" "MeineRegion" "/MeinVerzeichnis/bin/Regions/Regions.ini"
##
function regionsiniteilen() {
	# Letzte Bearbeitung 01.10.2023
	INIVERZEICHNIS=$1                                                     # Auszulesendes Verzeichnis
	RTREGIONSNAME=$2                                                      # Auszulesende Region
	INI_FILE="/$STARTVERZEICHNIS/$INIVERZEICHNIS/bin/Regions/Regions.ini" # Auszulesende Datei

	if [ ! -d "$INI_FILE" ]; then
		log info "REGIONSINITEILEN: Schreiben der Werte fuer $RTREGIONSNAME"
		# Schreiben der einzelnen Punkte nur wenn vorhanden ist.
		# shellcheck disable=SC2005
		{
			echo "[$RTREGIONSNAME]"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "RegionUUID")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "Location")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "SizeX")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "SizeY")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "SizeZ")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "InternalAddress")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "InternalPort")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "AllowAlternatePorts")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "ResolveAddress")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "ExternalHostName")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "MaxPrims")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "MaxAgents")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "DefaultLanding")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "NonPhysicalPrimMax")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "PhysicalPrimMax")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "ClampPrimSize")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "MaxPrimsPerUser")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "ScopeID")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "RegionType")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "MaptileStaticUUID")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "MaptileStaticFile")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "MasterAvatarFirstName")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "MasterAvatarLastName")"
			echo "$(get_value_from_Region_key "${INI_FILE}" "$RTREGIONSNAME" "MasterAvatarSandboxPassword")"
		} >>"/$STARTVERZEICHNIS/$INIVERZEICHNIS/bin/Regions/$RTREGIONSNAME.ini"
	else
		log error "REGIONSINITEILEN: $INI_FILE wurde nicht gefunden"
	fi
	return 0
}

## * autoregionsiniteilen
	# Diese Funktion ruft zuerst die Funktion `makeverzeichnisliste` auf, um eine Liste von Verzeichnissen zu erstellen,
	# und iteriert dann über jedes Verzeichnis in der Liste. Für jedes Verzeichnis wird die Regions.ini-Datei in mehrere
	# separate INI-Dateien aufgeteilt, eine für jede Region, und die einzelnen Regionsdateien werden umbenannt. Falls die
	# Regions.ini-Datei in einem Verzeichnis nicht vorhanden ist, wird sie nicht umbenannt.
	#? Parameter:
	#   - Keine
	#? Rückgabewert:
	#   - 0: Erfolgreiche Ausführung der Funktion
	#? Verwendungsbeispiel:
	#   autoregionsiniteilen
##
function autoregionsiniteilen() {
	# Letzte Bearbeitung 01.10.2023
	makeverzeichnisliste
	sleep 1
	for ((i = 0; i < "$ANZAHLVERZEICHNISSLISTE"; i++)); do
		log info "Region.ini ${VERZEICHNISSLISTE[$i]} zerlegen"
		log line
		VERZEICHNIS="${VERZEICHNISSLISTE[$i]}"
		# Regions.ini teilen:
		echo "$VERZEICHNIS"                                                # OK geht
		INI_FILE="/$STARTVERZEICHNIS/$VERZEICHNIS/bin/Regions/Regions.ini" # Auszulesende Datei
		# shellcheck disable=SC2155
		declare -a TARGETS="$(get_regionsarray "${INI_FILE}")"
		# shellcheck disable=SC2068
		for MeineRegion in ${TARGETS[@]}; do
			regionsiniteilen "$VERZEICHNIS" "$MeineRegion"
			sleep 1
			log rohtext "regionsiniteilen $VERZEICHNIS $MeineRegion"
		done
		#  Dann umbenennen:
		# Pruefung ob Datei vorhanden ist, wenn ja umbenennen.
		if [ ! -d "$INI_FILE" ]; then
			mv /$STARTVERZEICHNIS/"$INIVERZEICHNIS"/bin/Regions/Regions.ini /$STARTVERZEICHNIS/"$INIVERZEICHNIS"/bin/Regions/"$DATUM"-Regions.ini.old
		fi
	done
	return 0
}

## * createregionlist
	# Diese Funktion erstellt eine Liste von Regionsnamen aus den INI-Dateien in den angegebenen Verzeichnissen und speichert
	# sie in der Datei osmregionlist.ini. Zuvor wird die vorhandene osmregionlist.ini-Datei (falls vorhanden) gesichert und in
	# osmregionlist.ini.old umbenannt.
	#? Parameter:
	#   - Keine
	#? Rückgabewert:
	#   - 0: Erfolgreiche Ausführung der Funktion
	#? Verwendungsbeispiel:
	#   createregionlist
##  
function createregionlist() {
	# Letzte Bearbeitung 01.10.2023
	# Alte osmregionlist.ini sichern und in osmregionlist.ini.old umbenennen.
	if [ -f "/$STARTVERZEICHNIS/osmregionlist.ini" ]; then
		if [ -f "/$STARTVERZEICHNIS/osmregionlist.ini.old" ]; then
			rm -r /$STARTVERZEICHNIS/osmregionlist.ini.old
		fi
		mv /$STARTVERZEICHNIS/osmregionlist.ini /$STARTVERZEICHNIS/osmregionlist.ini.old
	fi
	# Die mit regionsconfigdateiliste erstellte Datei osmregionlist.ini nach sim Verzeichnis und Regionsnamen in die osmregionlist.ini speichern.
	declare -A Dateien # Array erstellen
	makeverzeichnisliste
	sleep 1
	for ((i = 0; i < "$ANZAHLVERZEICHNISSLISTE"; i++)); do
		log info "Regionnamen ${VERZEICHNISSLISTE[$i]} schreiben"
		VERZEICHNIS="${VERZEICHNISSLISTE[$i]}"
		# shellcheck disable=SC2178
		Dateien=$(find /$STARTVERZEICHNIS/"$VERZEICHNIS"/bin/Regions/ -name "*.ini")
		for i2 in "${Dateien[@]}"; do # Array abarbeiten
			echo "$i2" >>osmregionlist.ini
		done
	done
	# Ueberfluessige Zeichen entfernen
	LOESCHEN=$(sed s/'\/'$STARTVERZEICHNIS'\/'//g /$STARTVERZEICHNIS/osmregionlist.ini)
	echo "$LOESCHEN" >/$STARTVERZEICHNIS/osmregionlist.ini                           # Aenderung /$STARTVERZEICHNIS/ speichern.
	LOESCHEN=$(sed s/'\/bin\/Regions\/'/' "'/g /$STARTVERZEICHNIS/osmregionlist.ini) # /bin/Regions/ entfernen.
	echo "$LOESCHEN" >/$STARTVERZEICHNIS/osmregionlist.ini                           # Aenderung /bin/Regions/ speichern.
	LOESCHEN=$(sed s/'.ini'/'"'/g /$STARTVERZEICHNIS/osmregionlist.ini)              # Endung .ini entfernen.
	echo "$LOESCHEN" >/$STARTVERZEICHNIS/osmregionlist.ini                           # Aenderung .ini entfernen speichern.

	LOESCHEN=$(sed s/'\"'/''/g /$STARTVERZEICHNIS/osmregionlist.ini) # " entfernen.
	echo "$LOESCHEN" >/$STARTVERZEICHNIS/osmregionlist.ini                           # Aenderung " entfernen speichern.

	# Schauen ob da noch Regions.ini bei sind also Regionen mit dem Namen Regions, diese Zeilen loeschen.
	LOESCHEN=$(sed '/Regions/d' /$STARTVERZEICHNIS/osmregionlist.ini) # Alle Zeilen mit dem Eintrag Regions entfernen	.
	echo "$LOESCHEN" >/$STARTVERZEICHNIS/osmregionlist.ini            # Aenderung .ini entfernen speichern.
	return 0
}

## * regionbackup
	# Diese Funktion erstellt ein Backup für eine OpenSimulator-Region, indem sie OAR- und Terrain-Daten sowie Konfigurationsdateien speichert.
	# Die Region wird in den Offline-Modus versetzt, wenn sie nicht bereits offline ist, bevor das Backup erstellt wird.
	#? Parameter:
	#   1. BACKUPVERZEICHNISSCREENNAME: Der Name des Bildschirms (Screen) für das Backup.
	#   2. REGIONSNAME: Der Name der Region, die gesichert werden soll.
	#? Rückgabewert:
	#   - 0: Erfolgreiche Ausführung der Funktion
	#? Verwendungsbeispiel:
	#   regionbackup "BackupScreen" "MyRegion"
##
function regionbackup() {
	# Letzte Bearbeitung 01.10.2023
	# regionbackup "$BACKUPSCREEN" "$BACKUPREGION"
	echo "Erstelle Backup von: $BACKUPSCREEN $BACKUPREGION"

	sleep 1
	BACKUPVERZEICHNISSCREENNAME=$1
	REGIONSNAME=$2

	echo
	echo "Backup $BACKUPVERZEICHNISSCREENNAME der Region $REGIONSNAME"
	cd /$STARTVERZEICHNIS/"$BACKUPVERZEICHNISSCREENNAME"/bin || return 1 # Test ob Verzeichnis vorhanden.
	mkdir -p /$STARTVERZEICHNIS/backup # Backup Verzeichnis anlegen falls nicht vorhanden.
	echo "Ich kann nicht pruefen ob die Region im OpenSimulator vorhanden ist."
	echo "Sollte sie nicht vorhanden sein wird root also alle Regionen gespeichert"
	# Ist die Region Online oder Offline?
	if [ -f /$STARTVERZEICHNIS/"$BACKUPVERZEICHNISSCREENNAME"/bin/Regions/"$REGIONSNAME".ini.offline ]; then
	echo "$REGIONSNAME ist heruntergefahren."
	else
	screen -S "$BACKUPVERZEICHNISSCREENNAME" -p 0 -X eval "stuff 'change region ${REGIONSNAME//\"/}'^M"
	echo "$BACKUPVERZEICHNISSCREENNAME $REGIONSNAME"
	screen -S "$BACKUPVERZEICHNISSCREENNAME" -p 0 -X eval "stuff 'save oar /$STARTVERZEICHNIS/backup/'$DATUM'-$REGIONSNAME.oar'^M"
	echo "$BACKUPVERZEICHNISSCREENNAME $DATUM-$REGIONSNAME.oar"

	# Neu xml backup
	screen -S "$BACKUPVERZEICHNISSCREENNAME" -p 0 -X eval "stuff 'save xml2 /$STARTVERZEICHNIS/backup/'$DATUM'-$REGIONSNAME.xml2'^M"
	echo "$BACKUPVERZEICHNISSCREENNAME $DATUM-$REGIONSNAME.xml2"
	# Neu xml backup ende

	screen -S "$BACKUPVERZEICHNISSCREENNAME" -p 0 -X eval "stuff 'terrain save /$STARTVERZEICHNIS/backup/'$DATUM'-$REGIONSNAME.png'^M"
	echo "$BACKUPVERZEICHNISSCREENNAME $DATUM-$REGIONSNAME.png"
	screen -S "$BACKUPVERZEICHNISSCREENNAME" -p 0 -X eval "stuff 'terrain save /$STARTVERZEICHNIS/backup/'$DATUM'-$REGIONSNAME.raw'^M"
	echo "$BACKUPVERZEICHNISSCREENNAME $DATUM-$REGIONSNAME.raw"
	echo "$BACKUPVERZEICHNISSCREENNAME Region $DATUM-$REGIONSNAME RAW und PNG Terrain werden gespeichert"
	fi
	
	sleep 10
	if [ -f /$STARTVERZEICHNIS/"$BACKUPVERZEICHNISSCREENNAME"/bin/Regions/"$REGIONSNAME".ini.offline ]; then
		cp /$STARTVERZEICHNIS/"$BACKUPVERZEICHNISSCREENNAME"/bin/Regions/"$REGIONSNAME".ini.offline /$STARTVERZEICHNIS/backup/"$DATUM"-"$REGIONSNAME".ini.offline
		echo "$BACKUPVERZEICHNISSCREENNAME Die Regions $DATUM-$REGIONSNAME.ini.offline wird gespeichert"
	fi
	if [ -f /$STARTVERZEICHNIS/"$BACKUPVERZEICHNISSCREENNAME"/bin/Regions/"$REGIONSNAME".ini ]; then
		cp /$STARTVERZEICHNIS/"$BACKUPVERZEICHNISSCREENNAME"/bin/Regions/"$REGIONSNAME".ini /$STARTVERZEICHNIS/backup/"$DATUM"-"$REGIONSNAME".ini
		echo "$BACKUPVERZEICHNISSCREENNAME Die Regions $DATUM-$REGIONSNAME.ini wird gespeichert"
	fi
	if [ -f /$STARTVERZEICHNIS/"$BACKUPVERZEICHNISSCREENNAME"/bin/Regions/"${REGIONSNAME//\"/}" ]; then
		cp /$STARTVERZEICHNIS/"$BACKUPVERZEICHNISSCREENNAME"/bin/Regions/"${REGIONSNAME//\"/}" /$STARTVERZEICHNIS/backup/"$DATUM"-"$REGIONSNAME".ini
		echo "$BACKUPVERZEICHNISSCREENNAME Die Regions $DATUM-$REGIONSNAME.ini wird gespeichert"
	fi

	echo "Backup der Region $REGIONSNAME wird fertiggestellt."
	return 0
}


## * autoallclean.
	# loescht Log, dll, so, exe, aot Dateien fuer einen saubere neue installation, mit Robust.
	# Hierbei werden keine Datenbanken oder Konfigurationen geloescht aber opensim ist anschliessend nicht mehr startbereit.
	# Um opensim wieder Funktionsbereit zu machen muss ein Upgrade oder ein oscopy vorgang ausgefuehrt werden.
	#? @param keine.
	#? @return nichts wird zurueckgegeben.
	# todo: nichts.
##
function autoallclean() {
	# Letzte Bearbeitung 01.10.2023
	makeverzeichnisliste
	sleep 1
	for ((i = 0; i < "$ANZAHLVERZEICHNISSLISTE"; i++)); do
		# Dateien
		rm /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/*.log
		rm /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/*.dll
		rm /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/*.exe
		rm /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/*.so
		rm /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/*.xml
		rm /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/*.dylib
		rm /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/*.example
		rm /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/*.sample
		rm /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/*.txt
		rm /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/*.config
		rm /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/*.py
		rm /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/*.old
		rm /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/*.pdb

		# Verzeichnisse leeren
		rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/assetcache/*
		rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/maptiles/*
		rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/MeshCache/*
		rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/j2kDecodeCache/*
		rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/ScriptEngines/*

        rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/addin-db-002/*
        rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/addon-modules/*
        rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/assets/*
        rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/bakes/*
        rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/data/*
        rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/Estates/*
        rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/inventory/*
        rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/lib/*
        rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/lib32/*
        rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/lib64/*
        rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/Library/*
        rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/openmetaverse_data/*
        rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/robust-include/*

		echo "autoallclean: ${VERZEICHNISSLISTE[$i]} geloescht"
		sleep 1
	done
	# nochmal das gleiche mit Robust
	echo "autoallclean: $ROBUSTVERZEICHNIS geloescht"
	rm /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/*.log
	rm /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/*.dll
	rm /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/*.exe
	rm /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/*.so
	rm /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/*.xml
	rm /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/*.dylib
	rm /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/*.example
	rm /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/*.sample
	rm /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/*.txt
	rm /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/*.config
	rm /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/*.py
	rm /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/*.old
	rm /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/*.pdb

	rm -r /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/assetcache/*
	rm -r /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/maptiles/*
	rm -r /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/MeshCache/*
	rm -r /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/j2kDecodeCache/*
	rm -r /$STARTVERZEICHNIS/$ROBUSTVERZEICHNIS/bin/ScriptEngines/*

	rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/addin-db-002/*
	rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/addon-modules/*
	rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/assets/*
	rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/bakes/*
	rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/data/*
	rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/Estates/*
	rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/inventory/*
	rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/lib/*
	rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/lib32/*
	rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/lib64/*
	rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/Library/*
	rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/openmetaverse_data/*
	rm -r /$STARTVERZEICHNIS/"${VERZEICHNISSLISTE[$i]}"/bin/robust-include/*

	return 0
}

## * autoregionbackup
	# Diese Funktion durchläuft die Regionen in Ihrem OpenSimulator-Grid und erstellt automatische Backups.
	#? Parameter:
	#   Keine Parameter erforderlich.
	#? Rückgabewert:
	#   - Kein expliziter Rückgabewert
	#? Verwendungsbeispiel:
	#   autoregionbackup
	# todo: Uebergabe Parameter Fehler. Bug Modus mit extra ausgaben. Ist keine osmregionlist.ini vorhanden muss sie erstellt werden.
##
function autoregionbackup() {
	# Letzte Bearbeitung 01.10.2023
	echo "Automatisches Backup wird gestartet."

    # Ist die osmregionlist.ini vorhanden?
    if [ ! -f "/$STARTVERZEICHNIS/osmregionlist.ini" ]; then
        echo "Die osmregionlist.ini Datei ist noch nicht vorhanden und wird erstellt."
		createregionlist
    else
        echo "Die osmregionlist.ini Datei ist bereits vorhanden."
    fi

	makeregionsliste
	sleep 1
	for ((i = 0; i < "$ANZAHLREGIONSLISTE"; i++)); do
		BACKUPSCREEN=$(echo "${REGIONSLISTE[$i]}" | cut -d ' ' -f 1)
		BACKUPREGION=$(echo "${REGIONSLISTE[$i]}" | cut -d ' ' -f 2)
		echo "Starte  Backup von: $BACKUPSCREEN $BACKUPREGION" # Testausgabe
		regionbackup "$BACKUPSCREEN" "$BACKUPREGION"
		if [ -f /$STARTVERZEICHNIS/"$BACKUPSCREEN"/bin/Regions/"$BACKUPREGION".ini.offline ]; then
			echo "$BACKUPREGION Region ist Offline und wird uebersprungen."
		else
			sleep $BACKUPWARTEZEIT
			echo "BACKUPWARTEZEIT $BACKUPWARTEZEIT Sekunden." # Testausgabe
		fi
	done
	return 0
}

# Zähle die Tabellen in der Datenbank und die Asset-Typen in der Tabelle 'assets'.
# bash osmtool_backup.sh datenbanktabellen "mein_benutzer" "geheim123" "meine_datenbank"
function datenbanktabellen() {
    username=$1
    password=$2
    databasename=$3
    logfile="/$STARTVERZEICHNIS/backup/${databasename}/status_report.txt"

    mkdir -p "/$STARTVERZEICHNIS/backup/${databasename}" || exit

    echo "📊 Statusbericht für Datenbank: $databasename" | tee "$logfile"
    echo "📅 Datum: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$logfile"

    # Tabellen zählen
    tabellenanzahl=$(mysql -u"$username" -p"$password" -D"$databasename" -e "SHOW TABLES;" | tail -n +2 | wc -l)
    echo "📦 Tabellen gefunden: $tabellenanzahl" | tee -a "$logfile"

    # Asset-Typen zählen (wenn Tabelle vorhanden)
    if mysql -u"$username" -p"$password" -D"$databasename" -e "SHOW TABLES LIKE 'assets';" | grep -q "assets"; then
        assettypen_anzahl=$(mysql -u"$username" -p"$password" -D"$databasename" -e "SELECT COUNT(DISTINCT assetType) FROM assets;" | tail -n 1)
        echo "🎨 Asset-Typen in 'assets': $assettypen_anzahl" | tee -a "$logfile"
    else
        echo "⚠️ Tabelle 'assets' nicht gefunden." | tee -a "$logfile"
    fi

    echo "✅ Bericht gespeichert unter: $logfile"
}


# beispiel: screen -fa -S BACKUPNOASSETS -d -U -m bash osmtool.sh backuptabelle_noassets "mein_benutzer" "geheim123" "meine_datenbank"
function backuptabelle_noassets() {
    username=$1
    password=$2
    databasename=$3

    mkdir -p /$STARTVERZEICHNIS/backup/"$databasename" || exit
    logfile="/$STARTVERZEICHNIS/backup/${databasename}/backup_log.txt"

    # Tabellennamen holen und speichern
    mysql -u"$username" -p"$password" -D"$databasename" -e "SHOW TABLES;" | tail -n +2 > /$STARTVERZEICHNIS/backup/"$databasename"/liste.txt

    # Anzahl der Tabellen zählen
    tabellenanzahl=$(wc -l < /$STARTVERZEICHNIS/backup/"$databasename"/liste.txt)
    echo "📦 Tabellen gefunden: $tabellenanzahl" | tee -a "$logfile"

    # Tabellen sichern (außer 'assets')
    gesichert=0
    while IFS= read -r tabellenname; do
        sleep 1
        if [[ "$tabellenname" != "assets" ]]; then
            mysqldump -u"$username" -p"$password" "$databasename" "$tabellenname" | zip > /$STARTVERZEICHNIS/backup/"$databasename"/"$tabellenname".sql.zip
            echo "✅ Gesichert: $tabellenname" | tee -a "$logfile"
            ((gesichert++))
        fi
    done < /$STARTVERZEICHNIS/backup/"$databasename"/liste.txt

    echo "🔒 Tabellen gesichert (ohne 'assets'): $gesichert" | tee -a "$logfile"
    return 0
}

# screen -fa -S ASSETBACKUP -d -U -m bash osmtool.sh asset_backup "mein_benutzer" "geheim123" "meine_datenbank"
function asset_backup() {
    username=$1
    password=$2
    databasename=$3
    fromtable="assets"
    fromtypes="assetType"

    mkdir -p /$STARTVERZEICHNIS/backup/"$databasename"/assets || exit
    cd /$STARTVERZEICHNIS/backup/"$databasename"/assets || exit
    logfile="./asset_backup_log.txt"

    # Assettypen holen
    mysql -u"$username" -p"$password" -D"$databasename" -e "SELECT DISTINCT $fromtypes FROM $fromtable;" | tail -n +2 > typen.txt
    assettypen_anzahl=$(wc -l < typen.txt)
    echo "📦 Assettypen gefunden: $assettypen_anzahl" | tee -a "$logfile"

    gesichert=0
    while IFS= read -r assettype; do
        filename="assetType_${assettype}"
        echo "✅ Sichere Asset-Typ: $assettype → $filename.sql.zip" | tee -a "$logfile"
        mysqldump -u"$username" -p"$password" "$databasename" --tables "$fromtable" --where="$fromtypes = '$assettype'" | zip > "$filename.sql.zip"
        ((gesichert++))
    done < typen.txt

    echo "🔒 Assettypen gesichert: $gesichert" | tee -a "$logfile"
}

Unterschiedliche assettypen der Tabelle assets zählen

# screen -fa -S DBRESTORE -d -U -m bash osmtool.sh db_restoretabelle_noassets "mein_benutzer" "geheim123" "meine_datenbank"
function db_restoretabelle_noassets() {
    username=$1
    password=$2
    databasename=$3
    restorepath="/$STARTVERZEICHNIS/backup/${databasename}"
    logfile="${restorepath}/restore_log.txt"

    cd "$restorepath" || exit

    if [[ ! -f liste.txt ]]; then
        echo "❌ Keine 'liste.txt' gefunden. Backup-Datei fehlt oder ungültig." | tee -a "$logfile"
        return 1
    fi

    echo "📦 Starte Wiederherstellung aus: $restorepath" | tee -a "$logfile"

    restored=0
    total=$(grep -v "^assets$" liste.txt | wc -l)
    echo "🔍 Tabellen zur Wiederherstellung (ohne 'assets'): $total" | tee -a "$logfile"

    while IFS= read -r tabellenname; do
        if [[ "$tabellenname" != "assets" ]]; then
            zipfile="${tabellenname}.sql.zip"
            if [[ -f "$zipfile" ]]; then
                echo "🔄 Wiederherstellung: $tabellenname" | tee -a "$logfile"
                unzip -p "$zipfile" | mysql -u"$username" -p"$password" "$databasename"
                ((restored++))
            else
                echo "⚠️ Datei fehlt: $zipfile" | tee -a "$logfile"
            fi
        fi
    done < liste.txt

    echo "✅ Tabellen erfolgreich wiederhergestellt: $restored von $total" | tee -a "$logfile"
    return 0
}

# Wiederherstellung der Asset-Typen
function asset_restore() {
    username=$1
    password=$2
    databasename=$3
    restorepath="/$STARTVERZEICHNIS/backup/${databasename}/assets"
    logfile="${restorepath}/asset_restore_log.txt"

    cd "$restorepath" || exit

    zipfiles=(assetType_*.sql.zip)
    anzahl=${#zipfiles[@]}
    echo "📦 Asset-Backups gefunden: $anzahl" | tee -a "$logfile"

    restored=0
    for zipfile in "${zipfiles[@]}"; do
        echo "🔄 Wiederherstellung: $zipfile" | tee -a "$logfile"
        unzip -p "$zipfile" | mysql -u"$username" -p"$password" "$databasename"
        ((restored++))
    done

    echo "✅ Assettypen wiederhergestellt: $restored" | tee -a "$logfile"
}

# Sichere die Datenbanken 'wordweb' und 'money' in ZIP-Dateien.
# bash osmtool_backup.sh sichere_wordweb_und_money "mein_benutzer" "geheim123"

function sichere_wordweb_und_money() {
    username=$1
    password=$2
    logfile="/$STARTVERZEICHNIS/backup/db_sicherung_log.txt"
    datum=$(date '+%Y-%m-%d_%H-%M-%S')

    mkdir -p /$STARTVERZEICHNIS/backup/wordweb
    mkdir -p /$STARTVERZEICHNIS/backup/money

    echo "📅 Sicherung gestartet: $datum" | tee -a "$logfile"

    # WORDWEB sichern
    echo "💾 Sichere Datenbank: wordweb" | tee -a "$logfile"
    mysqldump -u"$username" -p"$password" wordweb | zip > /$STARTVERZEICHNIS/backup/wordweb/wordweb_${datum}.sql.zip
    size_wordweb=$(du -sh /$STARTVERZEICHNIS/backup/wordweb/wordweb_${datum}.sql.zip | cut -f1)
    echo "✅ wordweb gesichert → Größe: $size_wordweb" | tee -a "$logfile"

    # MONEY sichern
    echo "💾 Sichere Datenbank: money" | tee -a "$logfile"
    mysqldump -u"$username" -p"$password" money | zip > /$STARTVERZEICHNIS/backup/money/money_${datum}.sql.zip
    size_money=$(du -sh /$STARTVERZEICHNIS/backup/money/money_${datum}.sql.zip | cut -f1)
    echo "✅ money gesichert → Größe: $size_money" | tee -a "$logfile"

    echo "📦 Sicherung abgeschlossen: $(date '+%Y-%m-%d %H:%M:%S')" | tee -a "$logfile"
}


case $KOMMANDO in
    "regionsiniteilen")        regionsiniteilen "$2" "$3" "$4"        ;;
    "autoregionsiniteilen")        autoregionsiniteilen        ;;
    "createregionlist")        createregionlist        ;;
    "regionbackup")        regionbackup "$2" "$3"        ;;
    "autoallclean")        autoallclean        ;;
    "autoregionbackup")        autoregionbackup        ;;
    "datenbanktabellen")        datenbanktabellen "$2" "$3" "$4"        ;;
    "backuptabelle_noassets")        backuptabelle_noassets "$2" "$3" "$4"        ;;
    "asset_backup")        asset_backup "$2" "$3" "$4"        ;;
    "db_restoretabelle_noassets")        db_restoretabelle_noassets "$2" "$3" "$4"        ;;
    "asset_restore")        asset_restore "$2" "$3" "$4"        ;;
    "sichere_wordweb_und_money")        sichere_wordweb_und_money "$2" "$3"        ;;
    *) echo "Unbekanntes Kommando: $KOMMANDO" ;;
esac
# Ende des Skripts
exit 0