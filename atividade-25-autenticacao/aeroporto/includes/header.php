<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= htmlspecialchars($titulo ?? 'Aeroporto') ?> · Aeroporto</title>
    <link rel="stylesheet" href="css/estilo.css">
</head>
<body>
    <header>
        <h1><a href="index.php">✈ Aeroporto</a></h1>
        <?php if (!empty($_SESSION['usuario_id'])): ?>
            <nav>
                <a href="index.php?acao=listar">Voos</a>
                <a href="index.php?acao=criar">Novo voo</a>
                <a href="index.php?acao=excluidos">Voos excluídos</a>
                <a href="index.php?acao=buscar">Buscar</a>
                <span class="usuario">👤 <?= htmlspecialchars($_SESSION['usuario']['nome'] . ' (' . $_SESSION['usuario']['perfil'] . ')') ?></span>
                <a href="logout.php">Sair</a>
            </nav>
        <?php endif; ?>
    </header>

    <main>
        <?php if (!empty($mensagem)): ?>
            <div class="mensagem <?= htmlspecialchars($mensagem['tipo']) ?>">
                <?= htmlspecialchars($mensagem['texto']) ?>
            </div>
        <?php endif; ?>