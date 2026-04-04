#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export DEFAULT_WORKDIR="/opt"
export OSMTOOL_CONFIG_FILE="${OSMTOOL_CONFIG_FILE:-$ROOT_DIR/osmtool_config.json}"
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

config_get_string() {
  local key="$1"
  local default_value="$2"
  local value=""

  [[ -f "$OSMTOOL_CONFIG_FILE" ]] || {
    printf '%s' "$default_value"
    return
  }

  if command -v jq >/dev/null 2>&1; then
    value="$(jq -r --arg k "$key" '.[$k] // empty' "$OSMTOOL_CONFIG_FILE" 2>/dev/null || true)"
  else
    value="$(sed -n -E "s/^[[:space:]]*\"${key}\"[[:space:]]*:[[:space:]]*\"([^\"]*)\"[[:space:]]*,?[[:space:]]*$/\1/p" "$OSMTOOL_CONFIG_FILE" | head -n1)"
  fi

  if [[ -n "$value" ]]; then
    printf '%s' "$value"
  else
    printf '%s' "$default_value"
  fi
}

config_get_bool() {
  local key="$1"
  local default_value="$2"
  local value=""

  [[ -f "$OSMTOOL_CONFIG_FILE" ]] || {
    printf '%s' "$default_value"
    return
  }

  if command -v jq >/dev/null 2>&1; then
    value="$(jq -r --arg k "$key" '.[$k] // empty' "$OSMTOOL_CONFIG_FILE" 2>/dev/null || true)"
  else
    value="$(sed -n -E "s/^[[:space:]]*\"${key}\"[[:space:]]*:[[:space:]]*(true|false)[[:space:]]*,?[[:space:]]*$/\1/p" "$OSMTOOL_CONFIG_FILE" | head -n1)"
  fi

  case "$value" in
    true|false) printf '%s' "$value" ;;
    *) printf '%s' "$default_value" ;;
  esac
}

config_get_int() {
  local key="$1"
  local default_value="$2"
  local value=""

  [[ -f "$OSMTOOL_CONFIG_FILE" ]] || {
    printf '%s' "$default_value"
    return
  }

  if command -v jq >/dev/null 2>&1; then
    value="$(jq -r --arg k "$key" '.[$k] // empty' "$OSMTOOL_CONFIG_FILE" 2>/dev/null || true)"
  else
    value="$(sed -n -E "s/^[[:space:]]*\"${key}\"[[:space:]]*:[[:space:]]*([0-9]+)[[:space:]]*,?[[:space:]]*$/\1/p" "$OSMTOOL_CONFIG_FILE" | head -n1)"
  fi

  if [[ "$value" =~ ^[0-9]+$ ]]; then
    printf '%s' "$value"
  else
    printf '%s' "$default_value"
  fi
}

config_path_value() {
  local value="$1"
  if [[ "$value" = /* ]]; then
    printf '%s' "$value"
  else
    printf '%s' "$ROOT_DIR/$value"
  fi
}

load_shared_config() {
  local cfg_lang cfg_workdir

  cfg_lang="$(normalize_lang "$(config_get_string "language" "de")")"
  cfg_workdir="$(config_get_string "path_workdir" "$DEFAULT_WORKDIR")"

  DEFAULT_WORKDIR="$cfg_workdir"
  export DEFAULT_WORKDIR

  if [[ -z "${OSM_LANG:-}" ]]; then
    APP_LANG="$cfg_lang"
  fi

  CONFIG_DB_ROOT_USER="$(config_get_string "db_root_user" "root")"
  CONFIG_DB_ROOT_PASS="$(config_get_string "db_root_pass" "")"
  CONFIG_DB_USER="$(config_get_string "db_user" "opensimuser")"
  CONFIG_DB_PASS="$(config_get_string "db_pass" "")"
  CONFIG_PUBLIC_HOST="$(config_get_string "public_host" "127.0.0.1")"
  CONFIG_GRIDNAME="$(config_get_string "gridname" "")"
  CONFIG_JANUS_PREFIX="$(config_get_string "janus_prefix" "/opt/janus")"
  CONFIG_OPENSIM_DIR="$(config_get_string "opensim_dir" "")"

  export CONFIG_DB_ROOT_USER CONFIG_DB_ROOT_PASS CONFIG_DB_USER CONFIG_DB_PASS
  export CONFIG_PUBLIC_HOST CONFIG_GRIDNAME CONFIG_JANUS_PREFIX CONFIG_OPENSIM_DIR
}

config_prompt_with_default() {
  local prompt="$1"
  local default_value="$2"
  local answer=""

  read -r -p "$prompt [$default_value]: " answer
  if [[ -z "$answer" ]]; then
    printf '%s' "$default_value"
  else
    printf '%s' "$answer"
  fi
}

write_shared_config_file() {
  local language="$1"
  local workdir="$2"
  local db_root_user="$3"
  local db_root_pass="$4"
  local db_user="$5"
  local db_pass="$6"
  local public_host="$7"
  local gridname="$8"
  local janus_prefix="$9"
  local opensim_dir="${10}"

  cat > "$OSMTOOL_CONFIG_FILE" <<EOF
{
  "language": "${language}",
  "path_workdir": "${workdir}",
  "path_lang_dir": "lang",
  "path_robust_bin": "robust/bin",
  "path_opensim_bin": "opensim/bin",
  "db_root_user": "${db_root_user}",
  "db_root_pass": "${db_root_pass}",
  "db_user": "${db_user}",
  "db_pass": "${db_pass}",
  "public_host": "${public_host}",
  "gridname": "${gridname}",
  "janus_prefix": "${janus_prefix}",
  "opensim_dir": "${opensim_dir}",
  "log_enabled": true,
  "old_log_del": true,
  "debug_log": "osmtool_debug.log",
  "max_log_size_mb": 10,
  "simulator_start_wait": 15,
  "moneyserver_start_wait": 30,
  "robustserver_start_wait": 30,
  "simulator_stop_wait": 15,
  "moneyserver_stop_wait": 30,
  "robustserver_stop_wait": 30
}
EOF
}

init_shared_config_interactive() {
  local cur_lang cur_workdir cur_db_root_user cur_db_root_pass cur_db_user cur_db_pass
  local cur_public_host cur_gridname cur_janus_prefix cur_opensim_dir
  local language workdir db_root_user db_root_pass db_user db_pass public_host gridname janus_prefix opensim_dir

  if [[ ! -t 0 ]]; then
    die "Interactive config initialization requires a TTY"
  fi

  cur_lang="$(normalize_lang "${OSM_LANG:-$(config_get_string "language" "de")}")"
  cur_workdir="$(config_get_string "path_workdir" "$DEFAULT_WORKDIR")"
  cur_db_root_user="$(config_get_string "db_root_user" "root")"
  cur_db_root_pass="$(config_get_string "db_root_pass" "")"
  cur_db_user="$(config_get_string "db_user" "opensimuser")"
  cur_db_pass="$(config_get_string "db_pass" "")"
  cur_public_host="$(config_get_string "public_host" "127.0.0.1")"
  cur_gridname="$(config_get_string "gridname" "")"
  cur_janus_prefix="$(config_get_string "janus_prefix" "/opt/janus")"
  cur_opensim_dir="$(config_get_string "opensim_dir" "$cur_workdir/opensim")"

  echo "Shared configuration file: $OSMTOOL_CONFIG_FILE"
  language="$(normalize_lang "$(config_prompt_with_default "Language (de|en|fr|es)" "$cur_lang")")"
  workdir="$(config_prompt_with_default "Workdir" "$cur_workdir")"
  db_root_user="$(config_prompt_with_default "DB root user" "$cur_db_root_user")"
  db_root_pass="$(config_prompt_with_default "DB root password" "$cur_db_root_pass")"
  db_user="$(config_prompt_with_default "DB app user" "$cur_db_user")"
  db_pass="$(config_prompt_with_default "DB app password" "$cur_db_pass")"
  public_host="$(config_prompt_with_default "Public host/IP" "$cur_public_host")"
  gridname="$(config_prompt_with_default "Grid name" "$cur_gridname")"
  janus_prefix="$(config_prompt_with_default "Janus prefix" "$cur_janus_prefix")"
  opensim_dir="$(config_prompt_with_default "OpenSim source dir" "$cur_opensim_dir")"

  mkdir -p "$(dirname "$OSMTOOL_CONFIG_FILE")"
  write_shared_config_file "$language" "$workdir" "$db_root_user" "$db_root_pass" "$db_user" "$db_pass" "$public_host" "$gridname" "$janus_prefix" "$opensim_dir"

  load_shared_config
  set_language "$language"
  log INFO "Shared configuration written: $OSMTOOL_CONFIG_FILE"
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
      case "$action" in init-config|server-check|prepare-ubuntu|install-opensim-deps|install-dotnet8|install-opensim|configure-opensim|configure-database|compile-janus|configure-janus|install-janus) return 0 ;; esac
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
      case "$action" in init-config|validate-file|validate-runtime) return 0 ;; esac
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

# Load shared settings before translations and module defaults are resolved.
load_shared_config

# Ensure translations are available in every script that sources this core.
init_i18n
