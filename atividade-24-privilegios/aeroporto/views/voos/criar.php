<?php $titulo = 'Novo voo'; ?>
<?php require __DIR__ . '/../../includes/header.php'; ?>

<h2>Novo voo</h2>

<form method="post" action="index.php?acao=salvar">
    <?php $voo = []; ?>
    <?php require __DIR__ . '/_formulario.php'; ?>

    <p>
        <button type="submit" class="botao">Cadastrar</button>
        <a href="index.php">Cancelar</a>
    </p>
</form>

<?php require __DIR__ . '/../../includes/footer.php'; ?>