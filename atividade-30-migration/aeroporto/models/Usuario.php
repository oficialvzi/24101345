<?php
// models/Usuario.php - SQL da tabela USUARIO (login)

require_once __DIR__ . '/../config/database.php';

class Usuario
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::conectar();
    }

    // Busca pelo e-mail com prepared statement; null se não existir
    public function buscarPorEmail(string $email): ?array
    {
        $stmt = $this->db->prepare(
            "SELECT id_usuario, nome, email, senha_hash, perfil FROM USUARIO WHERE email = :email"
        );
        $stmt->execute([':email' => $email]);

        return $stmt->fetch() ?: null;
    }
}
