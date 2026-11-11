<?php
// Uso: php migrate.php up    (aplica as pendentes)
//      php migrate.php down  (desfaz a última aplicada)

$pdo = new PDO(
    'mysql:host=localhost;dbname=aeroporto_lab;charset=utf8mb4',
    'root',
    '',
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
);

$pdo->exec("CREATE TABLE IF NOT EXISTS schema_migrations (
    version VARCHAR(100) PRIMARY KEY,
    aplicada_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
)");

// Separa o arquivo em duas partes: antes e depois da linha "-- down"
function separar(string $sql): array {
    $partes = preg_split('/^-- down\s*$/m', $sql);
    return [trim($partes[0]), trim($partes[1] ?? '')];
}

$comando = $argv[1] ?? 'up';

if ($comando === 'up') {
    $aplicadas = $pdo->query("SELECT version FROM schema_migrations")
                     ->fetchAll(PDO::FETCH_COLUMN);
    $arquivos = glob(__DIR__ . '/migrations/*.sql');
    sort($arquivos);

    foreach ($arquivos as $arquivo) {
        $versao = basename($arquivo, '.sql');
        if (in_array($versao, $aplicadas)) {
            continue;
        }
        [$up] = separar(file_get_contents($arquivo));
        $pdo->exec($up);
        $pdo->prepare("INSERT INTO schema_migrations (version) VALUES (?)")
            ->execute([$versao]);
        echo "Aplicada: $versao\n";
    }
} elseif ($comando === 'down') {
    $ultima = $pdo->query(
        "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1"
    )->fetchColumn();

    if (!$ultima) {
        echo "Nada a desfazer.\n";
        exit;
    }
    [, $down] = separar(file_get_contents(__DIR__ . "/migrations/$ultima.sql"));
    $pdo->exec($down);
    $pdo->prepare("DELETE FROM schema_migrations WHERE version = ?")
        ->execute([$ultima]);
    echo "Desfeita: $ultima\n";
}
