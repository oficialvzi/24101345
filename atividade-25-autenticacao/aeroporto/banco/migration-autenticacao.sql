-- Atividade 25 — login. Rodar como root, depois das migrations anteriores.
-- O projeto já tem a tabela USUARIO (id_usuario, nome, email, senha_hash), então ela foi
-- adaptada em vez de criar outra tabela "usuarios".
USE aeroporto;

-- Perfil do usuário da aplicação e senha obrigatória
ALTER TABLE USUARIO
    ADD COLUMN perfil VARCHAR(20) NOT NULL DEFAULT 'operador',
    MODIFY senha_hash VARCHAR(255) NOT NULL;

-- Usuários de teste, senha "senha123" (hash gerado com: php banco/gerar-hash.php senha123)
UPDATE USUARIO SET senha_hash = '$2y$12$u4McH4KCkjUSHrQFcW44puCFnBk7whi8TULNCvWzHepoxQIjtD2Ty', perfil = 'admin'    WHERE id_usuario = 1;
UPDATE USUARIO SET senha_hash = '$2y$12$qUBCN1Jefrccic/TXoPALeOzjolh2X/vy8KI6OEZ.ssYjOL5CYPti', perfil = 'operador' WHERE id_usuario = 2;

-- Código do voo (ex.: LA1234), validado no cadastro
ALTER TABLE VOO ADD COLUMN codigo VARCHAR(6) NULL UNIQUE AFTER numero_voo;
UPDATE VOO SET codigo = CONCAT('LA', 1000 + numero_voo);
ALTER TABLE VOO MODIFY codigo VARCHAR(6) NOT NULL;

-- A conta da aplicação precisa ler e-mail, hash e perfil para o login
GRANT SELECT (id_usuario, nome, email, senha_hash, perfil) ON aeroporto.USUARIO TO 'app_aeroporto'@'localhost';
