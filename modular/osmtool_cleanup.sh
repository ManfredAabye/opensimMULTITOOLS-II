#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/osmtool_core.sh"

usage() {
  cat <<'EOF'
Usage:
  osmtool_cleanup.sh [--workdir <path>] --action <cache-clean|log-clean|tmp-clean|reboot> [--dry-run <true|false>]

Examples:
  osmtool_cleanup.sh --action log-clean --workdir /opt --dry-run true
  osmtool_cleanup.sh --action cache-clean --workdir /opt/opensim
EOF
  print_usage_common
}

realpath_safe() {
  local p="$1"
  python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$p" 2>/dev/null || echo "$p"
}

assert_safe_workdir() {
  local rp
  rp="$(realpath_safe "$WORKDIR")"

  [[ -n "$rp" ]] || die "Invalid workdir"
  [[ "$rp" != "/" ]] || die "Refusing cleanup on root directory"
  [[ "$rp" != "/opt" ]] || die "Refusing cleanup on /opt root; choose a dedicated OpenSim workdir"
  [[ -d "$rp" ]] || die "Workdir not found: $rp"

  WORKDIR="$rp"
}

run_delete() {
  local path="$1"

  if [[ "$DRY_RUN" == "true" ]]; then
    log INFO "[DRY-RUN] Would remove: $path"
  else
    rm -rf "$path"
    log INFO "Removed: $path"
  fi
}

run_delete_file() {
  local path="$1"

  if [[ "$DRY_RUN" == "true" ]]; then
    log INFO "[DRY-RUN] Would delete file: $path"
  else
    rm -f "$path"
    log INFO "Deleted file: $path"
  fi
}

cache_clean() {
  log INFO "Cleaning map tiles and cache under $WORKDIR"
  local d
  while IFS= read -r d; do
    [[ -n "$d" ]] || continue
    run_delete "$d"
  done < <(find "$WORKDIR" -mindepth 2 -type d \( -name "assetcache" -o -name "MapTiles" -o -name "cache" \))
}

log_clean() {
  log INFO "Cleaning log files under $WORKDIR"
  local f
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    run_delete_file "$f"
  done < <(find "$WORKDIR" -type f \( -name "*.log" -o -name "OpenSim.log" -o -name "ProblemRestarts.log" \))
}

tmp_clean() {
  log INFO "Cleaning temporary files under $WORKDIR"
  local f
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    run_delete_file "$f"
  done < <(find "$WORKDIR" -type f \( -name "*.tmp" -o -name "*.temp" \))
}

safe_reboot() {
  if confirm "Reboot" "Reboot server now?"; then
    log INFO "Reboot requested"
    sudo reboot
  else
    log INFO "Reboot canceled"
  fi
}

WORKDIR="$DEFAULT_WORKDIR"
ACTION=""
PROFILE="grid-sim"
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workdir) WORKDIR="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --action) ACTION="$2"; shift 2 ;;
    --dry-run) DRY_RUN="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -n "$ACTION" ]] || die "Missing --action"
validate_profile "$PROFILE"
ensure_profile_action_allowed cleanup "$PROFILE" "$ACTION"
case "$DRY_RUN" in true|false) ;; *) die "--dry-run must be true or false" ;; esac
assert_safe_workdir
log INFO "Using profile: $PROFILE"
log INFO "Dry-run mode: $DRY_RUN"

case "$ACTION" in
  cache-clean) cache_clean ;;
  log-clean) log_clean ;;
  tmp-clean) tmp_clean ;;
  reboot) safe_reboot ;;
  *) die "Unsupported action: $ACTION" ;;
esac
