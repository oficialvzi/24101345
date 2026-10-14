<?php
// api/alunos.php - devolve a lista de alunos em JSON
require __DIR__ . '/../config.php';

$stmt = $pdo->prepare('SELECT id, nome, nota FROM alunos');
$stmt->execute();
$alunos = $stmt->fetchAll(PDO::FETCH_ASSOC);

// O PDO devolve DECIMAL como texto ("8.50"); convertemos para número
foreach ($alunos as $i => $aluno) {
    $alunos[$i]['id']   = (int) $aluno['id'];
    $alunos[$i]['nota'] = (float) $aluno['nota'];

    // Versão 2: a regra de negócio está no backend
    $alunos[$i]['status'] = $alunos[$i]['nota'] >= 7 ? 'Aprovado' : 'Reprovado';
}

header('Content-Type: application/json; charset=utf-8');
echo json_encode($alunos);