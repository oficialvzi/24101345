USE aeroporto;

-- Voos de uma rota em ordem de partida.
-- Colunas de igualdade (origem, destino) primeiro; coluna do ORDER BY por último.
CREATE INDEX idx_voo_rota_partida ON VOO (origem, destino, horario_partida);

-- Reservas por período (consulta por intervalo em data_reserva).
CREATE INDEX idx_passagem_data_reserva ON PASSAGEM (data_reserva);
