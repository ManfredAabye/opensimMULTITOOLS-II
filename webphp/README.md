# OSMTool Web PHP (DE/EN/FR/ES)

This folder contains a complete PHP web interface for `osmtool_main.sh`.

## Features

- Login-protected web UI
- Language switch: `de`, `en`, `fr`, `es`
- CSRF protection
- Session-based execution history
- Live status cards for screen sessions, ports and latest artifacts
- Command preview and output viewer
- External CSS and JavaScript assets
- Whitelisted module/action execution only
- Runner script wrapper for safer command execution
- Configurable timeout for long-running commands

## File Layout

- `public/index.php` - web UI and request handling
- `public/style.css` - layout and visual design
- `public/app.js` - client-side form switching for modules and actions
- `src/web_init.php` - session, auth helpers, CSRF
- `src/i18n.php` - translations
- `src/runner.php` - module catalog, command whitelist and execution
- `src/config.sample.php` - configuration template
- `bin/osmtool_web_runner.sh` - controlled bridge to `osmtool_main.sh`

## Setup

1. Typical Linux deploy path:

```bash
sudo mkdir -p /var/www/html/osmtool-web
sudo cp -a webphp/. /var/www/html/osmtool-web/
sudo chown -R www-data:www-data /var/www/html/osmtool-web
```

1. Edit config values:

```bash
nano /var/www/html/osmtool-web/src/config.php
```

1. Set execute bit for runner and main script:

```bash
chmod +x /var/www/html/osmtool-web/bin/osmtool_web_runner.sh
chmod +x /opt/opensimMULTITOOLS-II/osmtool_main.sh
```

1. Configure web server document root to:

```text
/var/www/html/osmtool-web/public
```

1. Open in browser and log in with `web_password` from config.

## Sudoers Example (recommended)

Use `visudo` and allow only the web runner:

```text
www-data ALL=(manni) NOPASSWD: /var/www/html/osmtool-web/bin/osmtool_web_runner.sh
```

Then keep `use_sudo=true` and `sudo_user=manni` in config.

## Supported Modules

- `install`
- `startstop`
- `cleanup`
- `health`
- `backup`
- `restore`
- `update`
- `config`
- `report`
- `smoke`
- `cron`

## Notes On Scope

- The web interface now exposes the modular command set instead of only a few shortcut actions.
- Visible form fields change automatically depending on the selected module and action.
- Sensitive values such as passwords and secrets are masked in the command preview.
- Timeout handling uses `command_timeout_seconds` from `src/config.php` or `src/config.sample.php`.
- Live status cards can be tuned with `status_ports` and `status_screens` in `src/config.php`.

## Notes

- Do not expose this UI publicly without HTTPS and IP restrictions.
- Keep the password strong and unique.
- Extend modules or actions in `src/runner.php` and `bin/osmtool_web_runner.sh` together.
