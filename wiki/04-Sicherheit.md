# Sicherheit

## Grundregeln

- Produktivsystem nur mit Backups betreiben.
- Webzugriff nach Moeglichkeit auf interne Netze/IPs begrenzen.
- HTTPS verwenden.
- Starkes Passwort in `webphp/src/config.php` setzen.

## Login-Schutz (Web)

Die Weboberflaeche enthaelt Brute-Force-Schutz:

- Sperre nach mehreren Fehlversuchen pro IP
- Zeitbasierte Entsperrung
- Audit-Logging von Login-Ereignissen

## Wichtige Einstellungen

In `webphp/src/config.php`:

- `auth_lockout_max_attempts`
- `auth_lockout_seconds`
- optional `auth_store_path`
- optional `auth_audit_log_path`

## Audit-Log

Typische Events:

- `login_success`
- `login_failed_password`
- `login_failed_locked`
- `login_blocked`
- `csrf_invalid`

Nutze das Log fuer Nachverfolgung von Angriffen und Fehlbedienung.
