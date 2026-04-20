#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/osmtool_core.sh"

usage() {
  cat <<'EOF'
Usage:
  osmtool_config.sh [--workdir <path>] --action <init-config|validate-file|validate-runtime>
    [--file <path>] [--strict <true|false>]

Examples:
  osmtool_config.sh --action init-config
  osmtool_config.sh --action validate-file --file /opt/sim1/bin/OpenSim.ini
  osmtool_config.sh --action validate-runtime --profile grid-sim --workdir /opt
EOF
  print_usage_common
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

check_runtime_file() {
  local file="$1"
  local errors_before="$VALIDATION_ERRORS"

  if [[ ! -f "$file" ]]; then
    log ERROR "Missing config file: $file"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    return 1
  fi

  validate_file "$file"
  if [[ "$VALIDATION_ERRORS" -gt "$errors_before" ]]; then
    return 1
  fi

  return 0
}

validate_ini_file() {
  local file="$1"
  local line_number=0
  local line trimmed seen_section=false

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_number=$((line_number + 1))
    trimmed="$(trim "$line")"

    [[ -z "$trimmed" ]] && continue
    case "$trimmed" in
      ';'*|'#'*) continue ;;
      '['*']')
        seen_section=true
        continue
        ;;
      *=*)
        continue
        ;;
      .include*)
        continue
        ;;
      *)
        log ERROR "Invalid INI syntax in $file:$line_number -> $line"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        ;;
    esac
  done < "$file"

  if [[ "$STRICT" == "true" && "$seen_section" == "false" ]]; then
    log ERROR "INI file has no section headers: $file"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
  fi
}

validate_json_file() {
  local file="$1"

  if command -v jq >/dev/null 2>&1; then
    if ! jq empty "$file" >/dev/null 2>&1; then
      log ERROR "Invalid JSON syntax: $file"
      VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    if ! python3 -m json.tool "$file" >/dev/null 2>&1; then
      log ERROR "Invalid JSON syntax: $file"
      VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
    return 0
  fi

  die "validate-json requires jq or python3"
}

validate_file() {
  local file="$1"

  [[ -f "$file" ]] || die "Config file not found: $file"

  case "$file" in
    *.ini|*.INI)
      log INFO "Validating INI file: $file"
      validate_ini_file "$file"
      ;;
    *.json|*.JSON)
      log INFO "Validating JSON file: $file"
      validate_json_file "$file"
      ;;
    *)
      die "Unsupported config file type: $file"
      ;;
  esac
}

validate_grid_runtime() {
  local sim_ini
  local sim_count=0

  check_runtime_file "$WORKDIR/robust/bin/Robust.ini"

  shopt -s nullglob
  for sim_ini in "$WORKDIR"/sim*/bin/OpenSim.ini; do
    sim_count=$((sim_count + 1))
    check_runtime_file "$sim_ini"
  done
  shopt -u nullglob

  if [[ "$sim_count" -eq 0 ]]; then
    log ERROR "No region runtime configs found under $WORKDIR/sim*/bin/OpenSim.ini"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
  fi
}

validate_robust_runtime() {
  check_runtime_file "$WORKDIR/robust/bin/Robust.ini"
}

validate_standalone_runtime() {
  check_runtime_file "$WORKDIR/standalone/bin/OpenSim.ini"
}

validate_runtime() {
  case "$PROFILE" in
    grid-sim) validate_grid_runtime ;;
    robust) validate_robust_runtime ;;
    standalone) validate_standalone_runtime ;;
  esac

  if [[ "$VALIDATION_ERRORS" -gt 0 ]]; then
    die "Configuration validation failed with $VALIDATION_ERRORS issue(s)"
  fi

  log INFO "Configuration validation passed"
}

WORKDIR="$DEFAULT_WORKDIR"
ACTION=""
PROFILE="grid-sim"
FILE=""
STRICT="false"
VALIDATION_ERRORS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workdir) WORKDIR="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --action) ACTION="$2"; shift 2 ;;
    --file) FILE="$2"; shift 2 ;;
    --strict) STRICT="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -n "$ACTION" ]] || die "Missing --action"
validate_profile "$PROFILE"
ensure_profile_action_allowed config "$PROFILE" "$ACTION"

if [[ "$ACTION" != "init-config" && ! -f "$OSMTOOL_CONFIG_FILE" ]]; then
  if [[ -t 0 ]]; then
    log INFO "Shared configuration not found. Starting interactive setup."
    init_shared_config_interactive
  else
    log INFO "Shared configuration not found at $OSMTOOL_CONFIG_FILE (non-interactive mode)"
  fi
fi

case "$STRICT" in
  true|false) ;;
  *) die "--strict must be true or false" ;;
esac

log INFO "Using profile: $PROFILE"

case "$ACTION" in
  init-config)
    init_shared_config_interactive
    ;;
  validate-file)
    [[ -n "$FILE" ]] || die "validate-file requires --file"
    validate_file "$FILE"
    if [[ "$VALIDATION_ERRORS" -gt 0 ]]; then
      die "Configuration validation failed with $VALIDATION_ERRORS issue(s)"
    fi
    log INFO "Configuration validation passed"
    ;;
  validate-runtime)
    validate_runtime
    ;;
  *) die "Unsupported action: $ACTION" ;;
esac