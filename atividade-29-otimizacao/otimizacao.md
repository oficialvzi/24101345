# Atividade 29 - Otimização de Consultas

## Parte 1 — Consultas sem índices
| Consulta | Tabela  | type | key   | rows | Observações |
| -------- | ------- | ---- | ----- | ---- | ----------- |
| Q1       | locacao | ALL  |NULL   |498636|Using where  |
| Q2       | cliente |eq_ref|PRIMARY|1     |Using where  |
| Q2       | locacao | ALL  |NULL   |498636|NULL         |

Actual time: 91.4 ms

### Por que o MySQL não teve alternativa a ler a tabela inteira?  
Porque não havia nenhum índice sobre id_cliente (nem sobre cpf); só existe a chave primária em id. Sem um índice que permita localizar diretamente as linhas desejadas, o MySQL precisa fazer uma varredura completa (type = ALL), lendo as ~500 mil linhas e aplicando o filtro em cada uma.

## Parte 2 — Consultas com índices
| Consulta | Tabela  | type   | key           | rows |
| -------- | ------- | ------ | ------------- | ---- |
| Q1       | locacao | ref    |idx_loc_cliente|10    | 
| Q2       | cliente | ref    |idx_cli_cpf    |1     | 
| Q2       | locacao | ref    |idx_loc_cliente|9     |

Actual time: 0.05 ms

| Filtro               | Parcela aproximada da tabela | type | key          |
| -------------------- | ---------------------------- | ---- | ------------ |
| status = 'cancelada' | cerca de 2%  (18332 rows)    | ref  |idx_loc_status|
| status = 'concluida' | cerca de 73%  (249318 rows)  | ref  |idx_loc_status|

### O índice idx_loc_status existe nos dois casos. Por que o resultado do plano deveria ser diferente?
A seletividade é muito diferente. `cancelada` atinge só ~2% da tabela, então o índice reduz muito a leitura. `concluida` atinge ~74% (370.000 linhas reais), e usar o índice exigiria centenas de milhares de buscas individuais na tabela, o que tende a custar mais que uma leitura sequencial; em teoria o otimizador escolheria `ALL`. No meu ambiente (MySQL 8.4) ele subestimou o número de linhas (249.318 estimadas contra 370.000 reais) e ainda usou o índice, mas o `EXPLAIN ANALYZE` mostrou que a varredura completa foi mais rápida (68,9 ms contra 170 ms com o índice).

## Parte 3 — Índices que o MySQL ignora
Índices criados: `idx_loc_data` em `locacao(data_retirada)` e `idx_cli_nome` em `cliente(nome)`.

### 3A — Função aplicada na coluna
Reescrita: `SELECT * FROM locacao WHERE data_retirada >= '2025-06-01' AND data_retirada < '2025-07-01';`

Comparação: antes `ALL`, sem índice, lendo 498636 linhas; depois `range` com `idx_loc_data`, lendo cerca de 24756 linhas.

### 3B — LIKE com % no início
Reescrita: `SELECT * FROM cliente WHERE nome LIKE 'Cliente 123%';`

Comparação: antes `ALL` (50196 linhas); depois `range` com `idx_cli_nome` (111 linhas).

### 3C — Conversão implícita de tipo
Reescrita: `SELECT * FROM cliente WHERE cpf = '00000004242';`

Comparação: antes `ALL` (50196 linhas, mesmo com `idx_cli_cpf` listado em `possible_keys`); depois `ref` com `idx_cli_cpf` (1 linha).

| Caso | type antes | type depois | Por que o índice não era usado? |
| ---- | ---------- | ----------- | ------------------------------- |
| 3A   | ALL        | range       | A função `DATE_FORMAT` é aplicada à coluna, então o MySQL precisa calcular o valor de cada linha e não consegue buscar no índice, que guarda os valores originais de `data_retirada`. Com uma faixa de datas, a coluna fica "pura" e o índice pode ser percorrido. |
| 3B   | ALL        | range       | O índice é ordenado pelo início do texto. Com `%` no começo, o prefixo é desconhecido e não há por onde começar a busca; com o prefixo fixo (`'Cliente 123%'`) dá para localizar a faixa no índice. |
| 3C   | ALL        | ref         | `cpf` é `VARCHAR` e foi comparado com um número. O MySQL converte cada `cpf` para número antes de comparar, o que impede o uso do índice (e ainda poderia dar resultados incorretos, pois `'00000004242'` vira 4242). Comparando com texto, os tipos coincidem e o índice é usado. |

## Parte 4 — Índice composto
Índice criado: `idx_loc_cli_data` em `locacao(id_cliente, data_retirada)`.

| Consulta | type  | key              | rows  |
| -------- | ----- | ---------------- | ----- |
| (a) id_cliente + data_retirada | range | idx_loc_cli_data | 3     |
| (b) só data_retirada           | range | idx_loc_data     | 24756 |

Na consulta (a), o MySQL escolheu o índice `idx_loc_cli_data` (o composto), em vez de `idx_loc_cliente`, porque ele resolve os dois filtros ao mesmo tempo: usa `id_cliente = 4242` e já limita a faixa de `data_retirada` dentro dele (só 3 linhas).

### Desafio — índice de data invisível
Com `idx_loc_data` invisível, a consulta (b) passou para `type = ALL`, `key = NULL`, 498636 linhas. O composto **não ajuda**: a coluna `data_retirada` é a segunda do índice `(id_cliente, data_retirada)`, e um índice só é aproveitado a partir da primeira coluna (regra do prefixo mais à esquerda). Sem filtrar `id_cliente`, o MySQL não consegue localizar a faixa de datas dentro do composto. Depois do teste, o índice voltou a ficar visível e a (b) voltou a usar `idx_loc_data`.

## Parte 5 — Fechamento
1. **Maior ganho:** a Q1 (locações de um cliente). Sem índice, o plano era `ALL` com `key = NULL` e ~498 mil linhas lidas (91,4 ms); com `idx_loc_cliente` virou `ref` com ~10 linhas lidas (0,05 ms), cerca de 1800 vezes mais rápido.
2. **Índice existente e não usado:** o 3C. Existia `idx_cli_cpf`, listado em `possible_keys`, mas o plano ficou `key = NULL` porque o `cpf` (texto) foi comparado com um número (`cpf = 4242`), forçando uma conversão implícita em cada linha. Outros casos: 3A (função na coluna), 3B (`LIKE '%...'`) e a consulta (b) quando só o composto estava disponível (a coluna `data_retirada` não era a primeira do índice).
3. **Custo na escrita:** cada índice é uma estrutura extra que precisa ser atualizada em todo `INSERT`, `DELETE` e em `UPDATE` das colunas indexadas. Quanto mais índices, mais lentas as escritas, e eles ainda ocupam espaço em disco e memória. Por isso só vale criar os índices que as consultas realmente usam.