<?php
// public/logout.php - encerra a sessão e volta para o login

session_start();

$_SESSION = [];
setcookie(session_name(), '', time() - 3600, '/'); // apaga o cookie da sessão no navegador
session_destroy();

header('Location: login.php');
exit;
