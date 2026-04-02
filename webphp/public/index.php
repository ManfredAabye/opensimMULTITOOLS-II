<?php
declare(strict_types=1);

require_once __DIR__ . '/../src/web_init.php';
require_once __DIR__ . '/../src/runner.php';

$lang = detect_lang(supported_languages());
$_SESSION['lang'] = $lang;

$catalog = translated_catalog($lang, $config);
$fieldDefs = web_field_definitions($config);

$selectedModule = (string)($_POST['module'] ?? $_GET['module'] ?? 'startstop');
if (!isset($catalog[$selectedModule])) {
    $selectedModule = 'startstop';
}

$selectedProfile = (string)($_POST['profile'] ?? $_GET['profile'] ?? 'grid-sim');
if (!in_array($selectedProfile, allowed_profiles(), true)) {
    $selectedProfile = 'grid-sim';
}

$selectedAction = (string)($_POST['action'] ?? $_GET['action'] ?? array_key_first($catalog[$selectedModule]['actions']));
if (!isset($catalog[$selectedModule]['actions'][$selectedAction])) {
    $selectedAction = (string)array_key_first($catalog[$selectedModule]['actions']);
}

$defaultWorkdir = (string)($config['default_workdir'] ?? '/opt');
$workdir = trim((string)($_POST['workdir'] ?? $_GET['workdir'] ?? $defaultWorkdir));
if ($workdir === '') {
    $workdir = $defaultWorkdir;
}

$formValues = [];
foreach ($fieldDefs as $field => $definition) {
    $formValues[$field] = field_value_from_request($field, $_POST + $_GET, $fieldDefs);
}
if ($formValues['target'] === '') {
    $formValues['target'] = default_target_for_profile($selectedProfile);
}

$message = '';
$messageType = 'ok';
$resultOutput = '';
$resultCode = null;
$commandPreview = '';

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
    $loginIp = client_ip_address();

    $remainingLock = remaining_lock_seconds($config, $loginIp);
    if ($remainingLock > 0) {
        $minutes = (int)max(1, ceil($remainingLock / 60));
        $message = str_replace('{minutes}', (string)$minutes, t($lang, 'login_locked'));
        $messageType = 'error';
        append_auth_audit_log($config, $loginIp, 'login_blocked', 'remaining_seconds=' . $remainingLock);
    } elseif (!verify_csrf($_POST['csrf'] ?? null)) {
        $message = t($lang, 'csrf_error');
        $messageType = 'error';
        append_auth_audit_log($config, $loginIp, 'csrf_invalid', 'login-form');
    } else {
        $password = (string)($_POST['password'] ?? '');
        $expected = (string)($config['web_password'] ?? '');
        if ($expected !== '' && hash_equals($expected, $password)) {
            register_login_attempt($config, $loginIp, true);
            append_auth_audit_log($config, $loginIp, 'login_success');
            session_regenerate_id(true);
            $_SESSION['auth'] = true;
            header('Location: index.php?lang=' . urlencode($lang));
            exit;
        }

        register_login_attempt($config, $loginIp, false);
        $remainingAfterFail = remaining_lock_seconds($config, $loginIp);
        if ($remainingAfterFail > 0) {
            $minutes = (int)max(1, ceil($remainingAfterFail / 60));
            $message = str_replace('{minutes}', (string)$minutes, t($lang, 'login_locked'));
            append_auth_audit_log($config, $loginIp, 'login_failed_locked', 'remaining_seconds=' . $remainingAfterFail);
        } else {
            $message = t($lang, 'invalid_login');
            append_auth_audit_log($config, $loginIp, 'login_failed_password');
        }
        $messageType = 'error';
    }
}

if (is_logged_in() && (($_POST['form'] ?? '') === 'run')) {
    $postedLang = detect_lang(supported_languages());
    $_SESSION['lang'] = $postedLang;
    $lang = $postedLang;

    try {
        if (!verify_csrf($_POST['csrf'] ?? null)) {
            throw new RuntimeException(t($lang, 'csrf_error'));
        }

        $request = normalize_run_request($config, $_POST, $lang);
        $selectedModule = $request['module'];
        $selectedAction = $request['action'];
        $selectedProfile = $request['profile'];
        $workdir = $request['workdir'];
        foreach ($request['fields'] as $field => $value) {
            $formValues[$field] = $value;
        }

        $result = run_whitelisted_action($config, $request);
        $resultOutput = (string)($result['output'] ?? '');
        $resultCode = (int)($result['exitCode'] ?? 1);
        $commandPreview = (string)($result['commandPreview'] ?? '');

        if (($result['ok'] ?? false) === true) {
            $message = t($lang, 'status_ok') . ' (exit=' . $resultCode . ')';
            $messageType = 'ok';
        } else {
            $message = t($lang, 'status_error') . ' (exit=' . $resultCode . ')';
            $messageType = 'error';
        }

        push_execution_history([
            'time' => date('Y-m-d H:i:s'),
            'module' => $selectedModule,
            'action' => $selectedAction,
            'profile' => $selectedProfile,
            'exitCode' => $resultCode,
            'ok' => $messageType === 'ok',
        ]);
    } catch (Throwable $exception) {
        $message = $exception->getMessage();
        $messageType = 'error';
        $resultCode = 1;
    }
}

$moduleCount = count($catalog);
$actionCount = 0;
foreach ($catalog as $moduleData) {
    $actionCount += count($moduleData['actions']);
}

$history = execution_history();
$activeAction = $catalog[$selectedModule]['actions'][$selectedAction];
$liveStatus = is_logged_in() ? collect_live_status($config, $selectedProfile, $workdir) : null;

$clientCatalog = [];
foreach ($catalog as $moduleKey => $moduleData) {
    $clientCatalog[$moduleKey] = [
        'label' => $moduleData['label'],
        'description' => $moduleData['description'],
        'actions' => [],
    ];
    foreach ($moduleData['actions'] as $actionKey => $actionData) {
        $clientCatalog[$moduleKey]['actions'][$actionKey] = [
            'label' => $actionData['label'],
            'description' => $actionData['description'],
            'fields' => $actionData['fields'],
            'profiles' => $actionData['profiles'],
        ];
    }
}

$clientFields = [];
foreach ($fieldDefs as $field => $definition) {
    $clientFields[$field] = [
        'type' => $definition['type'],
        'options' => $definition['options'] ?? [],
        'target_by_profile' => $definition['target_by_profile'] ?? [],
    ];
}

function render_input(string $field, array $definition, string $value, string $lang, string $profile): string
{
    $label = h(t($lang, $definition['label_key']));
    $placeholder = h((string)($definition['placeholder'] ?? ''));
    $fieldEscaped = h($field);
    $valueEscaped = h($value);

    if (($definition['type'] ?? '') === 'select') {
        $options = $definition['options'] ?? [];
        if ($field === 'target') {
            $options = $definition['target_by_profile'][$profile] ?? [];
        }
        $html = '<label for="field-' . $fieldEscaped . '">' . $label . '</label>';
        $html .= '<select id="field-' . $fieldEscaped . '" name="' . $fieldEscaped . '">';
        foreach ($options as $option) {
            $selected = $option === $value ? ' selected' : '';
            $html .= '<option value="' . h($option) . '"' . $selected . '>' . h($option) . '</option>';
        }
        $html .= '</select>';
        return $html;
    }

    $type = ($definition['type'] ?? 'text') === 'password' ? 'password' : 'text';
    return '<label for="field-' . $fieldEscaped . '">' . $label . '</label>'
        . '<input id="field-' . $fieldEscaped . '" type="' . $type . '" name="' . $fieldEscaped . '" value="' . $valueEscaped . '" placeholder="' . $placeholder . '">';
}
?>
<!doctype html>
<html lang="<?= h($lang) ?>">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= h(t($lang, 'title')) ?></title>
    <link rel="stylesheet" href="style.css">
    <script>
        window.osmtoolUiData = <?= json_encode(['catalog' => $clientCatalog, 'fields' => $clientFields], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE) ?>;
    </script>
    <script src="app.js" defer></script>
</head>
<body>
<div class="page-shell">
    <div class="hero-orb hero-orb-left"></div>
    <div class="hero-orb hero-orb-right"></div>
    <main class="wrap">
        <section class="hero card">
            <div class="hero-copy">
                <span class="eyebrow"><?= h(t($lang, 'hero_badge')) ?></span>
                <h1><?= h(t($lang, 'title')) ?></h1>
                <p class="hero-text"><?= h(t($lang, 'subtitle_full')) ?></p>
            </div>
            <div class="hero-tools">
                <div class="lang-links">
                    <a href="?lang=de">DE</a>
                    <a href="?lang=en">EN</a>
                    <a href="?lang=fr">FR</a>
                    <a href="?lang=es">ES</a>
                    <?php if (is_logged_in()): ?>
                        <a class="logout-link" href="?logout=1&amp;lang=<?= h($lang) ?>"><?= h(t($lang, 'logout')) ?></a>
                    <?php endif; ?>
                </div>
                <div class="stats-grid">
                    <article class="stat-tile">
                        <span><?= h(t($lang, 'stat_modules')) ?></span>
                        <strong><?= h((string)$moduleCount) ?></strong>
                    </article>
                    <article class="stat-tile">
                        <span><?= h(t($lang, 'stat_actions')) ?></span>
                        <strong><?= h((string)$actionCount) ?></strong>
                    </article>
                    <article class="stat-tile">
                        <span><?= h(t($lang, 'stat_timeout')) ?></span>
                        <strong><?= h((string)($config['command_timeout_seconds'] ?? 120)) ?>s</strong>
                    </article>
                    <article class="stat-tile">
                        <span><?= h(t($lang, 'stat_workdir')) ?></span>
                        <strong><?= h($workdir) ?></strong>
                    </article>
                </div>
            </div>
        </section>

        <?php if ($message !== ''): ?>
            <section class="message-bar <?= h($messageType) ?> card">
                <strong><?= h($message) ?></strong>
            </section>
        <?php endif; ?>

        <?php if (!is_logged_in()): ?>
            <section class="login-layout">
                <article class="card login-card">
                    <h2><?= h(t($lang, 'login_title')) ?></h2>
                    <p><?= h(t($lang, 'login_intro')) ?></p>
                    <form method="post" class="stack-form">
                        <input type="hidden" name="form" value="login">
                        <input type="hidden" name="csrf" value="<?= h(csrf_token()) ?>">
                        <input type="hidden" name="lang" value="<?= h($lang) ?>">
                        <label for="login-password"><?= h(t($lang, 'password')) ?></label>
                        <input id="login-password" type="password" name="password" autocomplete="current-password" required>
                        <button type="submit"><?= h(t($lang, 'login')) ?></button>
                    </form>
                </article>
                <article class="card feature-card">
                    <h2><?= h(t($lang, 'feature_title')) ?></h2>
                    <ul class="feature-list">
                        <li><?= h(t($lang, 'feature_modules')) ?></li>
                        <li><?= h(t($lang, 'feature_history')) ?></li>
                        <li><?= h(t($lang, 'feature_reports')) ?></li>
                        <li><?= h(t($lang, 'feature_security')) ?></li>
                    </ul>
                </article>
            </section>
        <?php else: ?>
            <section class="dashboard-grid">
                <article class="card quick-card">
                    <div class="section-head">
                        <h2><?= h(t($lang, 'quick_actions')) ?></h2>
                        <p><?= h(t($lang, 'quick_actions_hint')) ?></p>
                    </div>
                    <div class="quick-actions-grid">
                        <?php foreach ([
                            ['module' => 'startstop', 'action' => 'start', 'label' => t($lang, 'action_start')],
                            ['module' => 'startstop', 'action' => 'restart', 'label' => t($lang, 'action_restart')],
                            ['module' => 'health', 'action' => 'run', 'label' => t($lang, 'health_run')],
                            ['module' => 'report', 'action' => 'generate', 'label' => t($lang, 'report_generate')],
                        ] as $quick): ?>
                            <form method="post" class="quick-form">
                                <input type="hidden" name="form" value="run">
                                <input type="hidden" name="csrf" value="<?= h(csrf_token()) ?>">
                                <input type="hidden" name="lang" value="<?= h($lang) ?>">
                                <input type="hidden" name="module" value="<?= h($quick['module']) ?>">
                                <input type="hidden" name="action" value="<?= h($quick['action']) ?>">
                                <input type="hidden" name="profile" value="<?= h($selectedProfile) ?>">
                                <input type="hidden" name="workdir" value="<?= h($workdir) ?>">
                                <input type="hidden" name="target" value="<?= h(default_target_for_profile($selectedProfile)) ?>">
                                <button type="submit" class="ghost-button"><?= h($quick['label']) ?></button>
                            </form>
                        <?php endforeach; ?>
                    </div>
                </article>

                <article class="card status-card">
                    <div class="section-head">
                        <h2><?= h(t($lang, 'selected_action')) ?></h2>
                        <p id="action-description"><?= h($activeAction['description']) ?></p>
                    </div>
                    <div class="badge-row">
                        <span class="badge"><?= h($catalog[$selectedModule]['label']) ?></span>
                        <span class="badge muted"><?= h($activeAction['label']) ?></span>
                        <span class="badge muted"><?= h($selectedProfile) ?></span>
                    </div>
                </article>
            </section>

            <section class="live-status-grid">
                <article class="card live-card">
                    <div class="section-head">
                        <h2><?= h(t($lang, 'live_status_title')) ?></h2>
                        <p><?= h(t($lang, 'live_status_hint')) ?> <?= h((string)($liveStatus['generatedAt'] ?? '')) ?></p>
                    </div>
                    <div class="live-metrics">
                        <div class="live-metric">
                            <span><?= h(t($lang, 'live_screens')) ?></span>
                            <strong><?= h((string)($liveStatus['screensSummary']['ok'] ?? 0)) ?>/<?= h((string)($liveStatus['screensSummary']['total'] ?? 0)) ?></strong>
                        </div>
                        <div class="live-metric">
                            <span><?= h(t($lang, 'live_ports')) ?></span>
                            <strong><?= h((string)($liveStatus['portsSummary']['ok'] ?? 0)) ?>/<?= h((string)($liveStatus['portsSummary']['total'] ?? 0)) ?></strong>
                        </div>
                    </div>
                    <div class="status-columns">
                        <div>
                            <h3><?= h(t($lang, 'live_screens')) ?></h3>
                            <?php if (($liveStatus['screens']['available'] ?? false) !== true): ?>
                                <p class="empty-state"><?= h(t($lang, 'live_unavailable')) ?></p>
                            <?php else: ?>
                                <ul class="status-list">
                                    <?php foreach (($liveStatus['screens']['items'] ?? []) as $item): ?>
                                        <li>
                                            <span><?= h((string)$item['name']) ?></span>
                                            <span class="status-pill <?= !empty($item['ok']) ? 'ok' : 'error' ?>"><?= h(!empty($item['ok']) ? t($lang, 'live_up') : t($lang, 'live_down')) ?></span>
                                        </li>
                                    <?php endforeach; ?>
                                </ul>
                            <?php endif; ?>
                        </div>
                        <div>
                            <h3><?= h(t($lang, 'live_ports')) ?></h3>
                            <?php if (($liveStatus['ports']['available'] ?? false) !== true): ?>
                                <p class="empty-state"><?= h(t($lang, 'live_unavailable')) ?></p>
                            <?php else: ?>
                                <ul class="status-list">
                                    <?php foreach (($liveStatus['ports']['items'] ?? []) as $item): ?>
                                        <li>
                                            <span><?= h((string)$item['name']) ?></span>
                                            <span class="status-pill <?= !empty($item['ok']) ? 'ok' : 'error' ?>"><?= h(!empty($item['ok']) ? t($lang, 'live_listen') : t($lang, 'live_closed')) ?></span>
                                        </li>
                                    <?php endforeach; ?>
                                </ul>
                            <?php endif; ?>
                        </div>
                    </div>
                </article>

                <article class="card artifact-card">
                    <div class="section-head">
                        <h2><?= h(t($lang, 'artifact_title')) ?></h2>
                        <p><?= h(t($lang, 'artifact_hint')) ?></p>
                    </div>
                    <ul class="artifact-list">
                        <?php foreach (($liveStatus['artifacts'] ?? []) as $artifact): ?>
                            <li>
                                <strong><?= h((string)$artifact['label']) ?></strong>
                                <span><?= h($artifact['path'] !== null ? basename((string)$artifact['path']) : t($lang, 'artifact_missing')) ?></span>
                                <span class="artifact-age"><?= h((string)$artifact['age']) ?></span>
                            </li>
                        <?php endforeach; ?>
                    </ul>
                </article>
            </section>

            <section class="workspace-grid">
                <article class="card form-card">
                    <div class="section-head">
                        <h2><?= h(t($lang, 'form_title')) ?></h2>
                        <p><?= h(t($lang, 'hint_full')) ?></p>
                    </div>
                    <form method="post" class="command-form" id="command-form">
                        <input type="hidden" name="form" value="run">
                        <input type="hidden" name="csrf" value="<?= h(csrf_token()) ?>">
                        <input type="hidden" name="lang" value="<?= h($lang) ?>">

                        <div class="field-grid base-grid">
                            <div class="field-row">
                                <label for="module"><?= h(t($lang, 'field_module')) ?></label>
                                <select id="module" name="module">
                                    <?php foreach ($catalog as $moduleKey => $moduleData): ?>
                                        <option value="<?= h($moduleKey) ?>"<?= $moduleKey === $selectedModule ? ' selected' : '' ?>><?= h($moduleData['label']) ?></option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                            <div class="field-row">
                                <label for="action"><?= h(t($lang, 'action')) ?></label>
                                <select id="action" name="action">
                                    <?php foreach ($catalog[$selectedModule]['actions'] as $actionKey => $actionData): ?>
                                        <option value="<?= h($actionKey) ?>"<?= $actionKey === $selectedAction ? ' selected' : '' ?>><?= h($actionData['label']) ?></option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                            <div class="field-row">
                                <label for="profile"><?= h(t($lang, 'profile')) ?></label>
                                <select id="profile" name="profile">
                                    <?php foreach (allowed_profiles() as $profile): ?>
                                        <option value="<?= h($profile) ?>"<?= $profile === $selectedProfile ? ' selected' : '' ?>><?= h($profile) ?></option>
                                    <?php endforeach; ?>
                                </select>
                            </div>
                            <div class="field-row field-row-wide">
                                <label for="workdir"><?= h(t($lang, 'workdir')) ?></label>
                                <input id="workdir" name="workdir" value="<?= h($workdir) ?>">
                            </div>
                        </div>

                        <div class="section-head compact">
                            <h3><?= h(t($lang, 'advanced_fields')) ?></h3>
                            <p><?= h(t($lang, 'advanced_fields_hint')) ?></p>
                        </div>

                        <div class="field-grid advanced-grid">
                            <?php foreach ($fieldDefs as $field => $definition): ?>
                                <?php $hidden = !in_array($field, $activeAction['fields'], true); ?>
                                <div class="field-row action-field<?= $hidden ? ' is-hidden' : '' ?>" data-field="<?= h($field) ?>">
                                    <?= render_input($field, $definition, $formValues[$field], $lang, $selectedProfile) ?>
                                </div>
                            <?php endforeach; ?>
                        </div>

                        <div class="form-footer">
                            <button type="submit"><?= h(t($lang, 'execute')) ?></button>
                        </div>
                    </form>
                </article>

                <article class="card catalog-card">
                    <div class="section-head">
                        <h2><?= h(t($lang, 'catalog_title')) ?></h2>
                        <p><?= h(t($lang, 'catalog_hint')) ?></p>
                    </div>
                    <div class="catalog-list">
                        <?php foreach ($catalog as $moduleData): ?>
                            <div class="catalog-item">
                                <h3><?= h($moduleData['label']) ?></h3>
                                <p><?= h($moduleData['description']) ?></p>
                                <ul>
                                    <?php foreach ($moduleData['actions'] as $actionData): ?>
                                        <li>
                                            <strong><?= h($actionData['label']) ?></strong>
                                            <span><?= h($actionData['description']) ?></span>
                                        </li>
                                    <?php endforeach; ?>
                                </ul>
                            </div>
                        <?php endforeach; ?>
                    </div>
                </article>
            </section>

            <section class="results-grid">
                <article class="card result-card">
                    <div class="section-head">
                        <h2><?= h(t($lang, 'execution_result')) ?></h2>
                        <p><?= h(t($lang, 'execution_result_hint')) ?></p>
                    </div>
                    <?php if ($commandPreview !== ''): ?>
                        <div class="preview-block">
                            <span><?= h(t($lang, 'command_preview')) ?></span>
                            <code><?= h($commandPreview) ?></code>
                        </div>
                    <?php endif; ?>
                    <?php if ($resultCode !== null): ?>
                        <div class="preview-block">
                            <span><?= h(t($lang, 'output')) ?></span>
                            <pre><?= h($resultOutput) ?></pre>
                        </div>
                    <?php else: ?>
                        <p class="empty-state"><?= h(t($lang, 'no_result_yet')) ?></p>
                    <?php endif; ?>
                </article>

                <article class="card history-card">
                    <div class="section-head">
                        <h2><?= h(t($lang, 'history_title')) ?></h2>
                        <p><?= h(t($lang, 'history_hint')) ?></p>
                    </div>
                    <?php if ($history === []): ?>
                        <p class="empty-state"><?= h(t($lang, 'history_empty')) ?></p>
                    <?php else: ?>
                        <ul class="history-list">
                            <?php foreach ($history as $entry): ?>
                                <li>
                                    <strong><?= h((string)$entry['time']) ?></strong>
                                    <span><?= h((string)$entry['module']) ?> / <?= h((string)$entry['action']) ?> / <?= h((string)$entry['profile']) ?></span>
                                    <span class="history-status <?= !empty($entry['ok']) ? 'ok' : 'error' ?>">exit=<?= h((string)$entry['exitCode']) ?></span>
                                </li>
                            <?php endforeach; ?>
                        </ul>
                    <?php endif; ?>
                </article>
            </section>
        <?php endif; ?>
    </main>
</div>
</body>
</html>
