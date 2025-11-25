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

if (!is_null($controller) && is_null($method)) {
    $method = 'base';
}


$esRutaPublica = isset($rutas_publicas[$controller]) &&
    in_array($method, $rutas_publicas[$controller]);

$noLogueado = !isset($_SESSION['usuario']);


if ($noLogueado && !$esRutaPublica) {

    header("Location: /login/loginForm");
    exit();

} elseif (is_null($controller) && $noLogueado) {

    $controller = 'preguntados';
    $method = 'base';

} elseif (is_null($controller) && $noLogueado) {
    $controller = 'login';
    $method = 'loginForm';
}


$router->executeController($controller, $method);