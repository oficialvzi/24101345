# Atividade 25 — Login e validação no sistema do Aeroporto

O sistema da atividade 24 ganhou login, proteção das páginas de voos, validação do cadastro no servidor e tratamento dos erros do banco. Usuários de teste: `admin@aeroporto.local` (perfil `admin`) e `operador@aeroporto.local` (perfil `operador`), os dois com a senha `senha123`.

## 1. Tabela de usuários

O projeto já tinha a tabela `USUARIO` (`id_usuario`, `nome`, `email UNIQUE`, `senha_hash`). Em vez de criar outra `usuarios`, ela foi adaptada (`aeroporto/banco/migration-autenticacao.sql`):

```sql
ALTER TABLE USUARIO
    ADD COLUMN perfil VARCHAR(20) NOT NULL DEFAULT 'operador',
    MODIFY senha_hash VARCHAR(255) NOT NULL;

-- hash gerado com: php banco/gerar-hash.php senha123  (password_hash, PASSWORD_DEFAULT)
UPDATE USUARIO SET senha_hash = '$2y$12$u4Mc...', perfil = 'admin'    WHERE id_usuario = 1;
UPDATE USUARIO SET senha_hash = '$2y$12$qUBC...', perfil = 'operador' WHERE id_usuario = 2;

-- código do voo (ex.: LA1234), que não existia na tabela VOO
ALTER TABLE VOO ADD COLUMN codigo VARCHAR(6) NULL UNIQUE AFTER numero_voo;
UPDATE VOO SET codigo = CONCAT('LA', 1000 + numero_voo);
ALTER TABLE VOO MODIFY codigo VARCHAR(6) NOT NULL;

-- a conta app_aeroporto (atividade 24) passa a ler e-mail, hash e perfil, para o login
GRANT SELECT (id_usuario, nome, email, senha_hash, perfil) ON aeroporto.USUARIO TO 'app_aeroporto'@'localhost';
```

No banco só fica o hash bcrypt, nunca a senha (evidência 01). A mesma senha gera hashes diferentes, porque cada hash tem o seu salt.

## 2. Login e logout

**`public/login.php`** (trecho):

```php
$usuario = (new Usuario())->buscarPorEmail($email);   // prepared statement: WHERE email = :email

if ($usuario !== null && password_verify($senha, $usuario['senha_hash'])) {
    session_regenerate_id(true);
    $_SESSION['usuario_id'] = (int) $usuario['id_usuario'];
    $_SESSION['usuario']    = ['nome' => $usuario['nome'], 'perfil' => $usuario['perfil']];
    header('Location: index.php?acao=listar');
    exit;
}

$erro = 'E-mail ou senha inválidos';
```

A mensagem é a mesma para senha errada e para e-mail que não existe (03 e 04), para não revelar quais e-mails estão cadastrados.

**`public/logout.php`**: limpa `$_SESSION`, apaga o cookie da sessão e chama `session_destroy()` (06).

## 3. Proteger as páginas

**`includes/auth.php`**:

```php
if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}
if (empty($_SESSION['usuario_id'])) {
    header('Location: login.php');
    exit;
}
```

Todas as telas de voos passam pelo `public/index.php` (front controller), então o `require auth.php` fica no topo dele e cobre listar, criar, editar e excluir. Sem login, a lista redireciona para o login (02 e 12: `302 Location: login.php`). Depois do logout acontece o mesmo (06).

Com o login, a auditoria passou a gravar o `usuario_id` de quem fez login, e não mais o usuário 1 fixo.

## 4. Validação do cadastro de voo

No `VooController`, `validar()` monta o array `$erros`. O `salvar()` (e também o `atualizar()`) só chama o model se ele estiver vazio. Se não estiver, reexibe o formulário com a lista de erros e com os valores digitados.

```php
if (!preg_match('/^[A-Z]{2}[0-9]{3,4}$/', $codigo)) {
    $erros[] = 'Código inválido: use duas letras e 3 ou 4 números (ex.: LA1234).';
}
if (mb_strtolower($origem) === mb_strtolower($destino)) {
    $erros[] = 'A origem deve ser diferente do destino.';
}
if ($partida === false || $partida <= time()) {
    $erros[] = 'A data de partida deve estar no futuro.';
}
```

O teste com `L12`, origem `Brasília`, destino `brasília` e partida em 2025 mostrou os 3 erros, e nada foi salvo (07). O voo `GO1234` foi salvo normalmente (08).

## 5. Erros do banco

O PDO já usava `PDO::ERRMODE_EXCEPTION` (`config/database.php`). No `salvar()`:

```php
try {
    $this->voo->criar($_POST);
    ...
} catch (PDOException $e) {
    error_log($e->getMessage());
    // reexibe o formulário com: 'Não foi possível salvar o voo.'
}
```

**Teste:** `RENAME TABLE VOO TO VOO_tmp` e depois tentar cadastrar um voo. A tela mostrou só `Não foi possível salvar o voo.` (09), e o log do servidor recebeu `SQLSTATE[42S02] ... 1146 Table 'aeroporto.voo' doesn't exist` (10). Depois a tabela voltou ao nome original.

O `index.php` também ganhou `display_errors = 0` e um `set_exception_handler` que grava no log e mostra uma mensagem genérica. Sem isso, um erro do banco em outra tela, como a lista, aparecia na tela com o caminho dos arquivos.

A busca vulnerável da atividade 23 (versão A) foi removida. Agora a conta `app_aeroporto` precisa ler `senha_hash` para o login, e uma SQL Injection voltaria a vazar os hashes.

## 6. Desafio: excluir só com perfil admin

`exigirAdmin()` no controller, chamado em `confirmarExclusao()` e `excluir()`:

```php
if (($_SESSION['usuario']['perfil'] ?? '') !== 'admin') {
    http_response_code(403);
    require __DIR__ . '/../views/403.php';
    exit;
}
```

O operador recebe a tela de 403 ao clicar em Excluir (11), e o `POST` direto em `acao=excluir` também retorna `403` (12). O admin continua excluindo normalmente.

--- 

## 7. Evidências

### 01 — Senhas gravadas como hash

![Hashes](<imagens-evidencias/01-senhas-hash.jpg>)

### 02 — Lista de voos sem login: redirecionou para o login

![Sem login](<imagens-evidencias/02-sem-login-redireciona.jpg>)

### 03 — Senha errada

![Senha errada](<imagens-evidencias/03-senha-errada.jpg>)

### 04 — E-mail inexistente: mesma mensagem

![E-mail errado](<imagens-evidencias/04-email-errado.jpg>)

### 05 — Login correto (admin)

![Login ok](<imagens-evidencias/05-login-ok.jpg>)

### 06 — Depois do logout, a lista volta para o login

![Logout](<imagens-evidencias/06-logout.jpg>)

### 07 — Voo inválido rejeitado

![Voo inválido](<imagens-evidencias/07-voo-invalido.jpg>)

### 08 — Voo válido cadastrado

![Voo válido](<imagens-evidencias/08-voo-valido.jpg>)

### 09 — Erro de banco: mensagem genérica na tela

![Erro na tela](<imagens-evidencias/09-erro-banco-tela.jpg>)

### 10 — Erro de banco: detalhe no log

![Erro no log](<imagens-evidencias/10-erro-banco-log.jpg>)

### 11 — Desafio: operador tenta excluir e recebe 403

![403](<imagens-evidencias/11-operador-403.jpg>)

### 12 — Códigos HTTP: 302 sem login e 403 para o operador

![HTTP](<imagens-evidencias/12-http-302-403.jpg>)
