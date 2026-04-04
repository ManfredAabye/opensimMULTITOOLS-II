# Weboberflaeche

Die Weboberflaeche liegt im Ordner `webphp/`.

## Funktionen

- Login-Schutz
- Mehrsprachigkeit (`de`, `en`, `fr`, `es`)
- Modul- und Aktionsauswahl
- Kommando-Vorschau
- Ausgabefenster
- Live-Status fuer Screens, Ports und Artefakte

## Wichtige Regel zur Konfiguration

- Aktive Datei: `webphp/src/config.php`
- Vorlage: `webphp/src/config.sample.php`

Aenderungen werden nur aus `config.php` gelesen.

## Minimal-Setup

1. Dateien deployen
2. `webphp/src/config.php` anpassen
3. Webroot auf `webphp/public` setzen
4. Runner-Skript ausfuehrbar machen

## Live-Status anpassen

In `webphp/src/config.php`:

- `status_ports`
- `status_screens`

Wenn falsche Ports angezeigt werden, zuerst pruefen:

1. Wurde `config.php` geaendert?
2. Ist es die richtige Instanz?
3. Browser-Hard-Reload gemacht (`Ctrl+Shift+R`)?

## Referenz

Detaillierte technische Anleitung: `webphp/README.md`
