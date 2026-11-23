-- 01-dw.sql - modelo estrela e carga (ETL) da atividade 33. Rodar após 00-ambiente.sql:
--   mysql -u root < 01-dw.sql
USE aeroporto_bi;
DROP TABLE IF EXISTS fato_passagem, fato_voo, dim_tempo, dim_aeroporto, dim_companhia, dim_aeronave, dim_passageiro, dim_classe;

-- ---------- DIMENSÕES ----------
CREATE TABLE dim_tempo (
  sk_tempo INT PRIMARY KEY, data DATE NOT NULL UNIQUE,
  ano SMALLINT, trimestre TINYINT, mes TINYINT, nome_mes VARCHAR(12),
  dia TINYINT, dia_semana VARCHAR(15)
);
CREATE TABLE dim_aeroporto (sk_aeroporto INT AUTO_INCREMENT PRIMARY KEY, cidade VARCHAR(45) NOT NULL UNIQUE);
CREATE TABLE dim_companhia (sk_companhia INT AUTO_INCREMENT PRIMARY KEY, sigla CHAR(2) NOT NULL UNIQUE, nome VARCHAR(45));
CREATE TABLE dim_aeronave (sk_aeronave INT PRIMARY KEY, fabricante VARCHAR(45), modelo VARCHAR(45));
CREATE TABLE dim_passageiro (sk_passageiro INT AUTO_INCREMENT PRIMARY KEY, genero VARCHAR(20), faixa_etaria VARCHAR(10));
CREATE TABLE dim_classe (sk_classe INT AUTO_INCREMENT PRIMARY KEY, classe VARCHAR(20) NOT NULL UNIQUE);

-- ---------- FATOS ----------
CREATE TABLE fato_voo (
  numero_voo INT PRIMARY KEY,                 -- dimensão degenerada (id do OLTP)
  sk_tempo INT NOT NULL, sk_aeroporto_origem INT NOT NULL, sk_aeroporto_destino INT NOT NULL,
  sk_companhia INT NOT NULL, sk_aeronave INT NOT NULL,
  qtd_voos TINYINT NOT NULL DEFAULT 1, duracao_min INT NOT NULL,
  FOREIGN KEY (sk_tempo) REFERENCES dim_tempo(sk_tempo),
  FOREIGN KEY (sk_aeroporto_origem) REFERENCES dim_aeroporto(sk_aeroporto),
  FOREIGN KEY (sk_aeroporto_destino) REFERENCES dim_aeroporto(sk_aeroporto),
  FOREIGN KEY (sk_companhia) REFERENCES dim_companhia(sk_companhia),
  FOREIGN KEY (sk_aeronave) REFERENCES dim_aeronave(sk_aeronave)
);
CREATE TABLE fato_passagem (
  id_passagem INT PRIMARY KEY,                -- dimensão degenerada
  numero_voo INT NOT NULL,                    -- dimensão degenerada
  sk_tempo INT NOT NULL, sk_aeroporto_destino INT NOT NULL, sk_companhia INT NOT NULL,
  sk_aeronave INT NOT NULL, sk_passageiro INT NOT NULL, sk_classe INT NOT NULL,
  status_checkin VARCHAR(20) NOT NULL,
  qtd_passagens TINYINT NOT NULL DEFAULT 1, valor_pago DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (sk_tempo) REFERENCES dim_tempo(sk_tempo),
  FOREIGN KEY (sk_aeroporto_destino) REFERENCES dim_aeroporto(sk_aeroporto),
  FOREIGN KEY (sk_companhia) REFERENCES dim_companhia(sk_companhia),
  FOREIGN KEY (sk_aeronave) REFERENCES dim_aeronave(sk_aeronave),
  FOREIGN KEY (sk_passageiro) REFERENCES dim_passageiro(sk_passageiro),
  FOREIGN KEY (sk_classe) REFERENCES dim_classe(sk_classe)
);

-- ---------- ETL: 1) dimensões ----------
INSERT INTO dim_tempo
SELECT DATE_FORMAT(d,'%Y%m%d')+0, d, YEAR(d), QUARTER(d), MONTH(d),
       ELT(MONTH(d),'Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'),
       DAY(d),
       ELT(WEEKDAY(d)+1,'Segunda','Terça','Quarta','Quinta','Sexta','Sábado','Domingo')
FROM (WITH RECURSIVE c(d) AS (SELECT DATE '2026-01-01' UNION ALL SELECT d + INTERVAL 1 DAY FROM c WHERE d < '2026-12-31') SELECT d FROM c) t;

INSERT INTO dim_aeroporto (cidade)
SELECT origem FROM VOO UNION SELECT destino FROM VOO;

INSERT INTO dim_companhia (sigla, nome)
SELECT DISTINCT LEFT(codigo,2), CONCAT('Companhia ', LEFT(codigo,2)) FROM VOO;   -- lacuna: derivada do prefixo

INSERT INTO dim_aeronave SELECT numero_aeronave, fabricante, modelo FROM AERONAVE;

INSERT INTO dim_passageiro (genero, faixa_etaria)
SELECT DISTINCT COALESCE(genero,'Não informado'),
  CASE WHEN TIMESTAMPDIFF(YEAR,data_nasc,'2026-11-23')<18 THEN '0-17'
       WHEN TIMESTAMPDIFF(YEAR,data_nasc,'2026-11-23')<35 THEN '18-34'
       WHEN TIMESTAMPDIFF(YEAR,data_nasc,'2026-11-23')<60 THEN '35-59' ELSE '60+' END
FROM PASSAGEIRO;

INSERT INTO dim_classe (classe) SELECT DISTINCT classe FROM PASSAGEM;

-- ---------- ETL: 2) fatos (depois das dimensões) ----------
INSERT INTO fato_voo
SELECT v.numero_voo, DATE_FORMAT(v.horario_partida,'%Y%m%d')+0,
       ao.sk_aeroporto, ad.sk_aeroporto, c.sk_companhia, v.AERONAVE_numero_aeronave,
       1, TIMESTAMPDIFF(MINUTE, v.horario_partida, v.horario_chegada)
FROM VOO v
JOIN dim_aeroporto ao ON ao.cidade = v.origem
JOIN dim_aeroporto ad ON ad.cidade = v.destino
JOIN dim_companhia c  ON c.sigla = LEFT(v.codigo,2)
WHERE v.deleted_at IS NULL;

INSERT INTO fato_passagem
SELECT p.id_passagem, p.VOO_numero_voo, f.sk_tempo, f.sk_aeroporto_destino, f.sk_companhia, f.sk_aeronave,
       dp.sk_passageiro, dc.sk_classe, p.status_checkin, 1, p.valor_pago
FROM PASSAGEM p
JOIN fato_voo f ON f.numero_voo = p.VOO_numero_voo          -- já exclui voos apagados
JOIN PASSAGEIRO ps ON ps.cpf = p.PASSAGEIRO_cpf
JOIN dim_passageiro dp ON dp.genero = COALESCE(ps.genero,'Não informado')
  AND dp.faixa_etaria = CASE WHEN TIMESTAMPDIFF(YEAR,ps.data_nasc,'2026-11-23')<18 THEN '0-17'
       WHEN TIMESTAMPDIFF(YEAR,ps.data_nasc,'2026-11-23')<35 THEN '18-34'
       WHEN TIMESTAMPDIFF(YEAR,ps.data_nasc,'2026-11-23')<60 THEN '35-59' ELSE '60+' END
JOIN dim_classe dc ON dc.classe = p.classe;
