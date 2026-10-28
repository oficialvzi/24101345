<?php
// Campos do formulário de voo, compartilhados por criar.php e editar.php.
// Espera: $aeronaves (lista para o <select>) e $voo (vazio no cadastro, preenchido na edição).

// O banco devolve "2026-11-10 08:00:00"; o input datetime-local espera "2026-11-10T08:00"
$partida = !empty($voo['horario_partida']) ? date('Y-m-d\TH:i', strtotime($voo['horario_partida'])) : '';
$chegada = !empty($voo['horario_chegada']) ? date('Y-m-d\TH:i', strtotime($voo['horario_chegada'])) : '';
?>

<label for="codigo">Código</label>
<input type="text" id="codigo" name="codigo" maxlength="6" placeholder="LA1234"
       value="<?= htmlspecialchars($voo['codigo'] ?? '') ?>">

<label for="origem">Origem</label>
<input type="text" id="origem" name="origem" maxlength="45" required
       value="<?= htmlspecialchars($voo['origem'] ?? '') ?>">

<label for="destino">Destino</label>
<input type="text" id="destino" name="destino" maxlength="45" required
       value="<?= htmlspecialchars($voo['destino'] ?? '') ?>">

<label for="horario_partida">Partida</label>
<input type="datetime-local" id="horario_partida" name="horario_partida" required
       value="<?= htmlspecialchars($partida) ?>">

<label for="horario_chegada">Chegada</label>
<input type="datetime-local" id="horario_chegada" name="horario_chegada" required
       value="<?= htmlspecialchars($chegada) ?>">

<label for="numero_aeronave">Aeronave</label>
<select id="numero_aeronave" name="numero_aeronave" required>
    <option value="">Selecione...</option>
    <?php foreach ($aeronaves as $a): ?>
        <option value="<?= (int) $a['numero_aeronave'] ?>"
            <?= ($voo['AERONAVE_numero_aeronave'] ?? null) == $a['numero_aeronave'] ? 'selected' : '' ?>>
            <?= htmlspecialchars($a['numero_aeronave'] . ' - ' . $a['fabricante'] . ' ' . $a['modelo']) ?>
        </option>
    <?php endforeach; ?>
</select>