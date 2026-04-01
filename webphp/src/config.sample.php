<?php
declare(strict_types=1);

return [
    // Set this to a strong random value in production.
    'session_key' => 'change-me-super-random-session-key',

    // Default login password. Replace immediately in production.
    'web_password' => 'ChangeMeNow-2026',

    // Default assumes deployment under /var/www/html/osmtool-web.
    // You can keep this dynamic path or set an absolute path manually.
    'runner_path' => realpath(__DIR__ . '/../bin/osmtool_web_runner.sh') ?: (__DIR__ . '/../bin/osmtool_web_runner.sh'),

    // Web timeout in seconds.
    'command_timeout_seconds' => 120,

    // Default workdir passed to osmtool_main.sh.
    'default_workdir' => '/opt',

    // Allow running through sudo if needed.
    'use_sudo' => true,

    // If use_sudo=true, command becomes: sudo -n <sudo_user> <runner>
    // Example: www-data (Linux) or your service account.
    'sudo_user' => 'manni',
];
