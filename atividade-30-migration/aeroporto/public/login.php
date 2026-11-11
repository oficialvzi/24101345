<?php
// public/login.php - formulário de login (e-mail e senha)

session_start();
require_once __DIR__ . '/../models/Usuario.php';

if (!empty($_SESSION['usuario_id'])) {
    header('Location: index.php');
    exit;
}

$email = '';
$erro  = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = trim($_POST['email'] ?? '');
    $senha = $_POST['senha'] ?? '';

    try {
        $usuario = (new Usuario())->buscarPorEmail($email);
    } catch (PDOException $e) {
        error_log($e->getMessage());
        $usuario = null;
    }

    // Mesma mensagem para e-mail inexistente ou senha errada: não revela qual dos dois falhou
    if ($usuario !== null && password_verify($senha, $usuario['senha_hash'])) {
        session_regenerate_id(true); // novo id de sessão após o login (evita fixação de sessão)
        $_SESSION['usuario_id'] = (int) $usuario['id_usuario'];
        $_SESSION['usuario']    = ['nome' => $usuario['nome'], 'perfil' => $usuario['perfil']];
        header('Location: index.php?acao=listar');
        exit;
    }

    $erro = 'E-mail ou senha inválidos';
}

$titulo   = 'Login';
$mensagem = $erro ? ['tipo' => 'erro', 'texto' => $erro] : null;
require __DIR__ . '/../includes/header.php';
?>

<h2>Entrar</h2>

<form method="post" action="login.php">
    <label for="email">E-mail</label>
    <input type="email" id="email" name="email" required value="<?= htmlspecialchars($email) ?>">

    <label for="senha">Senha</label>
    <input type="password" id="senha" name="senha" required>

    <p><button type="submit" class="botao">Entrar</button></p>
</form>

<?php require __DIR__ . '/../includes/footer.php'; ?>
