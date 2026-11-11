-- =====================================================
-- Atividade 22 — Soft delete de voos + auditoria
-- Rodar como root, depois do schema da atividade 10
-- e dos dados de teste (banco/dados-teste.sql).
-- =====================================================
USE aeroporto;

-- -----------------------------------------------------
-- 1. Migration: coluna deleted_at na tabela VOO
--    NULL = voo ativo | data/hora = voo excluído (soft delete)
-- -----------------------------------------------------
ALTER TABLE VOO
  ADD COLUMN deleted_at DATETIME NULL DEFAULT NULL,
  ADD INDEX idx_voo_deleted_at (deleted_at);

-- -----------------------------------------------------
-- 2. Usuários do sistema (quem excluiu / restaurou)
--    Ainda não há tela de login: a sessão usa o usuário 1.
-- -----------------------------------------------------
CREATE TABLE USUARIO (
  id_usuario INT          NOT NULL AUTO_INCREMENT,
  nome       VARCHAR(100) NOT NULL,
  email      VARCHAR(100) NOT NULL,
  CONSTRAINT pk_usuario PRIMARY KEY (id_usuario),
  CONSTRAINT uq_usuario_email UNIQUE (email)
) ENGINE=InnoDB;

INSERT INTO USUARIO (id_usuario, nome, email)
VALUES (1, 'Administrador', 'admin@aeroporto.local');

-- -----------------------------------------------------
-- 3. Tabela de auditoria (InnoDB: participa da mesma transação do UPDATE)
--    Sem chave estrangeira para USUARIO de propósito: o log precisa
--    continuar existindo mesmo que o usuário seja removido um dia.
-- -----------------------------------------------------
CREATE TABLE auditoria (
  id          BIGINT      NOT NULL AUTO_INCREMENT,
  tabela      VARCHAR(50) NOT NULL,
  registro_id INT         NOT NULL,
  acao        VARCHAR(20) NOT NULL,
  usuario_id  INT         NOT NULL,
  dados_antes JSON        NULL,
  criado_em   DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT pk_auditoria PRIMARY KEY (id),
  CONSTRAINT chk_auditoria_acao CHECK (acao IN ('excluir', 'restaurar')),
  INDEX idx_auditoria_registro (tabela, registro_id)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- 4. Privilégios do usuário da aplicação
--    - VOO: sem DELETE. A aplicação só "exclui" com UPDATE.
--    - auditoria: só SELECT e INSERT. O log não pode ser alterado nem apagado pelo sistema.
-- -----------------------------------------------------
REVOKE ALL PRIVILEGES ON aeroporto.* FROM 'app_aeroporto'@'localhost';

GRANT SELECT, INSERT, UPDATE         ON aeroporto.VOO        TO 'app_aeroporto'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON aeroporto.AERONAVE   TO 'app_aeroporto'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON aeroporto.PASSAGEIRO TO 'app_aeroporto'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON aeroporto.PASSAGEM   TO 'app_aeroporto'@'localhost';
GRANT SELECT                         ON aeroporto.USUARIO    TO 'app_aeroporto'@'localhost';
GRANT SELECT, INSERT                 ON aeroporto.auditoria  TO 'app_aeroporto'@'localhost';

-- -----------------------------------------------------
-- 5. Consultas de referência
-- -----------------------------------------------------
-- excluir (soft delete):  UPDATE VOO SET deleted_at = NOW() WHERE numero_voo = :id AND deleted_at IS NULL;
-- listar os ativos:       SELECT * FROM VOO WHERE deleted_at IS NULL;
-- listar os excluídos:    SELECT * FROM VOO WHERE deleted_at IS NOT NULL;
-- restaurar:              UPDATE VOO SET deleted_at = NULL WHERE numero_voo = :id AND deleted_at IS NOT NULL;

-- -----------------------------------------------------
-- 6. Política de purga (LGPD / crescimento da tabela) — NÃO executada aqui
--    Apaga de vez os voos excluídos há mais de 5 anos e sem passagens.
--    Deve ser rodada por um DBA ou job agendado com um usuário próprio,
--    nunca pelo app_aeroporto (que não tem DELETE em VOO).
-- -----------------------------------------------------
-- DELETE FROM VOO
--  WHERE deleted_at < NOW() - INTERVAL 5 YEAR
--    AND NOT EXISTS (SELECT 1 FROM PASSAGEM p WHERE p.VOO_numero_voo = VOO.numero_voo);
