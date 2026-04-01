# OSMTool Web PHP (DE/EN/FR/ES)

This folder contains a minimal and secure PHP web controller for `osmtool_main.sh`.

## Features

- Login-protected web UI
- Language switch: `de`, `en`, `fr`, `es`
- CSRF protection
- Whitelisted actions only
- Runner script wrapper for safer command execution

## File Layout

- `public/index.php` - web UI and request handling
- `src/bootstrap.php` - session, auth helpers, CSRF
- `src/i18n.php` - translations
- `src/runner.php` - command whitelist and execution
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

## Supported Actions

- `start`
- `stop`
- `restart`
- `smoke`
- `report`
- `health`
- `cron-list`

## Notes

- Do not expose this UI publicly without HTTPS and IP restrictions.
- Keep the password strong and unique.
- Extend actions only in `src/runner.php` and `bin/osmtool_web_runner.sh` together.
