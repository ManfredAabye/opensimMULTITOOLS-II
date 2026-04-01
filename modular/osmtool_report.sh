#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=./osmtool_core.sh
source "$SCRIPT_DIR/osmtool_core.sh"

usage() {
  cat <<'EOF'
Usage:
  osmtool_report.sh [--workdir <path>] --action <generate>
    [--output <file>] [--expected-screens <csv|none>] [--ports <csv|none>]
    [--db-user <user>] [--db-pass <pass>] [--db-name <name>] [--log-file <path>]

Examples:
  osmtool_report.sh --action generate --workdir /opt --db-user opensim --db-pass secret --db-name robust
  osmtool_report.sh --action generate --workdir /opt --output /opt/reports/manual_report.txt
EOF
  print_usage_common
}

timestamp_compact() {
  date '+%Y%m%d_%H%M%S'
}

timestamp_iso() {
  date '+%Y-%m-%d %H:%M:%S'
}

split_csv() {
  local csv="$1"
  local token
  local IFS=','
  read -r -a _TOKENS <<< "$csv"
  for token in "${_TOKENS[@]}"; do
    token="${token## }"
    token="${token%% }"
    [[ -n "$token" ]] && printf '%s\n' "$token"
  done
}

reports_dir() {
  printf '%s' "$WORKDIR/reports"
}

ensure_reports_dir() {
  local dir
  dir="$(reports_dir)"

  if mkdir -p "$dir" 2>/dev/null; then
    return 0
  fi

  sudo mkdir -p "$dir"
  sudo chown "$(id -u):$(id -g)" "$dir"
}

latest_file() {
  local dir="$1"
  local pattern="$2"

  [[ -d "$dir" ]] || return 0
  find "$dir" -maxdepth 1 -type f -name "$pattern" -printf '%T@ %p\n' 2>/dev/null | \
    sort -rn | head -1 | cut -d' ' -f2-
}

format_file_age_hours() {
  local path="$1"
  local now ts age

  [[ -f "$path" ]] || {
    printf 'n/a'
    return 0
  }

  now="$(date +%s)"
  ts="$(stat -c %Y "$path" 2>/dev/null || echo 0)"
  if [[ "$ts" -le 0 ]]; then
    printf 'n/a'
    return 0
  fi

  age=$(( (now - ts) / 3600 ))
  printf '%sh' "$age"
}

screen_status_lines() {
  local screen_name

  if [[ -z "$EXPECTED_SCREENS" ]]; then
    printf 'screen: skipped\n'
    return 0
  fi

  while IFS= read -r screen_name; do
    [[ -n "$screen_name" ]] || continue
    if screen -list 2>/dev/null | grep -qE "\\.${screen_name}[[:space:]]"; then
      printf 'screen:%s=up\n' "$screen_name"
    else
      printf 'screen:%s=down\n' "$screen_name"
    fi
  done < <(split_csv "$EXPECTED_SCREENS")
}

port_status_lines() {
  local port
  local use_ss=0

  if [[ -z "$PORTS" ]]; then
    printf 'port: skipped\n'
    return 0
  fi

  if command -v ss >/dev/null 2>&1; then
    use_ss=1
  elif ! command -v netstat >/dev/null 2>&1; then
    printf 'port: unavailable (no ss/netstat)\n'
    return 0
  fi

  while IFS= read -r port; do
    [[ -n "$port" ]] || continue
    if [[ "$use_ss" -eq 1 ]]; then
      if ss -ltnH | awk '{print $4}' | grep -qE "[:.]${port}$"; then
        printf 'port:%s=listen\n' "$port"
      else
        printf 'port:%s=closed\n' "$port"
      fi
    else
      if netstat -ltn 2>/dev/null | awk '{print $4}' | grep -qE "[:.]${port}$"; then
        printf 'port:%s=listen\n' "$port"
      else
        printf 'port:%s=closed\n' "$port"
      fi
    fi
  done < <(split_csv "$PORTS")
}

database_status() {
  if [[ -z "$DB_USER" || -z "$DB_NAME" ]]; then
    printf 'db: skipped\n'
    return 0
  fi

  if ! command -v mariadb >/dev/null 2>&1; then
    printf 'db:%s=client-missing\n' "$DB_NAME"
    return 0
  fi

  if [[ -n "$DB_PASS" ]]; then
    if mariadb -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SELECT 1" >/dev/null 2>&1; then
      printf 'db:%s=ok\n' "$DB_NAME"
    else
      printf 'db:%s=fail\n' "$DB_NAME"
    fi
  else
    if mariadb -u"$DB_USER" "$DB_NAME" -e "SELECT 1" >/dev/null 2>&1; then
      printf 'db:%s=ok\n' "$DB_NAME"
    else
      printf 'db:%s=fail\n' "$DB_NAME"
    fi
  fi
}

log_warning_count() {
  local file="$1"
  [[ -f "$file" ]] || {
    printf 'n/a'
    return 0
  }

  grep -Eic 'error|warn|exception|fatal' "$file" 2>/dev/null || printf '0'
}

default_screens_for_profile() {
  case "$1" in
    grid-sim) echo "robustserver,sim1" ;;
    robust) echo "robustserver" ;;
    standalone) echo "standalone" ;;
  esac
}

default_ports_for_profile() {
  case "$1" in
    grid-sim) echo "8002,9000,9001,8088" ;;
    robust) echo "8002,9000,9001" ;;
    standalone) echo "9000" ;;
  esac
}

generate_report() {
  local out report_title log_target
  local newest_sql newest_oar newest_rollback

  ensure_reports_dir

  if [[ -n "$OUTPUT_FILE" ]]; then
    out="$OUTPUT_FILE"
  else
    out="$(reports_dir)/osm_report_$(timestamp_compact).txt"
  fi

  newest_sql="$(latest_file "$WORKDIR/backup" 'robust_*.sql*')"
  newest_oar="$(latest_file "$WORKDIR/backup" '*.oar')"
  newest_rollback="$(latest_file "$WORKDIR/rollback" '*.manifest')"
  log_target="$LOG_FILE_PATH"
  if [[ -z "$log_target" ]]; then
    log_target="$ROOT_DIR/osmtool_backup.log"
  fi

  report_title="OSMTool Daily Status Report"

  {
    printf '%s\n' "$report_title"
    printf 'generated_at: %s\n' "$(timestamp_iso)"
    printf 'profile: %s\n' "$PROFILE"
    printf 'workdir: %s\n' "$WORKDIR"
    printf '\n'
    printf '[runtime]\n'
    screen_status_lines
    port_status_lines
    database_status
    printf '\n'
    printf '[backup]\n'
    printf 'sql_latest: %s\n' "${newest_sql:-none}"
    printf 'sql_age: %s\n' "$(format_file_age_hours "${newest_sql:-}")"
    printf 'oar_latest: %s\n' "${newest_oar:-none}"
    printf 'oar_age: %s\n' "$(format_file_age_hours "${newest_oar:-}")"
    printf '\n'
    printf '[rollback]\n'
    printf 'latest_manifest: %s\n' "${newest_rollback:-none}"
    printf 'manifest_age: %s\n' "$(format_file_age_hours "${newest_rollback:-}")"
    printf '\n'
    printf '[logs]\n'
    printf 'file: %s\n' "$log_target"
    printf 'warning_matches: %s\n' "$(log_warning_count "$log_target")"
  } > "$out"

  log INFO "Report generated: $out"
  cat "$out"
}

WORKDIR="$DEFAULT_WORKDIR"
ACTION=""
PROFILE="grid-sim"
OUTPUT_FILE=""
EXPECTED_SCREENS=""
PORTS=""
DB_USER=""
DB_PASS=""
DB_NAME=""
LOG_FILE_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workdir) WORKDIR="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --action) ACTION="$2"; shift 2 ;;
    --output) OUTPUT_FILE="$2"; shift 2 ;;
    --expected-screens) EXPECTED_SCREENS="$2"; shift 2 ;;
    --ports) PORTS="$2"; shift 2 ;;
    --db-user) DB_USER="$2"; shift 2 ;;
    --db-pass) DB_PASS="$2"; shift 2 ;;
    --db-name) DB_NAME="$2"; shift 2 ;;
    --log-file) LOG_FILE_PATH="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -n "$ACTION" ]] || die "Missing --action"
validate_profile "$PROFILE"
ensure_profile_action_allowed report "$PROFILE" "$ACTION"

if [[ -z "$EXPECTED_SCREENS" ]]; then
  EXPECTED_SCREENS="$(default_screens_for_profile "$PROFILE")"
elif [[ "$EXPECTED_SCREENS" == "none" ]]; then
  EXPECTED_SCREENS=""
fi

if [[ -z "$PORTS" ]]; then
  PORTS="$(default_ports_for_profile "$PROFILE")"
elif [[ "$PORTS" == "none" ]]; then
  PORTS=""
fi

log INFO "Using profile: $PROFILE"

case "$ACTION" in
  generate) generate_report ;;
  *) die "Unsupported action: $ACTION" ;;
esac