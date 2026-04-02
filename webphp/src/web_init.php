<?php
declare(strict_types=1);

$configFile = __DIR__ . '/config.php';
if (!is_file($configFile)) {
    $configFile = __DIR__ . '/config.sample.php';
}

$config = require $configFile;

if (!isset($config['session_key']) || !is_string($config['session_key'])) {
    throw new RuntimeException('Missing session_key in config.');
}

function request_is_https(): bool
{
    if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') {
        return true;
    }

    return (int)($_SERVER['SERVER_PORT'] ?? 0) === 443;
}

session_name('osmtool_web');
session_set_cookie_params([
    'lifetime' => 0,
    'path' => '/',
    'secure' => request_is_https(),
    'httponly' => true,
    'samesite' => 'Strict',
]);

session_start();

if (!isset($_SESSION['session_seed'])) {
    $_SESSION['session_seed'] = hash('sha256', $config['session_key'] . random_int(1000, 999999));
}

require_once __DIR__ . '/i18n.php';

function is_logged_in(): bool
{
    return isset($_SESSION['auth']) && $_SESSION['auth'] === true;
}

function require_login(): void
{
    if (!is_logged_in()) {
        header('Location: index.php');
        exit;
    }
}

function csrf_token(): string
{
    if (!isset($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function verify_csrf(?string $token): bool
{
    if (!isset($_SESSION['csrf_token']) || !is_string($token)) {
        return false;
    }
    return hash_equals($_SESSION['csrf_token'], $token);
}

function h(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function execution_history(): array
{
    $history = $_SESSION['execution_history'] ?? [];
    return is_array($history) ? $history : [];
}

function push_execution_history(array $entry): void
{
    $history = execution_history();
    array_unshift($history, $entry);
    $_SESSION['execution_history'] = array_slice($history, 0, 8);
}
