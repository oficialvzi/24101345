-- Dados de teste para o sistema de voos (atividade 21)
USE aeroporto;

INSERT INTO
    AERONAVE (
        numero_aeronave,
        fabricante,
        modelo
    )
VALUES (1, 'Airbus', 'A320'),
    (2, 'Boeing', '737-800'),
    (3, 'Embraer', 'E195');

INSERT INTO
    VOO (
        origem,
        destino,
        horario_partida,
        horario_chegada,
        AERONAVE_numero_aeronave
    )
VALUES (
        'Brasília',
        'São Paulo',
        '2026-11-10 08:00:00',
        '2026-11-10 09:45:00',
        1
    ),
    (
        'São Paulo',
        'Rio de Janeiro',
        '2026-11-10 12:30:00',
        '2026-11-10 13:35:00',
        2
    ),
    (
        'Brasília',
        'Salvador',
        '2026-11-11 07:15:00',
        '2026-11-11 09:20:00',
        3
    ),
    (
        'Rio de Janeiro',
        'Brasília',
        '2026-11-12 18:00:00',
        '2026-11-12 19:50:00',
        1
    );

-- Um passageiro com passagem no voo 1: esse voo NÃO poderá ser excluído (FK RESTRICT)
INSERT INTO
    PASSAGEIRO (
        cpf,
        nome_completo,
        data_nasc,
        genero
    )
VALUES (
        '12345678901',
        'Maria Oliveira',
        '1995-04-20',
        'Feminino'
    );

INSERT INTO
    PASSAGEM (
        numero_assento,
        classe,
        valor_pago,
        PASSAGEIRO_cpf,
        VOO_numero_voo
    )
VALUES (
        '12A',
        'Econômica',
        650.00,
        '12345678901',
        1
    );