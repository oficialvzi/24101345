-- 004_drop_origem.sql
-- Atenção: a CHECK chk_voo_rota (origem <> destino) usa a coluna origem, então
-- o MySQL não deixa dropar a coluna sem dropar a constraint na mesma instrução.
-- up
ALTER TABLE VOO DROP CHECK chk_voo_rota, DROP COLUMN origem;

-- down
ALTER TABLE VOO ADD COLUMN origem VARCHAR(45) NULL, ADD CONSTRAINT chk_voo_rota CHECK (origem <> destino);
