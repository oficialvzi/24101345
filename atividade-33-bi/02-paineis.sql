-- 02-paineis.sql - as cinco consultas dos painéis. Rodar: mysql -u root aeroporto_bi -t < 02-paineis.sql
-- Painel 1: destinos mais frequentes (ranking, top 5)
SELECT a.cidade AS destino, SUM(f.qtd_voos) AS voos
FROM fato_voo f JOIN dim_aeroporto a ON a.sk_aeroporto = f.sk_aeroporto_destino
GROUP BY a.cidade ORDER BY voos DESC LIMIT 5;

-- Painel 2: passageiros por mês (evolução)
SELECT t.ano, t.mes, t.nome_mes, SUM(f.qtd_passagens) AS passageiros
FROM fato_passagem f JOIN dim_tempo t ON t.sk_tempo = f.sk_tempo
WHERE f.status_checkin <> 'cancelado'
GROUP BY t.ano, t.mes, t.nome_mes ORDER BY t.ano, t.mes;

-- Painel 3: número de voos (total e por mês)
SELECT t.ano, t.mes, t.nome_mes, SUM(f.qtd_voos) AS voos
FROM fato_voo f JOIN dim_tempo t ON t.sk_tempo = f.sk_tempo
GROUP BY t.ano, t.mes, t.nome_mes ORDER BY t.ano, t.mes;

-- Painel 4: companhia mais atuante (voos, passageiros e participação)
SELECT c.sigla, v.voos, p.passageiros,
       ROUND(100 * v.voos / SUM(v.voos) OVER (), 1) AS pct_voos
FROM dim_companhia c
JOIN (SELECT sk_companhia, SUM(qtd_voos) voos FROM fato_voo GROUP BY sk_companhia) v ON v.sk_companhia = c.sk_companhia
JOIN (SELECT sk_companhia, SUM(qtd_passagens) passageiros FROM fato_passagem
      WHERE status_checkin <> 'cancelado' GROUP BY sk_companhia) p ON p.sk_companhia = c.sk_companhia
ORDER BY v.voos DESC, p.passageiros DESC;

-- Painel 5 (livre): receita por classe e por mês (pivot)
SELECT t.mes, t.nome_mes,
       SUM(CASE WHEN c.classe = 'Econômica' THEN f.valor_pago ELSE 0 END) AS economica,
       SUM(CASE WHEN c.classe = 'Executiva' THEN f.valor_pago ELSE 0 END) AS executiva,
       SUM(CASE WHEN c.classe = 'Primeira'  THEN f.valor_pago ELSE 0 END) AS primeira
FROM fato_passagem f
JOIN dim_tempo t ON t.sk_tempo = f.sk_tempo
JOIN dim_classe c ON c.sk_classe = f.sk_classe
WHERE f.status_checkin <> 'cancelado'
GROUP BY t.mes, t.nome_mes ORDER BY t.mes;
