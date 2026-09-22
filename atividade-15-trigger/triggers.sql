-- =====================================================================
-- Atividade 15 — Triggers
-- Aluno: Arthur Choi Braga (24101345)
-- Banco: aeroporto (MariaDB / XAMPP)
--
-- Tabelas do modelo:
--   AERONAVE   — aeronaves da frota (numero_aeronave, fabricante, modelo)
--   PASSAGEIRO — passageiros cadastrados (cpf, nome, nascimento, gênero)
--   VOO        — voos com origem, destino, horários e aeronave
--   PASSAGEM   — passagens vendidas (assento, classe, check-in, valor)
--                ligando PASSAGEIRO e VOO
--
-- Pré-requisito: banco criado pelo sql_integridade.sql (atividade 10).
-- =====================================================================

USE aeroporto;

-- ---------------------------------------------------------------------
-- Ajuste no modelo (necessário para o Desafio 3)
-- Coluna com o saldo de assentos livres de cada voo. O CHECK impede que
-- o saldo fique negativo, ou seja, que um voo lotado venda mais passagens.
-- ---------------------------------------------------------------------
ALTER TABLE VOO
  ADD COLUMN assentos_disponiveis INT NOT NULL DEFAULT 180,
  ADD CONSTRAINT chk_voo_assentos CHECK (assentos_disponiveis >= 0);

-- Ajusta o saldo dos voos que já têm passagens vendidas
UPDATE VOO v
SET v.assentos_disponiveis = 180 - (SELECT COUNT(*) FROM PASSAGEM p
                                    WHERE p.VOO_numero_voo = v.numero_voo);

-- ---------------------------------------------------------------------
-- Tabela de auditoria (Desafio 2)
-- ---------------------------------------------------------------------
CREATE TABLE LOG_ALTERACAO_PASSAGEM (
  id_log          INT          NOT NULL AUTO_INCREMENT,
  id_passagem     INT          NOT NULL,
  campo_alterado  VARCHAR(30)  NOT NULL,
  valor_anterior  VARCHAR(50)  NULL,
  valor_novo      VARCHAR(50)  NULL,
  data_alteracao  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  usuario         VARCHAR(100) NOT NULL,
  CONSTRAINT pk_log_alteracao_passagem PRIMARY KEY (id_log)
) ENGINE=InnoDB;

DROP TRIGGER IF EXISTS trg_passagem_valida_partida;
DROP TRIGGER IF EXISTS trg_passagem_auditoria;
DROP TRIGGER IF EXISTS trg_passagem_atualiza_assentos;

DELIMITER $$

-- ---------------------------------------------------------------------
-- Desafio 1 — BEFORE INSERT em PASSAGEM
-- Regra: não é possível vender passagem para um voo que já partiu.
-- Busca o horário de partida do voo informado (NEW.VOO_numero_voo) e,
-- se ele for anterior ou igual ao momento atual, cancela o INSERT.
-- (Não pode ser feito com CHECK porque CHECK não aceita NOW().)
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_passagem_valida_partida
BEFORE INSERT ON PASSAGEM
FOR EACH ROW
BEGIN
  DECLARE v_partida DATETIME;

  SELECT horario_partida INTO v_partida
  FROM VOO
  WHERE numero_voo = NEW.VOO_numero_voo;

  IF v_partida <= NOW() THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Venda bloqueada: o voo informado ja partiu.';
  END IF;
END$$

-- ---------------------------------------------------------------------
-- Desafio 2 — AFTER UPDATE em PASSAGEM
-- Registra no log toda mudança de valor_pago (tarifa) e de
-- status_checkin, guardando o valor antigo (OLD) e o novo (NEW),
-- a data/hora e o usuário do banco.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_passagem_auditoria
AFTER UPDATE ON PASSAGEM
FOR EACH ROW
BEGIN
  IF OLD.valor_pago <> NEW.valor_pago THEN
    INSERT INTO LOG_ALTERACAO_PASSAGEM
      (id_passagem, campo_alterado, valor_anterior, valor_novo, usuario)
    VALUES
      (NEW.id_passagem, 'valor_pago', OLD.valor_pago, NEW.valor_pago, CURRENT_USER());
  END IF;

  IF OLD.status_checkin <> NEW.status_checkin THEN
    INSERT INTO LOG_ALTERACAO_PASSAGEM
      (id_passagem, campo_alterado, valor_anterior, valor_novo, usuario)
    VALUES
      (NEW.id_passagem, 'status_checkin', OLD.status_checkin, NEW.status_checkin, CURRENT_USER());
  END IF;
END$$

-- ---------------------------------------------------------------------
-- Desafio 3 — AFTER INSERT em PASSAGEM
-- Ao emitir uma passagem, diminui em 1 o saldo de assentos do voo.
-- O voo é localizado pela chave estrangeira NEW.VOO_numero_voo.
-- ---------------------------------------------------------------------
CREATE TRIGGER trg_passagem_atualiza_assentos
AFTER INSERT ON PASSAGEM
FOR EACH ROW
BEGIN
  UPDATE VOO
  SET assentos_disponiveis = assentos_disponiveis - 1
  WHERE numero_voo = NEW.VOO_numero_voo;
END$$

DELIMITER ;

-- =====================================================================
-- BATERIA DE TESTES
-- =====================================================================

-- Dados usados nos testes: um voo futuro (100), um voo que já partiu
-- (101) e um passageiro novo.
INSERT INTO VOO (numero_voo, origem, destino, horario_partida, horario_chegada, AERONAVE_numero_aeronave)
VALUES (100, 'BSB', 'REC', '2026-12-15 07:00:00', '2026-12-15 09:40:00', 1002),
       (101, 'GRU', 'POA', '2026-01-10 18:00:00', '2026-01-10 19:45:00', 1002);

INSERT INTO PASSAGEIRO (cpf, nome_completo, data_nasc, genero)
VALUES ('11122233344', 'Carla Mendes', '2001-06-21', 'Feminino');

-- ---------------------------------------------------------------------
-- Teste 1.1 — Passagem para voo que já partiu (deve ser BLOQUEADO)
-- Esperado: ERROR 1644 (45000): Venda bloqueada: o voo informado ja partiu.
-- ---------------------------------------------------------------------
INSERT INTO PASSAGEM (numero_assento, valor_pago, PASSAGEIRO_cpf, VOO_numero_voo)
VALUES ('5A', 350.00, '11122233344', 101);

-- ---------------------------------------------------------------------
-- Teste 1.2 — Passagem para voo futuro (deve ser ACEITO)
-- ---------------------------------------------------------------------
INSERT INTO PASSAGEM (numero_assento, valor_pago, PASSAGEIRO_cpf, VOO_numero_voo)
VALUES ('5A', 350.00, '11122233344', 100);

-- ---------------------------------------------------------------------
-- Teste 2 — Auditoria
-- Altera a tarifa e faz o check-in da passagem criada no teste 1.2.
-- Esperado: 2 linhas no log, com valor antigo, novo, data e usuário.
-- ---------------------------------------------------------------------
UPDATE PASSAGEM
SET valor_pago = 420.00, status_checkin = 'realizado'
WHERE numero_assento = '5A' AND VOO_numero_voo = 100;

SELECT * FROM LOG_ALTERACAO_PASSAGEM;

-- ---------------------------------------------------------------------
-- Teste 3 — Sincronização de assentos
-- Esperado: o saldo do voo 100 cai de 179 para 178.
-- ---------------------------------------------------------------------
SELECT numero_voo, assentos_disponiveis FROM VOO WHERE numero_voo = 100;   -- antes

INSERT INTO PASSAGEM (numero_assento, valor_pago, PASSAGEIRO_cpf, VOO_numero_voo)
VALUES ('5B', 350.00, '98765432100', 100);

SELECT numero_voo, assentos_disponiveis FROM VOO WHERE numero_voo = 100;   -- depois
