# Cronjobs

Cronjobs helfen, wiederkehrende Aufgaben zu automatisieren.

## 1. Kurzbefehle

```bash
bash osmtool_main.sh croninstall
bash osmtool_main.sh cronlist
```

## 2. Manuelle Crontab-Befehle

```bash
crontab -l
crontab -e
```

## 3. Beispiele

```cron
# Grid jeden Morgen um 05:00 neu starten
0 5 * * * bash /opt/osmtool.sh autorestart

# Alle 30 Minuten check_screens
*/30 * * * * bash /opt/osmtool.sh check_screens
```

## 4. Empfehlungen

- Logs aktivieren
- Zeiten so legen, dass Nutzer moeglichst wenig beeinflusst werden
- Neustarts mit Backup-Strategie kombinieren
