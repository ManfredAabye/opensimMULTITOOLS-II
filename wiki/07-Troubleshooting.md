# Troubleshooting

## 1. Live-Status zeigt falsche Ports

Pruefen:

1. Ports in `webphp/src/config.php` gesetzt?
1. Richtige Umgebung/Instanz aufgerufen?
1. Hard-Reload im Browser (`Ctrl+Shift+R`)?

## 2. Login ploetzlich gesperrt

Ursache:

- Mehrere falsche Loginversuche fuehren zur IP-Sperre.

Loesung:

- `auth_lockout_seconds` abwarten
- Audit-Log pruefen

## 3. check_screens startet neu

Erwartetes Verhalten:

- kritische Ausfaelle fuehren zu Neustart
- Status wird in `ProblemRestarts.log` protokolliert

## 4. Befehle schlagen ohne erkennbare Ursache fehl

Pruefen:

1. Rechte auf Skripte vorhanden (`chmod +x`)
1. Pfade korrekt (`/opt/...` vs andere Pfade)
1. Abhaengigkeiten installiert (dotnet, mysqldump, screen)

## 5. Web-UI startet Befehle nicht

Pruefen:

- runner-Skript vorhanden und ausfuehrbar
- `runner_path` korrekt
- `use_sudo` und `sudo_user` korrekt
- sudoers-Eintrag fuer Runner vorhanden
