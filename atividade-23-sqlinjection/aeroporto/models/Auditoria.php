<?php
// models/Auditoria.php - SQL da tabela auditoria (quem fez o quê, quando)

require_once __DIR__ . '/../config/database.php';

class Auditoria
{
    private PDO $db;

    public function __construct()
    {
        // Mesma conexão do model Voo (Database é singleton): por isso o INSERT
        // do log entra na MESMA transação aberta pelo Voo->excluir()/restaurar()
        $this->db = Database::conectar();
    }

    // REGISTRAR: lança PDOException se falhar, o que faz quem chamou dar rollback
    public function registrar(string $tabela, int $registroId, string $acao, int $usuarioId, ?array $dadosAntes): void
    {
        $sql = "INSERT INTO auditoria (tabela, registro_id, acao, usuario_id, dados_antes)
                VALUES (:tabela, :registro_id, :acao, :usuario_id, :dados_antes)";

        $stmt = $this->db->prepare($sql);
        $stmt->execute([
            ':tabela'      => $tabela,
            ':registro_id' => $registroId,
            ':acao'        => $acao,
            ':usuario_id'  => $usuarioId,
            ':dados_antes' => $dadosAntes === null ? null : json_encode($dadosAntes, JSON_UNESCAPED_UNICODE),
        ]);
    }
}
