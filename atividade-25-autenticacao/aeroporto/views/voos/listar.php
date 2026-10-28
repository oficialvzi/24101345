<?php $titulo = 'Voos'; ?>
<?php require __DIR__ . '/../../includes/header.php'; ?>

<h2>Voos cadastrados</h2>

<p><a class="botao" href="index.php?acao=criar">+ Novo voo</a></p>

<?php if (empty($voos)): ?>
    <p>Nenhum voo ativo.</p>
<?php else: ?>
    <table>
        <tr>
            <th>Voo</th>
            <th>Código</th>
            <th>Origem</th>
            <th>Destino</th>
            <th>Partida</th>
            <th>Chegada</th>
            <th>Aeronave</th>
            <th>Ações</th>
        </tr>
        <?php foreach ($voos as $v): ?>
            <tr>
                <td><?= (int) $v['numero_voo'] ?></td>
                <td><?= htmlspecialchars($v['codigo']) ?></td>
                <td><?= htmlspecialchars($v['origem']) ?></td>
                <td><?= htmlspecialchars($v['destino']) ?></td>
                <td><?= htmlspecialchars(date('d/m/Y H:i', strtotime($v['horario_partida']))) ?></td>
                <td><?= htmlspecialchars(date('d/m/Y H:i', strtotime($v['horario_chegada']))) ?></td>
                <td><?= htmlspecialchars($v['fabricante'] . ' ' . $v['modelo']) ?></td>
                <td>
                    <a href="index.php?acao=editar&id=<?= (int) $v['numero_voo'] ?>">Editar</a>
                    <a class="excluir"
                       href="index.php?acao=confirmarExclusao&id=<?= (int) $v['numero_voo'] ?>">Excluir</a>
                </td>
            </tr>
        <?php endforeach; ?>
    </table>
<?php endif; ?>

<?php require __DIR__ . '/../../includes/footer.php'; ?>