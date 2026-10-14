<?php
// models/Voo.php - todo o SQL da tabela VOO

require_once __DIR__ . '/../config/database.php';

class Voo
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::conectar();
    }

    // LISTAR: todos os voos, com os dados da aeronave (JOIN pela chave estrangeira)
    public function listar(): array
    {
        $sql = "SELECT v.numero_voo, v.origem, v.destino,
                       v.horario_partida, v.horario_chegada,
                       v.AERONAVE_numero_aeronave,
                       a.fabricante, a.modelo
                FROM VOO v
                JOIN AERONAVE a ON a.numero_aeronave = v.AERONAVE_numero_aeronave
                ORDER BY v.horario_partida";

        $stmt = $this->db->prepare($sql);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    // BUSCAR UM: usado para preencher a tela de edição
    public function buscar(int $numeroVoo): ?array
    {
        $stmt = $this->db->prepare("SELECT * FROM VOO WHERE numero_voo = :numero_voo");
        $stmt->execute([':numero_voo' => $numeroVoo]);
        $voo = $stmt->fetch();

        return $voo ?: null;
    }

    // CRIAR: numero_voo é AUTO_INCREMENT, o banco gera sozinho
    public function criar(array $dados): bool
    {
        $sql = "INSERT INTO VOO (origem, destino, horario_partida, horario_chegada, AERONAVE_numero_aeronave)
                VALUES (:origem, :destino, :horario_partida, :horario_chegada, :aeronave)";

        $stmt = $this->db->prepare($sql);

        return $stmt->execute([
            ':origem'          => $dados['origem'],
            ':destino'         => $dados['destino'],
            ':horario_partida' => $dados['horario_partida'],
            ':horario_chegada' => $dados['horario_chegada'],
            ':aeronave'        => $dados['numero_aeronave'],
        ]);
    }

    // EDITAR
    public function editar(int $numeroVoo, array $dados): bool
    {
        $sql = "UPDATE VOO
                SET origem = :origem,
                    destino = :destino,
                    horario_partida = :horario_partida,
                    horario_chegada = :horario_chegada,
                    AERONAVE_numero_aeronave = :aeronave
                WHERE numero_voo = :numero_voo";

        $stmt = $this->db->prepare($sql);

        return $stmt->execute([
            ':origem'          => $dados['origem'],
            ':destino'         => $dados['destino'],
            ':horario_partida' => $dados['horario_partida'],
            ':horario_chegada' => $dados['horario_chegada'],
            ':aeronave'        => $dados['numero_aeronave'],
            ':numero_voo'      => $numeroVoo,
        ]);
    }

    // EXCLUIR: falha (PDOException) se o voo tiver passagens, por causa da FK com ON DELETE RESTRICT
    public function excluir(int $numeroVoo): bool
    {
        $stmt = $this->db->prepare("DELETE FROM VOO WHERE numero_voo = :numero_voo");
        return $stmt->execute([':numero_voo' => $numeroVoo]);
    }
}