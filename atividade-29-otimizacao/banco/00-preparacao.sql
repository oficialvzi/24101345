DROP DATABASE IF EXISTS lab_otimizacao;
CREATE DATABASE lab_otimizacao;
USE lab_otimizacao;

CREATE TABLE cliente (
  id     INT PRIMARY KEY,
  nome   VARCHAR(60) NOT NULL,
  cpf    VARCHAR(11) NOT NULL,
  cidade VARCHAR(30) NOT NULL
);

CREATE TABLE locacao (
  id             INT PRIMARY KEY,
  id_cliente     INT NOT NULL,
  id_veiculo     INT NOT NULL,
  data_retirada  DATE NOT NULL,
  valor          DECIMAL(8,2) NOT NULL,
  status         VARCHAR(10) NOT NULL
);

SET SESSION cte_max_recursion_depth = 1000000;

INSERT INTO cliente (id, nome, cpf, cidade)
WITH RECURSIVE seq AS (
  SELECT 1 AS n UNION ALL SELECT n + 1 FROM seq WHERE n < 50000
)
SELECT n,
       CONCAT('Cliente ', n),
       LPAD(n, 11, '0'),
       ELT(1 + n % 5, 'Brasilia', 'Goiania', 'Anapolis', 'Taguatinga', 'Gama')
FROM seq;

INSERT INTO locacao (id, id_cliente, id_veiculo, data_retirada, valor, status)
WITH RECURSIVE seq AS (
  SELECT 1 AS n UNION ALL SELECT n + 1 FROM seq WHERE n < 500000
)
SELECT n,
       1 + (n * 7919) % 50000,
       1 + (n * 31) % 200,
       DATE_ADD('2023-01-01', INTERVAL n % 1095 DAY),
       100 + n % 400,
       CASE WHEN n % 50 = 0 THEN 'cancelada'
            WHEN n % 4  = 0 THEN 'aberta'
            ELSE 'concluida' END
FROM seq;

ANALYZE TABLE cliente, locacao;
