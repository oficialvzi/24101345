<?php
$pdo = new PDO(
    'mysql:host=localhost;dbname=aeroporto_lab;charset=utf8mb4',
    'root',
    '',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

do {
    $afetadas = $pdo->exec(
        "UPDATE VOO SET aeroporto_origem = origem
          WHERE aeroporto_origem IS NULL
          LIMIT 1000"
    );
    echo "Lote: $afetadas linhas\n";
    usleep(200000); // pausa de 0,2 s para não sobrecarregar o banco
} while ($afetadas > 0);
