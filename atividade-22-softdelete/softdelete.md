# Atividade 22 — Exclusão de Voos com Soft Delete

Continuação do sistema **Aeroporto** da atividade 21 (MVC em PHP + MySQL). A exclusão de voos deixou de usar `DELETE`: o voo é apenas **marcado como excluído** (`deleted_at`), some das listagens, continua no banco e pode ser **restaurado**. Toda exclusão e restauração é registrada em uma tabela de **auditoria**, na mesma transação.

**Tecnologias:** PHP 8.5 (PDO) · MySQL 8.4 · HTML/CSS


## 1. Banco de dados (`migration-softdelete.sql`)

| Item | O que faz |
|---|---|
| `ALTER TABLE VOO ADD deleted_at DATETIME NULL DEFAULT NULL` | `NULL` = voo ativo; data/hora = voo excluído |
| `INDEX idx_voo_deleted_at` | Todas as consultas filtram por `deleted_at`; o índice evita varrer a tabela inteira quando ela crescer |
| Tabela `USUARIO` | Quem excluiu/restaurou. Ainda não há login, então a sessão usa o usuário 1 (`Administrador`) |
| Tabela `auditoria` | Igual à sugerida no roteiro, com `CHECK` na ação (`excluir`/`restaurar`) e índice por `(tabela, registro_id)`. Sem FK para `USUARIO` de propósito: o log não pode sumir se o usuário for removido |
| Privilégios | O `app_aeroporto` perdeu o `DELETE` em `VOO` e só tem `SELECT, INSERT` em `auditoria` |

### Índice único

A tabela `VOO` do projeto não tem a coluna `codigo` do exemplo: o voo é identificado por `numero_voo`, chave primária `AUTO_INCREMENT`. Um voo novo sempre recebe um número novo, então **não existe colisão** com voos excluídos.

Se um dia for criada uma coluna `codigo` única (ex.: `AD4521`), a solução seria um índice único só sobre os voos ativos, usando uma coluna gerada que vale `NULL` para os excluídos (o `UNIQUE` aceita vários `NULL`):

```sql
ALTER TABLE VOO
  ADD COLUMN codigo_ativo VARCHAR(10) AS (IF(deleted_at IS NULL, codigo, NULL)) STORED,
  ADD UNIQUE INDEX uq_voo_codigo_ativo (codigo_ativo);
```

### Purga (LGPD e crescimento da tabela)

Registro "excluído" continua no banco. A migration traz (comentado) um `DELETE` de purga para voos excluídos há mais de 5 anos e sem passagens. Ele deve ser rodado por um DBA ou job agendado com um usuário próprio, nunca pelo `app_aeroporto`, que não tem `DELETE` em `VOO`.

---

## 2. Model `Voo`

| Método | SQL | Filtro |
|---|---|---|
| `listar()` | `SELECT ... JOIN AERONAVE` | ativos |
| `buscar($id)` | `SELECT ... WHERE numero_voo = :id` | ativos (voo excluído não abre na edição) |
| `editar($id, $dados)` | `UPDATE VOO ...` | ativos (POST forjado para voo excluído não altera nada) |
| `contarPassagensAtivas($id)` | `SELECT COUNT(*) FROM PASSAGEM ... status_checkin <> 'cancelado'` | — |
| `excluir($id, $usuario)` | `UPDATE VOO SET deleted_at = NOW()` + `INSERT INTO auditoria` | ativos |
| `listarExcluidos()` | `SELECT ... + quem excluiu (auditoria/USUARIO)` | excluídos |
| `restaurar($id, $usuario)` | `UPDATE VOO SET deleted_at = NULL` + `INSERT INTO auditoria` | excluídos |
| `criar($dados)` | `INSERT INTO VOO ...` | o voo nasce ativo (`deleted_at` = `NULL`) |

Nenhum método executa `DELETE`.

---

## 3. Relatório

### Como o filtro de registros ativos foi garantido

O filtro existe **uma única vez**, em duas constantes privadas do model `Voo`:

```php
private const ATIVOS    = 'v.deleted_at IS NULL';
private const EXCLUIDOS = 'v.deleted_at IS NOT NULL';
```

As listagens e buscas de voos ativos (`listar()` e `buscar()`) passam pelo método privado `consultarAtivos()`, que monta o `SELECT` com `WHERE v.deleted_at IS NULL` sempre presente; quem chama só pode **acrescentar** condições depois dele. O `editar()`, o `excluir()` e o `restaurar()` também usam as constantes no `WHERE` do `UPDATE`. Assim nenhum método escreve o filtro à mão, e o controller e as views nem sabem que a coluna `deleted_at` existe: eles só chamam `listar()`, `buscar()` ou `listarExcluidos()`. Na prática:

- voo excluído não aparece na lista (evidência 03);
- abrir `?acao=editar&id=7` com o voo 7 excluído mostra "Voo não encontrado";
- tentar excluir de novo um voo já excluído, ou restaurar um voo ativo, cai em "não encontrado".

### Como a atomicidade da exclusão com a auditoria foi tratada

`Voo->excluir()` abre uma transação no PDO e executa, em ordem:

1. `SELECT ... FOR UPDATE` do voo ativo: trava a linha até o fim e guarda os dados que vão para `dados_antes`;
2. confere se há passagens ativas (regra do desafio 1);
3. `UPDATE VOO SET deleted_at = NOW()`;
4. `Auditoria->registrar(...)`: `INSERT` em `auditoria` com tabela, id, ação, usuário e o JSON do voo antes da mudança;
5. `commit()`.

O model `Auditoria` usa a **mesma conexão PDO** (a classe `Database` é singleton), então o `INSERT` do log entra na mesma transação do `UPDATE`. As duas tabelas são InnoDB. Qualquer exceção em qualquer passo cai no `catch (Throwable)`, que faz `rollBack()` e relança a exceção para o controller mostrar a mensagem de erro. Ou o voo é excluído **e** o log é gravado, ou nada acontece. O `restaurar()` segue o mesmo padrão.

O controller completa o fluxo: o link "Excluir" só abre uma **tela de confirmação** (GET não altera nada); a exclusão de fato é um **POST com token CSRF**. Depois, o padrão Post/Redirect/Get leva de volta à lista com uma **mensagem de sucesso ou erro**.

---

## 4. Desafios extras

### 1 — Voo com reservas ativas: exclusão impedida

Escolha: **impedir a exclusão** quando o voo tem passagens com `status_checkin` diferente de `cancelado`.

Justificativa: cancelar em cascata faria passageiros que já pagaram perderem a reserva sem aviso, sem reembolso e sem remarcação, só porque alguém clicou em "Excluir". Cancelar passagens é um processo de negócio (avisar o cliente, devolver o dinheiro), não um efeito colateral. O sistema avisa já na tela de confirmação (sem botão de excluir, evidência 04) e o model confere de novo dentro da transação, para o caso de uma passagem ser vendida entre a confirmação e o clique. Passagens já canceladas não bloqueiam.

### 2 — Falha no meio da exclusão: rollback comprovado

`testes/teste-rollback.php` troca a auditoria por uma que sempre lança exceção. O `UPDATE` roda, a gravação do log falha e o rollback desfaz o `UPDATE`:

```text
$ php testes/teste-rollback.php 3
Voo 3
  antes:  deleted_at = NULL | linhas na auditoria = 0
  dentro da transação, após o UPDATE: deleted_at = 2026-10-25 13:44:17
  exceção capturada: Falha simulada ao gravar a auditoria
  depois: deleted_at = NULL | linhas na auditoria = 0
OK: rollback desfez o UPDATE, o voo continua ativo.
```

Dentro da transação o voo chegou a ficar com `deleted_at` preenchido; depois do rollback voltou a `NULL` e nenhuma linha foi gravada na auditoria.

### 3 — Backup com `mysqldump` e restauração

Feito em um banco separado, `aeroporto_teste`, para não apagar nada do banco do sistema:

```bash
# 1. backup do banco
mysqldump -u root --single-transaction --routines --triggers --default-character-set=utf8mb4 aeroporto > banco/backup/aeroporto-backup.sql

# 2. banco de teste criado a partir do backup
mysql -u root -e "CREATE DATABASE aeroporto_teste DEFAULT CHARACTER SET utf8mb4;"
mysql -u root aeroporto_teste < banco/backup/aeroporto-backup.sql

# 3. exclusão DEFINITIVA do voo 4
mysql -u root -e "DELETE FROM aeroporto_teste.VOO WHERE numero_voo = 4;"

# 4. restauração a partir do backup
mysql -u root aeroporto_teste < banco/backup/aeroporto-backup.sql
```

```text
antes do DELETE:  4 | Rio de Janeiro | Brasília
após o DELETE:    apagados = 1  |  SELECT COUNT(*) ... numero_voo = 4  ->  0
após restaurar:   4 | Rio de Janeiro | Brasília | deleted_at = NULL
```

**Soft delete × backup:** o soft delete recupera **um registro** na hora, pelo próprio sistema, sem perder nada que aconteceu depois, mas só funciona se o dado nunca saiu do banco. O backup recupera **o banco inteiro** (inclusive após `DELETE`, `DROP` ou perda do servidor), mas volta tudo para o momento do dump: o que foi gravado depois se perde, a não ser que se restaure em outro banco e copie só a linha necessária.

---

## 5. Evidências

### 01 — Lista de voos ativos

![Lista de voos ativos](<imagens-evidencias/01-listagem-voos-ativos.jpg>)

### 02 — Tela de confirmação antes de excluir (voo 7)

![Confirmação de exclusão](<imagens-evidencias/02-confirmacao-exclusao.jpg>)

### 03 — Exclusão concluída: mensagem de sucesso e voo 7 fora da lista

![Exclusão com sucesso](<imagens-evidencias/03-exclusao-sucesso.jpg>)

### 04 — Exclusão bloqueada: voo 1 tem passagem ativa (desafio 1)

![Exclusão bloqueada](<imagens-evidencias/04-exclusao-bloqueada-passagem-ativa.jpg>)

### 05 — Tela "Voos excluídos", com data, usuário e botão Restaurar

![Voos excluídos](<imagens-evidencias/05-voos-excluidos.jpg>)

### 06 — Voo 7 restaurado

![Restauração com sucesso](<imagens-evidencias/06-restauracao-sucesso.jpg>)

### 07 — Registros na tabela `auditoria`

```text
mysql> SELECT id, tabela, registro_id, acao, usuario_id, criado_em FROM auditoria;
+----+--------+-------------+-----------+------------+---------------------+
| id | tabela | registro_id | acao      | usuario_id | criado_em           |
+----+--------+-------------+-----------+------------+---------------------+
|  1 | VOO    |           7 | excluir   |          1 | 2026-10-25 13:45:37 |
|  2 | VOO    |           7 | restaurar |          1 | 2026-10-25 13:45:48 |
+----+--------+-------------+-----------+------------+---------------------+

dados_antes do id 1:
{"origem": "Brasília", "destino": "Recife", "deleted_at": null, "numero_voo": 7,
 "horario_chegada": "2026-11-20 12:40:00", "horario_partida": "2026-11-20 10:00:00",
 "AERONAVE_numero_aeronave": 2}
```