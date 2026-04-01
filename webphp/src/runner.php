<?php
declare(strict_types=1);

function allowed_profiles(): array
{
    return ['grid-sim', 'robust', 'standalone'];
}

function allowed_actions(): array
{
    return ['start', 'stop', 'restart', 'smoke', 'report', 'health', 'cron-list'];
}

function build_command(array $config, string $action, string $profile, string $lang, string $workdir): array
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

    return array_merge($base, [$runnerPath, $action, $profile, $lang, $workdir]);
}

function run_whitelisted_action(array $config, string $action, string $profile, string $lang, string $workdir): array
{
    if (!in_array($action, allowed_actions(), true)) {
        return ['ok' => false, 'exitCode' => 2, 'output' => "ERROR: action not allowed\n"];
    }

    if (!in_array($profile, allowed_profiles(), true)) {
        return ['ok' => false, 'exitCode' => 2, 'output' => "ERROR: invalid profile\n"];
    }

    if (!in_array($lang, supported_languages(), true)) {
        return ['ok' => false, 'exitCode' => 2, 'output' => "ERROR: invalid language\n"];
    }

    $workdirClean = trim($workdir);
    if ($workdirClean === '') {
        $workdirClean = (string)($config['default_workdir'] ?? '/opt');
    }

    $cmd = build_command($config, $action, $profile, $lang, $workdirClean);
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

    $stdout = stream_get_contents($pipes[1]);
    $stderr = stream_get_contents($pipes[2]);

    fclose($pipes[1]);
    fclose($pipes[2]);

    $exitCode = proc_close($process);
    $output = (string)$stdout . (string)$stderr;

    return ['ok' => $exitCode === 0, 'exitCode' => $exitCode, 'output' => $output];
}
