# Atividade 33 - Painéis do Aeroporto (BI)

Banco de trabalho: `aeroporto_bi` (criado por `00-ambiente.sql`). A estrela e o ETL estão em `01-dw.sql` e as cinco consultas em `02-paineis.sql`. Evidências em `imagens-evidencias/`.

## 1. Modelo estrela

Uma fato só não atende aos painéis: voo e passagem são acontecimentos diferentes. Um voo tem muitos passageiros, então na fato por passagem ele se repete e `COUNT(*)` conta passageiros em vez de voos (2076 contra 119 voos válidos). Por isso são **duas fatos com dimensões compartilhadas**.

### Grão
- Voo: Uma linha da fato representa um voo realizado, sem registrar os voos apagados (deleted_at IS NULL).
- Passagem: Uma linha da fato representa uma passagem vendida.

### Medidas

| Fato | Medida | Origem | Tipo |
|---|---|---|---|
| FATO_PASSAGEM | `valor_pago` | coluna do OLTP | aditiva |
| FATO_PASSAGEM | `qtd_passagens` (= 1) | criada no ETL | aditiva |
| FATO_VOO | `qtd_voos` (= 1) | criada no ETL | aditiva |
| FATO_VOO | `duracao_min` | `horario_chegada - horario_partida` no ETL | aditiva (a média é não aditiva e sai na consulta) |

Regra: passagem com `status_checkin = 'cancelado'` não conta como passageiro. A carga mantém todas as passagens e as consultas filtram com `WHERE status <> 'cancelado'`, então o status fica na fato.

### Dimensões

| Dimensão | Atributos principais | Usada por |
|---|---|---|
| `dim_tempo` | sk_tempo, data, ano, trimestre, mês, nome do mês, dia, dia da semana | as duas fatos (data de partida do voo) |
| `dim_aeroporto` | sk_aeroporto, cidade | FATO_VOO (origem e destino) e FATO_PASSAGEM (destino) |
| `dim_companhia` | sk_companhia, sigla, nome | as duas fatos |
| `dim_aeronave` | sk_aeronave, fabricante, modelo | as duas fatos |
| `dim_passageiro` | sk_passageiro, gênero, faixa etária (sem nome e sem CPF, por LGPD) | FATO_PASSAGEM |
| `dim_classe` | sk_classe, classe | FATO_PASSAGEM |

Decisões:
- **Dimensão com papéis (role-playing):** `dim_aeroporto` é uma tabela só. A `fato_voo` tem duas chaves para ela, `sk_aeroporto_origem` e `sk_aeroporto_destino`.
- **Dimensões degeneradas:** `numero_voo` e `id_passagem` ficam na fato como identificadores, sem tabela própria. O `numero_voo` permite `COUNT(DISTINCT)` se for preciso.
- **Assento** fica de fora: é único por voo e não serve para agrupar um painel.
- O `ano` na dimensão tempo evita misturar janeiro de 2026 com janeiro de 2027 num painel "por mês".

### Desenho da estrela

```
                      dim_tempo
                          |
 dim_companhia ------ FATO_VOO ------ dim_aeronave
                      /       \
        dim_aeroporto          dim_aeroporto
          (origem)               (destino)


 dim_passageiro ---+                +--- dim_classe
                   |                |
 dim_tempo --------+-- FATO_PASSAGEM +--- dim_aeroporto (destino)
                   |                |
 dim_companhia ----+                +--- dim_aeronave
```

---

## 2. Fichas dos painéis

**PAINEL 1: Destinos mais frequentes**
- Pergunta de negócio: para quais cidades o aeroporto mais envia voos?
- Indicador (medida): `qtd_voos` (soma)
- Dimensões usadas: `dim_aeroporto` (destino)
- Filtros do painel: período (mês ou ano), companhia
- Gráfico sugerido: barras horizontais ordenadas (top 5)
- Operação OLAP: ( ) roll up ( ) drill down ( ) slice ( ) dice ( ) pivot. Marcar **slice** ao filtrar o período. O ranking em si é uma agregação por destino.

**PAINEL 2: Número de passageiros por mês**
- Pergunta de negócio: como o movimento de passageiros evolui mês a mês?
- Indicador (medida): `qtd_passagens` (soma), excluindo passagens canceladas
- Dimensões usadas: `dim_tempo` (ano, mês)
- Filtros do painel: ano, companhia, destino
- Gráfico sugerido: linha (evolução no tempo)
- Operação OLAP: **drill down** (de ano para mês, para dia) e **roll up** (de mês para trimestre)

**PAINEL 3: Número de voos**
- Pergunta de negócio: quantos voos o aeroporto operou, no total e por mês?
- Indicador (medida): `qtd_voos` (soma)
- Dimensões usadas: `dim_tempo`
- Filtros do painel: ano, companhia, aeronave
- Gráfico sugerido: cartão com o total (indicador principal) e colunas por mês
- Operação OLAP: **roll up** (do mês para o total do ano) e **slice** por companhia

**PAINEL 4: Companhia aérea mais atuante**
- Pergunta de negócio: qual companhia opera mais voos e transporta mais passageiros, e qual a participação de cada uma?
- Indicador (medida): `qtd_voos` e `qtd_passagens` (somas) e o percentual de participação
- Dimensões usadas: `dim_companhia`
- Filtros do painel: período, destino
- Gráfico sugerido: barras (ranking) com rótulo de percentual, ou rosca para a participação
- Operação OLAP: **dice** (vários filtros ao mesmo tempo, como período e destino)

**PAINEL 5 (livre): Receita por classe, por mês**
- Pergunta de negócio: quanto cada classe (Econômica, Executiva, Primeira) arrecada em cada mês?
- Indicador (medida): `valor_pago` (soma), excluindo passagens canceladas
- Dimensões usadas: `dim_tempo` (mês) e `dim_classe`
- Filtros do painel: ano, companhia
- Gráfico sugerido: colunas empilhadas por mês
- Operação OLAP: **pivot** (a classe passa de linhas para colunas)

---

## 3. Estrutura das consultas

Todas partem de uma fato e juntam só as dimensões necessárias. O código completo e executável está em `02-paineis.sql`.

**Painel 1: destinos mais frequentes**
```sql
SELECT a.cidade AS destino, SUM(f.qtd_voos) AS voos
FROM fato_voo f
JOIN dim_aeroporto a ON a.sk_aeroporto = f.sk_aeroporto_destino
GROUP BY a.cidade
ORDER BY voos DESC
LIMIT 5;
```
- `GROUP BY`: `a.cidade`
- `WHERE`: nenhum neste painel (num filtro de período iria `t.ano` e `t.mes` com `JOIN dim_tempo`)
- Operação OLAP: agregação por destino (slice se filtrar o período)

**Painel 2: passageiros por mês**
```sql
SELECT t.ano, t.mes, t.nome_mes, SUM(f.qtd_passagens) AS passageiros
FROM fato_passagem f
JOIN dim_tempo t ON t.sk_tempo = f.sk_tempo
WHERE f.status_checkin <> 'cancelado'
GROUP BY t.ano, t.mes, t.nome_mes
ORDER BY t.ano, t.mes;
```
- `GROUP BY`: `t.ano, t.mes, t.nome_mes`
- `WHERE`: `status_checkin <> 'cancelado'`
- Operação OLAP: drill down / roll up no tempo

**Painel 3: número de voos**
```sql
SELECT t.ano, t.mes, t.nome_mes, SUM(f.qtd_voos) AS voos
FROM fato_voo f
JOIN dim_tempo t ON t.sk_tempo = f.sk_tempo
GROUP BY t.ano, t.mes, t.nome_mes
ORDER BY t.ano, t.mes;
```
- `GROUP BY`: `t.ano, t.mes, t.nome_mes`
- `WHERE`: nenhum (a fato já tem só voos não apagados)
- Operação OLAP: roll up (para o total, `SUM(f.qtd_voos)` sem agrupar)

**Painel 4: companhia mais atuante**
```sql
SELECT c.sigla, v.voos, p.passageiros,
       ROUND(100 * v.voos / SUM(v.voos) OVER (), 1) AS pct_voos
FROM dim_companhia c
JOIN (SELECT sk_companhia, SUM(qtd_voos) voos
      FROM fato_voo GROUP BY sk_companhia) v ON v.sk_companhia = c.sk_companhia
JOIN (SELECT sk_companhia, SUM(qtd_passagens) passageiros
      FROM fato_passagem WHERE status_checkin <> 'cancelado'
      GROUP BY sk_companhia) p ON p.sk_companhia = c.sk_companhia
ORDER BY v.voos DESC, p.passageiros DESC;
```
- `GROUP BY`: `sk_companhia`, dentro de cada subconsulta
- `WHERE`: `status_checkin <> 'cancelado'` (só na fato de passagens)
- Operação OLAP: dice
- Cuidado: cada fato é agregada **separadamente** e só depois juntada, para não multiplicar linhas.

**Painel 5: receita por classe por mês**
```sql
SELECT t.mes, t.nome_mes,
       SUM(CASE WHEN c.classe = 'Econômica' THEN f.valor_pago ELSE 0 END) AS economica,
       SUM(CASE WHEN c.classe = 'Executiva' THEN f.valor_pago ELSE 0 END) AS executiva,
       SUM(CASE WHEN c.classe = 'Primeira'  THEN f.valor_pago ELSE 0 END) AS primeira
FROM fato_passagem f
JOIN dim_tempo t  ON t.sk_tempo = f.sk_tempo
JOIN dim_classe c ON c.sk_classe = f.sk_classe
WHERE f.status_checkin <> 'cancelado'
GROUP BY t.mes, t.nome_mes
ORDER BY t.mes;
```
- `GROUP BY`: `t.mes, t.nome_mes`
- `WHERE`: `status_checkin <> 'cancelado'`
- Operação OLAP: pivot (o `CASE` transforma as classes em colunas)

### Conferência dos resultados
- Voos somam **119**, igual à tabela `VOO` sem o voo apagado (e não 2076 nem 120).
- A fato de passagens tem **2061** linhas: as 2076 do OLTP menos as 15 do voo apagado.
- Painel 4: LA 40 voos, GO 40, AD 39 (soma 119); a participação soma 100%.

---

## 4. ETL e wireframe

**ETL em 3 linhas** (`01-dw.sql`)
- **Extract:** lê `VOO`, `PASSAGEM`, `PASSAGEIRO` e `AERONAVE` do OLTP.
- **Transform:** descarta voos com `deleted_at` preenchido; cria `qtd_voos = 1`, `qtd_passagens = 1` e `duracao_min` (chegada menos partida); deriva a companhia do prefixo do `codigo`; troca CPF e nome por gênero e faixa etária; gera as chaves substitutas e a dimensão tempo.
- **Load:** primeiro as dimensões (`dim_tempo`, `dim_aeroporto`, `dim_companhia`, `dim_aeronave`, `dim_passageiro`, `dim_classe`), depois `fato_voo` e por último `fato_passagem` (que depende da fato de voos).

**Wireframe do painel 2 (passageiros por mês)**

```
+------------------------------------------------------------------+
|  PASSAGEIROS POR MÊS                                             |
|                                                                  |
|  Ano: [2026 v]   Companhia: [Todas v]   Destino: [Todos v]       |
|                                                                  |
|  +------------------+                                            |
|  |   1.769          |   total de passageiros no período          |
|  |   passageiros    |   (indicador principal)                    |
|  +------------------+                                            |
|                                                                  |
|  passageiros                                                     |
|  200 |            *                                              |
|  150 |   *   *       *   *   *   *   *   *                       |
|  100 | *                                       *                 |
|   50 |                                                           |
|      +--Jan-Fev-Mar-Abr-Mai-Jun-Jul-Ago-Set-Out-Nov-Dez--        |
|                       (gráfico de linha)                         |
|                                                                  |
|  Clique em um mês para ver os dias (drill down)                  |
+------------------------------------------------------------------+
```

---

## 5. Lacunas do modelo OLTP

- **Companhia aérea:** não existe tabela/coluna de companhia (só o prefixo do `codigo` do voo). Afeta o painel 4. Solução usada: derivar a sigla das duas primeiras letras do código. O ideal é criar a tabela `COMPANHIA` no OLTP.
- Aeroporto como entidade: `origem`/`destino` são texto livre (`VARCHAR(45)`), sem código IATA, o que pode gerar a mesma cidade escrita de formas diferentes.
- Soft delete: voos com `deleted_at` preenchido devem ser excluídos na carga.
- Status do voo: o OLTP não registra se o voo foi realizado ou cancelado. Usamos `deleted_at IS NULL` como aproximação de "voo realizado".
- Não há registro do embarque real nem de atraso, só `horario_partida` e `horario_chegada` planejados.
- Não há capacidade de assentos por aeronave, então não dá para calcular a taxa de ocupação.
