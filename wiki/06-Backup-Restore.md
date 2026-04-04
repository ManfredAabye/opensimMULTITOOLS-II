# Backup und Restore

## 1. Grundprinzip

Jede groessere Aenderung startet mit einem Backup.

Empfohlen:

- Datenbank-Backup vor Updates
- OAR-Backup vor Regionenumbauten
- Regelmaessige automatisierte Sicherung per Cron

## 2. Datenbank sichern (Kurzbefehl)

```bash
export OSM_DB_PASS='DEIN_PASSWORT'
bash osmtool_main.sh dbbackup
```

## 3. Modulare Backup-Aktionen

Beispiele (ausfuehrlicher Modus):

```bash
bash osmtool_main.sh --module backup --action db-backup --db-user root --db-pass DEIN_PASSWORT --db-name opensim --workdir /opt
bash osmtool_main.sh --module backup --action oar-backup --workdir /opt --region sim1 --session sim1
bash osmtool_main.sh --module backup --action full-backup --workdir /opt --db-user root --db-pass DEIN_PASSWORT --db-name opensim --region sim1 --session sim1 --compress true
```

## 4. Restore

Restore-Funktionen laufen ueber das Modul `restore`.

Vor einem produktiven Restore immer:

- passenden Backupstand verifizieren
- Zielsystem stoppen
- optional Dry-Run oder Testsystem nutzen

## 5. Aufbewahrung

- Backups versioniert speichern
- externe/offsite Kopie einplanen
- Restore regelmaessig testen
