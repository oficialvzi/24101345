-- =====================================================
-- Projeto AEROPORTO — schema com regras de integridade
-- MySQL 8.0.16+ ou MariaDB 10.2+ (necessário para CHECK)
-- =====================================================
DROP SCHEMA IF EXISTS aeroporto;
CREATE SCHEMA aeroporto DEFAULT CHARACTER SET utf8mb4;
USE aeroporto;

-- -----------------------------------------------------
-- AERONAVE
-- -----------------------------------------------------
CREATE TABLE AERONAVE (
  numero_aeronave INT         NOT NULL,
  fabricante      VARCHAR(45) NULL,
  modelo          VARCHAR(45) NULL,
  CONSTRAINT pk_aeronave PRIMARY KEY (numero_aeronave)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- PASSAGEIRO
-- -----------------------------------------------------
CREATE TABLE PASSAGEIRO (
  cpf           CHAR(11)     NOT NULL,
  nome_completo VARCHAR(100) NOT NULL,
  data_nasc     DATE         NOT NULL,
  genero        VARCHAR(20)  NULL,
  CONSTRAINT pk_passageiro        PRIMARY KEY (cpf),
  CONSTRAINT chk_passageiro_cpf   CHECK (cpf REGEXP '^[0-9]{11}$'),
  CONSTRAINT chk_passageiro_nasc  CHECK (data_nasc >= '1900-01-01'),
  CONSTRAINT chk_passageiro_genero
    CHECK (genero IS NULL OR genero IN ('Feminino','Masculino','Outro','Não informado'))
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- VOO
-- -----------------------------------------------------
CREATE TABLE VOO (
  numero_voo               INT         NOT NULL AUTO_INCREMENT,
  origem                   VARCHAR(45) NOT NULL,
  destino                  VARCHAR(45) NOT NULL,
  horario_partida          DATETIME    NOT NULL,
  horario_chegada          DATETIME    NOT NULL,
  AERONAVE_numero_aeronave INT         NOT NULL,
  CONSTRAINT pk_voo PRIMARY KEY (numero_voo),
  CONSTRAINT fk_voo_aeronave FOREIGN KEY (AERONAVE_numero_aeronave)
    REFERENCES AERONAVE (numero_aeronave)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_voo_rota     CHECK (origem <> destino),
  CONSTRAINT chk_voo_horarios CHECK (horario_chegada > horario_partida)
) ENGINE=InnoDB;

-- -----------------------------------------------------
-- PASSAGEM
-- -----------------------------------------------------
CREATE TABLE PASSAGEM (
  id_passagem     INT           NOT NULL AUTO_INCREMENT,
  numero_assento  VARCHAR(5)    NOT NULL,
  classe          VARCHAR(20)   NOT NULL DEFAULT 'Econômica',
  status_checkin  VARCHAR(20)   NOT NULL DEFAULT 'pendente',
  valor_pago      DECIMAL(10,2) NOT NULL,
  data_reserva    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PASSAGEIRO_cpf  CHAR(11)      NOT NULL,
  VOO_numero_voo  INT           NOT NULL,
  CONSTRAINT pk_passagem PRIMARY KEY (id_passagem),
  CONSTRAINT uq_passagem_assento_voo UNIQUE (VOO_numero_voo, numero_assento),
  CONSTRAINT uq_passagem_passageiro_voo UNIQUE (VOO_numero_voo, PASSAGEIRO_cpf),
  CONSTRAINT fk_passagem_passageiro FOREIGN KEY (PASSAGEIRO_cpf)
    REFERENCES PASSAGEIRO (cpf)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_passagem_voo FOREIGN KEY (VOO_numero_voo)
    REFERENCES VOO (numero_voo)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_passagem_valor  CHECK (valor_pago >= 0),
  CONSTRAINT chk_passagem_classe CHECK (classe IN ('Econômica','Executiva','Primeira')),
  CONSTRAINT chk_passagem_status CHECK (status_checkin IN ('pendente','realizado','no-show','cancelado')),
  CONSTRAINT chk_passagem_assento CHECK (numero_assento REGEXP '^[0-9]{1,3}[A-F]$')
) ENGINE=InnoDB;
