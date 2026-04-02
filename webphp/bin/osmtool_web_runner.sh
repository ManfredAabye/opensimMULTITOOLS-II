#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MAIN_SCRIPT="$PROJECT_ROOT/osmtool_main.sh"

if [[ ! -x "$MAIN_SCRIPT" ]]; then
  echo "ERROR: osmtool_main.sh not executable: $MAIN_SCRIPT" >&2
  exit 1
fi

MODULE="${1:-}"
ACTION="${2:-}"
PROFILE="${3:-grid-sim}"
LANG="${4:-de}"
WORKDIR="${5:-/opt}"

shift $(( $# >= 5 ? 5 : $# ))

EXTRA_ARGS=("$@")

case "$MODULE" in
  install|startstop|cleanup|health|backup|restore|update|config|report|smoke|cron) ;;
  *) echo "ERROR: unsupported module" >&2; exit 2 ;;
esac

case "$PROFILE" in
  grid-sim|robust|standalone) ;;
  *) echo "ERROR: invalid profile" >&2; exit 2 ;;
esac

case "$LANG" in
  de|en|fr|es) ;;
  *) echo "ERROR: invalid language" >&2; exit 2 ;;
esac

run_main() {
  bash "$MAIN_SCRIPT" --mode cli --profile "$PROFILE" --lang "$LANG" --workdir "$WORKDIR" --module "$MODULE" --action "$ACTION" "${EXTRA_ARGS[@]}"
}

run_main
