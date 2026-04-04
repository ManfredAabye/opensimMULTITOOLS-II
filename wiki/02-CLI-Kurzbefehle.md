# CLI Kurzbefehle

Diese Kurzbefehle sind absichtlich kurz gehalten und fuer den Alltag gedacht.

## Verfuegbare Kurzbefehle

```bash
bash osmtool_main.sh install-grid-sim
bash osmtool_main.sh opensimstart
bash osmtool_main.sh opensimstop
bash osmtool_main.sh opensimrestart
bash osmtool_main.sh healthcheck
bash osmtool_main.sh smoketest
bash osmtool_main.sh dailyreport
bash osmtool_main.sh croninstall
bash osmtool_main.sh cronlist
bash osmtool_main.sh janusinstall
bash osmtool_main.sh janusrestart
bash osmtool_main.sh dbsetup
bash osmtool_main.sh dbbackup
```

## Befehle mit Variablen

### dbsetup

Legt Datenbanken und Benutzer an.

```bash
export OSM_DB_PASS='DEIN_PASSWORT'
bash osmtool_main.sh dbsetup
```

Optionale Variablen:

- `OSM_DB_USER` (Standard: `opensim`)
- `OSM_DB_ROOT_USER` (Standard: `root`)
- `OSM_DB_ROOT_PASS` (Standard: leer)

### dbbackup

Sichert die Datenbank.

```bash
export OSM_DB_PASS='DEIN_PASSWORT'
bash osmtool_main.sh dbbackup
```

Optionale Variablen:

- `OSM_DB_USER` (Standard: `root`)
- `OSM_DB_NAME` (Standard: `opensim`)

## Wenn du volle Kontrolle brauchst

Neben Kurzbefehlen kannst du auch den modularen Modus mit `--module` und `--action` nutzen.
