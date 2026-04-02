<?php
declare(strict_types=1);

return [
    // Set this to a strong random value in production.
    'session_key' => 'change-me-super-random-session-key',

    // Default login password. Replace immediately in production.
    'web_password' => 'ChangeMeNow-2026',

    // Login brute-force protection.
    'auth_lockout_max_attempts' => 3,
    'auth_lockout_seconds' => 1800,

    // Optional custom storage paths for lockout state and audit logs.
    // 'auth_store_path' => '/var/www/html/osmtool-web/var/security/login_attempts.json',
    // 'auth_audit_log_path' => '/var/log/osmtool-web/auth_audit.log',

    // Default assumes deployment under /var/www/html/osmtool-web.
    // You can keep this dynamic path or set an absolute path manually.
    'runner_path' => realpath(__DIR__ . '/../bin/osmtool_web_runner.sh') ?: (__DIR__ . '/../bin/osmtool_web_runner.sh'),

    // Web timeout in seconds.
    'command_timeout_seconds' => 120,

    // Default workdir passed to osmtool_main.sh.
    'default_workdir' => '/opt',

    // Optional dashboard overrides for live status cards.
    'status_ports' => [
        'grid-sim' => ['8002', '9010', '9020', '9030'],
        'robust' => ['8002', '9010', '9020', '9030'],
        'standalone' => ['9000'],
    ],

    'status_screens' => [
        'grid-sim' => ['robustserver', 'sim1'],
        'robust' => ['robustserver'],
        'standalone' => ['standalone'],
    ],

    // Allow running through sudo if needed.
    'use_sudo' => true,

    // If use_sudo=true, command becomes: sudo -n <sudo_user> <runner>
    // Example: www-data (Linux) or your service account.
    'sudo_user' => 'sudoUserHier',
];
