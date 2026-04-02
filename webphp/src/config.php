<?php
declare(strict_types=1);

return [
    'session_key' => 'change-me-super-random-session-key',
    'web_password' => 'ChangeMeNow-2026',
    // Default assumes deployment under /var/www/html/osmtool-web
    'runner_path' => realpath(__DIR__ . '/../bin/osmtool_web_runner.sh') ?: (__DIR__ . '/../bin/osmtool_web_runner.sh'),
    'command_timeout_seconds' => 120,
    'default_workdir' => '/opt',

    // Optional dashboard overrides for live status cards.
    'status_ports' => [
        'grid-sim' => ['8002', '9010', '9020', '9030'],
        'robust' => ['8002', '9010', '9020', '9030'],
        'standalone' => ['9000'],
    ],

    'status_screens' => [
        'grid-sim' => ['robustserver', 'sim1', 'sim2', 'sim3'],
        'robust' => ['robustserver'],
        'standalone' => ['standalone'],
    ],

    'use_sudo' => true,
    'sudo_user' => 'sudoUserHier',
];
