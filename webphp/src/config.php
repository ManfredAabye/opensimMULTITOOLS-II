<?php
declare(strict_types=1);

return [
    'session_key' => 'change-me-super-random-session-key',
    'web_password' => 'ChangeMeNow-2026',
    // Default assumes deployment under /var/www/html/osmtool-web
    'runner_path' => realpath(__DIR__ . '/../bin/osmtool_web_runner.sh') ?: (__DIR__ . '/../bin/osmtool_web_runner.sh'),
    'command_timeout_seconds' => 120,
    'default_workdir' => '/opt',
    'use_sudo' => true,
    'sudo_user' => 'manni',
];
