-- 00-ambiente.sql - banco de trabalho da atividade 33 (BI). Rodar como root:
--   mysql -u root < 00-ambiente.sql
-- Cria aeroporto_bi com o OLTP do projeto (sem tocar nos outros bancos) e dados
-- sintéticos suficientes para os painéis (jan-nov/2026). Reexecutável.

DROP DATABASE IF EXISTS aeroporto_bi;
CREATE DATABASE aeroporto_bi CHARACTER SET utf8mb4;
USE aeroporto_bi;

CREATE TABLE AERONAVE (
  numero_aeronave INT PRIMARY KEY,
  fabricante VARCHAR(45), modelo VARCHAR(45)
);
CREATE TABLE PASSAGEIRO (
  cpf CHAR(11) PRIMARY KEY,
  nome_completo VARCHAR(100) NOT NULL,
  data_nasc DATE NOT NULL,
  genero VARCHAR(20)
);
CREATE TABLE VOO (
  numero_voo INT AUTO_INCREMENT PRIMARY KEY,
  codigo VARCHAR(6) NOT NULL UNIQUE,
  origem VARCHAR(45) NOT NULL,
  destino VARCHAR(45) NOT NULL,
  horario_partida DATETIME NOT NULL,
  horario_chegada DATETIME NOT NULL,
  AERONAVE_numero_aeronave INT NOT NULL,
  deleted_at DATETIME NULL,
  FOREIGN KEY (AERONAVE_numero_aeronave) REFERENCES AERONAVE(numero_aeronave),
  CHECK (horario_chegada > horario_partida)
);
CREATE TABLE PASSAGEM (
  id_passagem INT AUTO_INCREMENT PRIMARY KEY,
  numero_assento VARCHAR(5) NOT NULL,
  classe VARCHAR(20) NOT NULL DEFAULT 'Econômica',
  status_checkin VARCHAR(20) NOT NULL DEFAULT 'pendente',
  valor_pago DECIMAL(10,2) NOT NULL,
  data_reserva DATETIME NOT NULL,
  PASSAGEIRO_cpf CHAR(11) NOT NULL,
  VOO_numero_voo INT NOT NULL,
  UNIQUE (VOO_numero_voo, numero_assento),
  UNIQUE (VOO_numero_voo, PASSAGEIRO_cpf),
  FOREIGN KEY (PASSAGEIRO_cpf) REFERENCES PASSAGEIRO(cpf),
  FOREIGN KEY (VOO_numero_voo) REFERENCES VOO(numero_voo)
);

INSERT INTO AERONAVE VALUES (1,'Airbus','A320'),(2,'Boeing','737-800'),(3,'Embraer','E195');

-- 200 passageiros
INSERT INTO PASSAGEIRO
SELECT LPAD(n,11,'0'), CONCAT('Passageiro ', n),
       DATE_ADD('1960-01-01', INTERVAL (n*97 % 15000) DAY),
       ELT(1 + n % 4,'Feminino','Masculino','Outro','Não informado')
FROM (WITH RECURSIVE s(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM s WHERE n<200) SELECT n FROM s) t;

-- 120 voos entre jan e nov/2026, com destinos variados (origem/destino sempre diferentes)
INSERT INTO VOO (codigo, origem, destino, horario_partida, horario_chegada, AERONAVE_numero_aeronave)
SELECT CONCAT(ELT(1 + n % 3,'LA','GO','AD'), LPAD(n,4,'0')),
       ELT(1 + n % 6,'Brasília','São Paulo','Rio de Janeiro','Brasília','Salvador','Brasília'),
       ELT(1 + (n*7) % 8,'São Paulo','Rio de Janeiro','Salvador','Recife','Natal','Manaus','Porto Alegre','Fortaleza'),
       DATE_ADD('2026-01-03 06:00:00', INTERVAL (n*2.7) DAY) + INTERVAL (n%12) HOUR,
       DATE_ADD('2026-01-03 06:00:00', INTERVAL (n*2.7) DAY) + INTERVAL (n%12)+2 HOUR,
       1 + n % 3
FROM (WITH RECURSIVE s(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM s WHERE n<120) SELECT n FROM s) t;
-- evita origem = destino
UPDATE VOO SET destino = 'Curitiba' WHERE origem = destino;
-- 1 voo cancelado (soft delete) para testar o filtro deleted_at
UPDATE VOO SET deleted_at = NOW() WHERE numero_voo = 5;

-- 10 a 25 passagens por voo (sem repetir passageiro nem assento no mesmo voo)
INSERT INTO PASSAGEM (numero_assento, classe, status_checkin, valor_pago, data_reserva, PASSAGEIRO_cpf, VOO_numero_voo)
SELECT CONCAT(1 + k % 30, ELT(1 + k % 6,'A','B','C','D','E','F')),
       ELT(1 + (v+k) % 5 % 3,'Econômica','Executiva','Primeira'),
       ELT(1 + (v*k) % 4,'realizado','realizado','no-show','cancelado'),
       ROUND(250 + ((v*31 + k*17) % 900), 2),
       v2.horario_partida - INTERVAL (5 + (k*3) % 40) DAY,
       LPAD(1 + (v*13 + k*7) % 200, 11, '0'),
       v2.numero_voo
FROM VOO v2
JOIN (SELECT numero_voo v FROM VOO) vv ON vv.v = v2.numero_voo
JOIN (WITH RECURSIVE s(k) AS (SELECT 1 UNION ALL SELECT k+1 FROM s WHERE k<25) SELECT k FROM s) ks
  ON ks.k <= 10 + (v2.numero_voo % 16)
GROUP BY v2.numero_voo, ks.k;
