<?php
declare(strict_types=1);

function supported_languages(): array
{
    return ['de', 'en', 'fr', 'es'];
}

function translations(): array
{
    return [
        'de' => [
            'title' => 'OSMTool Web Steuerung',
            'subtitle' => 'Sichere Web-Oberflaeche fuer OpenSim Aktionen',
            'login_title' => 'Anmeldung',
            'password' => 'Passwort',
            'login' => 'Einloggen',
            'logout' => 'Ausloggen',
            'language' => 'Sprache',
            'profile' => 'Profil',
            'action' => 'Aktion',
            'execute' => 'Ausfuehren',
            'workdir' => 'Workdir',
            'output' => 'Ausgabe',
            'status_ok' => 'Erfolgreich',
            'status_error' => 'Fehler',
            'invalid_login' => 'Anmeldung fehlgeschlagen.',
            'csrf_error' => 'Ungueltiges Formular-Token.',
            'not_allowed' => 'Aktion nicht erlaubt.',
            'run_failed' => 'Ausfuehrung fehlgeschlagen.',
            'hint' => 'Es werden nur freigegebene Aktionen ausgefuehrt.',
            'action_start' => 'Start',
            'action_stop' => 'Stop',
            'action_restart' => 'Neustart',
            'action_smoke' => 'Smoke-Test',
            'action_report' => 'Report erzeugen',
            'action_health' => 'Healthcheck',
            'action_cron_list' => 'Cronjobs anzeigen',
        ],
        'en' => [
            'title' => 'OSMTool Web Control',
            'subtitle' => 'Secure web interface for OpenSim actions',
            'login_title' => 'Login',
            'password' => 'Password',
            'login' => 'Sign in',
            'logout' => 'Sign out',
            'language' => 'Language',
            'profile' => 'Profile',
            'action' => 'Action',
            'execute' => 'Execute',
            'workdir' => 'Workdir',
            'output' => 'Output',
            'status_ok' => 'Success',
            'status_error' => 'Error',
            'invalid_login' => 'Login failed.',
            'csrf_error' => 'Invalid form token.',
            'not_allowed' => 'Action not allowed.',
            'run_failed' => 'Execution failed.',
            'hint' => 'Only whitelisted actions are executed.',
            'action_start' => 'Start',
            'action_stop' => 'Stop',
            'action_restart' => 'Restart',
            'action_smoke' => 'Smoke test',
            'action_report' => 'Generate report',
            'action_health' => 'Health check',
            'action_cron_list' => 'List cron jobs',
        ],
        'fr' => [
            'title' => 'Controle Web OSMTool',
            'subtitle' => 'Interface web securisee pour les actions OpenSim',
            'login_title' => 'Connexion',
            'password' => 'Mot de passe',
            'login' => 'Se connecter',
            'logout' => 'Se deconnecter',
            'language' => 'Langue',
            'profile' => 'Profil',
            'action' => 'Action',
            'execute' => 'Executer',
            'workdir' => 'Repertoire de travail',
            'output' => 'Sortie',
            'status_ok' => 'Succes',
            'status_error' => 'Erreur',
            'invalid_login' => 'Echec de connexion.',
            'csrf_error' => 'Jeton de formulaire invalide.',
            'not_allowed' => 'Action non autorisee.',
            'run_failed' => 'Execution echouee.',
            'hint' => 'Seules les actions en liste blanche sont executees.',
            'action_start' => 'Demarrer',
            'action_stop' => 'Arreter',
            'action_restart' => 'Redemarrer',
            'action_smoke' => 'Test smoke',
            'action_report' => 'Generer un rapport',
            'action_health' => 'Controle de sante',
            'action_cron_list' => 'Lister les cron jobs',
        ],
        'es' => [
            'title' => 'Control Web OSMTool',
            'subtitle' => 'Interfaz web segura para acciones de OpenSim',
            'login_title' => 'Inicio de sesion',
            'password' => 'Contrasena',
            'login' => 'Entrar',
            'logout' => 'Salir',
            'language' => 'Idioma',
            'profile' => 'Perfil',
            'action' => 'Accion',
            'execute' => 'Ejecutar',
            'workdir' => 'Directorio de trabajo',
            'output' => 'Salida',
            'status_ok' => 'Correcto',
            'status_error' => 'Error',
            'invalid_login' => 'Error de inicio de sesion.',
            'csrf_error' => 'Token de formulario invalido.',
            'not_allowed' => 'Accion no permitida.',
            'run_failed' => 'La ejecucion fallo.',
            'hint' => 'Solo se ejecutan acciones permitidas.',
            'action_start' => 'Iniciar',
            'action_stop' => 'Detener',
            'action_restart' => 'Reiniciar',
            'action_smoke' => 'Prueba smoke',
            'action_report' => 'Generar informe',
            'action_health' => 'Chequeo de salud',
            'action_cron_list' => 'Listar cron jobs',
        ],
    ];
}

function detect_lang(array $supported): string
{
    $lang = $_GET['lang'] ?? $_POST['lang'] ?? $_SESSION['lang'] ?? 'de';
    if (!is_string($lang) || !in_array($lang, $supported, true)) {
        return 'de';
    }
    return $lang;
}

function t(string $lang, string $key): string
{
    $all = translations();
    return $all[$lang][$key] ?? $all['en'][$key] ?? $key;
}
