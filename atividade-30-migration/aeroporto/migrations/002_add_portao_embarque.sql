-- 002_add_portao_embarque.sql
-- up
ALTER TABLE VOO ADD COLUMN portao_embarque VARCHAR(5) NULL;

-- down
ALTER TABLE VOO DROP COLUMN portao_embarque;
