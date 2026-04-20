#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/osmtool_core.sh"

usage() {
  cat <<'EOF'
Usage:
  osmtool_update.sh [--workdir <path>] --action <create-rollback|list-rollbacks|update-opensim|update-janus|full-update>
    [--opensim-dir <path>] [--opensim-repo <url>] [--opensim-branch <name>] [--repo-mode <update|fresh>]
    [--tsassets-dir <path>] [--currency-dir <path>] [--data-backup-dir <path>]
    [--deploy-binaries <true|false>] [--legacy-patch-dir <path>]
    [--janus-prefix <path>] [--janus-src <path>] [--public-host <host>] [--http-port <port>]
    [--admin-port <port>] [--rtp-range <from-to>] [--enable-admin <true|false>]
    [--api-secret <value>] [--admin-secret <value>] [--label <name>] [--dry-run <true|false>]

Examples:
  osmtool_update.sh --action create-rollback --workdir /opt --label pre_update
  osmtool_update.sh --action update-opensim --workdir /opt --dry-run true
EOF
  print_usage_common
}

timestamp() {
  date '+%Y%m%d_%H%M%S'
}

rollback_dir() {
  printf '%s' "$WORKDIR/rollback"
}

ensure_rollback_dir() {
  local dir
  dir="$(rollback_dir)"

  if mkdir -p "$dir" 2>/dev/null; then
    return 0
  fi

  sudo mkdir -p "$dir"
  sudo chown "$(id -u):$(id -g)" "$dir"
}

path_relative_to_root() {
  local path="$1"
  printf '%s' "${path#/}"
}

append_snapshot_path() {
  local path="$1"

  [[ -e "$path" ]] || return 0
  SNAPSHOT_PATHS+=("$(path_relative_to_root "$path")")
}

build_opensim_snapshot_paths() {
  local sim_dir

  SNAPSHOT_PATHS=()
  append_snapshot_path "$OPENSIM_DIR"
  append_snapshot_path "$WORKDIR/robust/bin"
  append_snapshot_path "$WORKDIR/standalone/bin"

  shopt -s nullglob
  for sim_dir in "$WORKDIR"/sim*; do
    append_snapshot_path "$sim_dir/bin"
  done
  shopt -u nullglob
}

build_janus_snapshot_paths() {
  SNAPSHOT_PATHS=()
  append_snapshot_path "$JANUS_PREFIX"
  append_snapshot_path "$JANUS_SRC"
}

create_snapshot_archive() {
  local scope="$1"
  shift
  local archive_name archive_path manifest_path
  local -a paths=("$@")

  ensure_rollback_dir

  if [[ ${#paths[@]} -eq 0 ]]; then
    log WARN "No existing paths found for rollback scope: $scope"
    return 0
  fi

  archive_name="${scope}_$(timestamp)"
  if [[ -n "$LABEL" ]]; then
    archive_name="${archive_name}_${LABEL}"
  fi

  archive_path="$(rollback_dir)/${archive_name}.tar.gz"
  manifest_path="$(rollback_dir)/${archive_name}.manifest"

  log INFO "Creating rollback archive: $archive_path"
  printf '%s\n' "${paths[@]}" > "$manifest_path"

  if [[ "$DRY_RUN" == "true" ]]; then
    log INFO "[DRY-RUN] Would archive paths listed in: $manifest_path"
    return 0
  fi

  tar -czf "$archive_path" -C / "${paths[@]}"
  log INFO "Rollback archive created: $archive_path"
  log INFO "Rollback manifest created: $manifest_path"
}

run_install_action() {
  local install_action="$1"
  local -a cmd

  cmd=("$SCRIPT_DIR/osmtool_install.sh" --profile "$PROFILE" --workdir "$WORKDIR" --action "$install_action")

  [[ -n "$OPENSIM_DIR" ]] && cmd+=(--opensim-dir "$OPENSIM_DIR")
  [[ -n "$OPENSIM_REPO" ]] && cmd+=(--opensim-repo "$OPENSIM_REPO")
  [[ -n "$OPENSIM_BRANCH" ]] && cmd+=(--opensim-branch "$OPENSIM_BRANCH")
  [[ -n "$REPO_MODE" ]] && cmd+=(--repo-mode "$REPO_MODE")
  [[ -n "$TSASSETS_DIR" ]] && cmd+=(--tsassets-dir "$TSASSETS_DIR")
  [[ -n "$CURRENCY_DIR" ]] && cmd+=(--currency-dir "$CURRENCY_DIR")
  [[ -n "$DATA_BACKUP_DIR" ]] && cmd+=(--data-backup-dir "$DATA_BACKUP_DIR")
  [[ -n "$DEPLOY_BINARIES" ]] && cmd+=(--deploy-binaries "$DEPLOY_BINARIES")
  [[ -n "$LEGACY_PATCH_DIR" ]] && cmd+=(--legacy-patch-dir "$LEGACY_PATCH_DIR")
  [[ -n "$JANUS_PREFIX" ]] && cmd+=(--janus-prefix "$JANUS_PREFIX")
  [[ -n "$JANUS_SRC" ]] && cmd+=(--janus-src "$JANUS_SRC")
  [[ -n "$PUBLIC_HOST" ]] && cmd+=(--public-host "$PUBLIC_HOST")
  [[ -n "$HTTP_PORT" ]] && cmd+=(--http-port "$HTTP_PORT")
  [[ -n "$ADMIN_PORT" ]] && cmd+=(--admin-port "$ADMIN_PORT")
  [[ -n "$RTP_RANGE" ]] && cmd+=(--rtp-range "$RTP_RANGE")
  [[ -n "$ENABLE_ADMIN" ]] && cmd+=(--enable-admin "$ENABLE_ADMIN")
  [[ -n "$API_SECRET" ]] && cmd+=(--api-secret "$API_SECRET")
  [[ -n "$ADMIN_SECRET" ]] && cmd+=(--admin-secret "$ADMIN_SECRET")

  log INFO "Delegating update to install action: $install_action"
  if [[ "$DRY_RUN" == "true" ]]; then
    printf -v rendered '%q ' "${cmd[@]}"
    log INFO "[DRY-RUN] $rendered"
    return 0
  fi

  "${cmd[@]}"
}

create_rollback() {
  build_opensim_snapshot_paths
  create_snapshot_archive opensim "${SNAPSHOT_PATHS[@]}"
  build_janus_snapshot_paths
  create_snapshot_archive janus "${SNAPSHOT_PATHS[@]}"
}

list_rollbacks() {
  local dir
  dir="$(rollback_dir)"

  if [[ ! -d "$dir" ]]; then
    log INFO "No rollback directory found: $dir"
    return 0
  fi

  find "$dir" -maxdepth 1 -type f \( -name '*.tar.gz' -o -name '*.manifest' \) -printf '%T@ %p\n' 2>/dev/null | \
    sort -rn | cut -d' ' -f2-
}

update_opensim() {
  build_opensim_snapshot_paths
  create_snapshot_archive opensim "${SNAPSHOT_PATHS[@]}"
  run_install_action install-opensim
}

update_janus() {
  build_janus_snapshot_paths
  create_snapshot_archive janus "${SNAPSHOT_PATHS[@]}"
  run_install_action install-janus
}

full_update() {
  update_opensim
  update_janus
}

WORKDIR="$DEFAULT_WORKDIR"
ACTION=""
PROFILE="grid-sim"
OPENSIM_DIR=""
OPENSIM_REPO=""
OPENSIM_BRANCH=""
REPO_MODE="update"
TSASSETS_DIR=""
CURRENCY_DIR=""
DATA_BACKUP_DIR=""
DEPLOY_BINARIES="true"
LEGACY_PATCH_DIR=""
JANUS_PREFIX=""
JANUS_SRC=""
PUBLIC_HOST=""
HTTP_PORT=""
ADMIN_PORT=""
RTP_RANGE=""
ENABLE_ADMIN=""
API_SECRET=""
ADMIN_SECRET=""
LABEL=""
DRY_RUN="false"
SNAPSHOT_PATHS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workdir) WORKDIR="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --action) ACTION="$2"; shift 2 ;;
    --opensim-dir) OPENSIM_DIR="$2"; shift 2 ;;
    --opensim-repo) OPENSIM_REPO="$2"; shift 2 ;;
    --opensim-branch) OPENSIM_BRANCH="$2"; shift 2 ;;
    --repo-mode) REPO_MODE="$2"; shift 2 ;;
    --tsassets-dir) TSASSETS_DIR="$2"; shift 2 ;;
    --currency-dir) CURRENCY_DIR="$2"; shift 2 ;;
    --data-backup-dir) DATA_BACKUP_DIR="$2"; shift 2 ;;
    --deploy-binaries) DEPLOY_BINARIES="$2"; shift 2 ;;
    --legacy-patch-dir) LEGACY_PATCH_DIR="$2"; shift 2 ;;
    --janus-prefix) JANUS_PREFIX="$2"; shift 2 ;;
    --janus-src) JANUS_SRC="$2"; shift 2 ;;
    --public-host) PUBLIC_HOST="$2"; shift 2 ;;
    --http-port) HTTP_PORT="$2"; shift 2 ;;
    --admin-port) ADMIN_PORT="$2"; shift 2 ;;
    --rtp-range) RTP_RANGE="$2"; shift 2 ;;
    --enable-admin) ENABLE_ADMIN="$2"; shift 2 ;;
    --api-secret) API_SECRET="$2"; shift 2 ;;
    --admin-secret) ADMIN_SECRET="$2"; shift 2 ;;
    --label) LABEL="$2"; shift 2 ;;
    --dry-run) DRY_RUN="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -n "$ACTION" ]] || die "Missing --action"
validate_profile "$PROFILE"
ensure_profile_action_allowed update "$PROFILE" "$ACTION"

case "$DRY_RUN" in
  true|false) ;;
  *) die "--dry-run must be true or false" ;;
esac

OPENSIM_DIR="${OPENSIM_DIR:-$WORKDIR/opensim}"
JANUS_PREFIX="${JANUS_PREFIX:-/opt/janus}"
JANUS_SRC="${JANUS_SRC:-$WORKDIR/janus-gateway}"

log INFO "Using profile: $PROFILE"

case "$ACTION" in
  create-rollback) create_rollback ;;
  list-rollbacks) list_rollbacks ;;
  update-opensim) update_opensim ;;
  update-janus) update_janus ;;
  full-update) full_update ;;
  *) die "Unsupported action: $ACTION" ;;
esac