<?php $titulo = 'Excluir voo'; ?>
<?php require __DIR__ . '/../../includes/header.php'; ?>

<h2>Excluir voo <?= (int) $voo['numero_voo'] ?>?</h2>

<div class="cartao">
    <dl>
        <dt>Origem</dt>   <dd><?= htmlspecialchars($voo['origem']) ?></dd>
        <dt>Destino</dt>  <dd><?= htmlspecialchars($voo['destino']) ?></dd>
        <dt>Partida</dt>  <dd><?= htmlspecialchars(date('d/m/Y H:i', strtotime($voo['horario_partida']))) ?></dd>
        <dt>Chegada</dt>  <dd><?= htmlspecialchars(date('d/m/Y H:i', strtotime($voo['horario_chegada']))) ?></dd>
        <dt>Aeronave</dt> <dd><?= htmlspecialchars($voo['fabricante'] . ' ' . $voo['modelo']) ?></dd>
    </dl>

    <?php if ($passagensAtivas > 0): ?>
        <div class="mensagem erro">
            Este voo tem <?= (int) $passagensAtivas ?> passagem(ns) ativa(s) e não pode ser excluído.
            Cancele as passagens antes.
        </div>
        <p><a href="index.php">Voltar</a></p>
    <?php else: ?>
        <p class="aviso">
            O voo deixará de aparecer na lista, mas continuará no banco e poderá ser
            restaurado na tela "Voos excluídos". A exclusão fica registrada na auditoria.
        </p>

        <form method="post" action="index.php?acao=excluir">
            <input type="hidden" name="numero_voo" value="<?= (int) $voo['numero_voo'] ?>">
            <input type="hidden" name="csrf" value="<?= htmlspecialchars($csrf) ?>">

            <button type="submit" class="botao perigo">Sim, excluir</button>
            <a href="index.php">Cancelar</a>
        </form>
    <?php endif; ?>
</div>

<?php require __DIR__ . '/../../includes/footer.php'; ?>
