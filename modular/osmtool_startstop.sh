#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/osmtool_core.sh"

usage() {
  cat <<'EOF'
Usage:
  osmtool_startstop.sh [--workdir <path>] [--profile <grid-sim|robust|standalone>] --target <grid|robust|sim1|standalone|janus|region> --action <start|stop|restart> [--name <region-screen-name>]
    [--janus-prefix <path>]

Examples:
  osmtool_startstop.sh --profile grid-sim --target grid --action start --workdir /opt
  osmtool_startstop.sh --profile robust --target robust --action restart --workdir /opt
EOF
  print_usage_common
}

run_screen_cmd() {
  local screen_name="$1"
  local command_text="$2"
  screen -S "$screen_name" -p 0 -X stuff "${command_text}^M"
}

screen_session_exists() {
  local screen_name="$1"
  screen -list 2>/dev/null | grep -qE "\\.${screen_name}[[:space:]]"
}

stop_screen_session() {
  local screen_name="$1"
  local grace_seconds="${2:-6}"

  if ! screen_session_exists "$screen_name"; then
    log INFO "$screen_name is not running"
    return 0
  fi

  run_screen_cmd "$screen_name" "shutdown"
  log INFO "Sent shutdown to $screen_name"
  sleep "$grace_seconds"

  if screen_session_exists "$screen_name"; then
    log INFO "Session '$screen_name' still running after shutdown; forcing screen quit"
    screen -S "$screen_name" -X quit || true
    sleep 1
  fi

  if screen_session_exists "$screen_name"; then
    log ERROR "Failed to stop screen session: $screen_name"
    return 1
  fi

  log INFO "Screen session '$screen_name' stopped"
  return 0
}

ensure_janus_ready() {
  local marker="$JANUS_PREFIX/.osmtool_janus_ready"
  local core_cfg="$JANUS_PREFIX/etc/janus/janus.jcfg"
  local core_cfg_legacy="$JANUS_PREFIX/etc/janus/janus.cfg"
  local http_cfg="$JANUS_PREFIX/etc/janus/janus.transport.http.jcfg"
  local http_cfg_legacy="$JANUS_PREFIX/etc/janus/janus.transport.http.cfg"

  [[ -f "$JANUS_PREFIX/bin/janus" ]] || die "Janus binary missing: $JANUS_PREFIX/bin/janus. Run install module action compile-janus/install-janus first."

  if [[ ! -f "$core_cfg" && ! -f "$core_cfg_legacy" ]]; then
    die "Janus core config missing in $JANUS_PREFIX/etc/janus. Run configure-janus/install-janus first."
  fi

  if [[ ! -f "$http_cfg" && ! -f "$http_cfg_legacy" ]]; then
    die "Janus HTTP config missing in $JANUS_PREFIX/etc/janus. Run configure-janus/install-janus first."
  fi

  [[ -f "$marker" ]] || log INFO "Janus ready marker not found ($marker). Continuing because binary/config files exist."
}

janus_service_action() {
  local action="$1"
  local janus_bin janus_cfg

  janus_bin="$JANUS_PREFIX/bin/janus"
  janus_cfg="$JANUS_PREFIX/etc/janus/janus.jcfg"
  [[ -f "$janus_cfg" ]] || janus_cfg="$JANUS_PREFIX/etc/janus/janus.cfg"

  if command -v systemctl >/dev/null 2>&1; then
    if systemctl list-unit-files 2>/dev/null | grep -q '^janus\.service'; then
      sudo systemctl "$action" janus
      return 0
    fi
  fi

  if command -v service >/dev/null 2>&1; then
    if service --status-all 2>/dev/null | grep -q janus; then
      sudo service janus "$action"
      return 0
    fi
  fi

  if [[ -x "$WORKDIR/janus.sh" ]]; then
    "$WORKDIR/janus.sh" "${action}_janus" || "$WORKDIR/janus.sh" "$action"
    return 0
  fi

  if [[ -x "$WORKDIR/janus/janus.sh" ]]; then
    "$WORKDIR/janus/janus.sh" "${action}_janus" || "$WORKDIR/janus/janus.sh" "$action"
    return 0
  fi

  # Fallback: control Janus directly from installed binary.
  if [[ -x "$janus_bin" ]]; then
    case "$action" in
      start)
        if pgrep -f "$janus_bin" >/dev/null 2>&1; then
          log INFO "Janus already running"
          return 0
        fi
        if command -v screen >/dev/null 2>&1; then
          screen -fa -S janus_gateway -d -U -m "$janus_bin" -C "$janus_cfg"
        else
          nohup "$janus_bin" -C "$janus_cfg" >/tmp/janus.log 2>&1 &
        fi
        return 0
        ;;
      stop)
        pkill -f "$janus_bin" >/dev/null 2>&1 || true
        if command -v screen >/dev/null 2>&1; then
          if screen -list | grep -q "janus_gateway"; then
            screen -S janus_gateway -X quit || true
          fi
        fi
        return 0
        ;;
      restart)
        pkill -f "$janus_bin" >/dev/null 2>&1 || true
        sleep 1
        if command -v screen >/dev/null 2>&1; then
          screen -fa -S janus_gateway -d -U -m "$janus_bin" -C "$janus_cfg"
        else
          nohup "$janus_bin" -C "$janus_cfg" >/tmp/janus.log 2>&1 &
        fi
        return 0
        ;;
    esac
  fi

  die "Janus control not configured. Expected system service or janus.sh helper."
}

require_ini() {
  local bin_dir="$1"
  local ini_file="$2"
  local label="$3"

  if [[ ! -f "$bin_dir/$ini_file" ]]; then
    die "$label cannot start: missing $bin_dir/$ini_file — run the config action first"
  fi
}

screen_start() {
  local screen_name="$1"
  local bin_dir="$2"
  local dll="$3"
  local pat="\\.${screen_name}[[:space:]]"

  if screen -list 2>/dev/null | grep -qE "$pat"; then
    log INFO "Screen session '$screen_name' already running — skipping start"
    return 0
  fi

  log INFO "Starting $screen_name from $bin_dir"
  (cd "$bin_dir" && screen -fa -S "$screen_name" -d -U -m dotnet "$dll")
  sleep 0.5

  if screen -list 2>/dev/null | grep -qE "$pat"; then
    log INFO "Screen session '$screen_name' started successfully"
  else
    log ERROR "Screen session '$screen_name' did not stay alive — check logs or missing config"
  fi
}

start_grid() {
  log INFO "Starting grid from $WORKDIR"

  if [[ -d "$WORKDIR/robust/bin" ]]; then
    require_ini "$WORKDIR/robust/bin" "Robust.ini" "RobustServer"
    screen_start "robustserver" "$WORKDIR/robust/bin" "Robust.dll"
  fi

  if [[ -f "$WORKDIR/robust/bin/MoneyServer.dll" && -f "$WORKDIR/robust/bin/MoneyServer.ini" ]]; then
    screen_start "moneyserver" "$WORKDIR/robust/bin" "MoneyServer.dll"
  fi

  if [[ -d "$WORKDIR/sim1/bin" ]]; then
    require_ini "$WORKDIR/sim1/bin" "OpenSim.ini" "sim1"
    screen_start "sim1" "$WORKDIR/sim1/bin" "OpenSim.dll"
  fi
}

stop_grid() {
  log INFO "Stopping grid"
  stop_screen_session "sim1" || true
  stop_screen_session "moneyserver" || true
  stop_screen_session "robustserver" || true
}

restart_grid() {
  stop_grid
  sleep 5
  start_grid
}

start_single() {
  local target="$1"
  case "$target" in
    robust)
      require_ini "$WORKDIR/robust/bin" "Robust.ini" "RobustServer"
      screen_start "robustserver" "$WORKDIR/robust/bin" "Robust.dll"
      ;;
    sim1)
      require_ini "$WORKDIR/sim1/bin" "OpenSim.ini" "sim1"
      screen_start "sim1" "$WORKDIR/sim1/bin" "OpenSim.dll"
      ;;
    standalone)
      require_ini "$WORKDIR/standalone/bin" "OpenSim.ini" "standalone"
      screen_start "standalone" "$WORKDIR/standalone/bin" "OpenSim.dll"
      ;;
    janus)
      ensure_janus_ready
      janus_service_action start
      ;;
    region)
      [[ -n "$NAME" ]] || die "--name is required for --target region"
      require_ini "$WORKDIR/${NAME}/bin" "OpenSim.ini" "$NAME"
      screen_start "$NAME" "$WORKDIR/${NAME}/bin" "OpenSim.dll"
      ;;
    *)
      die "Unsupported start target: $target"
      ;;
  esac
}

stop_single() {
  local target="$1"
  case "$target" in
    robust)
      stop_screen_session "robustserver"
      ;;
    sim1)
      stop_screen_session "sim1"
      ;;
    standalone)
      stop_screen_session "standalone"
      ;;
    janus) janus_service_action stop ;;
    region)
      [[ -n "$NAME" ]] || die "--name is required for --target region"
      stop_screen_session "$NAME"
      ;;
    *) die "Unsupported stop target: $target" ;;
  esac
}

WORKDIR="$DEFAULT_WORKDIR"
TARGET=""
ACTION=""
NAME=""
PROFILE="grid-sim"
JANUS_PREFIX="${JANUS_PREFIX:-/opt/janus}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workdir) WORKDIR="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --janus-prefix) JANUS_PREFIX="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --action) ACTION="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -n "$TARGET" ]] || die "Missing --target"
[[ -n "$ACTION" ]] || die "Missing --action"
validate_profile "$PROFILE"
ensure_profile_action_allowed startstop "$PROFILE" "$ACTION"
ensure_profile_target_allowed "$PROFILE" "$TARGET"

if [[ "$TARGET" == "janus" && "$ACTION" != "stop" ]]; then
  ensure_janus_ready
fi

log INFO "Using profile: $PROFILE"

if [[ "$TARGET" == "grid" ]]; then
  case "$ACTION" in
    start) start_grid ;;
    stop) stop_grid ;;
    restart) restart_grid ;;
    *) die "Unsupported action for grid: $ACTION" ;;
  esac
else
  case "$ACTION" in
    start) start_single "$TARGET" ;;
    stop) stop_single "$TARGET" ;;
    restart)
      stop_single "$TARGET"
      sleep 3
      start_single "$TARGET"
      ;;
    *) die "Unsupported action: $ACTION" ;;
  esac
fi
