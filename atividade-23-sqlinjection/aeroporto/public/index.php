<?php
// public/index.php - única porta de entrada do sistema (front controller)

session_start();

// Ainda não há tela de login: todas as ações são feitas pelo usuário 1 (tabela USUARIO).
// É esse id que vai para a auditoria como "quem excluiu/restaurou".
$_SESSION['usuario'] ??= ['id' => 1, 'nome' => 'Administrador'];

require_once __DIR__ . '/../controllers/VooController.php';

$controller = new VooController();
$acao       = $_GET['acao'] ?? 'listar';

match ($acao) {
    'listar'            => $controller->listar(),
    'criar'             => $controller->criar(),
    'salvar'            => $controller->salvar(),
    'editar'            => $controller->editar(),
    'atualizar'         => $controller->atualizar(),
    'confirmarExclusao' => $controller->confirmarExclusao(),
    'excluir'           => $controller->excluir(),
    'excluidos'         => $controller->excluidos(),
    'buscar'            => $controller->buscar(),
    'restaurar'         => $controller->restaurar(),
    default             => $controller->listar(),
};
