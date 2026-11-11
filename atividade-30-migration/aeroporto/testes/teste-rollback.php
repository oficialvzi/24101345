<?php
// testes/teste-rollback.php - Desafio 2: falha no meio da exclusão
// Rodar na pasta aeroporto/:  php testes/teste-rollback.php [numero_voo]
//
// Troca a auditoria por uma que SEMPRE falha. O Voo->excluir() executa o UPDATE
// (deleted_at = NOW()) e, logo depois, a gravação do log lança uma exceção.
// O teste confere que o rollback desfez o UPDATE: o voo continua ativo.

require_once __DIR__ . '/../models/Voo.php';

$numeroVoo = (int) ($argv[1] ?? 3);
$db        = Database::conectar();

// Auditoria "quebrada": simula, por exemplo, a tabela de log cheia ou sem permissão
$auditoriaQuebrada = new class extends Auditoria {
    public function registrar(string $tabela, int $registroId, string $acao, int $usuarioId, ?array $dadosAntes): void
    {
        // Prova de que o UPDATE já rodou dentro da transação antes da falha
        $stmt = Database::conectar()->prepare("SELECT deleted_at FROM VOO WHERE numero_voo = ?");
        $stmt->execute([$registroId]);
        echo "  dentro da transação, após o UPDATE: deleted_at = " . ($stmt->fetchColumn() ?? 'NULL') . PHP_EOL;

        throw new PDOException('Falha simulada ao gravar a auditoria');
    }
};

function estado(PDO $db, int $numeroVoo): string
{
    $stmt = $db->prepare("SELECT deleted_at FROM VOO WHERE numero_voo = ?");
    $stmt->execute([$numeroVoo]);
    return $stmt->fetchColumn() ?? 'NULL';
}

function totalAuditoria(PDO $db): int
{
    return (int) $db->query("SELECT COUNT(*) FROM auditoria")->fetchColumn();
}

echo "Voo $numeroVoo" . PHP_EOL;
echo "  antes:  deleted_at = " . estado($db, $numeroVoo) . " | linhas na auditoria = " . totalAuditoria($db) . PHP_EOL;

try {
    (new Voo($auditoriaQuebrada))->excluir($numeroVoo, 1);
    echo "  ERRO: a exclusão deveria ter falhado" . PHP_EOL;
} catch (PDOException $e) {
    echo "  exceção capturada: " . $e->getMessage() . PHP_EOL;
}

$depois = estado($db, $numeroVoo);
echo "  depois: deleted_at = $depois | linhas na auditoria = " . totalAuditoria($db) . PHP_EOL;
echo $depois === 'NULL'
    ? "OK: rollback desfez o UPDATE, o voo continua ativo." . PHP_EOL
    : "FALHOU: o voo ficou excluído sem registro na auditoria." . PHP_EOL;
