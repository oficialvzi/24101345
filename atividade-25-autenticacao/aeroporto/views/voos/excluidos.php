<?php $titulo = 'Voos excluídos'; ?>
<?php require __DIR__ . '/../../includes/header.php'; ?>

<h2>Voos excluídos</h2>

<p>Voos marcados como excluídos (soft delete). Eles não aparecem na lista de voos, mas podem ser restaurados.</p>

<?php if (empty($voos)): ?>
    <p>Nenhum voo excluído.</p>
<?php else: ?>
    <table>
        <tr>
            <th>Voo</th>
            <th>Origem</th>
            <th>Destino</th>
            <th>Partida</th>
            <th>Aeronave</th>
            <th>Excluído em</th>
            <th>Excluído por</th>
            <th>Ações</th>
        </tr>
        <?php foreach ($voos as $v): ?>
            <tr>
                <td><?= (int) $v['numero_voo'] ?></td>
                <td><?= htmlspecialchars($v['origem']) ?></td>
                <td><?= htmlspecialchars($v['destino']) ?></td>
                <td><?= htmlspecialchars(date('d/m/Y H:i', strtotime($v['horario_partida']))) ?></td>
                <td><?= htmlspecialchars($v['fabricante'] . ' ' . $v['modelo']) ?></td>
                <td><?= htmlspecialchars(date('d/m/Y H:i:s', strtotime($v['deleted_at']))) ?></td>
                <td><?= htmlspecialchars($v['excluido_por'] ?? '—') ?></td>
                <td>
                    <form class="inline" method="post" action="index.php?acao=restaurar"
                          onsubmit="return confirm('Restaurar o voo <?= (int) $v['numero_voo'] ?>?')">
                        <input type="hidden" name="numero_voo" value="<?= (int) $v['numero_voo'] ?>">
                        <input type="hidden" name="csrf" value="<?= htmlspecialchars($csrf) ?>">
                        <button type="submit" class="botao">Restaurar</button>
                    </form>
                </td>
            </tr>
        <?php endforeach; ?>
    </table>
<?php endif; ?>

<?php require __DIR__ . '/../../includes/footer.php'; ?>
