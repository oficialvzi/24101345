<?php
// models/Voo.php - todo o SQL da tabela VOO (com soft delete)

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/Auditoria.php';

class Voo
{
    private const ATIVOS    = 'v.deleted_at IS NULL';
    private const EXCLUIDOS = 'v.deleted_at IS NOT NULL';

    private PDO $db;
    private Auditoria $auditoria;

    // A auditoria pode ser trocada (usado no teste de rollback, testes/teste-rollback.php)
    public function __construct(?Auditoria $auditoria = null)
    {
        $this->db        = Database::conectar();
        $this->auditoria = $auditoria ?? new Auditoria();
    }

    // LISTAR: somente os voos ativos, com os dados da aeronave
    public function listar(): array
    {
        return $this->consultarAtivos('', []);
    }

    // BUSCAR UM: somente se estiver ativo (voo excluído não pode ser editado)
    public function buscar(int $numeroVoo): ?array
    {
        $voos = $this->consultarAtivos('AND v.numero_voo = :numero_voo', [':numero_voo' => $numeroVoo]);

        return $voos[0] ?? null;
    }

    //buscar vulnerável
    public function buscarVulneravel(string $destino): array
    {
        $sql = "SELECT v.numero_voo, v.origem, v.destino, v.horario_partida, v.horario_chegada
                FROM VOO v WHERE " . self::ATIVOS . " AND v.destino = '$destino'";

        return $this->db->query($sql)->fetchAll();
    }

    // BUSCA POR DESTINO — versão B (segura): prepared statement, o texto vai separado como DADO
    public function buscarSeguro(string $destino): array
    {
        $stmt = $this->db->prepare(
            "SELECT v.numero_voo, v.origem, v.destino, v.horario_partida, v.horario_chegada
             FROM VOO v WHERE " . self::ATIVOS . " AND v.destino = :destino"
        );
        $stmt->execute([':destino' => $destino]);

        return $stmt->fetchAll();
    }

    // LISTAR EXCLUÍDOS: tela "Voos excluídos", com quem excluiu (última ação "excluir" da auditoria)
    public function listarExcluidos(): array
    {
        $sql = "SELECT v.numero_voo, v.origem, v.destino,
                       v.horario_partida, v.horario_chegada, v.deleted_at,
                       a.fabricante, a.modelo,
                       u.nome AS excluido_por
                FROM VOO v
                JOIN AERONAVE a ON a.numero_aeronave = v.AERONAVE_numero_aeronave
                LEFT JOIN auditoria au ON au.id = (
                    SELECT MAX(x.id) FROM auditoria x
                    WHERE x.tabela = 'VOO' AND x.registro_id = v.numero_voo AND x.acao = 'excluir'
                )
                LEFT JOIN USUARIO u ON u.id_usuario = au.usuario_id
                WHERE " . self::EXCLUIDOS . "
                ORDER BY v.deleted_at DESC";

        $stmt = $this->db->prepare($sql);
        $stmt->execute();

        return $stmt->fetchAll();
    }

    // Passagens que ainda valem (não canceladas): usadas para bloquear a exclusão
    public function contarPassagensAtivas(int $numeroVoo): int
    {
        $stmt = $this->db->prepare(
            "SELECT COUNT(*) FROM PASSAGEM
             WHERE VOO_numero_voo = :numero_voo AND status_checkin <> 'cancelado'"
        );
        $stmt->execute([':numero_voo' => $numeroVoo]);

        return (int) $stmt->fetchColumn();
    }

    // CRIAR: deleted_at fica NULL (padrão da coluna), então o voo já nasce ativo
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

    // EDITAR: só altera voo ativo (um POST forjado para um voo excluído não muda nada)
    public function editar(int $numeroVoo, array $dados): bool
    {
        $sql = "UPDATE VOO v
                SET v.origem = :origem,
                    v.destino = :destino,
                    v.horario_partida = :horario_partida,
                    v.horario_chegada = :horario_chegada,
                    v.AERONAVE_numero_aeronave = :aeronave
                WHERE v.numero_voo = :numero_voo AND " . self::ATIVOS;

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

    // EXCLUIR (soft delete): UPDATE em deleted_at + registro na auditoria, na MESMA transação.
    // Nunca executa DELETE. Se qualquer passo falhar, tudo sofre rollback.
    public function excluir(int $numeroVoo, int $usuarioId): void
    {
        $this->db->beginTransaction();

        try {
            // FOR UPDATE trava a linha até o commit: ninguém exclui/edita o mesmo voo ao mesmo tempo
            $antes = $this->travar($numeroVoo, self::ATIVOS);

            if ($antes === null) {
                throw new DomainException("Voo $numeroVoo não encontrado ou já excluído.");
            }

            // Regra escolhida: voo com passagens ativas NÃO pode ser excluído (ver README)
            if ($this->contarPassagensAtivas($numeroVoo) > 0) {
                throw new DomainException(
                    "Não é possível excluir o voo $numeroVoo: ele possui passagens ativas. Cancele as passagens antes."
                );
            }

            $stmt = $this->db->prepare(
                "UPDATE VOO v SET v.deleted_at = NOW() WHERE v.numero_voo = :numero_voo AND " . self::ATIVOS
            );
            $stmt->execute([':numero_voo' => $numeroVoo]);

            $this->auditoria->registrar('VOO', $numeroVoo, 'excluir', $usuarioId, $antes);

            $this->db->commit();
        } catch (Throwable $e) {
            $this->db->rollBack();
            throw $e;
        }
    }

    // RESTAURAR: volta deleted_at para NULL, também auditado na mesma transação
    public function restaurar(int $numeroVoo, int $usuarioId): void
    {
        $this->db->beginTransaction();

        try {
            $antes = $this->travar($numeroVoo, self::EXCLUIDOS);

            if ($antes === null) {
                throw new DomainException("Voo $numeroVoo não está na lista de excluídos.");
            }

            $stmt = $this->db->prepare(
                "UPDATE VOO v SET v.deleted_at = NULL WHERE v.numero_voo = :numero_voo AND " . self::EXCLUIDOS
            );
            $stmt->execute([':numero_voo' => $numeroVoo]);

            $this->auditoria->registrar('VOO', $numeroVoo, 'restaurar', $usuarioId, $antes);

            $this->db->commit();
        } catch (Throwable $e) {
            $this->db->rollBack();
            throw $e;
        }
    }

    // Base de todas as listagens/buscas de voos ativos: o filtro ATIVOS está sempre no WHERE
    private function consultarAtivos(string $condicaoExtra, array $parametros): array
    {
        $sql = "SELECT v.numero_voo, v.origem, v.destino,
                       v.horario_partida, v.horario_chegada,
                       v.AERONAVE_numero_aeronave,
                       a.fabricante, a.modelo
                FROM VOO v
                JOIN AERONAVE a ON a.numero_aeronave = v.AERONAVE_numero_aeronave
                WHERE " . self::ATIVOS . " $condicaoExtra
                ORDER BY v.horario_partida";

        $stmt = $this->db->prepare($sql);
        $stmt->execute($parametros);

        return $stmt->fetchAll();
    }

    // Lê e trava a linha (dentro da transação); o resultado vira o "dados_antes" da auditoria
    private function travar(int $numeroVoo, string $filtro): ?array
    {
        $stmt = $this->db->prepare(
            "SELECT v.* FROM VOO v WHERE v.numero_voo = :numero_voo AND $filtro FOR UPDATE"
        );
        $stmt->execute([':numero_voo' => $numeroVoo]);
        $voo = $stmt->fetch();

        return $voo ?: null;
    }
}
