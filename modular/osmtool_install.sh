#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./osmtool_core.sh
source "$SCRIPT_DIR/osmtool_core.sh"

usage() {
  cat <<'EOF'
Usage:
  osmtool_install.sh [--workdir <path>] --action <bootstrap-server|server-check|prepare-ubuntu|install-opensim-deps|install-dotnet8|install-opensim|configure-opensim|configure-database|compile-janus|configure-janus|install-janus>
    [--opensim-dir <path>] [--opensim-repo <url>] [--opensim-branch <name>] [--repo-mode <update|fresh>]
    [--tsassets-dir <path>] [--currency-dir <path>] [--data-backup-dir <path>]
    [--deploy-binaries <true|false>] [--legacy-patch-dir <path>]
    [--db-root-user <name>] [--db-root-pass <value>] [--db-user <name>] [--db-pass <value>]
    [--janus-prefix <path>] [--janus-src <path>] [--public-host <host>] [--http-port <port>]
    [--admin-port <port>] [--rtp-range <from-to>] [--enable-admin <true|false>]
    [--api-secret <value>] [--admin-secret <value>]

Actions:
  bootstrap-server Server zentral vorbereiten (Pflicht vor Build/Install)
  server-check     Validate server readiness and required dependencies
  prepare-ubuntu   Basic apt update/upgrade and base packages
  install-opensim-deps Install OpenSim runtime dependencies
  install-dotnet8  Install .NET SDK 8.0 for OpenSim build/runtime
  install-opensim  Clone/update, enrich, build and optionally deploy OpenSim
  configure-opensim Generate required runtime ini files from example templates
  configure-database Create MariaDB databases/users/grants for robust and sim* runtimes
  compile-janus    Build and install Janus Gateway
  configure-janus  Configure Janus for OpenSim usage
  install-janus    Compile + configure Janus in one run

Examples:
  osmtool_install.sh --action bootstrap-server --workdir /opt
  osmtool_install.sh --action configure-opensim --profile grid-sim --workdir /opt
  osmtool_install.sh --action configure-database --workdir /opt --db-user opensim --db-pass secret
EOF
  print_usage_common
}

has_dotnet8_sdk() {
  if ! command -v dotnet >/dev/null 2>&1; then
    return 1
  fi

  dotnet --list-sdks 2>/dev/null | awk '{print $1}' | grep -Eq '^8\.'
}

package_available_in_apt() {
  local pkg="$1"
  apt-cache show "$pkg" >/dev/null 2>&1
}

resolve_package_token() {
  local token="$1"
  local candidate
  local IFS='|'
  read -r -a candidates <<< "$token"

  for candidate in "${candidates[@]}"; do
    if dpkg -s "$candidate" >/dev/null 2>&1; then
      echo "$candidate"
      return 0
    fi
  done

  for candidate in "${candidates[@]}"; do
    if package_available_in_apt "$candidate"; then
      echo "$candidate"
      return 0
    fi
  done

  return 1
}

ensure_user_writable_dir() {
  local dir="$1"

  if mkdir -p "$dir" 2>/dev/null; then
    return 0
  fi

  sudo mkdir -p "$dir"
  sudo chown "$(id -u):$(id -g)" "$dir"
}

ensure_user_owns_path() {
  local path="$1"

  if [[ -e "$path" && ! -w "$path" ]]; then
    sudo chown -R "$(id -u):$(id -g)" "$path"
  fi
}

sync_git_repo() {
  local repo_url="$1"
  local repo_dir="$2"
  local branch="$3"
  local repo_mode="$4"
  local parent_dir
  local active_branch

  parent_dir="$(dirname "$repo_dir")"
  if [[ ! -d "$parent_dir" ]]; then
    ensure_user_writable_dir "$parent_dir"
  fi

  if [[ "$repo_mode" == "fresh" && -e "$repo_dir" ]]; then
    log INFO "Removing existing repository for fresh checkout: $repo_dir"
    rm -rf "$repo_dir" 2>/dev/null || sudo rm -rf "$repo_dir"
  fi

  if [[ -d "$repo_dir/.git" ]]; then
    ensure_user_owns_path "$repo_dir"
    log INFO "Updating repository: $repo_dir"
    git -C "$repo_dir" fetch --all --prune
    active_branch="$branch"
    if [[ -z "$active_branch" ]]; then
      active_branch="$(git -C "$repo_dir" branch --show-current)"
    fi
    if [[ -z "$active_branch" ]]; then
      active_branch="$(git -C "$repo_dir" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')"
    fi
    if [[ -n "$active_branch" ]]; then
      git -C "$repo_dir" checkout "$active_branch"
      git -C "$repo_dir" pull --ff-only origin "$active_branch"
    else
      git -C "$repo_dir" pull --ff-only
    fi
    return 0
  fi

  if [[ -d "$repo_dir" && -z "$(ls -A "$repo_dir" 2>/dev/null)" ]]; then
    rmdir "$repo_dir" 2>/dev/null || sudo rmdir "$repo_dir"
  fi

  if [[ -e "$repo_dir" ]]; then
    die "Path exists but is not a git repository: $repo_dir"
  fi

  if [[ ! -w "$parent_dir" ]]; then
    sudo mkdir -p "$repo_dir"
    sudo chown "$(id -u):$(id -g)" "$repo_dir"
  fi

  log INFO "Cloning repository $repo_url -> $repo_dir"
  if [[ -n "$branch" ]]; then
    git clone --branch "$branch" --single-branch "$repo_url" "$repo_dir"
  else
    git clone "$repo_url" "$repo_dir"
  fi
}

sync_support_repo() {
  local repo_name="$1"
  local repo_url="$2"
  local repo_dir="$3"

  log INFO "Preparing support repository: $repo_name"
  sync_git_repo "$repo_url" "$repo_dir" "" "$REPO_MODE"
}

copy_tree_contents() {
  local src_dir="$1"
  local dst_dir="$2"
  local label="$3"

  if [[ ! -d "$src_dir" ]]; then
    log INFO "Skipping missing source for $label: $src_dir"
    return 0
  fi

  mkdir -p "$dst_dir"
  # Exclude .git to avoid permission issues on repeated runs
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude='.git' "$src_dir/" "$dst_dir/"
  else
    find "$src_dir" -maxdepth 1 -mindepth 1 ! -name '.git' \
      -exec cp -a {} "$dst_dir/" \;
  fi
  log INFO "Copied $label: $src_dir -> $dst_dir"
}

apply_legacy_patches() {
  local patch_dir="$1"
  local patch_file

  [[ -n "$patch_dir" ]] || return 0

  if [[ ! -d "$patch_dir" ]]; then
    die "Legacy patch directory not found: $patch_dir"
  fi

  shopt -s nullglob
  local patches=("$patch_dir"/*.patch)
  shopt -u nullglob

  if [[ ${#patches[@]} -eq 0 ]]; then
    log INFO "No legacy patches found in $patch_dir"
    return 0
  fi

  for patch_file in "${patches[@]}"; do
    if git -C "$OPENSIM_DIR" apply --reverse --check "$patch_file" >/dev/null 2>&1; then
      log INFO "Legacy patch already applied: $(basename "$patch_file")"
      continue
    fi

    log INFO "Applying legacy patch: $(basename "$patch_file")"
    if ! git -C "$OPENSIM_DIR" apply "$patch_file"; then
      git -C "$OPENSIM_DIR" apply --ignore-space-change --ignore-whitespace "$patch_file" \
        || die "Failed to apply legacy patch: $patch_file"
    fi
  done
}

deploy_opensim_binaries() {
  local src_bin="$OPENSIM_DIR/bin"
  local deployed=0
  local sim_dir

  [[ -d "$src_bin" ]] || die "OpenSim build output missing: $src_bin"

  if [[ -d "$WORKDIR/robust/bin" ]]; then
    copy_tree_contents "$src_bin" "$WORKDIR/robust/bin" "robust binaries"
    deployed=1
  fi

  if [[ -d "$WORKDIR/standalone/bin" ]]; then
    copy_tree_contents "$src_bin" "$WORKDIR/standalone/bin" "standalone binaries"
    deployed=1
  fi

  shopt -s nullglob
  for sim_dir in "$WORKDIR"/sim*; do
    if [[ -d "$sim_dir/bin" ]]; then
      copy_tree_contents "$src_bin" "$sim_dir/bin" "region binaries"
      deployed=1
    fi
  done
  shopt -u nullglob

  if [[ "$deployed" -eq 0 ]]; then
    log INFO "No target runtime directories found for binary deployment under $WORKDIR"
  else
    log INFO "OpenSim binaries deployed to available runtime directories"
  fi
}

install_dotnet8() {
  need_cmd apt-get
  need_cmd sudo
  need_cmd wget

  if has_dotnet8_sdk; then
    log INFO "dotnet SDK 8.x already installed"
    return 0
  fi

  log INFO "Installing .NET SDK 8.0"
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates gnupg

  if ! apt-cache policy dotnet-sdk-8.0 | grep -q "Candidate:"; then
    local version_id pkg_url pkg_file
    version_id="$(. /etc/os-release && echo "${VERSION_ID}")"
    pkg_url="https://packages.microsoft.com/config/ubuntu/${version_id}/packages-microsoft-prod.deb"
    pkg_file="/tmp/packages-microsoft-prod.deb"

    log INFO "Adding Microsoft package repository for Ubuntu ${version_id}"
    wget -q -O "$pkg_file" "$pkg_url"
    sudo dpkg -i "$pkg_file"
    rm -f "$pkg_file"
    sudo apt-get update
  fi

  sudo apt-get install -y dotnet-sdk-8.0

  if has_dotnet8_sdk; then
    log INFO "dotnet SDK 8.x installed successfully"
    return 0
  fi

  die "dotnet SDK 8.x installation failed"
}

install_opensim_deps() {
  local tokens=(
    git zip screen libgdiplus zlib1g libunwind8 libgssapi-krb5-2 libstdc++6
    "mariadb-client|default-mysql-client|mysql-client"
    "mariadb-server|mysql-server"
    "libgcc-s1|libgcc1"
    "libssl3|libssl1.1"
    "libicu74|libicu72|libicu71|libicu70|libicu67"
    "liblttng-ust1|liblttng-ust0"
  )
  local to_install=()
  local token resolved

  need_cmd apt-get
  need_cmd sudo

  for token in "${tokens[@]}"; do
    if resolve_package_token "$token" >/dev/null 2>&1; then
      resolved="$(resolve_package_token "$token")"
      if ! dpkg -s "$resolved" >/dev/null 2>&1; then
        to_install+=("$resolved")
      fi
    else
      die "No installable package found for token: $token"
    fi
  done

  if [[ ${#to_install[@]} -eq 0 ]]; then
    log INFO "OpenSim runtime dependencies already installed"
    return 0
  fi

  log INFO "Installing OpenSim dependencies: ${to_install[*]}"
  sudo apt-get update
  sudo apt-get install -y "${to_install[@]}"
}

ensure_mariadb_service() {
  need_cmd sudo

  if ! command -v mariadb >/dev/null 2>&1; then
    die "MariaDB client not found after dependency install"
  fi

  if command -v systemctl >/dev/null 2>&1; then
    if systemctl list-unit-files 2>/dev/null | grep -q '^mariadb\.service'; then
      log INFO "Ensuring mariadb.service is enabled and running"
      sudo systemctl enable --now mariadb
      if ! systemctl is-active --quiet mariadb; then
        die "MariaDB service could not be started"
      fi
      return 0
    fi
  fi

  if command -v service >/dev/null 2>&1; then
    if service --status-all 2>/dev/null | grep -q mariadb; then
      log INFO "Ensuring MariaDB service is running"
      sudo service mariadb start
      return 0
    fi
  fi

  log INFO "No controllable MariaDB service unit detected; skipping service activation"
}

bootstrap_server() {
  log INFO "Starting central server bootstrap"
  prepare_ubuntu
  install_opensim_deps
  install_dotnet8
  ensure_mariadb_service
  server_check
  mark_server_prepared
  log INFO "Central server bootstrap completed"
}

copy_ini_if_missing() {
  local bin_dir="$1"
  local src_name="$2"
  local dst_name="$3"
  local src dst

  src="$bin_dir/$src_name"
  dst="$bin_dir/$dst_name"

  [[ -d "$bin_dir" ]] || return 0

  if [[ -f "$dst" ]]; then
    log INFO "Keeping existing config: $dst"
    return 0
  fi

  if [[ -f "$src" ]]; then
    cp -a "$src" "$dst"
    log INFO "Created config from template: $dst"
  else
    log INFO "Template not found, skipping: $src"
  fi
}

copy_example_if_missing() {
  local bin_dir="$1"
  local base_name="$2"
  copy_ini_if_missing "$bin_dir" "${base_name}.example" "$base_name"
}

set_ini_key_value() {
  local file="$1"
  local key="$2"
  local value="$3"
  local escaped

  [[ -f "$file" ]] || return 0
  escaped="${value//\\/\\\\}"
  escaped="${escaped//&/\\&}"
  sed -i -E "s|^([[:space:]]*${key}[[:space:]]*=[[:space:]]*).*$|\\1\"${escaped}\"|" "$file"
}

set_architecture_include() {
  local file="$1"
  local include_value="$2"

  [[ -f "$file" ]] || return 0

  if grep -qE '^[[:space:]]*Include-Architecture[[:space:]]*=' "$file"; then
    sed -i -E "s|^([[:space:]]*Include-Architecture[[:space:]]*=[[:space:]]*).*$|\\1\"${include_value}\"|" "$file"
  else
    {
      echo ""
      echo "[Architecture]"
      echo "Include-Architecture = \"${include_value}\""
    } >> "$file"
  fi
}

read_userinfo_credential() {
  local file="$1"
  local key="$2"

  [[ -f "$file" ]] || return 1
  awk -F '=' -v key="$key" '
    $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
      sub(/^[[:space:]]+/, "", $2)
      sub(/[[:space:]]+$/, "", $2)
      print $2
      exit
    }
  ' "$file"
}

configure_opensim_runtime() {
  local sim_dir cfg_user cfg_pass userinfo_file sim_arch

  log INFO "Configuring OpenSim runtime ini files"

  copy_ini_if_missing "$WORKDIR/robust/bin" "Robust.HG.ini.example" "Robust.ini"
  copy_ini_if_missing "$WORKDIR/robust/bin" "Robust.ini.example" "Robust.ini"
  copy_ini_if_missing "$WORKDIR/robust/bin" "MoneyServer.ini.example" "MoneyServer.ini"
  copy_example_if_missing "$WORKDIR/robust/bin/config-include" "GridCommon.ini"
  copy_example_if_missing "$WORKDIR/robust/bin/config-include" "osslEnable.ini"

  copy_ini_if_missing "$WORKDIR/standalone/bin" "OpenSim.ini.example" "OpenSim.ini"
  copy_example_if_missing "$WORKDIR/standalone/bin/config-include" "StandaloneCommon.ini"
  copy_example_if_missing "$WORKDIR/standalone/bin/config-include" "osslEnable.ini"

  sim_arch="config-include/Grid.ini"
  if [[ "$PROFILE" == "standalone" ]]; then
    sim_arch="config-include/Standalone.ini"
  fi

  shopt -s nullglob
  for sim_dir in "$WORKDIR"/sim*/bin; do
    copy_ini_if_missing "$sim_dir" "OpenSim.ini.example" "OpenSim.ini"
    copy_example_if_missing "$sim_dir/config-include" "GridCommon.ini"
    copy_example_if_missing "$sim_dir/config-include" "osslEnable.ini"
    set_architecture_include "$sim_dir/OpenSim.ini" "$sim_arch"
  done
  shopt -u nullglob

  cfg_user="$DB_USER"
  cfg_pass="$DB_PASS"
  userinfo_file="$WORKDIR/UserInfo.ini"

  if [[ -z "$cfg_user" ]]; then
    cfg_user="$(read_userinfo_credential "$userinfo_file" "DB_Benutzername" || true)"
  fi
  if [[ -z "$cfg_pass" ]]; then
    cfg_pass="$(read_userinfo_credential "$userinfo_file" "DB_Passwort" || true)"
  fi

  if [[ -n "$cfg_user" && -n "$cfg_pass" ]]; then
    set_ini_key_value "$WORKDIR/robust/bin/MoneyServer.ini" "username" "$cfg_user"
    set_ini_key_value "$WORKDIR/robust/bin/MoneyServer.ini" "password" "$cfg_pass"
    log INFO "Updated MoneyServer.ini database credentials from configured values"
  else
    log INFO "MoneyServer.ini credentials unchanged (no DB credentials available in parameters/UserInfo.ini)"
  fi

  log INFO "OpenSim runtime ini configuration completed"
}

sql_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\'/\'\'}"
  printf '%s' "$s"
}

run_mariadb_sql() {
  local sql="$1"

  if [[ -n "$DB_ROOT_PASS" ]]; then
    mariadb -u"$DB_ROOT_USER" -p"$DB_ROOT_PASS" -e "$sql"
  else
    mariadb -u"$DB_ROOT_USER" -e "$sql"
  fi
}

discover_sim_databases() {
  local sim_bin sim_name
  local sim_dbs=()

  shopt -s nullglob
  for sim_bin in "$WORKDIR"/sim*/bin; do
    sim_name="$(basename "$(dirname "$sim_bin")")"
    sim_dbs+=("$sim_name")
  done
  shopt -u nullglob

  printf '%s\n' "${sim_dbs[@]}"
}

write_db_credentials_file() {
  local file="$WORKDIR/UserInfo.ini"

  mkdir -p "$WORKDIR" 2>/dev/null || sudo mkdir -p "$WORKDIR"
  if [[ ! -f "$file" ]]; then
    : > "$file" 2>/dev/null || sudo touch "$file"
  fi

  {
    echo "[DatabaseData]"
    echo "DB_Benutzername = $DB_USER"
    echo "DB_Passwort = $DB_PASS"
  } | sudo tee "$file" >/dev/null

  log INFO "Database credentials written: $file"
}

configure_database() {
  local escaped_user escaped_pass db_name
  local db_ident
  local sim_db_list

  need_cmd mariadb
  need_cmd sudo
  ensure_mariadb_service

  [[ -n "$DB_USER" ]] || die "--db-user is required for configure-database"
  [[ -n "$DB_PASS" ]] || die "--db-pass is required for configure-database"

  escaped_user="$(sql_escape "$DB_USER")"
  escaped_pass="$(sql_escape "$DB_PASS")"

  if ! run_mariadb_sql "SELECT 1" >/dev/null 2>&1; then
    die "Cannot connect to MariaDB as '$DB_ROOT_USER'. Check --db-root-user/--db-root-pass and server state."
  fi

  log INFO "Configuring MariaDB databases and grants"

  if [[ -d "$WORKDIR/robust" ]]; then
    run_mariadb_sql "CREATE DATABASE IF NOT EXISTS robust CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    log INFO "Ensured database: robust"
  fi

  sim_db_list="$(discover_sim_databases)"
  if [[ -n "$sim_db_list" ]]; then
    while IFS= read -r db_name; do
      [[ -n "$db_name" ]] || continue
      db_ident="\`$db_name\`"
      run_mariadb_sql "CREATE DATABASE IF NOT EXISTS $db_ident CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
      log INFO "Ensured database: $db_name"
    done <<< "$sim_db_list"
  fi

  run_mariadb_sql "CREATE USER IF NOT EXISTS '$escaped_user'@'localhost' IDENTIFIED BY '$escaped_pass';"
  run_mariadb_sql "ALTER USER '$escaped_user'@'localhost' IDENTIFIED BY '$escaped_pass';"

  if [[ -d "$WORKDIR/robust" ]]; then
    run_mariadb_sql "GRANT ALL PRIVILEGES ON robust.* TO '$escaped_user'@'localhost';"
  fi

  if [[ -n "$sim_db_list" ]]; then
    while IFS= read -r db_name; do
      [[ -n "$db_name" ]] || continue
      db_ident="\`$db_name\`"
      run_mariadb_sql "GRANT ALL PRIVILEGES ON $db_ident.* TO '$escaped_user'@'localhost';"
    done <<< "$sim_db_list"
  fi

  run_mariadb_sql "FLUSH PRIVILEGES;"

  write_db_credentials_file
  log INFO "MariaDB database setup completed"
}

server_check() {
  local fail=0
  local os_id=""
  local free_kb="0"
  local missing_pkgs=()
  local required_janus_pkgs=(
    build-essential cmake git pkg-config automake libtool gengetopt
    libmicrohttpd-dev libjansson-dev libssl-dev libsofia-sip-ua-dev libglib2.0-dev
    libopus-dev libogg-dev libcurl4-openssl-dev liblua5.3-dev libconfig-dev
    libwebsockets-dev libsrtp2-dev libnice-dev libsqlite3-dev
  )
  local required_opensim_tokens=(
    git zip screen libgdiplus zlib1g libunwind8 libgssapi-krb5-2 libstdc++6
    "mariadb-client|default-mysql-client|mysql-client"
    "mariadb-server|mysql-server"
    "libgcc-s1|libgcc1"
    "libssl3|libssl1.1"
    "libicu74|libicu72|libicu71|libicu70|libicu67"
    "liblttng-ust1|liblttng-ust0"
  )
  local pkg token

  log INFO "Running server readiness check"

  if [[ -f /etc/os-release ]]; then
    # shellcheck disable=SC1091
    source /etc/os-release
    os_id="${ID:-unknown}"
    log INFO "Detected OS: ${PRETTY_NAME:-unknown}"
  fi

  if [[ "$os_id" != "ubuntu" && "$os_id" != "debian" ]]; then
    log ERROR "Unsupported OS for this automation: $os_id"
    fail=1
  fi

  if command -v sudo >/dev/null 2>&1; then
    if sudo -n true >/dev/null 2>&1; then
      log INFO "sudo non-interactive check: OK"
    else
      log INFO "sudo available but password will be required"
    fi
  else
    log ERROR "sudo not found"
    fail=1
  fi

  if command -v apt-get >/dev/null 2>&1; then
    log INFO "apt-get available"
  else
    log ERROR "apt-get missing"
    fail=1
  fi

  if command -v curl >/dev/null 2>&1; then
    if curl -Is https://github.com >/dev/null 2>&1; then
      log INFO "Network check to github.com: OK"
    else
      log ERROR "Network check to github.com failed"
      fail=1
    fi
  else
    log ERROR "curl missing"
    fail=1
  fi

  free_kb="$(df -Pk /opt | awk 'NR==2 {print $4}')"
  if [[ -n "$free_kb" && "$free_kb" -gt 2097152 ]]; then
    log INFO "Disk space in /opt is sufficient"
  else
    log ERROR "Low disk space in /opt (need at least 2GB free)"
    fail=1
  fi

  for pkg in "${required_janus_pkgs[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      missing_pkgs+=("$pkg")
    fi
  done

  for token in "${required_opensim_tokens[@]}"; do
    if ! resolve_package_token "$token" >/dev/null 2>&1; then
      missing_pkgs+=("$token")
    fi
  done

  if [[ ${#missing_pkgs[@]} -eq 0 ]]; then
    log INFO "All required Janus/OpenSim dependency packages are installed"
  else
    log ERROR "Missing packages: ${missing_pkgs[*]}"
    log INFO "Run: sudo apt-get update && sudo apt-get install -y ${missing_pkgs[*]}"
    fail=1
  fi

  if has_dotnet8_sdk; then
    log INFO "dotnet SDK 8.x found"
  else
    log ERROR "dotnet SDK 8.x missing (required for OpenSim build/runtime)"
    fail=1
  fi

  if command -v mysqldump >/dev/null 2>&1; then
    log INFO "mysqldump found (MariaDB backup tooling ready)"
  else
    log ERROR "mysqldump missing (MariaDB client tools are required)"
    fail=1
  fi

  if [[ "$fail" -eq 0 ]]; then
    log INFO "Server readiness check PASSED"
    return 0
  fi

  die "Server readiness check FAILED"
}

upsert_key() {
  local file="$1"
  local key="$2"
  local value="$3"

  if grep -Eq "^[[:space:]]*;?[[:space:]]*${key}[[:space:]]*=" "$file"; then
    sudo sed -i -E "s|^[[:space:]]*;?[[:space:]]*(${key})[[:space:]]*=.*|\1 = $value|" "$file"
  else
    echo "$key = $value" | sudo tee -a "$file" >/dev/null
  fi
}

generate_alnum_token() {
  local length="${1:-32}"
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex "$((length / 2))" | cut -c1-"$length"
    return
  fi
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$length"
}

server_prep_marker() {
  printf '%s' "$WORKDIR/.osmtool_server_prepared"
}

mark_server_prepared() {
  local marker
  marker="$(server_prep_marker)"
  mkdir -p "$WORKDIR" 2>/dev/null || sudo mkdir -p "$WORKDIR"
  cat <<EOF | sudo tee "$marker" >/dev/null
PREPARED_AT=$(date '+%Y-%m-%d %H:%M:%S')
WORKDIR=$WORKDIR
PROFILE=$PROFILE
DOTNET_REQUIRED=8.0
EOF
  log INFO "Server bootstrap marker created: $marker"
}

ensure_server_prepared() {
  local marker
  marker="$(server_prep_marker)"
  [[ -f "$marker" ]] || die "Server preinstallation missing. Run install action bootstrap-server first."
}

compile_janus() {
  need_cmd apt-get
  need_cmd git

  log INFO "Installing Janus build dependencies"
  sudo apt-get update
  sudo apt-get install -y \
    build-essential cmake git pkg-config automake libtool gengetopt \
    libmicrohttpd-dev libjansson-dev libssl-dev libsofia-sip-ua-dev libglib2.0-dev \
    libopus-dev libogg-dev libcurl4-openssl-dev liblua5.3-dev libconfig-dev \
    libwebsockets-dev libsrtp2-dev libnice-dev libsqlite3-dev

  if [[ -d "$JANUS_SRC/.git" ]]; then
    log INFO "Updating existing Janus source at $JANUS_SRC"
    git -C "$JANUS_SRC" pull --ff-only
  else
    if [[ -e "$JANUS_SRC" ]]; then
      die "Janus source path exists but is not a git repository: $JANUS_SRC"
    fi
    log INFO "Cloning Janus source to $JANUS_SRC"
    git clone https://github.com/meetecho/janus-gateway.git "$JANUS_SRC"
  fi

  log INFO "Building Janus"
  (
    cd "$JANUS_SRC"
    sh autogen.sh
    ./configure --prefix="$JANUS_PREFIX"
    make -j"$(nproc)"
    sudo make install
    sudo make configs
  )

  log INFO "Janus compiled and installed to $JANUS_PREFIX"
}

configure_janus() {
  local conf_dir core_cfg http_cfg api_secret admin_secret
  conf_dir="$JANUS_PREFIX/etc/janus"

  [[ -d "$conf_dir" ]] || die "Janus config dir not found: $conf_dir"

  core_cfg="$conf_dir/janus.jcfg"
  [[ -f "$core_cfg" ]] || core_cfg="$conf_dir/janus.cfg"

  http_cfg="$conf_dir/janus.transport.http.jcfg"
  [[ -f "$http_cfg" ]] || http_cfg="$conf_dir/janus.transport.http.cfg"

  [[ -f "$core_cfg" ]] || die "Missing janus core config in $conf_dir"
  [[ -f "$http_cfg" ]] || die "Missing janus HTTP transport config in $conf_dir"

  api_secret="$API_SECRET"
  [[ -n "$api_secret" ]] || api_secret="$(generate_alnum_token 32)"

  admin_secret="$ADMIN_SECRET"
  [[ -n "$admin_secret" ]] || admin_secret="$(generate_alnum_token 32)"

  sudo cp "$core_cfg" "$core_cfg.bak-$(date +%Y%m%d-%H%M%S)"
  sudo cp "$http_cfg" "$http_cfg.bak-$(date +%Y%m%d-%H%M%S)"

  upsert_key "$core_cfg" "rtp_port_range" "\"$RTP_RANGE\""
  upsert_key "$http_cfg" "http" "true"
  upsert_key "$http_cfg" "port" "$HTTP_PORT"
  upsert_key "$http_cfg" "api_secret" "\"$api_secret\""

  if [[ "$ENABLE_ADMIN" == "true" ]]; then
    upsert_key "$http_cfg" "admin_http" "true"
    upsert_key "$http_cfg" "admin_port" "$ADMIN_PORT"
    upsert_key "$http_cfg" "admin_secret" "\"$admin_secret\""
  else
    upsert_key "$http_cfg" "admin_http" "false"
  fi

  local snippet_file
  snippet_file="$WORKDIR/opensim-janus-config.generated.ini"

  mkdir -p "$WORKDIR" 2>/dev/null || sudo mkdir -p "$WORKDIR"
  cat <<EOF | sudo tee "$snippet_file" >/dev/null
[JanusWebRtcVoice]
  JanusGatewayURI = http://$PUBLIC_HOST:$HTTP_PORT/janus
  APIToken = $api_secret
EOF

  if [[ "$ENABLE_ADMIN" == "true" ]]; then
    cat <<EOF | sudo tee -a "$snippet_file" >/dev/null
  JanusGatewayAdminURI = http://$PUBLIC_HOST:$ADMIN_PORT/admin
  AdminAPIToken = $admin_secret
EOF
  fi

  cat <<'EOF' | sudo tee -a "$snippet_file" >/dev/null
  MessageDetails = false
EOF

  cat <<EOF | sudo tee "$JANUS_PREFIX/.osmtool_janus_ready" >/dev/null
JANUS_PREFIX=$JANUS_PREFIX
HTTP_PORT=$HTTP_PORT
ADMIN_PORT=$ADMIN_PORT
ENABLE_ADMIN=$ENABLE_ADMIN
RTP_RANGE=$RTP_RANGE
PUBLIC_HOST=$PUBLIC_HOST
EOF

  log INFO "Janus configured. Marker created: $JANUS_PREFIX/.osmtool_janus_ready"
}

prepare_ubuntu() {
  need_cmd apt-get
  log INFO "Preparing Ubuntu server"
  sudo apt-get update
  sudo apt-get -y upgrade
  sudo apt-get -y install curl git screen unzip jq wget
  log INFO "Ubuntu base packages installed"
}

install_opensim() {
  need_cmd git
  need_cmd dotnet
  need_cmd bash

  log INFO "Starting OpenSim install/build flow"
  log INFO "OpenSim repository: $OPENSIM_REPO"
  log INFO "OpenSim branch: $OPENSIM_BRANCH"
  log INFO "OpenSim directory: $OPENSIM_DIR"

  sync_git_repo "$OPENSIM_REPO" "$OPENSIM_DIR" "$OPENSIM_BRANCH" "$REPO_MODE"
  ensure_user_owns_path "$OPENSIM_DIR"

  if [[ -n "$LEGACY_PATCH_DIR" ]]; then
    apply_legacy_patches "$LEGACY_PATCH_DIR"
  fi

  sync_support_repo "opensim-tsassets" "$TSASSETS_REPO" "$TSASSETS_DIR"
  sync_support_repo "opensimcurrencyserver" "$CURRENCY_REPO" "$CURRENCY_DIR"
  sync_support_repo "os-data-backup" "$DATA_BACKUP_REPO" "$DATA_BACKUP_DIR"

  copy_tree_contents "$TSASSETS_DIR/bin" "$OPENSIM_DIR/bin" "tsassets bin content"
  copy_tree_contents "$TSASSETS_DIR/OpenSim" "$OPENSIM_DIR/OpenSim" "tsassets OpenSim content"
  copy_tree_contents "$CURRENCY_DIR/addon-modules" "$OPENSIM_DIR/addon-modules" "currency addon modules"
  copy_tree_contents "$CURRENCY_DIR/bin" "$OPENSIM_DIR/bin" "currency bin content"
  copy_tree_contents "$DATA_BACKUP_DIR" "$OPENSIM_DIR/addon-modules/os-data-backup" "os-data-backup content"

  log INFO "Running OpenSim prebuild"
  (
    cd "$OPENSIM_DIR"
    bash runprebuild.sh
    dotnet build --configuration Release OpenSim.sln
  )

  [[ -f "$OPENSIM_DIR/bin/OpenSim.dll" ]] || die "OpenSim build output missing: $OPENSIM_DIR/bin/OpenSim.dll"
  [[ -f "$OPENSIM_DIR/bin/Robust.dll" ]] || die "OpenSim build output missing: $OPENSIM_DIR/bin/Robust.dll"

  if [[ "$DEPLOY_BINARIES" == "true" ]]; then
    deploy_opensim_binaries
    configure_opensim_runtime
  else
    log INFO "Binary deployment skipped by configuration"
  fi

  log INFO "OpenSim install/build flow completed"
}

install_janus() {
  compile_janus
  configure_janus
}

WORKDIR="$DEFAULT_WORKDIR"
ACTION=""
PROFILE="grid-sim"
REPO_MODE="${REPO_MODE:-update}"
OPENSIM_REPO="${OPENSIM_REPO:-https://github.com/opensim/opensim.git}"
OPENSIM_BRANCH="${OPENSIM_BRANCH:-master}"
OPENSIM_DIR="${OPENSIM_DIR:-$WORKDIR/opensim}"
TSASSETS_REPO="${TSASSETS_REPO:-https://github.com/ManfredAabye/opensim-tsassets.git}"
TSASSETS_DIR="${TSASSETS_DIR:-$WORKDIR/opensim-tsassets}"
CURRENCY_REPO="${CURRENCY_REPO:-https://github.com/ManfredAabye/opensimcurrencyserver-dotnet.git}"
CURRENCY_DIR="${CURRENCY_DIR:-$WORKDIR/opensimcurrencyserver}"
DATA_BACKUP_REPO="${DATA_BACKUP_REPO:-https://github.com/ManfredAabye/os-data-backup.git}"
DATA_BACKUP_DIR="${DATA_BACKUP_DIR:-$WORKDIR/os-data-backup}"
DEPLOY_BINARIES="${DEPLOY_BINARIES:-true}"
LEGACY_PATCH_DIR="${LEGACY_PATCH_DIR:-}"
DB_ROOT_USER="${DB_ROOT_USER:-root}"
DB_ROOT_PASS="${DB_ROOT_PASS:-}"
DB_USER="${DB_USER:-opensimuser}"
DB_PASS="${DB_PASS:-}"
JANUS_PREFIX="${JANUS_PREFIX:-/opt/janus}"
JANUS_SRC="${JANUS_SRC:-$WORKDIR/janus-gateway}"
PUBLIC_HOST="${PUBLIC_HOST:-127.0.0.1}"
HTTP_PORT="${HTTP_PORT:-8088}"
ADMIN_PORT="${ADMIN_PORT:-7088}"
RTP_RANGE="${RTP_RANGE:-10000-10200}"
ENABLE_ADMIN="${ENABLE_ADMIN:-false}"
API_SECRET="${API_SECRET:-}"
ADMIN_SECRET="${ADMIN_SECRET:-}"

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
    --db-root-user) DB_ROOT_USER="$2"; shift 2 ;;
    --db-root-pass) DB_ROOT_PASS="$2"; shift 2 ;;
    --db-user) DB_USER="$2"; shift 2 ;;
    --db-pass) DB_PASS="$2"; shift 2 ;;
    --janus-prefix) JANUS_PREFIX="$2"; shift 2 ;;
    --janus-src) JANUS_SRC="$2"; shift 2 ;;
    --public-host) PUBLIC_HOST="$2"; shift 2 ;;
    --http-port) HTTP_PORT="$2"; shift 2 ;;
    --admin-port) ADMIN_PORT="$2"; shift 2 ;;
    --rtp-range) RTP_RANGE="$2"; shift 2 ;;
    --enable-admin) ENABLE_ADMIN="$2"; shift 2 ;;
    --api-secret) API_SECRET="$2"; shift 2 ;;
    --admin-secret) ADMIN_SECRET="$2"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

[[ -n "$ACTION" ]] || die "Missing --action"
validate_profile "$PROFILE"
ensure_profile_action_allowed install "$PROFILE" "$ACTION"

case "$REPO_MODE" in
  update|fresh) ;;
  *) die "Unsupported repo mode: $REPO_MODE" ;;
esac

case "$DEPLOY_BINARIES" in
  true|false) ;;
  *) die "--deploy-binaries must be true or false" ;;
esac

case "$ACTION" in
  install-opensim|configure-opensim|configure-database|compile-janus|configure-janus|install-janus)
    ensure_server_prepared
    ;;
esac

log INFO "Using workdir: $WORKDIR"
log INFO "Using profile: $PROFILE"
log INFO "Repo mode: $REPO_MODE"
log INFO "OpenSim dir: $OPENSIM_DIR"
log INFO "Janus prefix: $JANUS_PREFIX"

case "$ACTION" in
  bootstrap-server) bootstrap_server ;;
  server-check) server_check ;;
  prepare-ubuntu) prepare_ubuntu ;;
  install-opensim-deps) install_opensim_deps ;;
  install-dotnet8) install_dotnet8 ;;
  install-opensim) install_opensim ;;
  configure-opensim) configure_opensim_runtime ;;
  configure-database) configure_database ;;
  compile-janus) compile_janus ;;
  configure-janus) configure_janus ;;
  install-janus) install_janus ;;
  *) die "Unsupported action: $ACTION" ;;
esac
