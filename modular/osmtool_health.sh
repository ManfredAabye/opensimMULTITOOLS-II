#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=./osmtool_core.sh
source "$SCRIPT_DIR/osmtool_core.sh"

usage() {
  cat <<'EOF'
Usage:
  osmtool_health.sh [--workdir <path>] --action <run>
    [--expected-screens <csv|none>] [--ports <csv|none>] [--db-user <user>] [--db-pass <pass>] [--db-name <name>]
    [--log-file <path>] [--warning-threshold <n>]

Examples:
  osmtool_health.sh --action run --workdir /opt
  osmtool_health.sh --action run --workdir /opt --expected-screens robustserver,sim1 --ports 9000,8002,8088
EOF
  print_usage_common
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

report_ok() {
  log INFO "[OK] $1"
}

report_warn() {
  log INFO "[WARN] $1"
}

report_err() {
  log ERROR "[FAIL] $1"
}

check_screens() {
  local fail_count=0
  local screen_name

  if [[ -z "$EXPECTED_SCREENS" ]]; then
    report_warn "Screen check skipped (no expected screens configured)"
    return 0
  fi

  while IFS= read -r screen_name; do
    [[ -n "$screen_name" ]] || continue
    if screen -list 2>/dev/null | grep -qE "\\.${screen_name}[[:space:]]"; then
      report_ok "Screen session running: $screen_name"
    else
      report_err "Screen session missing: $screen_name"
      fail_count=$((fail_count + 1))
    fi
  done < <(split_csv "$EXPECTED_SCREENS")

  return "$fail_count"
}

check_ports() {
  local fail_count=0
  local port
  local cmd_ss=0

  if [[ -z "$PORTS" ]]; then
    report_warn "Port check skipped (no ports configured)"
    return 0
  fi

  if command -v ss >/dev/null 2>&1; then
    cmd_ss=1
  elif ! command -v netstat >/dev/null 2>&1; then
    report_warn "Port check skipped (neither ss nor netstat available)"
    return 0
  fi

  while IFS= read -r port; do
    [[ -n "$port" ]] || continue
    if [[ "$cmd_ss" -eq 1 ]]; then
      if ss -ltnH | awk '{print $4}' | grep -qE "[:.]${port}$"; then
        report_ok "Port listening: $port"
      else
        report_err "Port not listening: $port"
        fail_count=$((fail_count + 1))
      fi
    else
      if netstat -ltn 2>/dev/null | awk '{print $4}' | grep -qE "[:.]${port}$"; then
        report_ok "Port listening: $port"
      else
        report_err "Port not listening: $port"
        fail_count=$((fail_count + 1))
      fi
    fi
  done < <(split_csv "$PORTS")

  return "$fail_count"
}

check_database() {
  local fail_count=0

  if [[ -z "$DB_USER" || -z "$DB_NAME" ]]; then
    report_warn "Database check skipped (missing --db-user/--db-name)"
    return 0
  fi

  if ! command -v mariadb >/dev/null 2>&1; then
    report_err "Database check failed: mariadb client missing"
    return 1
  fi

  if [[ -n "$DB_PASS" ]]; then
    if mariadb -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" -e "SELECT 1" >/dev/null 2>&1; then
      report_ok "Database reachable: $DB_NAME"
    else
      report_err "Database not reachable: $DB_NAME"
      fail_count=$((fail_count + 1))
    fi
  else
    if mariadb -u"$DB_USER" "$DB_NAME" -e "SELECT 1" >/dev/null 2>&1; then
      report_ok "Database reachable: $DB_NAME"
    else
      report_err "Database not reachable: $DB_NAME"
      fail_count=$((fail_count + 1))
    fi
  fi

  return "$fail_count"
}

count_log_warnings() {
  local file="$1"
  grep -Eic 'error|warn|exception|fatal' "$file" 2>/dev/null || true
}

check_logs() {
  local warn_count total=0
  local default_logs=()

  if [[ -n "$LOG_FILE_PATH" ]]; then
    default_logs+=("$LOG_FILE_PATH")
  else
    default_logs+=("$ROOT_DIR/osmtool_backup.log")
    default_logs+=("$WORKDIR/robust/bin/OpenSim.log")
  fi

  for logf in "${default_logs[@]}"; do
    if [[ -f "$logf" ]]; then
      warn_count="$(count_log_warnings "$logf")"
      report_ok "Log scan: $logf -> $warn_count matches"
      total=$((total + warn_count))
    else
      report_warn "Log file not found, skipped: $logf"
    fi
  done

  if [[ "$total" -gt "$WARNING_THRESHOLD" ]]; then
    report_err "Log warning threshold exceeded: $total > $WARNING_THRESHOLD"
    return 1
  fi

  report_ok "Log warning threshold OK: $total <= $WARNING_THRESHOLD"
  return 0
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

run_health() {
  local fails=0

  log INFO "Running health checks for profile: $PROFILE"
  log INFO "Using workdir: $WORKDIR"

  if ! check_screens; then
    fails=$((fails + 1))
  fi

  if ! check_ports; then
    fails=$((fails + 1))
  fi

  if ! check_database; then
    fails=$((fails + 1))
  fi

  if ! check_logs; then
    fails=$((fails + 1))
  fi

  if [[ "$fails" -eq 0 ]]; then
    report_ok "Healthcheck PASSED"
    return 0
  fi

  report_err "Healthcheck FAILED with $fails failing check group(s)"
  return 1
}

WORKDIR="$DEFAULT_WORKDIR"
ACTION=""
PROFILE="grid-sim"
EXPECTED_SCREENS=""
PORTS=""
DB_USER=""
DB_PASS=""
DB_NAME=""
LOG_FILE_PATH=""
WARNING_THRESHOLD=50

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workdir) WORKDIR="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --action) ACTION="$2"; shift 2 ;;
    --expected-screens) EXPECTED_SCREENS="$2"; shift 2 ;;
    --ports) PORTS="$2"; shift 2 ;;
    --db-user) DB_USER="$2"; shift 2 ;;
    --db-pass) DB_PASS="$2"; shift 2 ;;
    --db-name) DB_NAME="$2"; shift 2 ;;
    --log-file) LOG_FILE_PATH="$2"; shift 2 ;;
    --warning-threshold) WARNING_THRESHOLD="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -n "$ACTION" ]] || die "Missing --action"
validate_profile "$PROFILE"
ensure_profile_action_allowed health "$PROFILE" "$ACTION"

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

case "$ACTION" in
  run) run_health ;;
  *) die "Unsupported action: $ACTION" ;;
esac
