#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/osmtool_core.sh"

usage() {
  cat <<'EOF'
Usage:
  osmtool_restore.sh [--workdir <path>] --action <db-restore|oar-restore|full-restore|list-backups>
    [--db-user <user>] [--db-pass <pass>] [--db-name <name>]
    [--region <name>] [--session <screen-name>] [--file <backup-file>]
    [--dry-run <true|false>]

Examples:
  osmtool_restore.sh --action list-backups --workdir /opt
  osmtool_restore.sh --action db-restore --db-user opensim --db-pass secret --db-name robust --file /opt/backup/robust_robust_20260401_120000.sql
EOF
  print_usage_common
}

backup_dir() {
  printf '%s' "$WORKDIR/backup"
}

ensure_backup_dir() {
  local dir
  dir="$(backup_dir)"

  if [[ ! -d "$dir" ]]; then
    die "Backup directory does not exist: $dir"
  fi

  return 0
}

list_backups() {
  local dir
  dir="$(backup_dir)"

  if [[ ! -d "$dir" ]]; then
    log INFO "No backup directory found: $dir"
    return 0
  fi

  log INFO "SQL Backups:"
  find "$dir" -maxdepth 1 -name "robust_*.sql*" -type f -printf '%T@ %p\n' 2>/dev/null | \
    sort -rn | cut -d' ' -f2- | head -5 || true

  log INFO "OAR Backups:"
  find "$dir" -maxdepth 1 -name "*.oar" -type f -printf '%T@ %p\n' 2>/dev/null | \
    sort -rn | cut -d' ' -f2- | head -5 || true
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

validate_sql_file() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    die "SQL backup file not found: $file"
  fi

  # Check for gzip compression
  if [[ "$file" =~ \.gz$ ]]; then
    need_cmd zcat
    return 0
  fi

  return 0
}

validate_oar_file() {
  local file="$1"

  if [[ ! -f "$file" ]]; then
    die "OAR backup file not found: $file"
  fi

  if [[ ! "$file" =~ \.oar$ ]]; then
    die "File does not appear to be an OAR backup: $file"
  fi

  return 0
}

db_restore_mysql() {
  local file sql_cmd

  [[ -n "$DB_USER" && -n "$DB_PASS" && -n "$DB_NAME" ]] || die "db-restore requires --db-user --db-pass --db-name"
  [[ -n "$FILE" ]] || die "db-restore requires --file"

  file="$FILE"
  validate_sql_file "$file"

  need_cmd mysql

  if [[ "$file" =~ \.gz$ ]]; then
    sql_cmd="zcat '$file' | mysql -u'$DB_USER' -p'$DB_PASS' '$DB_NAME'"
  else
    sql_cmd="mysql -u'$DB_USER' -p'$DB_PASS' '$DB_NAME' < '$file'"
  fi

  log INFO "Database restore command:"
  log INFO "$sql_cmd"

  if [[ "$DRY_RUN" == "true" ]]; then
    log INFO "[DRY-RUN] Not executing database restore"
    return 0
  fi

  log INFO "Restoring database from: $file"
  if [[ "$file" =~ \.gz$ ]]; then
    zcat "$file" | mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" || die "Database restore failed"
  else
    mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$file" || die "Database restore failed"
  fi

  log INFO "Database restore completed successfully from: $file"
}

db_restore() {
  db_restore_mysql
}

oar_restore() {
  local session_name file cmd

  [[ -n "$REGION" ]] || die "oar-restore requires --region"
  [[ -n "$FILE" ]] || die "oar-restore requires --file"

  file="$FILE"
  validate_oar_file "$file"

  session_name="$(resolve_default_session)"

  if ! screen_session_exists "$session_name"; then
    die "Screen session not running: $session_name"
  fi

  cmd="load oar $file"
  log INFO "OAR restore command:"
  log INFO "$cmd"

  if [[ "$DRY_RUN" == "true" ]]; then
    log INFO "[DRY-RUN] Not executing OAR restore"
    log INFO "To complete restore, region '$session_name' must be running and responsive"
    return 0
  fi

  log INFO "Sending OAR restore command to screen session '$session_name'"
  send_to_screen "$session_name" "$cmd"
  log INFO "OAR restore command sent. Region import may take some time. Check session output for completion."
}

full_restore() {
  local has_sql has_oar

  has_sql=false
  has_oar=false

  # Try to detect which restores to perform based on parameters
  if [[ -n "$FILE" ]] && [[ "$FILE" =~ \.(sql|gz)$ ]]; then
    has_sql=true
  fi

  if [[ -n "$FILE" ]] && [[ "$FILE" =~ \.oar$ ]]; then
    has_oar=true
  fi

  if [[ "$has_sql" == "true" ]]; then
    log INFO "Detected SQL backup file, proceeding with database restore..."
    db_restore
  fi

  if [[ "$has_oar" == "true" ]]; then
    log INFO "Detected OAR backup file, proceeding with OAR restore..."
    if [[ -n "$REGION" ]]; then
      oar_restore
    else
      log WARN "OAR file provided but no --region specified. Skipping OAR restore."
    fi
  fi

  if [[ "$has_sql" == "false" && "$has_oar" == "false" ]]; then
    die "full-restore requires --file with .sql/.sql.gz or .oar extension"
  fi
}

WORKDIR="$DEFAULT_WORKDIR"
ACTION=""
DB_USER=""
DB_PASS=""
DB_NAME=""
REGION=""
SESSION_NAME=""
FILE=""
DRY_RUN="false"
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
    --file) FILE="$2"; shift 2 ;;
    --dry-run) DRY_RUN="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -n "$ACTION" ]] || die "Missing --action"
validate_profile "$PROFILE"
ensure_profile_action_allowed restore "$PROFILE" "$ACTION"

case "$DRY_RUN" in
  true|false) ;;
  *) die "--dry-run must be true or false" ;;
esac

log INFO "Using profile: $PROFILE"

case "$ACTION" in
  db-restore) db_restore ;;
  oar-restore) oar_restore ;;
  full-restore) full_restore ;;
  list-backups) ensure_backup_dir; list_backups ;;
  *) die "Unsupported action: $ACTION" ;;
esac
