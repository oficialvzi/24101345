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

    public function excluir(): void
    {
        $numeroVoo = (int) ($_GET['id'] ?? 0);

        try {
            $this->voo->excluir($numeroVoo);
            $this->definirMensagem('sucesso', "Voo $numeroVoo excluído com sucesso.");
        } catch (PDOException $e) {
            $this->definirMensagem('erro', $this->traduzirErro($e));
        }

        $this->redirecionar('acao=listar');
    }

    // Converte o código de erro do MySQL em uma mensagem que o usuário entende
    private function traduzirErro(PDOException $e): string
    {
        return match ($e->errorInfo[1] ?? null) {
            1451    => 'Não é possível excluir: este voo possui passagens vendidas.',
            1452    => 'A aeronave escolhida não existe.',
            3819    => 'Dados inválidos: a origem deve ser diferente do destino e a chegada deve ser depois da partida.',
            1048    => 'Preencha todos os campos.',
            default => 'Erro ao salvar no banco de dados.',
        };
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