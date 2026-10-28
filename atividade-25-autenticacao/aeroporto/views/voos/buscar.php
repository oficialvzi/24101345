<?php $titulo = 'Buscar voos'; ?>
<?php require __DIR__ . '/../../includes/header.php'; ?>

<h2>Buscar voos por destino</h2>

<form method="get" action="index.php" class="busca">
    <input type="hidden" name="acao" value="buscar">

    <label for="destino">Destino</label>
    <input type="text" id="destino" name="destino" value="<?= htmlspecialchars($destino) ?>">

    <p><button type="submit" class="botao">Buscar</button></p>
</form>

<?php if ($destino !== '' && empty($mensagem)): ?>
    <p><?= count($voos) ?> resultado(s).</p>

    <?php if (!empty($voos)): ?>
        <table>
            <tr>
                <th>Voo</th>
                <th>Origem</th>
                <th>Destino</th>
                <th>Partida</th>
                <th>Chegada</th>
            </tr>
            <?php foreach ($voos as $v): ?>
                <tr>
                    <td><?= htmlspecialchars($v['numero_voo']) ?></td>
                    <td><?= htmlspecialchars($v['origem']) ?></td>
                    <td><?= htmlspecialchars($v['destino']) ?></td>
                    <td><?= htmlspecialchars($v['horario_partida']) ?></td>
                    <td><?= htmlspecialchars($v['horario_chegada']) ?></td>
                </tr>
            <?php endforeach; ?>
        </table>
    <?php endif; ?>
<?php endif; ?>

<?php require __DIR__ . '/../../includes/footer.php'; ?>
