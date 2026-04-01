#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=./osmtool_core.sh
source "$SCRIPT_DIR/osmtool_core.sh"

usage() {
  cat <<'EOF'
Usage:
  osmtool_cron.sh [--workdir <path>] --action <install|list|remove>
    [--backup-schedule "<cron>"] [--restart-schedule "<cron>"] [--check-schedule "<cron>"] [--report-schedule "<cron>"] [--smoke-schedule "<cron>"]
    [--db-user <user>] [--db-pass <pass>] [--db-name <name>]
    [--region <name>] [--session <screen-name>] [--compress <true|false>]

Examples:
  osmtool_cron.sh --action list
  osmtool_cron.sh --action install --backup-schedule "0 3 * * *" --db-user root --db-pass secret --db-name opensim --region sim1
  osmtool_cron.sh --action remove
EOF
  print_usage_common
}

need_crontab() {
  need_cmd crontab
}

quote_sq() {
  local s="$1"
  s="${s//\'/\'\"\'\"\'}"
  printf "'%s'" "$s"
}

build_backup_cmd() {
  local cmd
  cmd="bash $ROOT_DIR/osmtool_main.sh --module backup --profile $PROFILE --workdir $WORKDIR --action full-backup --db-user $DB_USER --db-name $DB_NAME --region $REGION --session $SESSION_NAME --compress $COMPRESS"

  if [[ -n "$DB_PASS" ]]; then
    cmd+=" --db-pass $DB_PASS"
  fi

  printf '%s' "$cmd"
}

build_restart_cmd() {
  printf '%s' "bash $ROOT_DIR/osmtool_main.sh --module startstop --profile $PROFILE --workdir $WORKDIR --target grid --action restart"
}

build_check_cmd() {
  printf '%s' "bash $ROOT_DIR/osmtool_main.sh --module install --profile $PROFILE --workdir $WORKDIR --action server-check"
}

build_report_cmd() {
  local cmd
  cmd="bash $ROOT_DIR/osmtool_main.sh --module report --profile $PROFILE --workdir $WORKDIR --action generate --db-user $DB_USER --db-name $DB_NAME"

  if [[ -n "$DB_PASS" ]]; then
    cmd+=" --db-pass $DB_PASS"
  fi

  printf '%s' "$cmd"
}

build_smoke_cmd() {
  printf '%s' "bash $ROOT_DIR/osmtool_main.sh --module smoke --profile $PROFILE --workdir $WORKDIR --action run"
}

cron_block_start="# OSMTOOL_CRON_BEGIN"
cron_block_end="# OSMTOOL_CRON_END"

emit_cron_block() {
  local backup_cmd restart_cmd check_cmd report_cmd smoke_cmd
  backup_cmd="$(build_backup_cmd)"
  restart_cmd="$(build_restart_cmd)"
  check_cmd="$(build_check_cmd)"
  report_cmd="$(build_report_cmd)"
  smoke_cmd="$(build_smoke_cmd)"

  echo "$cron_block_start"
  echo "SHELL=/bin/bash"
  echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  echo "$BACKUP_SCHEDULE $backup_cmd >> $ROOT_DIR/osmtool_backup.log 2>&1"
  echo "$RESTART_SCHEDULE $restart_cmd >> $ROOT_DIR/osmtool_backup.log 2>&1"
  echo "$CHECK_SCHEDULE $check_cmd >> $ROOT_DIR/osmtool_backup.log 2>&1"
  echo "$REPORT_SCHEDULE $report_cmd >> $ROOT_DIR/osmtool_backup.log 2>&1"
  echo "$SMOKE_SCHEDULE $smoke_cmd >> $ROOT_DIR/osmtool_backup.log 2>&1"
  echo "$cron_block_end"
}

existing_crontab() {
  crontab -l 2>/dev/null || true
}

strip_osmtool_block() {
  awk -v start="$cron_block_start" -v end="$cron_block_end" '
    $0 == start {inblock=1; next}
    $0 == end {inblock=0; next}
    !inblock {print}
  '
}

install_cron() {
  local current tmp
  [[ -n "$DB_USER" && -n "$DB_NAME" ]] || die "install cron requires --db-user and --db-name"

  current="$(existing_crontab)"
  tmp="$(mktemp)"

  printf '%s\n' "$current" | strip_osmtool_block > "$tmp"
  if [[ -s "$tmp" ]]; then
    echo >> "$tmp"
  fi
  emit_cron_block >> "$tmp"

  crontab "$tmp"
  rm -f "$tmp"
  log INFO "OSMTool cron jobs installed/updated"
}

list_cron() {
  local current
  current="$(existing_crontab)"

  if printf '%s\n' "$current" | grep -q "^$cron_block_start$"; then
    printf '%s\n' "$current" | awk -v start="$cron_block_start" -v end="$cron_block_end" '
      $0 == start {inblock=1; print; next}
      $0 == end {print; inblock=0; next}
      inblock {print}
    '
  else
    log INFO "No OSMTool cron block configured"
  fi
}

remove_cron() {
  local current tmp
  current="$(existing_crontab)"
  tmp="$(mktemp)"

  printf '%s\n' "$current" | strip_osmtool_block > "$tmp"
  crontab "$tmp"
  rm -f "$tmp"
  log INFO "OSMTool cron block removed"
}

WORKDIR="$DEFAULT_WORKDIR"
ACTION=""
PROFILE="grid-sim"

BACKUP_SCHEDULE="0 3 * * *"
RESTART_SCHEDULE="0 5 * * 1"
CHECK_SCHEDULE="*/15 * * * *"
REPORT_SCHEDULE="30 6 * * *"
SMOKE_SCHEDULE="45 6 * * *"

DB_USER="root"
DB_PASS=""
DB_NAME="opensim"
REGION="sim1"
SESSION_NAME="sim1"
COMPRESS="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workdir) WORKDIR="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --action) ACTION="$2"; shift 2 ;;
    --backup-schedule) BACKUP_SCHEDULE="$2"; shift 2 ;;
    --restart-schedule) RESTART_SCHEDULE="$2"; shift 2 ;;
    --check-schedule) CHECK_SCHEDULE="$2"; shift 2 ;;
    --report-schedule) REPORT_SCHEDULE="$2"; shift 2 ;;
    --smoke-schedule) SMOKE_SCHEDULE="$2"; shift 2 ;;
    --db-user) DB_USER="$2"; shift 2 ;;
    --db-pass) DB_PASS="$2"; shift 2 ;;
    --db-name) DB_NAME="$2"; shift 2 ;;
    --region) REGION="$2"; shift 2 ;;
    --session) SESSION_NAME="$2"; shift 2 ;;
    --compress) COMPRESS="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -n "$ACTION" ]] || die "Missing --action"
validate_profile "$PROFILE"
need_crontab

case "$ACTION" in
  install|list|remove) ;;
  *) die "Unsupported action: $ACTION" ;;
esac

case "$COMPRESS" in
  true|false) ;;
  *) die "--compress must be true or false" ;;
esac

case "$ACTION" in
  install) install_cron ;;
  list) list_cron ;;
  remove) remove_cron ;;
esac
