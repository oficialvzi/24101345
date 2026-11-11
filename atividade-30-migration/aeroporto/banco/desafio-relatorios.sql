-- banco/desafio-relatorios.sql - conta só de leitura (desafio). Rodar como root.

DROP USER IF EXISTS 'relatorios'@'localhost';
CREATE USER 'relatorios'@'localhost' IDENTIFIED BY 'Relat0rios#Le24';
GRANT SELECT ON aeroporto.* TO 'relatorios'@'localhost';

-- Item 2: tira a leitura geral e libera só colunas sem CPF de PASSAGEIRO
REVOKE SELECT ON aeroporto.* FROM 'relatorios'@'localhost';
GRANT SELECT (nome_completo, data_nasc) ON aeroporto.PASSAGEIRO TO 'relatorios'@'localhost';

-- Item 4 (alternativa): view só com as colunas permitidas
CREATE OR REPLACE VIEW aeroporto.vw_passageiros_publico AS
    SELECT nome_completo, data_nasc FROM aeroporto.PASSAGEIRO;
GRANT SELECT ON aeroporto.vw_passageiros_publico TO 'relatorios'@'localhost';

SHOW GRANTS FOR 'relatorios'@'localhost';
