# Atividade Prática: Exclusão de Voos com Soft Delete

**Disciplina:** Administração de Banco de Dados
**Aula 21:** Backup e Recuperação no contexto MVC

---

## 1. Enunciado

Crie uma solução de exclusão de voos usando o conceito de **Soft Delete**.

Em vez de apagar o registro com `DELETE`, o sistema deve apenas marcá-lo como excluído. O voo deixa de aparecer nas listagens, mas continua no banco e pode ser restaurado.

## 2. Contexto

Soft delete protege contra **exclusão acidental de um registro**. Ele não substitui o backup, que protege contra a perda do banco inteiro. Nesta atividade você vai trabalhar a camada de proteção que cabe ao código (Model e Controller).

Considere uma tabela `voos` já existente no projeto, por exemplo:

| Coluna    | Tipo        | Observação                    |
| --------- | ----------- | ----------------------------- |
| `id`      | INT         | Chave primária                |
| `codigo`  | VARCHAR(10) | Código do voo (ex.: `AD4521`) |
| `origem`  | VARCHAR(50) |                               |
| `destino` | VARCHAR(50) |                               |
| `partida` | DATETIME    |                               |

Ajuste os nomes ao esquema que você já usa.

## 3. Requisitos mínimos

1. **Migration:** adicionar a coluna `deleted_at` (`DATETIME NULL DEFAULT NULL`) à tabela `voos`.
2. **Model:**
   - criar o método `excluir($id)`, que executa um `UPDATE` preenchendo `deleted_at` com a data e hora atuais (nunca um `DELETE`);
   - fazer **todas** as listagens e buscas de voos filtrarem apenas os registros ativos (`deleted_at IS NULL`);
   - criar o método `restaurar($id)`, que volta `deleted_at` para `NULL`.
3. **Controller:** criar a ação de excluir, com **confirmação** do usuário antes da exclusão e **mensagem de retorno** (sucesso ou erro).
4. **Auditoria:** registrar quem excluiu e quando, em uma tabela de auditoria, **na mesma transação** da exclusão. Se a gravação do log falhar, a exclusão deve sofrer `rollback`.
5. **Tela "Voos excluídos":** listar os voos com `deleted_at` preenchido, com um botão para restaurar cada um.

## 4. Tabela de auditoria sugerida

```sql
CREATE TABLE auditoria (
  id          BIGINT AUTO_INCREMENT PRIMARY KEY,
  tabela      VARCHAR(50),
  registro_id INT,
  acao        VARCHAR(20),
  usuario_id  INT,
  dados_antes JSON,
  criado_em   DATETIME DEFAULT NOW()
);
```

## 5. Consultas de referência

```sql
-- adicionar a coluna
ALTER TABLE voos
  ADD COLUMN deleted_at DATETIME NULL;

-- excluir (soft delete)
UPDATE voos SET deleted_at = NOW() WHERE id = :id;

-- listar somente os ativos
SELECT * FROM voos WHERE deleted_at IS NULL;

-- listar os excluídos
SELECT * FROM voos WHERE deleted_at IS NOT NULL;

-- restaurar
UPDATE voos SET deleted_at = NULL WHERE id = :id;
```

## 6. Pontos de atenção

- **Consulta sem filtro:** esquecer o `WHERE deleted_at IS NULL` faz voos excluídos reaparecerem. Centralize o filtro no Model, em vez de repeti-lo em cada consulta.
- **Índice único:** se o `codigo` do voo tem índice único, um novo voo com o mesmo código colide com o registro excluído. Pense em como tratar isso (por exemplo, um índice composto).
- **Dados "apagados" continuam no banco:** em sistemas reais, isso exige uma política de purga (atenção à LGPD).
- **Crescimento da tabela:** indexe `deleted_at` e considere eliminar registros muito antigos periodicamente.

## 7. Entregáveis

- Código-fonte do projeto (Model, Controller e Views alteradas).
- Script SQL da migration e da tabela de auditoria.
- Um breve relatório (meia página) explicando:
  - como o filtro de registros ativos foi garantido;
  - como a atomicidade da exclusão com a auditoria foi tratada.

## 8. Critérios de avaliação (pesos sugeridos)

| Critério                              | Peso |
| ------------------------------------- | ---- |
| Soft delete e restauração funcionando | 40%  |
| Filtro consistente nas consultas      | 20%  |
| Auditoria na mesma transação          | 20%  |
| Organização MVC e código              | 20%  |

## 9. Desafio extra

1. **Voo com reservas ativas:** impedir a exclusão ou cancelar as reservas em cascata, justificando a escolha.
2. **Falha no meio da exclusão:** simular um erro depois do `UPDATE` e comprovar que o `rollback` desfaz a operação.
3. **Backup e restauração:** gerar um backup com `mysqldump`, apagar um voo **definitivamente** (`DELETE`) em um banco de teste e restaurá-lo a partir do backup. Em seguida, explique em duas ou três linhas a diferença entre recuperar um voo por soft delete e recuperá-lo por backup.