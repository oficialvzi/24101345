CREATE DATABASE escola CHARACTER SET utf8mb4;
USE escola;

CREATE TABLE alunos (
id INT AUTO_INCREMENT PRIMARY KEY,
nome VARCHAR(100) NOT NULL,
nota DECIMAL(4,2) NOT NULL
);

INSERT INTO alunos (nome, nota) VALUES
('Ana Souza', 8.5),
('Bruno Lima', 6.0),
('Carlos Mendes', 7.0),
('Daniel Oliveira', 5.5),
('Eduarda Santos', 9.0);