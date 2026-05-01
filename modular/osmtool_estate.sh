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
  osmtool_estate.sh [--workdir <path>] [--profile <grid-sim|robust|standalone>] --action <createmasteruser|createmasterestate|createmasterestateall|firststart>
    [--estate-wait <seconds>]

Actions:
  createmasteruser      Start robustserver if needed and create master user in robust console
  createmasterestate    Start sim1 and create master estate, then process remaining simulators
  createmasterestateall Start sim2..sim999 and process estate prompts per region
  firststart            Run createmasteruser then createmasterestate
EOF
  print_usage_common
}

screen_session_exists() {
  local screen_name="$1"
  screen -list 2>/dev/null | grep -qE "\\.${screen_name}[[:space:]]"
}

screen_start_dotnet() {
  local screen_name="$1"
  local bin_dir="$2"
  local dll_name="$3"

  if screen_session_exists "$screen_name"; then
    log INFO "Screen session already running: $screen_name"
    return 0
  fi

  (cd "$bin_dir" && screen -fa -S "$screen_name" -d -U -m dotnet "$dll_name")
  sleep 1

  if ! screen_session_exists "$screen_name"; then
    die "Failed to start screen session: $screen_name"
  fi
}

stuff_enter() {
  local screen_name="$1"
  local value="$2"
  screen -S "$screen_name" -p 0 -X eval "stuff '${value}'^M"
}

ini_get() {
  local ini_file="$1"
  local section="$2"
  local key="$3"

  awk -F ' = ' '
  /^\[/ { current_section = substr($0, 2, length($0)-2) }
  current_section == "'"$section"'" && $1 == "'"$key"'" {
    sub(/^[ \t]+/, "", $2)
    sub(/[ \t\r]+$/, "", $2)
    print $2
    exit
  }
  ' "$ini_file"
}

save_master_userdata() {
  local ini_file="$1"
  local firstname="$2"
  local lastname="$3"
  local password="$4"
  local email="$5"
  local userid="$6"

  touch "$ini_file"

  {
    printf '\n[UserData]\n'
    printf 'Vorname = %s\n' "$firstname"
    printf 'Nachname = %s\n' "$lastname"
    printf 'Passwort = %s\n' "$password"
    printf 'E-Mail = %s\n' "$email"
    printf 'UserID = %s\n' "$userid"
  } >> "$ini_file"
}

createmasteruser() {
  local robust_bin="$WORKDIR/robust/bin"
  local ini_file="$WORKDIR/UserInfo.ini"
  local first_default="${OSM_MASTER_FIRSTNAME:-Master}"
  local last_default="${OSM_MASTER_LASTNAME:-Avatar}"
  local pass_default email_default userid_default
  local firstname lastname password email userid input

  if [[ ! -f "$robust_bin/Robust.dll" ]]; then
    die "Missing robust binary: $robust_bin/Robust.dll"
  fi

  screen_start_dotnet "robustserver" "$robust_bin" "Robust.dll"
  sleep "$ROBUSTSERVER_START_WAIT"

  pass_default="$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16)"
  userid_default="$(command -v uuidgen >/dev/null 2>&1 && uuidgen || cat /proc/sys/kernel/random/uuid)"
  email_default="${first_default}@${last_default}.com"

  firstname="$first_default"
  lastname="$last_default"
  password="$pass_default"
  email="$email_default"
  userid="$userid_default"

  if [[ -t 0 ]]; then
    read -r -p "Vorname [$firstname]: " input
    firstname="${input:-$firstname}"

    read -r -p "Nachname [$lastname]: " input
    lastname="${input:-$lastname}"

    read -r -p "Passwort [$password]: " input
    password="${input:-$password}"

    read -r -p "E-Mail [$email]: " input
    email="${input:-$email}"

    read -r -p "UserID [$userid]: " input
    userid="${input:-$userid}"
  fi

  stuff_enter "robustserver" "create user"
  sleep 1
  stuff_enter "robustserver" "$firstname"
  sleep 1
  stuff_enter "robustserver" "$lastname"
  sleep 1
  stuff_enter "robustserver" "$password"
  sleep 1
  stuff_enter "robustserver" "$email"
  sleep 1
  stuff_enter "robustserver" "$userid"
  sleep 1
  stuff_enter "robustserver" "Ruth"

  save_master_userdata "$ini_file" "$firstname" "$lastname" "$password" "$email" "$userid"
  log INFO "Master user created: $firstname $lastname"
  log INFO "User data written to: $ini_file"
}

read_estate_basics() {
  local ini_file="$WORKDIR/UserInfo.ini"

  [[ -f "$ini_file" ]] || die "UserInfo.ini not found: $ini_file"

  GRIDNAME="$(ini_get "$ini_file" "ServerData" "GridName")"
  VORNAME="$(ini_get "$ini_file" "UserData" "Vorname")"
  NACHNAME="$(ini_get "$ini_file" "UserData" "Nachname")"
  ESTATE_NAME="${GRIDNAME} Estate"

  [[ -n "$GRIDNAME" ]] || die "Missing GridName in $ini_file"
  [[ -n "$VORNAME" ]] || die "Missing Vorname in $ini_file"
  [[ -n "$NACHNAME" ]] || die "Missing Nachname in $ini_file"
}

createmasterestateall() {
  local started_sims=0
  local i sim_bin regions_dir region_count r

  read_estate_basics

  log INFO "Start simulator instances and process estate prompts"

  for ((i=2; i<=999; i++)); do
    sim_bin="$WORKDIR/sim$i/bin"
    if [[ -d "$sim_bin" && -f "$sim_bin/OpenSim.dll" ]]; then
      screen_start_dotnet "sim$i" "$sim_bin" "OpenSim.dll"
      ((started_sims+=1))

      log INFO "Waiting ${ESTATE_WAIT}s for estate prompt on sim$i"
      sleep "$ESTATE_WAIT"

      regions_dir="$sim_bin/Regions"
      if [[ ! -d "$regions_dir" ]]; then
        log INFO "sim$i has no Regions directory, skipping"
        continue
      fi

      region_count=$(find "$regions_dir" -maxdepth 1 -name '*.ini' | wc -l | tr -d '[:space:]')
      if [[ -z "$region_count" || "$region_count" -lt 1 ]]; then
        log INFO "sim$i has no region ini files, skipping"
        continue
      fi

      for ((r=1; r<=region_count; r++)); do
        if [[ "$r" -eq 1 ]]; then
          # First region: Vorname -> Nachname -> Estate Name
          stuff_enter "sim$i" "$VORNAME"
          sleep 2
          stuff_enter "sim$i" "$NACHNAME"
          sleep 2
          stuff_enter "sim$i" "$ESTATE_NAME"
          sleep 2
          log INFO "sim$i region $r: owner and estate entered"
        else
          # Additional regions: user already known, accept defaults by Enter
          stuff_enter "sim$i" ""
          sleep 1
          stuff_enter "sim$i" ""
          sleep 1
          stuff_enter "sim$i" ""
          sleep 1
          log INFO "sim$i region $r: confirmed by Enter"
        fi
      done
    fi
  done

  [[ "$started_sims" -gt 0 ]] || die "No sim2..sim999 instances found to process"
  log INFO "Processed estate prompts for $started_sims simulator(s)"
}

createmasterestate() {
  local sim1_bin="$WORKDIR/sim1/bin"

  read_estate_basics

  if [[ ! -f "$sim1_bin/OpenSim.dll" ]]; then
    die "Missing sim1 binary: $sim1_bin/OpenSim.dll"
  fi

  screen_start_dotnet "sim1" "$sim1_bin" "OpenSim.dll"
  sleep "$ESTATE_WAIT"

  # sim1 expects: estate name, owner first name, owner last name
  stuff_enter "sim1" "$ESTATE_NAME"
  sleep 1
  stuff_enter "sim1" "$VORNAME"
  sleep 1
  stuff_enter "sim1" "$NACHNAME"
  sleep 1

  log INFO "Master estate created on sim1"
  createmasterestateall
}

firststart() {
  createmasteruser
  createmasterestate
}

WORKDIR="$DEFAULT_WORKDIR"
ACTION=""
PROFILE="grid-sim"
ESTATE_WAIT="${ESTATE_WAIT:-30}"

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
    --action) ACTION="$2"; shift 2 ;;
    --estate-wait) ESTATE_WAIT="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die "$(msgf ERR_UNKNOWN_OPTION "$1")" ;;
  esac
done

[[ -n "$ACTION" ]] || die "$(msg ERR_MISSING_ACTION)"
validate_profile "$PROFILE"
ensure_profile_action_allowed estate "$PROFILE" "$ACTION"

if [[ ! "$ESTATE_WAIT" =~ ^[0-9]+$ ]]; then
  die "Invalid --estate-wait value: $ESTATE_WAIT"
fi

log INFO "Using profile: $PROFILE"
log INFO "Using workdir: $WORKDIR"

case "$ACTION" in
  createmasteruser) createmasteruser ;;
  createmasterestate) createmasterestate ;;
  createmasterestateall) createmasterestateall ;;
  firststart) firststart ;;
  *) die "Unsupported action: $ACTION" ;;
esac
