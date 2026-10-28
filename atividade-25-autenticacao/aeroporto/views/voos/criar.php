<?php $titulo = 'Novo voo'; ?>
<?php require __DIR__ . '/../../includes/header.php'; ?>

<h2>Novo voo</h2>

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

<form method="post" action="index.php?acao=salvar">
    <?php $voo ??= []; ?>
    <?php require __DIR__ . '/_formulario.php'; ?>

    <p>
        <button type="submit" class="botao">Cadastrar</button>
        <a href="index.php">Cancelar</a>
    </p>
</form>

<?php require __DIR__ . '/../../includes/footer.php'; ?>