#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export DEFAULT_WORKDIR="/opt"
LANG_DIR="$ROOT_DIR/lang"
APP_LANG="${OSM_LANG:-de}"

LOG_FILE="${LOG_FILE:-$ROOT_DIR/osmtool_backup.log}"

declare -A I18N_CURRENT=()
declare -A I18N_EN=()

log() {
  local level="$1"
  shift
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" | tee -a "$LOG_FILE"
}

die() {
  log ERROR "$*"
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

normalize_lang() {
  case "$1" in
    de|en|fr|es) echo "$1" ;;
    *) echo "de" ;;
  esac
}

validate_profile() {
  case "$1" in
    grid-sim|robust|standalone) return 0 ;;
    *) die "$(msg ERR_INVALID_PROFILE): $1" ;;
  esac
}

profile_action_allowed() {
  local module="$1"
  local profile="$2"
  local action="$3"

  case "$module:$profile" in
    install:grid-sim|install:robust|install:standalone)
      case "$action" in server-check|prepare-ubuntu|install-opensim-deps|install-dotnet8|install-opensim|configure-opensim|configure-database|compile-janus|configure-janus|install-janus) return 0 ;; esac
      ;;
    startstop:grid-sim|startstop:robust|startstop:standalone)
      case "$action" in start|stop|restart) return 0 ;; esac
      ;;
    cleanup:grid-sim|cleanup:robust|cleanup:standalone)
      case "$action" in cache-clean|log-clean|tmp-clean|reboot) return 0 ;; esac
      ;;
    health:grid-sim|health:robust|health:standalone)
      case "$action" in run) return 0 ;; esac
      ;;
    backup:grid-sim)
      case "$action" in db-backup|oar-backup|full-backup) return 0 ;; esac
      ;;
    backup:robust)
      case "$action" in db-backup|full-backup) return 0 ;; esac
      ;;
    backup:standalone)
      case "$action" in oar-backup|full-backup) return 0 ;; esac
      ;;
    cron:grid-sim|cron:robust|cron:standalone)
      case "$action" in install|list|remove) return 0 ;; esac
      ;;
    restore:grid-sim)
      case "$action" in db-restore|oar-restore|full-restore|list-backups) return 0 ;; esac
      ;;
    restore:robust)
      case "$action" in db-restore|full-restore|list-backups) return 0 ;; esac
      ;;
    restore:standalone)
      case "$action" in oar-restore|full-restore|list-backups) return 0 ;; esac
      ;;
    update:grid-sim|update:robust|update:standalone)
      case "$action" in create-rollback|list-rollbacks|update-opensim|update-janus|full-update) return 0 ;; esac
      ;;
    config:grid-sim|config:robust|config:standalone)
      case "$action" in validate-file|validate-runtime) return 0 ;; esac
      ;;
    report:grid-sim|report:robust|report:standalone)
      case "$action" in generate) return 0 ;; esac
      ;;
    smoke:grid-sim|smoke:robust|smoke:standalone)
      case "$action" in run) return 0 ;; esac
      ;;
  esac

  return 1
}

ensure_profile_action_allowed() {
  local module="$1"
  local profile="$2"
  local action="$3"

  if ! profile_action_allowed "$module" "$profile" "$action"; then
    die "$(msg ERR_ACTION_NOT_ALLOWED): module=$module profile=$profile action=$action"
  fi
}

profile_target_allowed() {
  local profile="$1"
  local target="$2"

  case "$profile" in
    grid-sim)
      case "$target" in grid|robust|sim1|region|janus) return 0 ;; esac
      ;;
    robust)
      case "$target" in robust|janus) return 0 ;; esac
      ;;
    standalone)
      case "$target" in standalone|janus) return 0 ;; esac
      ;;
  esac

  return 1
}

ensure_profile_target_allowed() {
  local profile="$1"
  local target="$2"

  if ! profile_target_allowed "$profile" "$target"; then
    die "$(msg ERR_TARGET_NOT_ALLOWED): profile=$profile target=$target"
  fi
}

load_lang_file() {
  local lang_file="$1"
  local target_array_name="$2"
  local line key value

  [[ -f "$lang_file" ]] || return 1

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "${line:0:1}" == "#" ]] && continue
    [[ "$line" == *=* ]] || continue
    key="${line%%=*}"
    value="${line#*=}"
    if [[ "$target_array_name" == "I18N_EN" ]]; then
      I18N_EN["$key"]="$value"
    else
      I18N_CURRENT["$key"]="$value"
    fi
  done < "$lang_file"
  return 0
}

init_i18n() {
  APP_LANG="$(normalize_lang "$APP_LANG")"

  I18N_CURRENT=()
  I18N_EN=()

  load_lang_file "$LANG_DIR/en.lang" I18N_EN || true
  load_lang_file "$LANG_DIR/${APP_LANG}.lang" I18N_CURRENT || true
}

set_language() {
  APP_LANG="$(normalize_lang "$1")"
  export OSM_LANG="$APP_LANG"
  init_i18n
}

msg() {
  local key="$1"
  if [[ -n "${I18N_CURRENT[$key]:-}" ]]; then
    printf '%s' "${I18N_CURRENT[$key]}"
    return
  fi

  if [[ -n "${I18N_EN[$key]:-}" ]]; then
    printf '%s' "${I18N_EN[$key]}"
    return
  fi

  printf '%s' "$key"
}

ui_backend() {
  if command -v whiptail >/dev/null 2>&1; then
    echo "whiptail"
    return
  fi

  if command -v dialog >/dev/null 2>&1; then
    echo "dialog"
    return
  fi

  echo "none"
}

show_menu() {
  local title="$1"
  local text="$2"
  shift 2
  local backend
  backend="$(ui_backend)"

  case "$backend" in
    whiptail)
      whiptail --title "$title" --menu "$text" 20 80 12 "$@" 3>&1 1>&2 2>&3
      ;;
    dialog)
      dialog --clear --stdout --title "$title" --menu "$text" 20 80 12 "$@"
      ;;
    none)
      die "$(msg ERR_NO_UI_BACKEND)"
      ;;
  esac
}

confirm() {
  local title="$1"
  local text="$2"
  local backend
  backend="$(ui_backend)"

  case "$backend" in
    whiptail)
      whiptail --title "$title" --yesno "$text" 10 70
      ;;
    dialog)
      dialog --clear --title "$title" --yesno "$text" 10 70
      ;;
    none)
      return 1
      ;;
  esac
}

print_usage_common() {
  cat <<'EOF'
Global options:
  --workdir <path>     Base path (default: /opt)
  --mode <cli|ui>      Run in CLI mode (default) or menu mode
  --lang <de|en|fr|es> Language selection
  --profile <name>     Runtime profile (grid-sim|robust|standalone)
  --help               Show help
EOF
}

# Ensure translations are available in every script that sources this core.
init_i18n
