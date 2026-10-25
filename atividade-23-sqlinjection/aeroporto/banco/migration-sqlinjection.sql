-- Atividade 23 — dados de teste para o ataque de SQL Injection
-- Rodar como root, depois da migration da atividade 22.
USE aeroporto;

-- Coluna de senha (hash bcrypt) na tabela de usuários: é o alvo do payload 4 (UNION)
ALTER TABLE USUARIO ADD COLUMN senha_hash VARCHAR(255) NULL;

UPDATE USUARIO
   SET senha_hash = '$2y$12$MlC7K9772AnEaUFLiz1Kf.3oaNEf9GcYoy8Pibvc2bedy2ENoQzwu'
 WHERE id_usuario = 1;

INSERT INTO USUARIO (id_usuario, nome, email, senha_hash)
VALUES (2, 'Operador', 'operador@aeroporto.local',
        '$2y$12$ZaOF79J26vggp0wD/F10iu9ibGWYkYO3db.9fA3MkWeYs/cxdFrtK');
