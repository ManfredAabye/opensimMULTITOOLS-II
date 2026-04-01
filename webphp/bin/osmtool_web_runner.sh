#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
MAIN_SCRIPT="$PROJECT_ROOT/osmtool_main.sh"

if [[ ! -x "$MAIN_SCRIPT" ]]; then
  echo "ERROR: osmtool_main.sh not executable: $MAIN_SCRIPT" >&2
  exit 1
fi

ACTION="${1:-}"
PROFILE="${2:-grid-sim}"
LANG="${3:-de}"
WORKDIR="${4:-/opt}"

case "$PROFILE" in
  grid-sim|robust|standalone) ;;
  *) echo "ERROR: invalid profile" >&2; exit 2 ;;
esac

case "$LANG" in
  de|en|fr|es) ;;
  *) echo "ERROR: invalid language" >&2; exit 2 ;;
esac

run_main() {
  bash "$MAIN_SCRIPT" --mode cli --profile "$PROFILE" --lang "$LANG" --workdir "$WORKDIR" "$@"
}

case "$ACTION" in
  start)
    run_main --module startstop --action start
    ;;
  stop)
    run_main --module startstop --action stop
    ;;
  restart)
    run_main --module startstop --action restart
    ;;
  smoke)
    run_main --module smoke --action run
    ;;
  report)
    run_main --module report --action generate
    ;;
  health)
    run_main --module health --action run
    ;;
  cron-list)
    run_main --module cron --action list
    ;;
  *)
    echo "ERROR: unsupported action" >&2
    exit 2
    ;;
esac
