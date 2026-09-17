# Views e Índices — Projeto Aeroporto

## Propostas de view

### View 1

```
Nome da view: vw_passagens_detalhadas
Tabelas de origem: PASSAGEM, PASSAGEIRO, VOO, AERONAVE
Tipo: JOIN
É atualizável? Não. Possui JOIN entre várias tabelas; uso somente leitura.
Problema que ela resolve: evita repetir o JOIN de 4 tabelas para exibir passagens com passageiro, voo e aeronave.
Esboço do SELECT:
SELECT p.id_passagem, p.PASSAGEIRO_cpf AS cpf, pa.nome_completo,
       v.numero_voo, v.origem, v.destino, v.horario_partida, v.horario_chegada,
       a.fabricante, a.modelo, p.numero_assento, p.classe,
       p.status_checkin, p.valor_pago, p.data_reserva
FROM PASSAGEM p
JOIN PASSAGEIRO pa ON pa.cpf = p.PASSAGEIRO_cpf
JOIN VOO v         ON v.numero_voo = p.VOO_numero_voo
JOIN AERONAVE a    ON a.numero_aeronave = v.AERONAVE_numero_aeronave;
```

### View 2

```
Nome da view: vw_ocupacao_receita_voo
Tabelas de origem: VOO, PASSAGEM
Tipo: agregação
É atualizável? Não. Usa GROUP BY, COUNT e SUM.
Problema que ela resolve: relatório de passagens vendidas, check-ins, divisão por classe e receita de cada voo.
Esboço do SELECT:
SELECT v.numero_voo, v.origem, v.destino, v.horario_partida,
       COUNT(p.id_passagem)                      AS passagens_vendidas,
       SUM(p.status_checkin = 'realizado')       AS checkins_realizados,
       SUM(p.classe = 'Econômica')               AS qtd_economica,
       SUM(p.classe IN ('Executiva','Primeira')) AS qtd_premium,
       COALESCE(SUM(p.valor_pago), 0)            AS receita_total,
       ROUND(AVG(p.valor_pago), 2)               AS ticket_medio
FROM VOO v
LEFT JOIN PASSAGEM p ON p.VOO_numero_voo = v.numero_voo
GROUP BY v.numero_voo, v.origem, v.destino, v.horario_partida;
```

### View 3

```
Nome da view: vw_checkin_pendente
Tabelas de origem: PASSAGEM
Tipo: simples
É atualizável? Sim. Tabela única, sem agregação e contém a chave primária; usa WITH CHECK OPTION para impedir gravações fora do filtro.
Problema que ela resolve: lista apenas passagens com check-in pendente.
Esboço do SELECT:
SELECT id_passagem, PASSAGEIRO_cpf, VOO_numero_voo, numero_assento, classe, status_checkin
FROM PASSAGEM
WHERE status_checkin = 'pendente'
WITH CHECK OPTION;
```

## Registro de resultados

Base de teste: 60 aeronaves, 100.000 passageiros, 24.000 voos e 400.000 passagens. Tempo médio de 10 execuções (`events_statements_summary_by_digest`).

| Consulta testada | `type` antes | `rows` antes | tempo médio antes (ms) | `type` depois | `rows` depois | tempo médio depois (ms) | Conclusão |
|---|---|---|---|---|---|---|---|
| `SELECT * FROM VOO WHERE origem='BSB' AND destino='SSA' ORDER BY horario_partida` — `idx_voo_rota_partida (origem, destino, horario_partida)` | ALL | 23.953 | 8,50 | ref | 3.000 | 5,40 | Ajudou. Linhas examinadas caíram 9x e o índice composto eliminou o filesort. Manter. |
| `SELECT COUNT(*), SUM(valor_pago) FROM PASSAGEM WHERE data_reserva >= '2026-03-01' AND data_reserva < '2026-03-08'` — `idx_passagem_data_reserva` | ALL | 398.142 | 69,03 | range | 7.647 | 11,02 | Ajudou. 6x mais rápida em coluna seletiva consultada por faixa. Manter, apesar do custo em INSERT. |
| `SELECT * FROM PASSAGEM WHERE status_checkin='pendente'` — `idx_passagem_status` | ALL | 398.142 | 155,79 | ref | 118.612 | 107,84 | Ganho parcial. Coluna de baixa seletividade (15% das linhas) e custo de escrita alto em PASSAGEM. Índice removido. |
| `SELECT * FROM AERONAVE WHERE fabricante='Embraer'` — `idx_aeronave_fabricante` | ALL | 60 | 0,30 | ref | 20 | 0,28 | Sem ganho. Tabela pequena; diferença dentro da variação normal. Índice removido. |
