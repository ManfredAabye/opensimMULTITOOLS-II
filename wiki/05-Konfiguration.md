# Konfiguration

## 1. Zentrale Bereiche

Es gibt zwei Konfigurationswelten:

- CLI/Skripte: ueber Parameter und Umgebungsvariablen
- Web: ueber `webphp/src/config.php`

## 2. Web-Konfiguration

Wichtige Eintraege in `webphp/src/config.php`:

- `session_key`: Schluessel fuer Session-Schutz
- `web_password`: Login-Passwort fuer Web-UI
- `command_timeout_seconds`: Timeout fuer Runner
- `default_workdir`: Standard-Arbeitsverzeichnis
- `status_ports`: Port-Check pro Profil
- `status_screens`: Screen-Check pro Profil
- `use_sudo` und `sudo_user`: optionaler sudo-Betrieb

## 3. Sicherheitseinstellungen

- `auth_lockout_max_attempts`
- `auth_lockout_seconds`
- optional `auth_store_path`
- optional `auth_audit_log_path`

## 4. Typische Stolpersteine

- Nur `config.sample.php` geaendert statt `config.php`
- Falscher Deploy-Pfad oder falsche Instanz
- Browsercache zeigt alte Daten

## 5. Empfehlung

Aendere zuerst in einer Testumgebung. Dokumentiere eigene Abweichungen in einer separaten Betriebsdoku.
