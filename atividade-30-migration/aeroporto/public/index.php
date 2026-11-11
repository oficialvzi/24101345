<?php
// public/index.php - única porta de entrada do sistema (front controller)

// Sem login, redireciona para login.php. O usuário logado ($_SESSION['usuario_id'])
// é quem vai para a auditoria como "quem excluiu/restaurou".
require __DIR__ . '/../includes/auth.php';

require_once __DIR__ . '/../controllers/VooController.php';

// Erro que escapou dos try/catch: nunca vai para a tela, só para o log
ini_set('display_errors', '0');
set_exception_handler(function (Throwable $e): void {
    error_log($e->getMessage());
    http_response_code(500);
    echo 'Ocorreu um erro inesperado. Tente novamente mais tarde.';
});

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
