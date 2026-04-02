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

function client_ip_address(): string
{
    $remote = trim((string)($_SERVER['REMOTE_ADDR'] ?? 'unknown'));
    if ($remote === '') {
        $remote = 'unknown';
    }

    $forwarded = (string)($_SERVER['HTTP_X_FORWARDED_FOR'] ?? '');
    if ($forwarded !== '') {
        $first = trim(explode(',', $forwarded)[0] ?? '');
        if ($first !== '' && filter_var($first, FILTER_VALIDATE_IP)) {
            return $first;
        }
    }

    return $remote;
}

function security_store_path(array $config): string
{
    $configured = trim((string)($config['auth_store_path'] ?? ''));
    if ($configured !== '') {
        return $configured;
    }
    return __DIR__ . '/../var/security/login_attempts.json';
}

function security_audit_log_path(array $config): string
{
    $configured = trim((string)($config['auth_audit_log_path'] ?? ''));
    if ($configured !== '') {
        return $configured;
    }
    return __DIR__ . '/../var/security/auth_audit.log';
}

function ensure_parent_directory(string $filePath): void
{
    $dir = dirname($filePath);
    if ($dir !== '' && !is_dir($dir)) {
        @mkdir($dir, 0770, true);
    }
}

function auth_lockout_max_attempts(array $config): int
{
    $value = (int)($config['auth_lockout_max_attempts'] ?? 3);
    return $value > 0 ? $value : 3;
}

function auth_lockout_seconds(array $config): int
{
    $value = (int)($config['auth_lockout_seconds'] ?? 1800);
    return $value > 0 ? $value : 1800;
}

function read_auth_state(array $config): array
{
    $path = security_store_path($config);
    ensure_parent_directory($path);

    $handle = @fopen($path, 'c+');
    if (!is_resource($handle)) {
        return [];
    }

    if (!flock($handle, LOCK_EX)) {
        fclose($handle);
        return [];
    }

    $raw = stream_get_contents($handle);
    $state = [];
    if (is_string($raw) && trim($raw) !== '') {
        $decoded = json_decode($raw, true);
        if (is_array($decoded)) {
            $state = $decoded;
        }
    }

    $now = time();
    foreach ($state as $ip => $entry) {
        $last = (int)($entry['last_attempt'] ?? 0);
        $lockedUntil = (int)($entry['locked_until'] ?? 0);
        if ($last > 0 && ($now - $last) > (7 * 24 * 3600) && $lockedUntil < $now) {
            unset($state[$ip]);
        }
    }

    ftruncate($handle, 0);
    rewind($handle);
    fwrite($handle, json_encode($state, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
    fflush($handle);
    flock($handle, LOCK_UN);
    fclose($handle);

    return $state;
}

function write_auth_state(array $config, array $state): void
{
    $path = security_store_path($config);
    ensure_parent_directory($path);

    $handle = @fopen($path, 'c+');
    if (!is_resource($handle)) {
        return;
    }

    if (!flock($handle, LOCK_EX)) {
        fclose($handle);
        return;
    }

    ftruncate($handle, 0);
    rewind($handle);
    fwrite($handle, json_encode($state, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
    fflush($handle);
    flock($handle, LOCK_UN);
    fclose($handle);
}

function remaining_lock_seconds(array $config, string $ip): int
{
    $state = read_auth_state($config);
    $entry = $state[$ip] ?? null;
    if (!is_array($entry)) {
        return 0;
    }

    $lockedUntil = (int)($entry['locked_until'] ?? 0);
    $remaining = $lockedUntil - time();
    return $remaining > 0 ? $remaining : 0;
}

function register_login_attempt(array $config, string $ip, bool $success): void
{
    $state = read_auth_state($config);
    $entry = $state[$ip] ?? ['failed_attempts' => 0, 'locked_until' => 0, 'last_attempt' => 0];
    $now = time();

    if ($success) {
        $entry['failed_attempts'] = 0;
        $entry['locked_until'] = 0;
    } else {
        if ((int)($entry['locked_until'] ?? 0) <= $now) {
            $entry['failed_attempts'] = (int)($entry['failed_attempts'] ?? 0) + 1;
            if ($entry['failed_attempts'] >= auth_lockout_max_attempts($config)) {
                $entry['locked_until'] = $now + auth_lockout_seconds($config);
                $entry['failed_attempts'] = 0;
            }
        }
    }

    $entry['last_attempt'] = $now;
    $state[$ip] = $entry;
    write_auth_state($config, $state);
}

function append_auth_audit_log(array $config, string $ip, string $event, string $detail = ''): void
{
    $path = security_audit_log_path($config);
    ensure_parent_directory($path);
    $ua = trim((string)($_SERVER['HTTP_USER_AGENT'] ?? 'unknown-agent'));
    $line = sprintf(
        "%s\tip=%s\tevent=%s\tdetail=%s\tua=%s\n",
        date('Y-m-d H:i:s'),
        $ip,
        $event,
        $detail,
        str_replace(["\t", "\n", "\r"], ' ', $ua)
    );
    @file_put_contents($path, $line, FILE_APPEND | LOCK_EX);
}
