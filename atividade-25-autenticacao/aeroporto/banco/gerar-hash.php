<?php
// banco/gerar-hash.php - gera o hash da senha para gravar em USUARIO.senha_hash
// Rodar: php banco/gerar-hash.php senha123

echo password_hash($argv[1] ?? 'senha123', PASSWORD_DEFAULT), PHP_EOL;
