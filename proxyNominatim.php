<?php

if (!isset($_GET['q'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Falta parámetro q']);
    exit;
}

$search = urlencode($_GET['q']);
$url = "https://nominatim.openstreetmap.org/search?q=$search&format=json&addressdetails=1";

// Inicializamos cURL
$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_USERAGENT, "MiApp/1.0"); // obligatorio para Nominatim
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

// Devolvemos la respuesta al frontend
header('Content-Type: application/json');
http_response_code($httpCode);
echo $response;
