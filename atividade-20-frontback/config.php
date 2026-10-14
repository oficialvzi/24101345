<?php
// config.php - credenciais e conexão com o banco
$host = 'localhost';
$db   = 'escola';
$user = 'app_escola';
$pass = 'senha_forte';

$pdo = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $pass, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
]);