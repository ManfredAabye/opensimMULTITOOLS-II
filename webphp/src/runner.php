<?php
declare(strict_types=1);

function allowed_profiles(): array
{
    return ['grid-sim', 'robust', 'standalone'];
}

function allowed_targets_by_profile(): array
{
    return [
        'grid-sim' => ['grid', 'robust', 'sim1', 'region', 'janus'],
        'robust' => ['robust', 'janus'],
        'standalone' => ['standalone', 'janus'],
    ];
}

function web_module_catalog(): array
{
    return [
        'install' => [
            'label_key' => 'module_install',
            'description_key' => 'module_install_desc',
            'actions' => [
                'server-check' => ['label_key' => 'install_server_check', 'description_key' => 'install_server_check_desc', 'fields' => []],
                'prepare-ubuntu' => ['label_key' => 'install_prepare_ubuntu', 'description_key' => 'install_prepare_ubuntu_desc', 'fields' => []],
                'install-opensim-deps' => ['label_key' => 'install_opensim_deps', 'description_key' => 'install_opensim_deps_desc', 'fields' => []],
                'install-dotnet8' => ['label_key' => 'install_dotnet8', 'description_key' => 'install_dotnet8_desc', 'fields' => []],
                'install-opensim' => ['label_key' => 'install_opensim', 'description_key' => 'install_opensim_desc', 'fields' => ['opensim_dir', 'opensim_repo', 'opensim_branch', 'repo_mode', 'tsassets_dir', 'currency_dir', 'data_backup_dir', 'deploy_binaries', 'legacy_patch_dir']],
                'configure-opensim' => ['label_key' => 'configure_opensim', 'description_key' => 'configure_opensim_desc', 'fields' => []],
                'configure-database' => ['label_key' => 'configure_database', 'description_key' => 'configure_database_desc', 'fields' => ['db_root_user', 'db_root_pass', 'db_user', 'db_pass']],
                'compile-janus' => ['label_key' => 'compile_janus', 'description_key' => 'compile_janus_desc', 'fields' => ['janus_prefix', 'janus_src']],
                'configure-janus' => ['label_key' => 'configure_janus', 'description_key' => 'configure_janus_desc', 'fields' => ['janus_prefix', 'public_host', 'http_port', 'admin_port', 'rtp_range', 'enable_admin', 'api_secret', 'admin_secret']],
                'install-janus' => ['label_key' => 'install_janus', 'description_key' => 'install_janus_desc', 'fields' => ['janus_prefix', 'janus_src', 'public_host', 'http_port', 'admin_port', 'rtp_range', 'enable_admin', 'api_secret', 'admin_secret']],
            ],
        ],
        'startstop' => [
            'label_key' => 'module_startstop',
            'description_key' => 'module_startstop_desc',
            'actions' => [
                'start' => ['label_key' => 'action_start', 'description_key' => 'start_desc', 'fields' => ['target', 'name', 'janus_prefix']],
                'stop' => ['label_key' => 'action_stop', 'description_key' => 'stop_desc', 'fields' => ['target', 'name', 'janus_prefix']],
                'restart' => ['label_key' => 'action_restart', 'description_key' => 'restart_desc', 'fields' => ['target', 'name', 'janus_prefix']],
            ],
        ],
        'cleanup' => [
            'label_key' => 'module_cleanup',
            'description_key' => 'module_cleanup_desc',
            'actions' => [
                'cache-clean' => ['label_key' => 'cleanup_cache', 'description_key' => 'cleanup_cache_desc', 'fields' => ['dry_run']],
                'log-clean' => ['label_key' => 'cleanup_logs', 'description_key' => 'cleanup_logs_desc', 'fields' => ['dry_run']],
                'tmp-clean' => ['label_key' => 'cleanup_tmp', 'description_key' => 'cleanup_tmp_desc', 'fields' => ['dry_run']],
                'reboot' => ['label_key' => 'cleanup_reboot', 'description_key' => 'cleanup_reboot_desc', 'fields' => []],
            ],
        ],
        'health' => [
            'label_key' => 'module_health',
            'description_key' => 'module_health_desc',
            'actions' => [
                'run' => ['label_key' => 'health_run', 'description_key' => 'health_run_desc', 'fields' => ['expected_screens', 'ports', 'db_user', 'db_pass', 'db_name', 'log_file', 'warning_threshold']],
            ],
        ],
        'backup' => [
            'label_key' => 'module_backup',
            'description_key' => 'module_backup_desc',
            'actions' => [
                'db-backup' => ['label_key' => 'backup_db', 'description_key' => 'backup_db_desc', 'fields' => ['db_user', 'db_pass', 'db_name', 'compress'], 'profiles' => ['grid-sim', 'robust']],
                'oar-backup' => ['label_key' => 'backup_oar', 'description_key' => 'backup_oar_desc', 'fields' => ['region', 'session'], 'profiles' => ['grid-sim', 'standalone']],
                'full-backup' => ['label_key' => 'backup_full', 'description_key' => 'backup_full_desc', 'fields' => ['db_user', 'db_pass', 'db_name', 'region', 'session', 'compress']],
            ],
        ],
        'restore' => [
            'label_key' => 'module_restore',
            'description_key' => 'module_restore_desc',
            'actions' => [
                'list-backups' => ['label_key' => 'restore_list', 'description_key' => 'restore_list_desc', 'fields' => []],
                'db-restore' => ['label_key' => 'restore_db', 'description_key' => 'restore_db_desc', 'fields' => ['file', 'db_user', 'db_pass', 'db_name', 'dry_run'], 'profiles' => ['grid-sim', 'robust']],
                'oar-restore' => ['label_key' => 'restore_oar', 'description_key' => 'restore_oar_desc', 'fields' => ['file', 'region', 'session', 'dry_run'], 'profiles' => ['grid-sim', 'standalone']],
                'full-restore' => ['label_key' => 'restore_full', 'description_key' => 'restore_full_desc', 'fields' => ['file', 'region', 'session', 'db_user', 'db_pass', 'db_name', 'dry_run']],
            ],
        ],
        'update' => [
            'label_key' => 'module_update',
            'description_key' => 'module_update_desc',
            'actions' => [
                'create-rollback' => ['label_key' => 'update_create_rollback', 'description_key' => 'update_create_rollback_desc', 'fields' => ['label', 'dry_run']],
                'list-rollbacks' => ['label_key' => 'update_list_rollbacks', 'description_key' => 'update_list_rollbacks_desc', 'fields' => []],
                'update-opensim' => ['label_key' => 'update_opensim', 'description_key' => 'update_opensim_desc', 'fields' => ['label', 'dry_run', 'opensim_dir', 'opensim_repo', 'opensim_branch', 'repo_mode', 'tsassets_dir', 'currency_dir', 'data_backup_dir', 'deploy_binaries', 'legacy_patch_dir']],
                'update-janus' => ['label_key' => 'update_janus', 'description_key' => 'update_janus_desc', 'fields' => ['label', 'dry_run', 'janus_prefix', 'janus_src', 'public_host', 'http_port', 'admin_port', 'rtp_range', 'enable_admin', 'api_secret', 'admin_secret']],
                'full-update' => ['label_key' => 'update_full', 'description_key' => 'update_full_desc', 'fields' => ['label', 'dry_run', 'opensim_dir', 'opensim_repo', 'opensim_branch', 'repo_mode', 'tsassets_dir', 'currency_dir', 'data_backup_dir', 'deploy_binaries', 'legacy_patch_dir', 'janus_prefix', 'janus_src', 'public_host', 'http_port', 'admin_port', 'rtp_range', 'enable_admin', 'api_secret', 'admin_secret']],
            ],
        ],
        'config' => [
            'label_key' => 'module_config',
            'description_key' => 'module_config_desc',
            'actions' => [
                'validate-file' => ['label_key' => 'config_validate_file', 'description_key' => 'config_validate_file_desc', 'fields' => ['file', 'strict']],
                'validate-runtime' => ['label_key' => 'config_validate_runtime', 'description_key' => 'config_validate_runtime_desc', 'fields' => ['strict']],
            ],
        ],
        'report' => [
            'label_key' => 'module_report',
            'description_key' => 'module_report_desc',
            'actions' => [
                'generate' => ['label_key' => 'report_generate', 'description_key' => 'report_generate_desc', 'fields' => ['output_file', 'expected_screens', 'ports', 'db_user', 'db_pass', 'db_name', 'log_file']],
            ],
        ],
        'smoke' => [
            'label_key' => 'module_smoke',
            'description_key' => 'module_smoke_desc',
            'actions' => [
                'run' => ['label_key' => 'smoke_run', 'description_key' => 'smoke_run_desc', 'fields' => ['target', 'name', 'expected_screens', 'wait_after_start', 'wait_after_stop', 'janus_prefix']],
            ],
        ],
        'cron' => [
            'label_key' => 'module_cron',
            'description_key' => 'module_cron_desc',
            'actions' => [
                'install' => ['label_key' => 'cron_install', 'description_key' => 'cron_install_desc', 'fields' => ['backup_schedule', 'restart_schedule', 'check_schedule', 'report_schedule', 'smoke_schedule', 'db_user', 'db_pass', 'db_name', 'region', 'session', 'compress']],
                'list' => ['label_key' => 'cron_list', 'description_key' => 'cron_list_desc', 'fields' => []],
                'remove' => ['label_key' => 'cron_remove', 'description_key' => 'cron_remove_desc', 'fields' => []],
            ],
        ],
    ];
}

function web_field_definitions(array $config): array
{
    return [
        'target' => ['flag' => '--target', 'type' => 'select', 'label_key' => 'field_target', 'target_by_profile' => allowed_targets_by_profile()],
        'name' => ['flag' => '--name', 'type' => 'text', 'label_key' => 'field_name', 'placeholder' => 'sim2'],
        'db_root_user' => ['flag' => '--db-root-user', 'type' => 'text', 'label_key' => 'field_db_root_user', 'placeholder' => 'root'],
        'db_root_pass' => ['flag' => '--db-root-pass', 'type' => 'password', 'label_key' => 'field_db_root_pass'],
        'db_user' => ['flag' => '--db-user', 'type' => 'text', 'label_key' => 'field_db_user', 'placeholder' => 'opensim'],
        'db_pass' => ['flag' => '--db-pass', 'type' => 'password', 'label_key' => 'field_db_pass'],
        'db_name' => ['flag' => '--db-name', 'type' => 'text', 'label_key' => 'field_db_name', 'placeholder' => 'opensim'],
        'region' => ['flag' => '--region', 'type' => 'text', 'label_key' => 'field_region', 'placeholder' => 'sim1'],
        'session' => ['flag' => '--session', 'type' => 'text', 'label_key' => 'field_session', 'placeholder' => 'sim1'],
        'compress' => ['flag' => '--compress', 'type' => 'select', 'label_key' => 'field_compress', 'options' => ['true', 'false'], 'default' => 'true'],
        'file' => ['flag' => '--file', 'type' => 'text', 'label_key' => 'field_file', 'placeholder' => '/opt/backup/file.sql.gz'],
        'dry_run' => ['flag' => '--dry-run', 'type' => 'select', 'label_key' => 'field_dry_run', 'options' => ['false', 'true'], 'default' => 'false'],
        'strict' => ['flag' => '--strict', 'type' => 'select', 'label_key' => 'field_strict', 'options' => ['false', 'true'], 'default' => 'false'],
        'output_file' => ['flag' => '--output', 'type' => 'text', 'label_key' => 'field_output_file', 'placeholder' => '/opt/reports/manual_report.txt'],
        'expected_screens' => ['flag' => '--expected-screens', 'type' => 'text', 'label_key' => 'field_expected_screens', 'placeholder' => 'robustserver,sim1'],
        'ports' => ['flag' => '--ports', 'type' => 'text', 'label_key' => 'field_ports', 'placeholder' => '8002,9000,9001,8088'],
        'log_file' => ['flag' => '--log-file', 'type' => 'text', 'label_key' => 'field_log_file', 'placeholder' => '/opt/robust/bin/OpenSim.log'],
        'warning_threshold' => ['flag' => '--warning-threshold', 'type' => 'text', 'label_key' => 'field_warning_threshold', 'placeholder' => '5'],
        'backup_schedule' => ['flag' => '--backup-schedule', 'type' => 'text', 'label_key' => 'field_backup_schedule', 'placeholder' => '0 3 * * *'],
        'restart_schedule' => ['flag' => '--restart-schedule', 'type' => 'text', 'label_key' => 'field_restart_schedule', 'placeholder' => '0 5 * * 1'],
        'check_schedule' => ['flag' => '--check-schedule', 'type' => 'text', 'label_key' => 'field_check_schedule', 'placeholder' => '*/15 * * * *'],
        'report_schedule' => ['flag' => '--report-schedule', 'type' => 'text', 'label_key' => 'field_report_schedule', 'placeholder' => '30 6 * * *'],
        'smoke_schedule' => ['flag' => '--smoke-schedule', 'type' => 'text', 'label_key' => 'field_smoke_schedule', 'placeholder' => '45 6 * * *'],
        'opensim_dir' => ['flag' => '--opensim-dir', 'type' => 'text', 'label_key' => 'field_opensim_dir', 'placeholder' => '/opt/opensim'],
        'opensim_repo' => ['flag' => '--opensim-repo', 'type' => 'text', 'label_key' => 'field_opensim_repo', 'placeholder' => 'https://github.com/opensim/opensim'],
        'opensim_branch' => ['flag' => '--opensim-branch', 'type' => 'text', 'label_key' => 'field_opensim_branch', 'placeholder' => 'master'],
        'repo_mode' => ['flag' => '--repo-mode', 'type' => 'select', 'label_key' => 'field_repo_mode', 'options' => ['update', 'fresh'], 'default' => 'update'],
        'tsassets_dir' => ['flag' => '--tsassets-dir', 'type' => 'text', 'label_key' => 'field_tsassets_dir', 'placeholder' => '/opt/opensim-tsassets'],
        'currency_dir' => ['flag' => '--currency-dir', 'type' => 'text', 'label_key' => 'field_currency_dir', 'placeholder' => '/opt/opensimcurrencyserver-dotnet'],
        'data_backup_dir' => ['flag' => '--data-backup-dir', 'type' => 'text', 'label_key' => 'field_data_backup_dir', 'placeholder' => '/opt/os-data-backup'],
        'deploy_binaries' => ['flag' => '--deploy-binaries', 'type' => 'select', 'label_key' => 'field_deploy_binaries', 'options' => ['true', 'false'], 'default' => 'true'],
        'legacy_patch_dir' => ['flag' => '--legacy-patch-dir', 'type' => 'text', 'label_key' => 'field_legacy_patch_dir', 'placeholder' => '/opt/patches'],
        'janus_prefix' => ['flag' => '--janus-prefix', 'type' => 'text', 'label_key' => 'field_janus_prefix', 'placeholder' => '/opt/janus'],
        'janus_src' => ['flag' => '--janus-src', 'type' => 'text', 'label_key' => 'field_janus_src', 'placeholder' => '/opt/src/janus-gateway'],
        'public_host' => ['flag' => '--public-host', 'type' => 'text', 'label_key' => 'field_public_host', 'placeholder' => '127.0.0.1'],
        'http_port' => ['flag' => '--http-port', 'type' => 'text', 'label_key' => 'field_http_port', 'placeholder' => '8088'],
        'admin_port' => ['flag' => '--admin-port', 'type' => 'text', 'label_key' => 'field_admin_port', 'placeholder' => '7088'],
        'rtp_range' => ['flag' => '--rtp-range', 'type' => 'text', 'label_key' => 'field_rtp_range', 'placeholder' => '10000-10200'],
        'enable_admin' => ['flag' => '--enable-admin', 'type' => 'select', 'label_key' => 'field_enable_admin', 'options' => ['false', 'true'], 'default' => 'false'],
        'api_secret' => ['flag' => '--api-secret', 'type' => 'password', 'label_key' => 'field_api_secret'],
        'admin_secret' => ['flag' => '--admin-secret', 'type' => 'password', 'label_key' => 'field_admin_secret'],
        'label' => ['flag' => '--label', 'type' => 'text', 'label_key' => 'field_label', 'placeholder' => 'pre_update'],
        'wait_after_start' => ['flag' => '--wait-after-start', 'type' => 'text', 'label_key' => 'field_wait_after_start', 'placeholder' => '3'],
        'wait_after_stop' => ['flag' => '--wait-after-stop', 'type' => 'text', 'label_key' => 'field_wait_after_stop', 'placeholder' => '8'],
    ];
}

function translated_catalog(string $lang, array $config): array
{
    $catalog = web_module_catalog();
    foreach ($catalog as $module => &$moduleData) {
        $moduleData['label'] = t($lang, $moduleData['label_key']);
        $moduleData['description'] = t($lang, $moduleData['description_key']);
        foreach ($moduleData['actions'] as $action => &$actionData) {
            $actionData['label'] = t($lang, $actionData['label_key']);
            $actionData['description'] = t($lang, $actionData['description_key']);
            $actionData['module'] = $module;
            $actionData['action'] = $action;
            $actionData['profiles'] = $actionData['profiles'] ?? allowed_profiles();
        }
        unset($actionData);
    }
    unset($moduleData);

    return $catalog;
}

function default_target_for_profile(string $profile): string
{
    return allowed_targets_by_profile()[$profile][0] ?? 'grid';
}

function field_value_from_request(string $field, array $source, array $definitions): string
{
    $value = $source[$field] ?? ($definitions[$field]['default'] ?? '');
    return is_string($value) ? trim($value) : '';
}

function validate_simple_value(string $field, string $value, array $definition, string $profile): string
{
    if ($value === '') {
        return '';
    }

    if (str_contains($value, "\0") || str_contains($value, "\r") || str_contains($value, "\n")) {
        throw new RuntimeException('Invalid value for field: ' . $field);
    }

    if (($definition['type'] ?? '') === 'select') {
        if ($field === 'target') {
            $allowed = $definition['target_by_profile'][$profile] ?? [];
            if (!in_array($value, $allowed, true)) {
                throw new RuntimeException('Invalid target selected.');
            }
        } elseif (!in_array($value, $definition['options'] ?? [], true)) {
            throw new RuntimeException('Invalid selected option for field: ' . $field);
        }
    }

    if (in_array($field, ['http_port', 'admin_port', 'warning_threshold', 'wait_after_start', 'wait_after_stop'], true) && !ctype_digit($value)) {
        throw new RuntimeException('Field requires a numeric value: ' . $field);
    }

    return $value;
}

function normalize_run_request(array $config, array $source, string $lang): array
{
    $catalog = web_module_catalog();
    $fields = web_field_definitions($config);

    $module = (string)($source['module'] ?? 'startstop');
    $profile = (string)($source['profile'] ?? 'grid-sim');
    $workdir = trim((string)($source['workdir'] ?? (string)($config['default_workdir'] ?? '/opt')));
    $action = (string)($source['action'] ?? 'start');

    if (!isset($catalog[$module])) {
        throw new RuntimeException('Unknown module selected.');
    }
    if (!in_array($profile, allowed_profiles(), true)) {
        throw new RuntimeException('Unknown profile selected.');
    }
    if (!isset($catalog[$module]['actions'][$action])) {
        throw new RuntimeException('Unknown action selected.');
    }
    $allowedProfiles = $catalog[$module]['actions'][$action]['profiles'] ?? allowed_profiles();
    if (!in_array($profile, $allowedProfiles, true)) {
        throw new RuntimeException('Action not allowed for selected profile.');
    }
    if ($workdir === '') {
        $workdir = (string)($config['default_workdir'] ?? '/opt');
    }
    if (!in_array($lang, supported_languages(), true)) {
        throw new RuntimeException('Unsupported language.');
    }

    $selectedFields = $catalog[$module]['actions'][$action]['fields'];
    $values = [];
    foreach ($selectedFields as $field) {
        $value = field_value_from_request($field, $source, $fields);
        $value = validate_simple_value($field, $value, $fields[$field], $profile);
        if ($value !== '') {
            $values[$field] = $value;
        }
    }

    if (in_array('target', $selectedFields, true) && !isset($values['target'])) {
        $values['target'] = default_target_for_profile($profile);
    }

    foreach (['file' => ['restore', 'config'], 'db_pass' => ['backup', 'restore', 'cron', 'health', 'report', 'install'], 'db_user' => ['backup', 'restore', 'cron', 'health', 'report', 'install'], 'db_name' => ['backup', 'restore', 'cron', 'health', 'report']] as $field => $moduleWhitelist) {
        if (in_array($module, $moduleWhitelist, true) && isset($source[$field]) && !isset($values[$field])) {
            $value = field_value_from_request($field, $source, $fields);
            if ($value !== '') {
                $values[$field] = validate_simple_value($field, $value, $fields[$field], $profile);
            }
        }
    }

    return [
        'module' => $module,
        'action' => $action,
        'profile' => $profile,
        'lang' => $lang,
        'workdir' => $workdir,
        'fields' => $values,
    ];
}

function default_status_ports(string $profile): array
{
    return match ($profile) {
        'grid-sim' => ['8002', '9000', '9001', '8088'],
        'robust' => ['8002', '9000', '9001'],
        'standalone' => ['9000'],
        default => [],
    };
}

function default_status_screens(string $profile, string $workdir): array
{
    if ($profile === 'robust') {
        return ['robustserver'];
    }

    if ($profile === 'standalone') {
        return ['standalone'];
    }

    $screens = [];
    if (is_dir($workdir . '/robust/bin')) {
        $screens[] = 'robustserver';
    }

    $simBins = glob(rtrim($workdir, '/') . '/sim*/bin/OpenSim.ini') ?: [];
    foreach ($simBins as $simIni) {
        $screens[] = basename(dirname(dirname($simIni)));
    }

    if ($screens === []) {
        $screens = ['robustserver', 'sim1'];
    }

    return array_values(array_unique($screens));
}

function configured_status_ports(array $config, string $profile): array
{
    $ports = $config['status_ports'][$profile] ?? null;
    if (!is_array($ports) || $ports === []) {
        return default_status_ports($profile);
    }

    return array_values(array_filter(array_map(static fn ($value): string => trim((string)$value), $ports), static fn (string $value): bool => $value !== ''));
}

function configured_status_screens(array $config, string $profile, string $workdir): array
{
    $screens = $config['status_screens'][$profile] ?? null;
    if (!is_array($screens) || $screens === []) {
        return default_status_screens($profile, $workdir);
    }

    return array_values(array_filter(array_map(static fn ($value): string => trim((string)$value), $screens), static fn (string $value): bool => $value !== ''));
}

function run_status_command(array $command, int $timeoutSeconds = 3): array
{
    $descriptorSpec = [
        0 => ['pipe', 'r'],
        1 => ['pipe', 'w'],
        2 => ['pipe', 'w'],
    ];

    $process = @proc_open($command, $descriptorSpec, $pipes);
    if (!is_resource($process)) {
        return ['ok' => false, 'output' => '', 'error' => 'process-start-failed'];
    }

    fclose($pipes[0]);
    stream_set_blocking($pipes[1], false);
    stream_set_blocking($pipes[2], false);

    $stdout = '';
    $stderr = '';
    $deadline = microtime(true) + $timeoutSeconds;

    while (true) {
        $stdout .= (string)stream_get_contents($pipes[1]);
        $stderr .= (string)stream_get_contents($pipes[2]);
        $status = proc_get_status($process);
        if (!($status['running'] ?? false)) {
            break;
        }
        if (microtime(true) >= $deadline) {
            proc_terminate($process);
            break;
        }
        usleep(100000);
    }

    $stdout .= (string)stream_get_contents($pipes[1]);
    $stderr .= (string)stream_get_contents($pipes[2]);
    fclose($pipes[1]);
    fclose($pipes[2]);
    $exitCode = proc_close($process);

    return [
        'ok' => $exitCode === 0,
        'output' => trim($stdout),
        'error' => trim($stderr),
    ];
}

function collect_screen_status(array $screens): array
{
    $result = run_status_command(['screen', '-list']);
    if ($result['ok'] !== true && $result['output'] === '') {
        return ['available' => false, 'items' => []];
    }

    $output = $result['output'] . "\n" . $result['error'];
    $items = [];
    foreach ($screens as $screenName) {
        $items[] = [
            'name' => $screenName,
            'ok' => (bool)preg_match('/\.' . preg_quote($screenName, '/') . '[[:space:]]/i', $output),
        ];
    }

    return ['available' => true, 'items' => $items];
}

function collect_port_status(array $ports): array
{
    $result = run_status_command(['ss', '-ltnH']);
    if ($result['ok'] !== true && $result['output'] === '') {
        $result = run_status_command(['netstat', '-ltn']);
    }
    if ($result['ok'] !== true && $result['output'] === '') {
        return ['available' => false, 'items' => []];
    }

    $items = [];
    foreach ($ports as $port) {
        $items[] = [
            'name' => $port,
            'ok' => (bool)preg_match('/[:.]' . preg_quote($port, '/') . '$/m', $result['output']),
        ];
    }

    return ['available' => true, 'items' => $items];
}

function latest_matching_file(string $directory, string $pattern): ?string
{
    $files = glob(rtrim($directory, '/') . '/' . $pattern) ?: [];
    if ($files === []) {
        return null;
    }

    usort($files, static fn (string $left, string $right): int => filemtime($right) <=> filemtime($left));
    return $files[0] ?? null;
}

function format_age(?string $path): string
{
    if ($path === null || !is_file($path)) {
        return 'n/a';
    }

    $ageSeconds = max(0, time() - (int)filemtime($path));
    if ($ageSeconds < 3600) {
        return (string)max(1, (int)floor($ageSeconds / 60)) . 'm';
    }
    if ($ageSeconds < 86400) {
        return (string)(int)floor($ageSeconds / 3600) . 'h';
    }

    return (string)(int)floor($ageSeconds / 86400) . 'd';
}

function summarize_status_items(array $items): array
{
    $ok = 0;
    foreach ($items as $item) {
        if (($item['ok'] ?? false) === true) {
            $ok++;
        }
    }

    return ['ok' => $ok, 'total' => count($items)];
}

function collect_live_status(array $config, string $profile, string $workdir): array
{
    $screens = configured_status_screens($config, $profile, $workdir);
    $ports = configured_status_ports($config, $profile);
    $backupDir = rtrim($workdir, '/') . '/backup';
    $reportDir = rtrim($workdir, '/') . '/reports';
    $rollbackDir = rtrim($workdir, '/') . '/rollback';

    $screenStatus = collect_screen_status($screens);
    $portStatus = collect_port_status($ports);
    $latestSql = latest_matching_file($backupDir, 'robust_*.sql*');
    $latestOar = latest_matching_file($backupDir, '*.oar');
    $latestReport = latest_matching_file($reportDir, '*.txt');
    $latestRollback = latest_matching_file($rollbackDir, '*.manifest');

    return [
        'generatedAt' => date('Y-m-d H:i:s'),
        'screens' => $screenStatus,
        'ports' => $portStatus,
        'screensSummary' => summarize_status_items($screenStatus['items']),
        'portsSummary' => summarize_status_items($portStatus['items']),
        'artifacts' => [
            ['label' => 'SQL', 'path' => $latestSql, 'age' => format_age($latestSql)],
            ['label' => 'OAR', 'path' => $latestOar, 'age' => format_age($latestOar)],
            ['label' => 'Report', 'path' => $latestReport, 'age' => format_age($latestReport)],
            ['label' => 'Rollback', 'path' => $latestRollback, 'age' => format_age($latestRollback)],
        ],
    ];
}

function build_command_preview(array $request): string
{
    $parts = [
        'osmtool_main.sh',
        '--mode', 'cli',
        '--module', $request['module'],
        '--action', $request['action'],
        '--profile', $request['profile'],
        '--lang', $request['lang'],
        '--workdir', $request['workdir'],
    ];

    $fieldDefs = web_field_definitions([]);
    foreach ($request['fields'] as $field => $value) {
        $parts[] = $fieldDefs[$field]['flag'];
        $parts[] = $field === 'db_pass' || $field === 'db_root_pass' || $field === 'api_secret' || $field === 'admin_secret' ? '******' : $value;
    }

    return implode(' ', array_map(static fn (string $item): string => preg_match('/^[a-zA-Z0-9._:\/\-*]+$/', $item) ? $item : '"' . addslashes($item) . '"', $parts));
}

function build_command(array $config, array $request): array
{
    $runnerPath = (string)($config['runner_path'] ?? '');
    if ($runnerPath === '') {
        throw new RuntimeException('runner_path missing in config.');
    }

    $base = [];
    $useSudo = (bool)($config['use_sudo'] ?? false);
    if ($useSudo) {
        $sudoUser = (string)($config['sudo_user'] ?? '');
        if ($sudoUser === '') {
            throw new RuntimeException('sudo_user missing in config.');
        }
        $base = ['sudo', '-n', '-u', $sudoUser];
    }

    $command = array_merge($base, [
        $runnerPath,
        $request['module'],
        $request['action'],
        $request['profile'],
        $request['lang'],
        $request['workdir'],
    ]);

    $fieldDefs = web_field_definitions($config);
    foreach ($request['fields'] as $field => $value) {
        $command[] = $fieldDefs[$field]['flag'];
        $command[] = $value;
    }

    return $command;
}

function run_whitelisted_action(array $config, array $request): array
{
    $cmd = build_command($config, $request);
    $descriptorSpec = [
        0 => ['pipe', 'r'],
        1 => ['pipe', 'w'],
        2 => ['pipe', 'w'],
    ];

    $process = proc_open($cmd, $descriptorSpec, $pipes);
    if (!is_resource($process)) {
        return ['ok' => false, 'exitCode' => 1, 'output' => "ERROR: unable to start process\n"];
    }

    fclose($pipes[0]);

    stream_set_blocking($pipes[1], false);
    stream_set_blocking($pipes[2], false);

    $stdout = '';
    $stderr = '';
    $timeout = max(5, (int)($config['command_timeout_seconds'] ?? 120));
    $deadline = microtime(true) + $timeout;
    $timedOut = false;

    while (true) {
        $stdout .= (string)stream_get_contents($pipes[1]);
        $stderr .= (string)stream_get_contents($pipes[2]);

        $status = proc_get_status($process);
        if (!($status['running'] ?? false)) {
            break;
        }

        if (microtime(true) >= $deadline) {
            $timedOut = true;
            proc_terminate($process);
            usleep(200000);
            $status = proc_get_status($process);
            if (($status['running'] ?? false) === true) {
                proc_terminate($process, 9);
            }
            break;
        }

        usleep(100000);
    }

    $stdout .= (string)stream_get_contents($pipes[1]);
    $stderr .= (string)stream_get_contents($pipes[2]);

    fclose($pipes[1]);
    fclose($pipes[2]);

    $exitCode = proc_close($process);
    if ($timedOut) {
        $exitCode = 124;
        $stderr .= "\nERROR: command timed out after {$timeout} seconds\n";
    }
    $output = (string)$stdout . (string)$stderr;

    return [
        'ok' => $exitCode === 0,
        'exitCode' => $exitCode,
        'output' => $output,
        'commandPreview' => build_command_preview($request),
        'timedOut' => $timedOut,
    ];
}
