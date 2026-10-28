<?php
// models/Aeronave.php - SQL da tabela AERONAVE (usado no <select> do formulário de voos)

require_once __DIR__ . '/../config/database.php';

class Aeronave
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::conectar();
    }

    public function listar(): array
    {
        $stmt = $this->db->prepare(
            "SELECT numero_aeronave, fabricante, modelo FROM AERONAVE ORDER BY numero_aeronave"
        );
        $stmt->execute();

        return $stmt->fetchAll();
    }
}