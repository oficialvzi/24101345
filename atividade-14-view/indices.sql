USE aeroporto;

CREATE INDEX idx_voo_rota_partida      ON VOO (origem, destino, horario_partida);
CREATE INDEX idx_passagem_data_reserva ON PASSAGEM (data_reserva);
CREATE INDEX idx_passagem_status       ON PASSAGEM (status_checkin);
CREATE INDEX idx_aeronave_fabricante   ON AERONAVE (fabricante);
