# opensimMULTITOOL II V26.4.230.588

Diese README ist fuer Einsteiger geschrieben.

Wenn du noch nie mit OpenSim oder Bash gearbeitet hast, starte mit den Schritten in diesem Dokument von oben nach unten.

## 1. Was ist dieses Projekt?

opensimMULTITOOLS-II hilft dir, einen OpenSim-Server zu:

- installieren
- starten und stoppen
- neu starten
- sichern (Backups)
- warten und pruefen

Das Projekt besteht aus zwei Hauptteilen:

- CLI-Skripte (Konsole): fuer Administration per Terminal
- Web-Oberflaeche unter webphp/: fuer Bedienung im Browser

Voraussetzungen

- Linux Server

## 2. Wichtige Sicherheitshinweise

- Vor groesseren Aktionen immer Backup machen.
- Erst in einer Testumgebung pruefen, dann auf Produktivsystem nutzen.
- Die Web-Oberflaeche nur mit HTTPS und moeglichst mit IP-Einschraenkung betreiben.
- Standard-Passwoerter sofort aendern.

## 3. Projektstruktur (kurz erklaert)

- osmtool_main.sh: Hauptstarter fuer Module und Aktionen
- modular/: einzelne Fachmodule (install, startstop, backup, restore, ...)
- webphp/: Web-Oberflaeche (PHP)
- osmtool.sh: klassisches Hauptskript mit vielen Direktfunktionen

## 4. Schnellstart fuer Einsteiger (CLI)

Voraussetzung: Du arbeitest auf Linux und hast Zugriff auf das Projektverzeichnis.

### Schritt 1: In das Projektverzeichnis wechseln

```bash
cd /opt/opensimMULTITOOLS-II
```

### Schritt 2: Ubuntu vorbereiten

```bash
bash osmtool_main.sh install-grid-sim
```

Hinweis: `install-grid-sim` fuehrt die komplette Installationskette fuer `grid-sim` aus.

### Schritt 3: OpenSim-Abhaengigkeiten installieren

```bash
bash osmtool_main.sh install-grid-sim
```

### Schritt 4: Server-Check ausfuehren

```bash
bash osmtool_main.sh healthcheck
```

### Schritt 5: OpenSim installieren und konfigurieren

```bash
bash osmtool_main.sh install-grid-sim
```

### Schritt 6: Datenbank einrichten

```bash
export OSM_DB_PASS='DEIN_PASSWORT'
bash osmtool_main.sh dbsetup
```

### Schritt 7: Grid starten

```bash
bash osmtool_main.sh opensimrestart
```

## 5. Alltagsbefehle (die wichtigsten)

```bash
# Grid neu starten
bash osmtool_main.sh opensimrestart

# Robust-Datenbank sichern
export OSM_DB_PASS='DEIN_PASSWORT'
bash osmtool_main.sh dbbackup

# Cronjobs installieren (automatische Backups/Checks)
bash osmtool_main.sh croninstall
```

Unterstuetzte Kurzbefehle (Ein-Wort-Aufruf):

- install-grid-sim
- opensimstart
- opensimstop
- opensimrestart
- healthcheck
- smoketest
- dailyreport
- croninstall
- cronlist
- janusinstall
- janusrestart
- dbsetup
- dbbackup

## 6. Web-Oberflaeche (webphp)

Die Web-Oberflaeche ist in webphp/ enthalten und zeigt unter anderem:

- Modulaktionen
- Kommando-Vorschau
- Ausgabe der Befehle
- Live-Status (Screens, Ports, Artefakte)

Detaillierte Web-Anleitung: webphp/README.md

### Wichtige Konfigurationsregel

Fuer die aktive Web-Konfiguration gilt:

- webphp/src/config.php = wird wirklich benutzt
- webphp/src/config.sample.php = nur Vorlage

Wenn du Ports oder Screens fuer den Live-Status aendern willst, musst du in config.php anpassen.

## 7. Login-Sicherheit der Web-Oberflaeche

Die Web-Oberflaeche hat einen Schutz gegen Brute-Force-Logins:

- Nach mehreren falschen Passwortversuchen wird die IP temporaer gesperrt.
- Sperrzeit und Schwelle sind konfigurierbar.
- Login-Ereignisse koennen in einer Audit-Logdatei gespeichert werden.

Wichtige Einstellungen in webphp/src/config.php:

- auth_lockout_max_attempts
- auth_lockout_seconds
- optional: auth_store_path
- optional: auth_audit_log_path

## 8. check_screens einfach erklaert

Die Funktion check_screens in osmtool.sh:

- prueft, ob wichtige Screen-Sessions laufen
- schreibt Ergebnisse in ProblemRestarts.log
- meldet auch, wenn ein Dienst laeuft
- startet ausgefallene Dienste neu (kritische Dienste mit Komplett-Neustart)

## 9. Typische Fehler und schnelle Loesungen

### Problem: Im Live-Status werden alte oder falsche Ports angezeigt

Loesung:

1. Ports in webphp/src/config.php aendern (nicht nur in config.sample.php).
2. Browser mit Hard-Reload neu laden (z. B. Ctrl+Shift+R).
3. Sicherstellen, dass du die richtige Instanz/den richtigen Server aufrufst.

### Problem: Login gesperrt nach Fehlversuchen

Loesung:

- Sperrzeit in auth_lockout_seconds abwarten
- oder Sperrdaten in der konfigurierten Lockout-Datei pruefen

## 10. Nuetzliche Dateien

- osmtool_main.sh
- osmtool.sh
- modular/osmtool_startstop.sh
- modular/osmtool_install.sh
- webphp/public/index.php
- webphp/src/config.php
- webphp/src/runner.php
- webphp/src/web_init.php

## 11. Hilfe

- Wiki: [opensimMULTITOOLS-II Wiki](https://github.com/ManfredAabye/opensimMULTITOOLS-II/wiki)
- Web-Dokumentation: webphp/README.md

## 12. Lizenz

- Skriptname: osmtool.sh
- Version: V26.4.230.588
- Autor: Manfred Aabye
- Lizenz: MIT

## Beispiel OpenSimulator Automatisierung

Liste crontabs:

	crontab -l

Editiere crontabs:

	crontab -e
	
Beispiel:

	# === OpenSimGrid-Automatisierung ===
	# Bedeutung: Minute Stunde Tag Monat Jahr Befehlskette

	# Woechentliches OpenSim Regionsbackup jeden Montag um 03:00 Uhr
	0 2 * * 1 /bin/bash /opt/osmtool.sh autoregionbackup

	# Monatliche Wartung am 1. des Monats
	30 4 1 * * bash '/opt/osmtool.sh' stop
	35 4 1 * * bash '/opt/osmtool.sh' cacheclean
	40 4 1 * * bash '/opt/osmtool.sh' mapclean
	45 4 1 * * bash '/opt/osmtool.sh' logclean
	50 4 1 * * bash '/opt/osmtool.sh' reboot

	# Täglicher Restart
	0 5 * * * bash '/opt/osmtool.sh' restart

	# Überwachung
	*/15 * * * * bash '/opt/osmtool.sh' check_screens

Save crontabs

	ctrl O
	Enter

Exit editor

	ctrl X

## Stand

Test Ubuntu 22.04, 24.04, 26.04 erfolgreich.

## Todo

CRLF -> LF über gitattributes einstellen. OK

Für die Regionen werden keine Besitzer und Estate angelegt diese müssen für jeden Simulator einzeln angelegt werden.
