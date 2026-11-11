-- banco/privilegios.sql - conta do SGBD usada pela aplicação, com privilégios mínimos
-- Rodar como root: mysql -u root -p < banco/privilegios.sql

-- Recria a conta do zero (remove os privilégios antigos, inclusive DELETE)
DROP USER IF EXISTS 'app_aeroporto'@'localhost';
CREATE USER 'app_aeroporto'@'localhost' IDENTIFIED BY 'Aer0porto#Voos24';

-- CRUD de voos: sem DELETE (a exclusão é soft delete, um UPDATE em deleted_at)
GRANT SELECT, INSERT, UPDATE ON aeroporto.VOO TO 'app_aeroporto'@'localhost';

-- Tabelas que as telas de voos também consultam
GRANT SELECT ON aeroporto.AERONAVE TO 'app_aeroporto'@'localhost';           -- lista de aeronaves
GRANT SELECT ON aeroporto.PASSAGEM TO 'app_aeroporto'@'localhost';           -- bloqueia excluir voo com passagens
GRANT SELECT, INSERT ON aeroporto.auditoria TO 'app_aeroporto'@'localhost';  -- registra excluir/restaurar
GRANT SELECT (id_usuario, nome) ON aeroporto.USUARIO TO 'app_aeroporto'@'localhost'; -- "excluído por" (sem email/senha)

SHOW GRANTS FOR 'app_aeroporto'@'localhost';
