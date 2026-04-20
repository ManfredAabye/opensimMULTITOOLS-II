#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/osmtool_core.sh"

usage() {
  cat <<'EOF'
Usage:
  osmtool_smoke.sh [--workdir <path>] --action <run>
    [--target <grid|robust|sim1|standalone|janus|region>] [--name <region-screen-name>]
    [--expected-screens <csv>] [--wait-after-start <sec>] [--wait-after-stop <sec>]
    [--janus-prefix <path>]

Examples:
  osmtool_smoke.sh --action run --profile grid-sim --workdir /opt
  osmtool_smoke.sh --action run --profile robust --workdir /opt --expected-screens robustserver
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

default_target_for_profile() {
  case "$1" in
    grid-sim) echo "grid" ;;
    robust) echo "robust" ;;
    standalone) echo "standalone" ;;
  esac
}

default_expected_screens_for_target() {
  case "$1" in
    grid) echo "robustserver,sim1" ;;
    robust) echo "robustserver" ;;
    sim1) echo "sim1" ;;
    standalone) echo "standalone" ;;
    janus) echo "janus_gateway" ;;
    region) [[ -n "$NAME" ]] && echo "$NAME" || echo "" ;;
    *) echo "" ;;
  esac
}

screen_session_exists() {
  local name="$1"
  screen -list 2>/dev/null | grep -qE "\\.${name}[[:space:]]"
}

verify_screens_up() {
  local name failed=0

  [[ -n "$EXPECTED_SCREENS" ]] || {
    log INFO "No expected screens configured; skipping UP verification"
    return 0
  }

  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    if screen_session_exists "$name"; then
      log INFO "[SMOKE][OK] screen up: $name"
    else
      log ERROR "[SMOKE][FAIL] screen not running: $name"
      failed=$((failed + 1))
    fi
  done < <(split_csv "$EXPECTED_SCREENS")

  return "$failed"
}

verify_screens_down() {
  local name failed=0

  [[ -n "$EXPECTED_SCREENS" ]] || {
    log INFO "No expected screens configured; skipping DOWN verification"
    return 0
  }

  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    if screen_session_exists "$name"; then
      log ERROR "[SMOKE][FAIL] screen still running: $name"
      failed=$((failed + 1))
    else
      log INFO "[SMOKE][OK] screen down: $name"
    fi
  done < <(split_csv "$EXPECTED_SCREENS")

  return "$failed"
}

run_startstop() {
  local action="$1"
  local -a cmd

  cmd=(bash "$ROOT_DIR/osmtool_main.sh" --module startstop --profile "$PROFILE" --workdir "$WORKDIR" --target "$TARGET" --action "$action")
  if [[ "$TARGET" == "region" && -n "$NAME" ]]; then
    cmd+=(--name "$NAME")
  fi
  if [[ -n "$JANUS_PREFIX" ]]; then
    cmd+=(--janus-prefix "$JANUS_PREFIX")
  fi

  "${cmd[@]}"
}

run_smoke() {
  local failures=0

  log INFO "[SMOKE] profile=$PROFILE target=$TARGET workdir=$WORKDIR"
  log INFO "[SMOKE] expected_screens=$EXPECTED_SCREENS"

  run_startstop start || failures=$((failures + 1))
  sleep "$WAIT_AFTER_START"
  verify_screens_up || failures=$((failures + 1))

  run_startstop restart || failures=$((failures + 1))
  sleep "$WAIT_AFTER_START"
  verify_screens_up || failures=$((failures + 1))

  run_startstop stop || failures=$((failures + 1))
  sleep "$WAIT_AFTER_STOP"
  verify_screens_down || failures=$((failures + 1))

  if [[ "$failures" -eq 0 ]]; then
    log INFO "[SMOKE][PASS] Start/Restart/Stop smoke test successful"
    return 0
  fi

  log ERROR "[SMOKE][FAIL] Smoke test failed with $failures issue group(s)"
  return 1
}

WORKDIR="$DEFAULT_WORKDIR"
ACTION=""
PROFILE="grid-sim"
TARGET=""
NAME=""
EXPECTED_SCREENS=""
WAIT_AFTER_START="3"
WAIT_AFTER_STOP="8"
JANUS_PREFIX="${JANUS_PREFIX:-/opt/janus}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workdir) WORKDIR="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --action) ACTION="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --expected-screens) EXPECTED_SCREENS="$2"; shift 2 ;;
    --wait-after-start) WAIT_AFTER_START="$2"; shift 2 ;;
    --wait-after-stop) WAIT_AFTER_STOP="$2"; shift 2 ;;
    --janus-prefix) JANUS_PREFIX="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -n "$ACTION" ]] || die "Missing --action"
validate_profile "$PROFILE"
ensure_profile_action_allowed smoke "$PROFILE" "$ACTION"

if [[ -z "$TARGET" ]]; then
  TARGET="$(default_target_for_profile "$PROFILE")"
fi
ensure_profile_target_allowed "$PROFILE" "$TARGET"

if [[ "$TARGET" == "region" && -z "$NAME" ]]; then
  die "--name is required for --target region"
fi

if [[ -z "$EXPECTED_SCREENS" ]]; then
  EXPECTED_SCREENS="$(default_expected_screens_for_target "$TARGET")"
fi

case "$ACTION" in
  run) run_smoke ;;
  *) die "Unsupported action: $ACTION" ;;
esac