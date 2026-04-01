<?php
declare(strict_types=1);

require_once __DIR__ . '/../src/bootstrap.php';
require_once __DIR__ . '/../src/runner.php';

$lang = detect_lang(supported_languages());
$_SESSION['lang'] = $lang;

$message = '';
$messageType = 'ok';
$resultOutput = '';
$resultCode = null;

if (isset($_GET['logout'])) {
    $_SESSION = [];
    session_destroy();
    header('Location: index.php?lang=' . urlencode($lang));
    exit;
}

if (($_POST['form'] ?? '') === 'login') {
    $postedLang = detect_lang(supported_languages());
    $_SESSION['lang'] = $postedLang;
    $lang = $postedLang;

    if (!verify_csrf($_POST['csrf'] ?? null)) {
        $message = t($lang, 'csrf_error');
        $messageType = 'error';
    } else {
        $password = (string)($_POST['password'] ?? '');
        $expected = (string)($config['web_password'] ?? '');
        if ($expected !== '' && hash_equals($expected, $password)) {
            $_SESSION['auth'] = true;
            header('Location: index.php?lang=' . urlencode($lang));
            exit;
        }
        $message = t($lang, 'invalid_login');
        $messageType = 'error';
    }
}

if (is_logged_in() && (($_POST['form'] ?? '') === 'run')) {
    if (!verify_csrf($_POST['csrf'] ?? null)) {
        $message = t($lang, 'csrf_error');
        $messageType = 'error';
    } else {
        $action = (string)($_POST['action'] ?? '');
        $profile = (string)($_POST['profile'] ?? 'grid-sim');
        $workdir = (string)($_POST['workdir'] ?? (string)($config['default_workdir'] ?? '/opt'));

        $result = run_whitelisted_action($config, $action, $profile, $lang, $workdir);
        $resultOutput = (string)($result['output'] ?? '');
        $resultCode = (int)($result['exitCode'] ?? 1);

        if (($result['ok'] ?? false) === true) {
            $message = t($lang, 'status_ok') . ' (exit=' . $resultCode . ')';
            $messageType = 'ok';
        } else {
            $message = t($lang, 'status_error') . ' (exit=' . $resultCode . ')';
            $messageType = 'error';
        }
    }
}

$actions = [
    'start' => t($lang, 'action_start'),
    'stop' => t($lang, 'action_stop'),
    'restart' => t($lang, 'action_restart'),
    'smoke' => t($lang, 'action_smoke'),
    'report' => t($lang, 'action_report'),
    'health' => t($lang, 'action_health'),
    'cron-list' => t($lang, 'action_cron_list'),
];

$profiles = [
    'grid-sim' => 'grid-sim',
    'robust' => 'robust',
    'standalone' => 'standalone',
];
?>
<!doctype html>
<html lang="<?= h($lang) ?>">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= h(t($lang, 'title')) ?></title>
    <style>
        :root {
            --bg1: #0f172a;
            --bg2: #1e293b;
            --card: #111827;
            --line: #334155;
            --text: #e5e7eb;
            --muted: #94a3b8;
            --ok: #16a34a;
            --err: #dc2626;
            --btn: #0284c7;
            --btnHover: #0369a1;
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: "Segoe UI", Tahoma, sans-serif;
            background: radial-gradient(1000px 600px at 20% 0%, #1d4ed8 0%, transparent 60%),
                        radial-gradient(900px 500px at 100% 100%, #0ea5e9 0%, transparent 50%),
                        linear-gradient(160deg, var(--bg1), var(--bg2));
            color: var(--text);
            min-height: 100vh;
            padding: 24px;
        }
        .wrap { max-width: 980px; margin: 0 auto; }
        .card {
            background: color-mix(in oklab, var(--card), black 8%);
            border: 1px solid var(--line);
            border-radius: 14px;
            padding: 18px;
            box-shadow: 0 12px 40px rgba(0,0,0,.25);
            margin-bottom: 18px;
        }
        h1 { margin: 0 0 8px; font-size: 1.7rem; }
        p { margin: 0 0 12px; color: var(--muted); }
        .topbar {
            display: flex;
            justify-content: space-between;
            gap: 12px;
            align-items: center;
            flex-wrap: wrap;
            margin-bottom: 14px;
        }
        label { display: block; margin-bottom: 6px; font-weight: 600; }
        input, select, button {
            width: 100%;
            border-radius: 10px;
            border: 1px solid var(--line);
            background: #0b1220;
            color: var(--text);
            padding: 10px 12px;
        }
        button {
            background: var(--btn);
            border: none;
            font-weight: 700;
            cursor: pointer;
        }
        button:hover { background: var(--btnHover); }
        .grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 12px;
        }
        .full { grid-column: 1 / -1; }
        .msg {
            margin: 10px 0;
            padding: 10px 12px;
            border-radius: 10px;
            font-weight: 700;
        }
        .ok { background: rgba(22,163,74,.2); border: 1px solid rgba(22,163,74,.5); }
        .error { background: rgba(220,38,38,.2); border: 1px solid rgba(220,38,38,.5); }
        pre {
            background: #020617;
            border: 1px solid var(--line);
            border-radius: 10px;
            padding: 12px;
            overflow: auto;
            max-height: 420px;
            margin: 0;
            white-space: pre-wrap;
        }
        .lang-links a {
            color: #bae6fd;
            margin-right: 8px;
            text-decoration: none;
        }
        .lang-links a:hover { text-decoration: underline; }
        @media (max-width: 800px) {
            .grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
<div class="wrap">
    <div class="card">
        <div class="topbar">
            <div>
                <h1><?= h(t($lang, 'title')) ?></h1>
                <p><?= h(t($lang, 'subtitle')) ?></p>
            </div>
            <div class="lang-links">
                <a href="?lang=de">DE</a>
                <a href="?lang=en">EN</a>
                <a href="?lang=fr">FR</a>
                <a href="?lang=es">ES</a>
                <?php if (is_logged_in()): ?>
                    | <a href="?logout=1&amp;lang=<?= h($lang) ?>"><?= h(t($lang, 'logout')) ?></a>
                <?php endif; ?>
            </div>
        </div>

        <?php if ($message !== ''): ?>
            <div class="msg <?= h($messageType) ?>"><?= h($message) ?></div>
        <?php endif; ?>

        <?php if (!is_logged_in()): ?>
            <form method="post">
                <input type="hidden" name="form" value="login">
                <input type="hidden" name="csrf" value="<?= h(csrf_token()) ?>">
                <input type="hidden" name="lang" value="<?= h($lang) ?>">
                <div class="grid">
                    <div class="full">
                        <label><?= h(t($lang, 'password')) ?></label>
                        <input type="password" name="password" autocomplete="current-password" required>
                    </div>
                    <div class="full">
                        <button type="submit"><?= h(t($lang, 'login')) ?></button>
                    </div>
                </div>
            </form>
        <?php else: ?>
            <p><?= h(t($lang, 'hint')) ?></p>
            <form method="post">
                <input type="hidden" name="form" value="run">
                <input type="hidden" name="csrf" value="<?= h(csrf_token()) ?>">
                <input type="hidden" name="lang" value="<?= h($lang) ?>">

                <div class="grid">
                    <div>
                        <label><?= h(t($lang, 'profile')) ?></label>
                        <select name="profile" required>
                            <?php foreach ($profiles as $value => $label): ?>
                                <option value="<?= h($value) ?>"><?= h($label) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div>
                        <label><?= h(t($lang, 'action')) ?></label>
                        <select name="action" required>
                            <?php foreach ($actions as $value => $label): ?>
                                <option value="<?= h($value) ?>"><?= h($label) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="full">
                        <label><?= h(t($lang, 'workdir')) ?></label>
                        <input name="workdir" value="<?= h((string)($config['default_workdir'] ?? '/opt')) ?>">
                    </div>
                    <div class="full">
                        <button type="submit"><?= h(t($lang, 'execute')) ?></button>
                    </div>
                </div>
            </form>

            <?php if ($resultCode !== null): ?>
                <div class="card" style="margin-top:14px;">
                    <label><?= h(t($lang, 'output')) ?></label>
                    <pre><?= h($resultOutput) ?></pre>
                </div>
            <?php endif; ?>
        <?php endif; ?>
    </div>
</div>
</body>
</html>
