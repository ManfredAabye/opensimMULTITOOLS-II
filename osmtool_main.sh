#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOD_DIR="$BASE_DIR/modular"

# shellcheck source=/dev/null
source "$MOD_DIR/osmtool_core.sh"
init_i18n

usage() {
  cat <<'EOF'
Usage:
  osmtool_main.sh [--mode <cli|ui>] [--lang <de|en|fr|es>] [--profile <grid-sim|robust|standalone>] --module <install|startstop|cleanup|health|backup|restore|update|config|report|smoke|cron> [module-options]
  osmtool_main.sh server_install
  osmtool_main.sh <opensimstart|opensimstop|opensimrestart|healthcheck|smoketest|dailyreport|croninstall|cronlist|janusinstall|janusrestart|dbsetup>

Examples:
  osmtool_main.sh server_install
  osmtool_main.sh opensimstart
  osmtool_main.sh opensimrestart
  osmtool_main.sh croninstall
  osmtool_main.sh --module install --action prepare-ubuntu
  osmtool_main.sh --module startstop --target grid --action restart --workdir /opt
  osmtool_main.sh --module cleanup --action log-clean --workdir /opt
  osmtool_main.sh --module health --action run --workdir /opt
  osmtool_main.sh --module backup --action db-backup --db-user root --db-pass secret --db-name opensim
  osmtool_main.sh --module update --action create-rollback --workdir /opt
  osmtool_main.sh --module config --action validate-runtime --workdir /opt
  osmtool_main.sh --module report --action generate --workdir /opt
  osmtool_main.sh --module smoke --action run --profile grid-sim --workdir /opt
  osmtool_main.sh --module cron --action list
  osmtool_main.sh --mode ui
EOF
  print_usage_common
}

dispatch_module() {
  local module="$1"
  shift

  case "$module" in
    install)
      "$MOD_DIR/osmtool_install.sh" --profile "$PROFILE" "$@"
      ;;
    startstop)
      "$MOD_DIR/osmtool_startstop.sh" --profile "$PROFILE" "$@"
      ;;
    cleanup)
      "$MOD_DIR/osmtool_cleanup.sh" --profile "$PROFILE" "$@"
      ;;
    health)
      "$MOD_DIR/osmtool_health.sh" --profile "$PROFILE" "$@"
      ;;
    backup)
      "$MOD_DIR/osmtool_data.sh" --profile "$PROFILE" "$@"
      ;;
    update)
      "$MOD_DIR/osmtool_update.sh" --profile "$PROFILE" "$@"
      ;;
    config)
      "$MOD_DIR/osmtool_config.sh" --profile "$PROFILE" "$@"
      ;;
    report)
      "$MOD_DIR/osmtool_report.sh" --profile "$PROFILE" "$@"
      ;;
    smoke)
      "$MOD_DIR/osmtool_smoke.sh" --profile "$PROFILE" "$@"
      ;;
    cron)
      bash "$MOD_DIR/osmtool_cron.sh" --profile "$PROFILE" "$@"
      ;;
    restore)
      "$MOD_DIR/osmtool_restore.sh" --profile "$PROFILE" "$@"
      ;;
    *)
      die "$(msg ERR_UNKNOWN_MODULE): $module"
      ;;
  esac
}

default_target_for_profile() {
  case "$1" in
    grid-sim) echo "grid" ;;
    robust) echo "robust" ;;
    standalone) echo "standalone" ;;
  esac
}

args_have_target() {
  local prev=""
  local token
  for token in "$@"; do
    if [[ "$prev" == "--target" ]]; then
      return 0
    fi
    prev="$token"
  done
  return 1
}

ui_flow() {
  local module action target

  PROFILE="$(show_menu "$(msg APP_TITLE)" "$(msg MENU_CHOOSE_PROFILE)" \
    "grid-sim" "$(msg PROFILE_GRID_SIM)" \
    "robust" "$(msg PROFILE_ROBUST)" \
    "standalone" "$(msg PROFILE_STANDALONE)")"
  validate_profile "$PROFILE"

  module="$(show_menu "$(msg APP_TITLE)" "$(msg MENU_CHOOSE_MODULE)" \
    "install" "$(msg MENU_INSTALL)" \
    "startstop" "$(msg MENU_STARTSTOP)" \
    "cleanup" "$(msg MENU_CLEANUP)" \
    "health" "$(msg MENU_HEALTH)" \
    "backup" "$(msg MENU_BACKUP)" \
    "restore" "$(msg MENU_RESTORE)" \
    "update" "$(msg MENU_UPDATE)" \
    "config" "$(msg MENU_CONFIG)" \
    "report" "$(msg MENU_REPORT)" \
    "smoke" "$(msg MENU_SMOKE)" \
    "cron" "$(msg MENU_CRON)")"

  case "$module" in
    install)
      action="$(show_menu "$(msg MENU_INSTALL)" "$(msg MENU_CHOOSE_ACTION)" \
        "server-check" "server-check" \
        "prepare-ubuntu" "prepare-ubuntu" \
        "install-opensim-deps" "install-opensim-deps" \
        "install-dotnet8" "install-dotnet8" \
        "install-opensim" "install-opensim" \
        "configure-opensim" "configure-opensim" \
        "configure-database" "configure-database" \
        "compile-janus" "compile-janus" \
        "configure-janus" "configure-janus" \
        "install-janus" "install-janus")"
      dispatch_module install --action "$action"
      ;;
    startstop)
      if [[ "$PROFILE" == "grid-sim" ]]; then
        target="$(show_menu "$(msg MENU_STARTSTOP)" "$(msg MENU_CHOOSE_TARGET)" \
          "grid" "$(msg TARGET_GRID)" \
          "robust" "$(msg TARGET_ROBUST)" \
          "sim1" "$(msg TARGET_SIM1)" \
          "janus" "$(msg TARGET_JANUS)")"
      elif [[ "$PROFILE" == "robust" ]]; then
        target="$(show_menu "$(msg MENU_STARTSTOP)" "$(msg MENU_CHOOSE_TARGET)" \
          "robust" "$(msg TARGET_ROBUST)" \
          "janus" "$(msg TARGET_JANUS)")"
      else
        target="$(show_menu "$(msg MENU_STARTSTOP)" "$(msg MENU_CHOOSE_TARGET)" \
          "standalone" "$(msg TARGET_STANDALONE)" \
          "janus" "$(msg TARGET_JANUS)")"
      fi

      action="$(show_menu "$(msg MENU_STARTSTOP)" "$(msg MENU_CHOOSE_ACTION)" \
        "start" "$(msg ACTION_START)" \
        "stop" "$(msg ACTION_STOP)" \
        "restart" "$(msg ACTION_RESTART)")"
      dispatch_module startstop --target "$target" --action "$action"
      ;;
    cleanup)
      action="$(show_menu "$(msg MENU_CLEANUP)" "$(msg MENU_CHOOSE_ACTION)" \
        "cache-clean" "$(msg ACTION_CACHE_CLEAN)" \
        "log-clean" "$(msg ACTION_LOG_CLEAN)" \
        "tmp-clean" "$(msg ACTION_TMP_CLEAN)" \
        "reboot" "$(msg ACTION_REBOOT)")"
      dispatch_module cleanup --action "$action"
      ;;
    health)
      action="$(show_menu "$(msg MENU_HEALTH)" "$(msg MENU_CHOOSE_ACTION)" \
        "run" "$(msg ACTION_HEALTH_RUN)")"
      dispatch_module health --action "$action"
      ;;
    backup)
      action="$(show_menu "$(msg MENU_BACKUP)" "$(msg MENU_CHOOSE_ACTION)" \
        "db-backup" "$(msg ACTION_DB_BACKUP)" \
        "oar-backup" "$(msg ACTION_OAR_BACKUP)" \
        "full-backup" "$(msg ACTION_FULL_BACKUP)")"
      dispatch_module backup --action "$action"
      ;;
    restore)
      action="$(show_menu "$(msg MENU_RESTORE)" "$(msg MENU_CHOOSE_ACTION)" \
        "list-backups" "$(msg ACTION_RESTORE_LIST)" \
        "db-restore" "$(msg ACTION_RESTORE_DB)" \
        "oar-restore" "$(msg ACTION_RESTORE_OAR)" \
        "full-restore" "$(msg ACTION_RESTORE_FULL)")"
      dispatch_module restore --action "$action"
      ;;
    update)
      action="$(show_menu "$(msg MENU_UPDATE)" "$(msg MENU_CHOOSE_ACTION)" \
        "create-rollback" "$(msg ACTION_UPDATE_ROLLBACK)" \
        "list-rollbacks" "$(msg ACTION_UPDATE_LIST)" \
        "update-opensim" "$(msg ACTION_UPDATE_OPENSIM)" \
        "update-janus" "$(msg ACTION_UPDATE_JANUS)" \
        "full-update" "$(msg ACTION_UPDATE_FULL)")"
      dispatch_module update --action "$action"
      ;;
    config)
      action="$(show_menu "$(msg MENU_CONFIG)" "$(msg MENU_CHOOSE_ACTION)" \
        "validate-file" "$(msg ACTION_CONFIG_FILE)" \
        "validate-runtime" "$(msg ACTION_CONFIG_RUNTIME)")"
      dispatch_module config --action "$action"
      ;;
    report)
      action="$(show_menu "$(msg MENU_REPORT)" "$(msg MENU_CHOOSE_ACTION)" \
        "generate" "$(msg ACTION_REPORT_GENERATE)")"
      dispatch_module report --action "$action"
      ;;
    smoke)
      action="$(show_menu "$(msg MENU_SMOKE)" "$(msg MENU_CHOOSE_ACTION)" \
        "run" "$(msg ACTION_SMOKE_RUN)")"
      dispatch_module smoke --action "$action"
      ;;
    cron)
      action="$(show_menu "$(msg MENU_CRON)" "$(msg MENU_CHOOSE_ACTION)" \
        "install" "$(msg ACTION_CRON_INSTALL)" \
        "list" "$(msg ACTION_CRON_LIST)" \
        "remove" "$(msg ACTION_CRON_REMOVE)")"
      dispatch_module cron --action "$action"
      ;;
    *)
      die "$(msg ERR_UNKNOWN_UI_MODULE): $module"
      ;;
  esac
}

MODE="cli"
MODULE=""
LANG_OVERRIDE="${OSM_LANG:-de}"
PROFILE="grid-sim"

if [[ $# -eq 0 ]]; then
  MODE="ui"
  ui_flow
  exit 0
fi

if [[ "${1:-}" == "h" || "${1:-}" == "help" ]]; then
  usage
  exit 0
fi

if [[ "${1:-}" == "server_install" ]]; then
  set_language "$LANG_OVERRIDE"
  validate_profile "$PROFILE"

  log INFO "Running server_install shortcut (prepare-ubuntu -> install-opensim-deps -> install-dotnet8 -> server-check -> install-opensim -> configure-opensim)"
  dispatch_module install --action prepare-ubuntu --workdir /opt
  dispatch_module install --action install-opensim-deps --workdir /opt
  dispatch_module install --action install-dotnet8 --workdir /opt
  dispatch_module install --action server-check --workdir /opt
  dispatch_module install --action install-opensim --workdir /opt
  dispatch_module install --action configure-opensim --workdir /opt
  exit 0
fi

if [[ "${1:-}" == "opensimstart" ]]; then
  set_language "$LANG_OVERRIDE"
  validate_profile "$PROFILE"
  dispatch_module startstop --target "$(default_target_for_profile "$PROFILE")" --action start --workdir /opt
  exit 0
fi

if [[ "${1:-}" == "opensimstop" ]]; then
  set_language "$LANG_OVERRIDE"
  validate_profile "$PROFILE"
  dispatch_module startstop --target "$(default_target_for_profile "$PROFILE")" --action stop --workdir /opt
  exit 0
fi

if [[ "${1:-}" == "opensimrestart" ]]; then
  set_language "$LANG_OVERRIDE"
  validate_profile "$PROFILE"
  dispatch_module startstop --target "$(default_target_for_profile "$PROFILE")" --action restart --workdir /opt
  exit 0
fi

if [[ "${1:-}" == "healthcheck" ]]; then
  set_language "$LANG_OVERRIDE"
  validate_profile "$PROFILE"
  dispatch_module health --action run --workdir /opt
  exit 0
fi

if [[ "${1:-}" == "smoketest" ]]; then
  set_language "$LANG_OVERRIDE"
  validate_profile "$PROFILE"
  dispatch_module smoke --action run --workdir /opt
  exit 0
fi

if [[ "${1:-}" == "dailyreport" ]]; then
  set_language "$LANG_OVERRIDE"
  validate_profile "$PROFILE"
  dispatch_module report --action generate --workdir /opt
  exit 0
fi

if [[ "${1:-}" == "croninstall" ]]; then
  set_language "$LANG_OVERRIDE"
  validate_profile "$PROFILE"
  dispatch_module cron --action install --workdir /opt
  exit 0
fi

if [[ "${1:-}" == "cronlist" ]]; then
  set_language "$LANG_OVERRIDE"
  validate_profile "$PROFILE"
  dispatch_module cron --action list --workdir /opt
  exit 0
fi

if [[ "${1:-}" == "janusinstall" ]]; then
  set_language "$LANG_OVERRIDE"
  validate_profile "$PROFILE"
  dispatch_module install --action install-janus --workdir /opt
  exit 0
fi

if [[ "${1:-}" == "janusrestart" ]]; then
  set_language "$LANG_OVERRIDE"
  validate_profile "$PROFILE"
  dispatch_module startstop --target janus --action restart --workdir /opt
  exit 0
fi

if [[ "${1:-}" == "dbsetup" ]]; then
  set_language "$LANG_OVERRIDE"
  validate_profile "$PROFILE"

  DB_USER_SHORT="${OSM_DB_USER:-opensim}"
  DB_PASS_SHORT="${OSM_DB_PASS:-}"
  DB_ROOT_USER_SHORT="${OSM_DB_ROOT_USER:-root}"
  DB_ROOT_PASS_SHORT="${OSM_DB_ROOT_PASS:-}"

  [[ -n "$DB_PASS_SHORT" ]] || die "dbsetup requires OSM_DB_PASS environment variable"

  dispatch_module install --action configure-database --workdir /opt --db-user "$DB_USER_SHORT" --db-pass "$DB_PASS_SHORT" --db-root-user "$DB_ROOT_USER_SHORT" --db-root-pass "$DB_ROOT_PASS_SHORT"
  exit 0
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="$2"; shift 2 ;;
    --lang) LANG_OVERRIDE="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --module) MODULE="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) break ;;
  esac
done

set_language "$LANG_OVERRIDE"
validate_profile "$PROFILE"

if [[ "$MODE" == "ui" ]]; then
  ui_flow
  exit 0
fi

[[ -n "$MODULE" ]] || die "$(msg ERR_MISSING_MODULE)"

if [[ "$MODULE" == "startstop" ]] && ! args_have_target "$@"; then
  dispatch_module "$MODULE" --target "$(default_target_for_profile "$PROFILE")" "$@"
else
  dispatch_module "$MODULE" "$@"
fi
