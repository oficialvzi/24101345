<?php
// config/database.php - conexão com o banco em um único lugar

class Database
{
    private static ?PDO $conexao = null;

    public static function conectar(): PDO
    {
        if (self::$conexao === null) {
            // Credenciais vêm do .env (fora da pasta pública e fora do Git)
            $env = parse_ini_file(__DIR__ . '/../.env');

            if ($env === false) {
                throw new RuntimeException('Arquivo .env não encontrado. Copie o .env.example para .env.');
            }

            self::$conexao = new PDO(
                "mysql:host={$env['DB_HOST']};dbname={$env['DB_NAME']};charset=utf8mb4",
                $env['DB_USER'],
                $env['DB_PASS'],
                [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                ]
            );
        }

        return self::$conexao;
    }
}