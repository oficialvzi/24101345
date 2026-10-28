<?php $titulo = 'Editar voo'; ?>
<?php require __DIR__ . '/../../includes/header.php'; ?>

<h2>Editar voo <?= (int) $voo['numero_voo'] ?></h2>

<?php if (!empty($erros)): ?>
    <div class="mensagem erro">
        <p>Corrija os campos abaixo:</p>
        <ul>
            <?php foreach ($erros as $e): ?>
                <li><?= htmlspecialchars($e) ?></li>
            <?php endforeach; ?>
        </ul>
    </div>
<?php endif; ?>

<form method="post" action="index.php?acao=atualizar">
    <input type="hidden" name="numero_voo" value="<?= (int) $voo['numero_voo'] ?>">

    <?php require __DIR__ . '/_formulario.php'; ?>

    <p>
        <button type="submit" class="botao">Salvar alterações</button>
        <a href="index.php">Cancelar</a>
    </p>
</form>

<?php require __DIR__ . '/../../includes/footer.php'; ?>