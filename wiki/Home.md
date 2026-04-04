# opensimMULTITOOLS-II Wiki

Willkommen zur lokalen Wiki-Dokumentation von opensimMULTITOOLS-II.

Diese Seiten erklaeren das Projekt fuer Einsteiger und fortgeschrittene Nutzer.

## Inhalt

1. [Schnellstart](01-Schnellstart.md)
2. [CLI Kurzbefehle](02-CLI-Kurzbefehle.md)
3. [Weboberflaeche](03-Weboberflaeche.md)
4. [Sicherheit](04-Sicherheit.md)
5. [Konfiguration](05-Konfiguration.md)
6. [Backup und Restore](06-Backup-Restore.md)
7. [Troubleshooting](07-Troubleshooting.md)
8. [Cronjobs](08-Cronjobs.md)

## Projektueberblick

opensimMULTITOOLS-II ist eine Sammlung von Skripten zur Verwaltung von OpenSim:

- Installation und Updates
- Start, Stop, Restart
- Backups und Restore
- Healthchecks und Reports
- Web-Dashboard mit Login, Mehrsprachigkeit und Live-Status

## Wichtige Dateien

- `osmtool_main.sh`: modularer Einstiegspunkt
- `osmtool.sh`: klassisches Hauptskript
- `modular/`: einzelne Funktionsmodule
- `webphp/`: Weboberflaeche
- `README.md`: komprimierter Projektleitfaden

## Version

- Aktueller Stand: V26.4.230.588

## Sicherheit zuerst

- Immer vor grossen Aktionen Backups machen.
- Erst in Testumgebung pruefen.
- Weboberflaeche nur abgesichert betreiben (HTTPS, starke Passwoerter, begrenzter Zugriff).
