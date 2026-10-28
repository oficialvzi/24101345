# Atividade 24 — Privilégios no sistema do Aeroporto

A conta do SGBD `app_aeroporto` foi recriada só com os privilégios que o CRUD de voos usa. O projeto é o mesmo da atividade 23.

## 1. Conta da aplicação

**Script (`aeroporto/banco/privilegios.sql`)**, rodado como `root`:

```sql
DROP USER IF EXISTS 'app_aeroporto'@'localhost';
CREATE USER 'app_aeroporto'@'localhost' IDENTIFIED BY '********';

GRANT SELECT, INSERT, UPDATE ON aeroporto.VOO TO 'app_aeroporto'@'localhost';
GRANT SELECT ON aeroporto.AERONAVE TO 'app_aeroporto'@'localhost';
GRANT SELECT ON aeroporto.PASSAGEM TO 'app_aeroporto'@'localhost';
GRANT SELECT, INSERT ON aeroporto.auditoria TO 'app_aeroporto'@'localhost';
GRANT SELECT (id_usuario, nome) ON aeroporto.USUARIO TO 'app_aeroporto'@'localhost';
```

As outras tabelas entram porque as telas de voos as consultam: `AERONAVE` (lista no formulário), `PASSAGEM` (bloqueia excluir voo com passagens), `auditoria` (registro de excluir/restaurar) e `USUARIO` (coluna "Excluído por"). Em `USUARIO`, só `id_usuario` e `nome`, sem e-mail e senha.

**`SHOW GRANTS`:** `USAGE` global; `SELECT, INSERT, UPDATE` em `voo`; `SELECT` em `aeronave` e `passagem`; `SELECT, INSERT` em `auditoria`; `SELECT (id_usuario, nome)` em `usuario`. Nenhum `DELETE` nem `DROP` (evidência 01).

## 2. Conexão do PHP

O `config/database.php` já lia o usuário e a senha do `.env` (desde a atividade 22), então só o `.env` mudou, com a senha nova:

```ini
DB_USER=app_aeroporto
DB_PASS="********"
```

No `VooController`, o `traduzirErro()` agora manda a mensagem do banco para o `error_log` e mostra `Operação não permitida.` para os erros de privilégio (1142 e 1143).

## 3. Teste do CRUD

| Operação | Esperado | O que aconteceu? |
|---|---|---|
| Listar voos (`SELECT`) | funciona | Funcionou, a lista aparece normal (02) |
| Criar voo (`INSERT`) | funciona | Funcionou, voo 8 cadastrado (02) |
| Editar voo (`UPDATE`) | funciona | Funcionou, destino do voo 8 trocado para Natal (03) |
| Excluir voo (`DELETE`) | **erro** | Pela tela **funcionou**, porque é soft delete (`UPDATE ... SET deleted_at = NOW()`) (04). Pelo terminal, `DELETE FROM VOO` deu `ERROR 1142 (42000): DELETE command denied to user 'app_aeroporto'@'localhost' for table 'voo'` (05) |

`DROP TABLE VOO` também deu `ERROR 1142` (05). Quem impede apagar de verdade é a conta sem `DELETE`, não o botão da tela.

## 4. Discussão

**1. O que mudou para a Maria? E para a conexão?**

Para a Maria, nada: ela continua entrando com o login dela e usando as mesmas telas. O que mudou foi a conexão do PHP com o MySQL, que antes podia tudo como `root` e agora só faz `SELECT/INSERT/UPDATE` nas tabelas do CRUD. A Maria é um usuário da aplicação (linha da tabela `usuarios`), e `app_aeroporto` é um usuário do SGBD, usado por todos.

**2. Quem decide se a Maria pode excluir um voo?**

O código PHP, porque o banco só vê a conta `app_aeroporto`, igual para todos, e não sabe quem é a Maria nem qual o perfil dela. O banco define o limite máximo da aplicação inteira; dentro desse limite, a regra por perfil (atendente pode ou não excluir) é do PHP.

**3. O que um atacante faria com SQL Injection agora? E com `root`?**

Agora ele fica preso aos privilégios da conta: pode ler voos, aeronaves, passagens e a auditoria, e alterar ou inserir voos, mas não apaga linhas, não derruba tabelas e não lê e-mail e senha de `USUARIO`. O mesmo payload `UNION` da atividade 23, que vazava os hashes, agora dá `ERROR 1143` (06). Com `root`, ele poderia ler e apagar qualquer tabela de qualquer banco, dar `DROP DATABASE` e criar contas para si.

## 5. Desafio: conta só de leitura

Script em `aeroporto/banco/desafio-relatorios.sql`.

1. `INSERT` em `VOO` com `SELECT ON aeroporto.*`: `ERROR 1142 (42000): INSERT command denied to user 'relatorios'@'localhost' for table 'voo'` (07).
2. Depois do `REVOKE`, foi concedido `SELECT (nome_completo, data_nasc)` em `PASSAGEIRO` (no projeto a tabela não tem `id`; o `cpf` é a chave).
3. `SELECT cpf FROM PASSAGEIRO`: `ERROR 1143 (42000): SELECT command denied to user 'relatorios'@'localhost' for column 'cpf' in table 'passageiro'`. Já `SELECT nome_completo` funciona (08).
4. Alternativa: view `vw_passageiros_publico` só com `nome_completo` e `data_nasc`, com `SELECT` concedido apenas nela (08).

---

## 6. Evidências

### 01 — `SHOW GRANTS` da conta `app_aeroporto`

![SHOW GRANTS](<imagens-evidencias/01-show-grants.jpg>)

### 02 — Criar voo (`INSERT`) e listar (`SELECT`)

![Criar voo](<imagens-evidencias/02-criar-voo.jpg>)

### 03 — Editar voo (`UPDATE`)

![Editar voo](<imagens-evidencias/03-editar-voo.jpg>)

### 04 — Excluir pela tela: soft delete funciona

![Soft delete](<imagens-evidencias/04-excluir-soft-delete.jpg>)

### 05 — `DELETE` e `DROP` negados no terminal

![DELETE e DROP negados](<imagens-evidencias/05-delete-drop-negados.jpg>)

### 06 — SQL Injection (`UNION`, versão A) bloqueada pelo privilégio de coluna

![SQLi negada](<imagens-evidencias/06-sqli-union-negado.jpg>)

### 07 — Desafio: `INSERT` negado para `relatorios`

![INSERT negado](<imagens-evidencias/07-relatorios-insert-negado.jpg>)

### 08 — Desafio: `cpf` negado, view liberada

![CPF negado](<imagens-evidencias/08-relatorios-cpf-negado.jpg>)
