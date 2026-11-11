-- 003_add_aeroporto_origem.sql
-- up
ALTER TABLE VOO ADD COLUMN aeroporto_origem VARCHAR(80) NULL;

-- down
ALTER TABLE VOO DROP COLUMN aeroporto_origem;
