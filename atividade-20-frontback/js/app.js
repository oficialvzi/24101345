// js/app.js - busca os alunos no backend e monta a tabela
const tabela = document.getElementById('tabela-alunos');

fetch('api/alunos.php')
    .then(response => response.json())
    .then(alunos => {
        alunos.forEach(aluno => {
            const linha = document.createElement('tr');

            const colunaNome = document.createElement('td');
            colunaNome.textContent = aluno.nome;

            const colunaNota = document.createElement('td');
            colunaNota.textContent = aluno.nota.toFixed(1).replace('.', ',');

            const colunaStatus = document.createElement('td');
            colunaStatus.textContent = aluno.status;

            linha.appendChild(colunaNome);
            linha.appendChild(colunaNota);
            linha.appendChild(colunaStatus);
            tabela.appendChild(linha);
        });
    })
    .catch(error => {
        console.error('Erro:', error);
    });