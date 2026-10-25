<?php
// controllers/VooController.php - recebe as requisições, chama os models e escolhe a view

require_once __DIR__ . '/../models/Voo.php';
require_once __DIR__ . '/../models/Aeronave.php';

class VooController
{
    private Voo $voo;
    private Aeronave $aeronave;

    public function __construct()
    {
        $this->voo      = new Voo();
        $this->aeronave = new Aeronave();
    }

    public function listar(): void
    {
        $mensagem = $this->pegarMensagem();
        $voos     = $this->voo->listar();
        require __DIR__ . '/../views/voos/listar.php';
    }

    public function criar(): void
    {
        $mensagem   = $this->pegarMensagem();
        $aeronaves  = $this->aeronave->listar();
        require __DIR__ . '/../views/voos/criar.php';
    }

    public function salvar(): void
    {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            $this->redirecionar('acao=listar');
        }

        try {
            $this->voo->criar($_POST);
            $this->definirMensagem('sucesso', 'Voo cadastrado com sucesso.');
            $this->redirecionar('acao=listar');
        } catch (PDOException $e) {
            $this->definirMensagem('erro', $this->traduzirErro($e));
            $this->redirecionar('acao=criar');
        }
    }

    public function editar(): void
    {
        $numeroVoo = (int) ($_GET['id'] ?? 0);
        $voo       = $this->voo->buscar($numeroVoo);

        if ($voo === null) {
            $this->definirMensagem('erro', 'Voo não encontrado.');
            $this->redirecionar('acao=listar');
        }

        $mensagem  = $this->pegarMensagem();
        $aeronaves = $this->aeronave->listar();
        require __DIR__ . '/../views/voos/editar.php';
    }

    public function atualizar(): void
    {
        if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
            $this->redirecionar('acao=listar');
        }

        $numeroVoo = (int) ($_POST['numero_voo'] ?? 0);

        try {
            $this->voo->editar($numeroVoo, $_POST);
            $this->definirMensagem('sucesso', "Voo $numeroVoo atualizado com sucesso.");
            $this->redirecionar('acao=listar');
        } catch (PDOException $e) {
            $this->definirMensagem('erro', $this->traduzirErro($e));
            $this->redirecionar("acao=editar&id=$numeroVoo");
        }
    }

    // Passo 1 da exclusão: tela de confirmação (GET não altera nada no banco)
    public function confirmarExclusao(): void
    {
        $numeroVoo = (int) ($_GET['id'] ?? 0);
        $voo       = $this->voo->buscar($numeroVoo);

        if ($voo === null) {
            $this->definirMensagem('erro', 'Voo não encontrado ou já excluído.');
            $this->redirecionar('acao=listar');
        }

        $mensagem         = $this->pegarMensagem();
        $passagensAtivas  = $this->voo->contarPassagensAtivas($numeroVoo);
        $csrf             = $this->tokenCsrf();
        require __DIR__ . '/../views/voos/confirmar-exclusao.php';
    }

    // Passo 2 da exclusão: só por POST, com token CSRF, depois da confirmação
    public function excluir(): void
    {
        $this->exigirPostComToken();

        $numeroVoo = (int) ($_POST['numero_voo'] ?? 0);

        try {
            $this->voo->excluir($numeroVoo, $this->usuarioLogado());
            $this->definirMensagem(
                'sucesso',
                "Voo $numeroVoo excluído. Ele pode ser restaurado em \"Voos excluídos\"."
            );
        } catch (DomainException $e) {
            $this->definirMensagem('erro', $e->getMessage());
        } catch (PDOException $e) {
            $this->definirMensagem('erro', "Erro ao excluir o voo $numeroVoo. Nada foi alterado.");
        }

        $this->redirecionar('acao=listar');
    }

    // Tela "Voos excluídos"
    public function excluidos(): void
    {
        $mensagem = $this->pegarMensagem();
        $voos     = $this->voo->listarExcluidos();
        $csrf     = $this->tokenCsrf();
        require __DIR__ . '/../views/voos/excluidos.php';
    }

    public function restaurar(): void
    {
        $this->exigirPostComToken();

        $numeroVoo = (int) ($_POST['numero_voo'] ?? 0);

        try {
            $this->voo->restaurar($numeroVoo, $this->usuarioLogado());
            $this->definirMensagem('sucesso', "Voo $numeroVoo restaurado. Ele voltou para a lista de voos.");
        } catch (DomainException $e) {
            $this->definirMensagem('erro', $e->getMessage());
        } catch (PDOException $e) {
            $this->definirMensagem('erro', "Erro ao restaurar o voo $numeroVoo. Nada foi alterado.");
        }

        $this->redirecionar('acao=excluidos');
    }

    // Converte o código de erro do MySQL em uma mensagem que o usuário entende
    private function traduzirErro(PDOException $e): string
    {
        return match ($e->errorInfo[1] ?? null) {
            1452    => 'A aeronave escolhida não existe.',
            3819    => 'Dados inválidos: a origem deve ser diferente do destino e a chegada deve ser depois da partida.',
            1048    => 'Preencha todos os campos.',
            default => 'Erro ao salvar no banco de dados.',
        };
    }

    // Ainda não há login: public/index.php coloca o usuário 1 (Administrador) na sessão
    private function usuarioLogado(): int
    {
        return (int) $_SESSION['usuario']['id'];
    }

    // Token CSRF: impede que um link ou formulário de outro site exclua/restaure voos
    private function tokenCsrf(): string
    {
        $_SESSION['csrf'] ??= bin2hex(random_bytes(32));
        return $_SESSION['csrf'];
    }

    private function exigirPostComToken(): void
    {
        $token = $_POST['csrf'] ?? '';

        if ($_SERVER['REQUEST_METHOD'] !== 'POST' || !hash_equals($_SESSION['csrf'] ?? '', $token)) {
            $this->definirMensagem('erro', 'Requisição inválida. Tente novamente pela tela do sistema.');
            $this->redirecionar('acao=listar');
        }
    }

    // Mensagem "flash": guardada na sessão, mostrada uma vez na próxima tela e apagada
    private function definirMensagem(string $tipo, string $texto): void
    {
        $_SESSION['mensagem'] = ['tipo' => $tipo, 'texto' => $texto];
    }

    private function pegarMensagem(): ?array
    {
        $mensagem = $_SESSION['mensagem'] ?? null;
        unset($_SESSION['mensagem']);
        return $mensagem;
    }

    private function redirecionar(string $query): never
    {
        header("Location: index.php?$query");
        exit;
    }
}
