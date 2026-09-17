USE aeroporto;

-- vw_passagens_detalhadas
-- Passagens com dados do passageiro, do voo e da aeronave.
-- View com JOIN: somente leitura.
CREATE OR REPLACE VIEW vw_passagens_detalhadas AS
SELECT p.id_passagem,
       p.PASSAGEIRO_cpf AS cpf,
       pa.nome_completo,
       v.numero_voo,
       v.origem,
       v.destino,
       v.horario_partida,
       v.horario_chegada,
       a.fabricante,
       a.modelo,
       p.numero_assento,
       p.classe,
       p.status_checkin,
       p.valor_pago,
       p.data_reserva
FROM PASSAGEM   p
JOIN PASSAGEIRO pa ON pa.cpf = p.PASSAGEIRO_cpf
JOIN VOO        v  ON v.numero_voo = p.VOO_numero_voo
JOIN AERONAVE   a  ON a.numero_aeronave = v.AERONAVE_numero_aeronave;

-- vw_ocupacao_receita_voo
-- Relatório por voo: passagens vendidas, check-ins, divisão por classe e receita.
-- LEFT JOIN mantém voos sem passagens vendidas (receita 0).
-- View com agregação: somente leitura.
CREATE OR REPLACE VIEW vw_ocupacao_receita_voo AS
SELECT v.numero_voo,
       v.origem,
       v.destino,
       v.horario_partida,
       COUNT(p.id_passagem)                      AS passagens_vendidas,
       SUM(p.status_checkin = 'realizado')       AS checkins_realizados,
       SUM(p.classe = 'Econômica')               AS qtd_economica,
       SUM(p.classe IN ('Executiva','Primeira')) AS qtd_premium,
       COALESCE(SUM(p.valor_pago), 0)            AS receita_total,
       ROUND(AVG(p.valor_pago), 2)               AS ticket_medio
FROM VOO v
LEFT JOIN PASSAGEM p ON p.VOO_numero_voo = v.numero_voo
GROUP BY v.numero_voo, v.origem, v.destino, v.horario_partida;

-- vw_checkin_pendente
-- Passagens com check-in pendente.
-- View atualizável (tabela única, contém a PK).
-- WITH CHECK OPTION impede gravar registros que saiam do filtro.
CREATE OR REPLACE VIEW vw_checkin_pendente AS
SELECT id_passagem, PASSAGEIRO_cpf, VOO_numero_voo, numero_assento, classe, status_checkin
FROM PASSAGEM
WHERE status_checkin = 'pendente'
WITH CHECK OPTION;
