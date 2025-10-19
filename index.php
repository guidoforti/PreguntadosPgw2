<?php
session_start();
include("helper/ConfigFactory.php");
$configFactory = new ConfigFactory();
$router = $configFactory->get("router");

$controller = isset($_GET['controller']) ? $_GET['controller'] : null;
$method = isset($_GET['method']) ? $_GET['method'] : null;
$router->executeController($controller, $method);