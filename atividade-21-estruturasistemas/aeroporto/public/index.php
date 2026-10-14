<?php
// public/index.php - única porta de entrada do sistema (front controller)

session_start();

require_once __DIR__ . '/../controllers/VooController.php';

$controller = new VooController();
$acao       = $_GET['acao'] ?? 'listar';

match ($acao) {
    'listar'    => $controller->listar(),
    'criar'     => $controller->criar(),
    'salvar'    => $controller->salvar(),
    'editar'    => $controller->editar(),
    'atualizar' => $controller->atualizar(),
    'excluir'   => $controller->excluir(),
    default     => $controller->listar(),
};