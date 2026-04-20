#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/osmtool_core.sh"

msgf() {
  local key="$1"
  shift
  # shellcheck disable=SC2059
  printf "$(msg "$key")" "$@"
}

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
  local grace_seconds="${2:-$SIMULATOR_STOP_WAIT}"

  if ! screen_session_exists "$screen_name"; then
    log INFO "$(msgf STARTSTOP_NOT_RUNNING "$screen_name")"
    return 0
  fi

  run_screen_cmd "$screen_name" "shutdown"
  log INFO "$(msgf STARTSTOP_SENT_SHUTDOWN "$screen_name")"
  sleep "$grace_seconds"

  if screen_session_exists "$screen_name"; then
    log INFO "$(msgf STARTSTOP_FORCE_QUIT "$screen_name")"
    screen -S "$screen_name" -X quit || true
    sleep 1
  fi

  if screen_session_exists "$screen_name"; then
    log ERROR "$(msgf STARTSTOP_STOP_FAILED "$screen_name")"
    return 1
  fi

  log INFO "$(msgf STARTSTOP_STOPPED "$screen_name")"
  return 0
}

ensure_janus_ready() {
  local marker="$JANUS_PREFIX/.osmtool_janus_ready"
  local core_cfg="$JANUS_PREFIX/etc/janus/janus.jcfg"
  local core_cfg_legacy="$JANUS_PREFIX/etc/janus/janus.cfg"
  local http_cfg="$JANUS_PREFIX/etc/janus/janus.transport.http.jcfg"
  local http_cfg_legacy="$JANUS_PREFIX/etc/janus/janus.transport.http.cfg"

  [[ -f "$JANUS_PREFIX/bin/janus" ]] || die "$(msgf STARTSTOP_JANUS_BIN_MISSING "$JANUS_PREFIX/bin/janus")"

  if [[ ! -f "$core_cfg" && ! -f "$core_cfg_legacy" ]]; then
    die "$(msgf STARTSTOP_JANUS_CORE_CFG_MISSING "$JANUS_PREFIX/etc/janus")"
  fi

  if [[ ! -f "$http_cfg" && ! -f "$http_cfg_legacy" ]]; then
    die "$(msgf STARTSTOP_JANUS_HTTP_CFG_MISSING "$JANUS_PREFIX/etc/janus")"
  fi

  [[ -f "$marker" ]] || log INFO "$(msgf STARTSTOP_JANUS_MARKER_MISSING "$marker")"
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
          log INFO "$(msg STARTSTOP_JANUS_ALREADY_RUNNING)"
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

  die "$(msg STARTSTOP_JANUS_CONTROL_NOT_CONFIGURED)"
}

require_ini() {
  local bin_dir="$1"
  local ini_file="$2"
  local label="$3"

  if [[ ! -f "$bin_dir/$ini_file" ]]; then
    die "$(msgf STARTSTOP_REQUIRED_INI_MISSING "$label" "$bin_dir/$ini_file")"
  fi
}

screen_start() {
  local screen_name="$1"
  local bin_dir="$2"
  local dll="$3"
  local pat="\\.${screen_name}[[:space:]]"

  if screen -list 2>/dev/null | grep -qE "$pat"; then
    log INFO "$(msgf STARTSTOP_ALREADY_RUNNING "$screen_name")"
    return 0
  fi

  log INFO "$(msgf STARTSTOP_STARTING_FROM "$screen_name" "$bin_dir")"
  (cd "$bin_dir" && screen -fa -S "$screen_name" -d -U -m dotnet "$dll")
  sleep 0.5

  if screen -list 2>/dev/null | grep -qE "$pat"; then
    log INFO "$(msgf STARTSTOP_STARTED_OK "$screen_name")"
    return 0
  else
    log ERROR "$(msgf STARTSTOP_START_FAILED "$screen_name")"
    return 1
  fi
}

list_sim_names_asc() {
  local sim_dir sim_name
  local sim_names=()

  shopt -s nullglob
  for sim_dir in "$WORKDIR"/sim[0-9]*; do
    [[ -d "$sim_dir/bin" ]] || continue
    sim_name="$(basename "$sim_dir")"
    [[ "$sim_name" =~ ^sim[0-9]+$ ]] || continue
    sim_names+=("$sim_name")
  done
  shopt -u nullglob

  if [[ ${#sim_names[@]} -eq 0 ]]; then
    return 0
  fi

  printf '%s\n' "${sim_names[@]}" | sort -V
}

start_grid() {
  local sim_name
  local sim_count=0

  log INFO "$(msgf STARTSTOP_GRID_STARTING "$WORKDIR")"

  [[ -d "$WORKDIR/robust/bin" ]] || die "$(msgf STARTSTOP_ROBUST_DIR_MISSING "$WORKDIR/robust/bin")"
  require_ini "$WORKDIR/robust/bin" "Robust.ini" "RobustServer"
  screen_start "robustserver" "$WORKDIR/robust/bin" "Robust.dll" || die "$(msg STARTSTOP_ROBUST_START_FAILED)"
  sleep "$ROBUSTSERVER_START_WAIT"

  [[ -f "$WORKDIR/robust/bin/MoneyServer.dll" ]] || die "$(msgf STARTSTOP_MONEY_DLL_MISSING "$WORKDIR/robust/bin/MoneyServer.dll")"
  [[ -f "$WORKDIR/robust/bin/MoneyServer.ini" ]] || die "$(msgf STARTSTOP_MONEY_INI_MISSING "$WORKDIR/robust/bin/MoneyServer.ini")"
  screen_start "moneyserver" "$WORKDIR/robust/bin" "MoneyServer.dll" || die "$(msg STARTSTOP_MONEY_START_FAILED)"
  sleep "$MONEYSERVER_START_WAIT"

  while IFS= read -r sim_name; do
    [[ -n "$sim_name" ]] || continue
    require_ini "$WORKDIR/$sim_name/bin" "OpenSim.ini" "$sim_name"
    screen_start "$sim_name" "$WORKDIR/$sim_name/bin" "OpenSim.dll" || die "$(msgf STARTSTOP_SIM_START_FAILED "$sim_name")"
    sleep "$SIMULATOR_START_WAIT"
    ((sim_count+=1))
  done < <(list_sim_names_asc)

  [[ "$sim_count" -gt 0 ]] || die "$(msgf STARTSTOP_NO_SIM_FOUND "$WORKDIR")"
}

stop_grid() {
  local sim_names=()
  local idx

  log INFO "$(msg STARTSTOP_GRID_STOPPING)"

  mapfile -t sim_names < <(list_sim_names_asc)
  for ((idx=${#sim_names[@]}-1; idx>=0; idx--)); do
    stop_screen_session "${sim_names[$idx]}" "$SIMULATOR_STOP_WAIT" || true
  done

  stop_screen_session "moneyserver" "$MONEYSERVER_STOP_WAIT" || true
  stop_screen_session "robustserver" "$ROBUSTSERVER_STOP_WAIT" || true
}

logclean_grid() {
  log INFO "$(msg STARTSTOP_LOGCLEAN_BEGIN)"

  if [[ -d "$WORKDIR/robust/bin" ]]; then
    rm -f "$WORKDIR/robust/bin/"*.log
    log INFO "$(msgf STARTSTOP_LOGS_DELETED "$WORKDIR/robust/bin")"
  fi

  local sim_dir sim_name
  shopt -s nullglob
  for sim_dir in "$WORKDIR"/sim[0-9]*/bin; do
    sim_name="$(basename "$(dirname "$sim_dir")")"
    [[ "$sim_name" =~ ^sim[0-9]+$ ]] || continue
    rm -f "$sim_dir/"*.log
    log INFO "$(msgf STARTSTOP_LOGS_DELETED "$sim_dir")"
  done
  shopt -u nullglob

  log INFO "$(msg STARTSTOP_LOGCLEAN_DONE)"
}

restart_grid() {
  stop_grid
  sleep "$SIMULATOR_STOP_WAIT"
  logclean_grid
  sleep "$SIMULATOR_START_WAIT"
  start_grid
  log INFO "$(msg STARTSTOP_ACTIVE_SESSIONS)"
  screen -ls 2>/dev/null || log INFO "$(msg STARTSTOP_NO_SESSIONS)"
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
      [[ -n "$NAME" ]] || die "$(msg STARTSTOP_NAME_REQUIRED)"
      require_ini "$WORKDIR/${NAME}/bin" "OpenSim.ini" "$NAME"
      screen_start "$NAME" "$WORKDIR/${NAME}/bin" "OpenSim.dll"
      ;;
    *)
      die "$(msgf STARTSTOP_UNSUPPORTED_START_TARGET "$target")"
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
      [[ -n "$NAME" ]] || die "$(msg STARTSTOP_NAME_REQUIRED)"
      stop_screen_session "$NAME"
      ;;
    *) die "$(msgf STARTSTOP_UNSUPPORTED_STOP_TARGET "$target")" ;;
  esac
}

WORKDIR="$DEFAULT_WORKDIR"
TARGET=""
ACTION=""
NAME=""
PROFILE="grid-sim"
JANUS_PREFIX="${JANUS_PREFIX:-/opt/janus}"

# Wartezeiten (Sekunden) – entsprechen den bewährten Werten aus osmtool.sh
SIMULATOR_STOP_WAIT="${SIMULATOR_STOP_WAIT:-15}"
MONEYSERVER_STOP_WAIT="${MONEYSERVER_STOP_WAIT:-30}"
ROBUSTSERVER_STOP_WAIT="${ROBUSTSERVER_STOP_WAIT:-30}"
SIMULATOR_START_WAIT="${SIMULATOR_START_WAIT:-15}"
MONEYSERVER_START_WAIT="${MONEYSERVER_START_WAIT:-30}"
ROBUSTSERVER_START_WAIT="${ROBUSTSERVER_START_WAIT:-30}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workdir) WORKDIR="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --janus-prefix) JANUS_PREFIX="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --action) ACTION="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die "$(msgf ERR_UNKNOWN_OPTION "$1")" ;;
  esac
done

[[ -n "$TARGET" ]] || die "$(msg ERR_MISSING_TARGET)"
[[ -n "$ACTION" ]] || die "$(msg ERR_MISSING_ACTION)"
validate_profile "$PROFILE"
ensure_profile_action_allowed startstop "$PROFILE" "$ACTION"
ensure_profile_target_allowed "$PROFILE" "$TARGET"

if [[ "$TARGET" == "janus" && "$ACTION" != "stop" ]]; then
  ensure_janus_ready
fi

log INFO "$(msgf INFO_USING_PROFILE "$PROFILE")"

if [[ "$TARGET" == "grid" ]]; then
  case "$ACTION" in
    start) start_grid ;;
    stop) stop_grid ;;
    restart) restart_grid ;;
    *) die "$(msgf ERR_UNSUPPORTED_GRID_ACTION "$ACTION")" ;;
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
    *) die "$(msgf ERR_UNSUPPORTED_ACTION "$ACTION")" ;;
  esac
fi
