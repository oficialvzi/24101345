-- =====================================================================
-- atividade 16 - locking, deadlocks e mvcc
-- aluno: arthur choi braga (24101345)
-- banco: aeroporto (mariadb / xampp)
--
-- ideia da atividade: dois passageiros tentando reservar o mesmo assento
-- de um voo ao mesmo tempo. o modelo sugerido no enunciado (tabelas
-- aeronaves/voos/assentos/reservas) já existe na prática nesse projeto
-- desde a atividade 08: AERONAVE, VOO, PASSAGEIRO e PASSAGEM. um assento
-- "reservado" aqui é simplesmente uma linha em PASSAGEM pra aquele voo,
-- e a atividade 10 já criou um UNIQUE (VOO_numero_voo, numero_assento)
-- que impede vender o mesmo assento duas vezes - ou seja, a "restrição
-- de unicidade" do item 13 do enunciado já estava feita.
--
-- pré-requisito: banco criado pelo sql_integridade.sql (atividade 10) +
-- triggers.sql (atividade 15, que criou a coluna assentos_disponiveis).
-- =====================================================================

USE aeroporto;

-- ---------------------------------------------------------------------
-- passageiros novos pros testes de concorrência, sem passagem ainda no
-- voo 100 (senão o UNIQUE de passageiro+voo da atividade 10 atrapalha)
-- ---------------------------------------------------------------------
INSERT INTO PASSAGEIRO (cpf, nome_completo, data_nasc, genero)
VALUES
  ('33344455566', 'Diego Farias', '1993-03-12', 'Masculino'),
  ('44455566677', 'Elisa Prado', '1997-08-05', 'Feminino'),
  ('55566677788', 'Fabio Nogueira', '1990-01-20', 'Masculino'),
  ('66677788899', 'Gabriela Rocha', '1994-07-14', 'Feminino');

-- ---------------------------------------------------------------------
-- procedure do desafio (item 21 do enunciado)
--
-- recebe passageiro, voo e assento e faz a reserva de forma segura:
-- trava a linha do voo com FOR UPDATE (assim só uma venda por vez
-- acontece pra aquele voo), confere de novo se o assento já foi
-- vendido já dentro do lock, e só depois insere a passagem. se der
-- qualquer erro no meio do caminho (voo que não existe, assento já
-- vendido, passageiro inválido etc) o handler desfaz tudo com ROLLBACK
-- e devolve o erro original pra quem chamou.
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_reservar_assento;

DELIMITER $$

CREATE PROCEDURE sp_reservar_assento(
  IN p_cpf CHAR(11),
  IN p_numero_voo INT,
  IN p_numero_assento VARCHAR(5),
  IN p_valor_pago DECIMAL(10,2)
)
BEGIN
  DECLARE v_voo_existe INT DEFAULT 0;
  DECLARE v_ja_vendido INT DEFAULT 0;

  -- se qualquer coisa der errado aqui dentro, desfaz a transação e
  -- repassa o erro original pra quem chamou a procedure
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  START TRANSACTION;

  -- trava a linha do voo. quem chegar primeiro segura esse lock até
  -- comitar, então a segunda sessão que tentar mexer no mesmo voo fica
  -- esperando aqui (é o FOR UPDATE que o enunciado pede)
  SELECT COUNT(*) INTO v_voo_existe
  FROM VOO
  WHERE numero_voo = p_numero_voo
  FOR UPDATE;

  IF v_voo_existe = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Voo informado nao existe.';
  END IF;

  -- já com o lock na mão, confere de novo se ninguém vendeu esse
  -- assento enquanto a gente esperava (é a "revalidação" que o
  -- enunciado pede na sessão 2 depois do COMMIT da sessão 1)
  SELECT COUNT(*) INTO v_ja_vendido
  FROM PASSAGEM
  WHERE VOO_numero_voo = p_numero_voo
    AND numero_assento = p_numero_assento;

  IF v_ja_vendido > 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Assento ja vendido para esse voo.';
  END IF;

  -- o trigger trg_passagem_valida_partida e o trg_passagem_atualiza_assentos
  -- (atividade 15) continuam rodando normalmente aqui
  INSERT INTO PASSAGEM (numero_assento, valor_pago, PASSAGEIRO_cpf, VOO_numero_voo)
  VALUES (p_numero_assento, p_valor_pago, p_cpf, p_numero_voo);

  COMMIT;
END$$

DELIMITER ;

-- =====================================================================
-- testes - cada bloco "sessão 1" / "sessão 2" precisa ser rodado em
-- duas conexões separadas (duas abas do mysql/heidisql/phpmyadmin),
-- do jeito que o enunciado pede em "abra duas conexões com o banco".
-- os resultados reais de cada teste estão no locking.md.
-- =====================================================================

-- ---------------------------------------------------------------------
-- teste 1 - condição de corrida no mesmo assento, sem passar pela
-- procedure (transação manual, igual ao exemplo do item 10 do
-- enunciado). serve pra mostrar o FOR UPDATE segurando a segunda
-- sessão até a primeira comitar.
-- ---------------------------------------------------------------------

-- sessão 1 (passageiro Ana Souza, cpf 12345678901) tenta o assento 7A
SELECT NOW() AS inicio_sessao1;
START TRANSACTION;
SELECT numero_voo, assentos_disponiveis FROM VOO WHERE numero_voo = 100 FOR UPDATE;
SELECT SLEEP(4) AS segurando_o_lock_por_4s; -- só pra dar tempo da sessão 2 tentar entrar
INSERT INTO PASSAGEM (numero_assento, valor_pago, PASSAGEIRO_cpf, VOO_numero_voo)
VALUES ('7A', 300.00, '12345678901', 100);
COMMIT;
SELECT NOW() AS fim_sessao1;

-- sessão 2 (passageiro Diego Farias, cpf 33344455566) tenta o MESMO
-- assento 7A, uns 1-2 segundos depois de abrir a sessão 1
SELECT NOW() AS inicio_sessao2;
START TRANSACTION;
SELECT numero_voo, assentos_disponiveis FROM VOO WHERE numero_voo = 100 FOR UPDATE; -- fica esperando aqui
SELECT NOW() AS liberou_o_lock_sessao2;
SELECT COUNT(*) AS assento_ja_vendido FROM PASSAGEM WHERE VOO_numero_voo = 100 AND numero_assento = '7A';
-- assento_ja_vendido veio 1, ou seja a sessão 1 venceu -> desiste
ROLLBACK;
SELECT NOW() AS fim_sessao2;

-- ---------------------------------------------------------------------
-- teste 2 - mesmo assento, agora chamando a procedure nas duas sessões
-- ao mesmo tempo de verdade (sem sleep manual). uma das duas ganha, a
-- outra recebe o erro "Assento ja vendido para esse voo" de forma
-- controlada, sem duplicar nada.
-- ---------------------------------------------------------------------

-- sessão 1 (Elisa Prado, cpf 44455566677)
CALL sp_reservar_assento('44455566677', 100, '8A', 300.00);

-- sessão 2 (Diego Farias, cpf 33344455566), disparada quase junto
CALL sp_reservar_assento('33344455566', 100, '8A', 300.00);

-- ---------------------------------------------------------------------
-- teste 3 - assentos DIFERENTES no mesmo voo, chamados ao mesmo tempo.
-- as duas devem passar sem erro (só serializam rapidinho no lock do
-- voo, mas nenhuma trava a outra por muito tempo nem falha).
-- ---------------------------------------------------------------------

-- sessão 1 (Fabio Nogueira, cpf 55566677788) -> assento 8B
CALL sp_reservar_assento('55566677788', 100, '8B', 280.00);

-- sessão 2 (Gabriela Rocha, cpf 66677788899) -> assento 8C
CALL sp_reservar_assento('66677788899', 100, '8C', 280.00);

-- ---------------------------------------------------------------------
-- teste 4 - deadlock de propósito, usando duas passagens que já
-- existem (id 4 = assento 5A, id 5 = assento 5B, ambas do voo 100).
-- cada sessão trava uma primeiro e tenta travar a outra depois, em
-- ordem invertida -> o mariadb detecta o ciclo e cancela uma sessão.
-- ---------------------------------------------------------------------

-- sessão 1: trava o id 4 (5A), espera, tenta travar o id 5 (5B)
START TRANSACTION;
SELECT id_passagem, numero_assento FROM PASSAGEM WHERE id_passagem = 4 FOR UPDATE;
SELECT SLEEP(2) AS segurando_5A;
SELECT id_passagem, numero_assento FROM PASSAGEM WHERE id_passagem = 5 FOR UPDATE; -- trava aqui ou dá deadlock
COMMIT;

-- sessão 2 (dispara ~0,3s depois da sessão 1): trava o id 5 (5B)
-- primeiro, espera um pouco, tenta travar o id 4 (5A) -> ordem
-- invertida da sessão 1, é isso que fecha o ciclo do deadlock
START TRANSACTION;
SELECT id_passagem, numero_assento FROM PASSAGEM WHERE id_passagem = 5 FOR UPDATE;
SELECT SLEEP(1) AS segurando_5B;
SELECT id_passagem, numero_assento FROM PASSAGEM WHERE id_passagem = 4 FOR UPDATE;
COMMIT;
