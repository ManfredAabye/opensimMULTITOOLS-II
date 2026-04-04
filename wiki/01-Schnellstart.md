# Schnellstart

Diese Anleitung fuehrt dich von Null bis zum ersten laufenden Grid.

## Voraussetzungen

- Linux-Server mit Shell-Zugang
- Projekt liegt z. B. unter `/opt/opensimMULTITOOLS-II`
- sudo-Rechte fuer Installation

## Schrittfolge

1. In das Projekt wechseln:

```bash
cd /opt/opensimMULTITOOLS-II
```

1. Grundinstallation fuer grid-sim starten:

```bash
bash osmtool_main.sh install-grid-sim
```

1. Datenbank einrichten (Passwort per Umgebungsvariable):

```bash
export OSM_DB_PASS='DEIN_PASSWORT'
bash osmtool_main.sh dbsetup
```

1. Grid starten:

```bash
bash osmtool_main.sh opensimrestart
```

1. Funktion pruefen:

```bash
bash osmtool_main.sh healthcheck
```

## Was install-grid-sim macht

Der Shortcut fuehrt intern eine komplette Kette aus:

- prepare-ubuntu
- install-opensim-deps
- install-dotnet8
- server-check
- install-opensim
- configure-opensim

## Naechster Schritt

- Weboberflaeche einrichten: [Weboberflaeche](03-Weboberflaeche.md)
