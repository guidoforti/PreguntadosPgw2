<?php
session_start();
include("helper/ConfigFactory.php");
$configFactory = new ConfigFactory();
$router = $configFactory->get("router");

$controller = $_GET['controller'] ?? null;
$method = $_GET['method'] ?? null;

$rutas_publicas = [
    'login' => ['loginForm', 'login', 'base', 'logout'],
    'registro' => ['registrarForm', 'registrar', 'base', 'validar'],
];

// ----------------------------------------------------
// LOGICA DE ASIGNACIÓN DEL MÉTODO POR DEFECTO (Si existe el controlador)
// ----------------------------------------------------

if (!is_null($controller) && is_null($method)) {
    $method = 'base'; // Si es /registro o /login, siempre ir a 'base'.
}

// ----------------------------------------------------
// LÓGICA DE SEGURIDAD (Maneja el caso no logueado y el caso de la raíz)
// ----------------------------------------------------

$esRutaPublica = isset($rutas_publicas[$controller]) &&
    in_array($method, $rutas_publicas[$controller]);

$noLogueado = !isset($_SESSION['usuario']);


// Caso 1: Usuario NO logueado, tratando de acceder a una ruta protegida O a la raíz (null, null)
if ($noLogueado && !$esRutaPublica) {

    // Si no está logueado Y no es una ruta pública, lo enviamos al login.
    header("Location: /login/loginForm");
    exit();

} elseif (is_null($controller) && $noLogueado) {
    // Caso 2: Si la URL es la raíz (null, null) Y está logueado, lo enviamos a home.

    $controller = 'preguntados';
    $method = 'base';

} elseif (is_null($controller) && $noLogueado) {
    $controller = 'login';
    $method = 'loginForm';
}


$router->executeController($controller, $method);