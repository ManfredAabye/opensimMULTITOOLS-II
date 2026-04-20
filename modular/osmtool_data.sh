#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/osmtool_core.sh"

usage() {
  cat <<'EOF'
Usage:
  osmtool_data.sh [--workdir <path>] --action <db-backup|oar-backup|full-backup>
    [--db-user <user>] [--db-pass <pass>] [--db-name <name>]
    [--region <name>] [--session <screen-name>] [--compress <true|false>]

Examples:
  osmtool_data.sh --action db-backup --db-user opensim --db-pass secret --db-name robust
  osmtool_data.sh --action oar-backup --region sim1 --session sim1 --workdir /opt
EOF
  print_usage_common
}

timestamp() {
  date '+%Y%m%d_%H%M%S'
}

backup_dir() {
  printf '%s' "$WORKDIR/backup"
}

ensure_backup_dir() {
  local dir
  dir="$(backup_dir)"

  if mkdir -p "$dir" 2>/dev/null; then
    return 0
  fi

  sudo mkdir -p "$dir"
  sudo chown "$(id -u):$(id -g)" "$dir"
}

compress_if_enabled() {
  local file_path="$1"

  if [[ "$COMPRESS" != "true" ]]; then
    printf '%s' "$file_path"
    return 0
  fi

  need_cmd gzip
  gzip -f "$file_path"
  printf '%s.gz' "$file_path"
}

resolve_default_session() {
  if [[ -n "$SESSION_NAME" ]]; then
    printf '%s' "$SESSION_NAME"
    return 0
  fi

  if [[ -n "$REGION" ]]; then
    printf '%s' "$REGION"
    return 0
  fi

  printf 'sim1'
}

screen_session_exists() {
  local name="$1"
  screen -list 2>/dev/null | grep -qE "\\.${name}[[:space:]]"
}

send_to_screen() {
  local session_name="$1"
  local command_text="$2"

  screen -S "$session_name" -p 0 -X stuff "${command_text}^M"
}

db_backup_mysql() {
  local out
  need_cmd mysqldump
  [[ -n "$DB_USER" && -n "$DB_PASS" && -n "$DB_NAME" ]] || die "db-backup(mysql) requires --db-user --db-pass --db-name"

  ensure_backup_dir
  out="$(backup_dir)/robust_${DB_NAME}_$(timestamp).sql"
  log INFO "Creating MySQL backup: $out"
  mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$out"
  out="$(compress_if_enabled "$out")"
  log INFO "DB backup created: $out"
}

db_backup() {
  db_backup_mysql
}

oar_backup() {
  local session_name out command_text

  [[ -n "$REGION" ]] || die "oar-backup requires --region"
  session_name="$(resolve_default_session)"

  ensure_backup_dir
  out="$(backup_dir)/${REGION}_$(timestamp).oar"

  if ! screen_session_exists "$session_name"; then
    die "Screen session not running: $session_name"
  fi

  # OpenSim console command to export current region as OAR.
  command_text="save oar $out"
  log INFO "Sending OAR export command to screen session '$session_name': $command_text"
  send_to_screen "$session_name" "$command_text"

  log INFO "OAR export command sent. Validate completion in the session log/output."
}

full_backup() {
  db_backup
  if [[ -n "$REGION" ]]; then
    oar_backup
  else
    log INFO "No --region provided. DB backup only in full-backup mode."
  fi
}

WORKDIR="$DEFAULT_WORKDIR"
ACTION=""
DB_USER=""
DB_PASS=""
DB_NAME=""
REGION=""
SESSION_NAME=""
COMPRESS="false"
PROFILE="grid-sim"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workdir) WORKDIR="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --action) ACTION="$2"; shift 2 ;;
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
ensure_profile_action_allowed backup "$PROFILE" "$ACTION"

case "$COMPRESS" in
  true|false) ;;
  *) die "--compress must be true or false" ;;
esac

log INFO "Using profile: $PROFILE"

case "$ACTION" in
  db-backup) db_backup ;;
  oar-backup) oar_backup ;;
  full-backup) full_backup ;;
  *) die "Unsupported action: $ACTION" ;;
esac
