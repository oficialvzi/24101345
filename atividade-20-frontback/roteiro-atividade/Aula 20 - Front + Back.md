# Roteiro de Atividades — Alunos, Notas e Status

## Objetivo

Desenvolver uma aplicação simples que utilize **MySQL, PHP e JavaScript (Fetch API)** para cadastrar, consultar e exibir alunos, suas notas e o respectivo status acadêmico.

Ao final da atividade, o estudante deverá compreender também onde é mais adequado implementar uma **regra de negócio**.

---

## 1. Criar a tabela `alunos`

Crie uma tabela chamada `alunos` no banco de dados.

A tabela deverá possuir, no mínimo, os seguintes campos:

- `id` — identificador único do aluno;
- `nome` — nome do aluno;
- `nota` — nota final do aluno.

### Exemplo de estrutura

```sql
CREATE TABLE alunos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    nota DECIMAL(4,2) NOT NULL
);
```

---

## 2. Inserir os alunos

Insira **ao menos 5 registros** na tabela `alunos`.

Os registros devem possuir nomes diferentes e notas variadas, incluindo alunos que serão aprovados e reprovados.

### Exemplo

```sql
INSERT INTO alunos (nome, nota) VALUES
('Ana Souza', 8.5),
('Bruno Lima', 6.0),
('Carlos Mendes', 7.0),
('Daniel Oliveira', 5.5),
('Eduarda Santos', 9.0);
```

> Você pode utilizar outros nomes e valores.

---

## 3. Criar o backend em PHP

Crie um arquivo PHP responsável por consultar os alunos no banco de dados.

O backend deverá:

1. estabelecer conexão com o banco;
2. executar uma consulta `SELECT`;
3. recuperar os dados dos alunos;
4. retornar os dados em formato **JSON**.

### Resultado esperado

A aplicação deverá disponibilizar os dados em uma estrutura semelhante a:

```json
[
    {
        "id": 1,
        "nome": "Ana Souza",
        "nota": 8.5
    },
    {
        "id": 2,
        "nome": "Bruno Lima",
        "nota": 6.0
    }
]
```

---

## 4. Listar os alunos utilizando JavaScript e `fetch()`

Crie uma página HTML que utilize **JavaScript** para consumir o endpoint PHP.

Utilize a função `fetch()` para realizar a requisição ao backend.

Exemplo:

```javascript
fetch('alunos.php')
    .then(response => response.json())
    .then(alunos => {
        // Exibir os alunos na página
    })
    .catch(error => {
        console.error('Erro:', error);
    });
```

Os alunos devem ser apresentados dinamicamente na página.

**Não é permitido deixar os dados dos alunos escritos diretamente no HTML.**

---

## 5. Mostrar a nota de cada aluno

Para cada aluno exibido, apresente:

- Nome;
- Nota.

Exemplo de apresentação:

| Aluno | Nota |
|---|---:|
| Ana Souza | 8,5 |
| Bruno Lima | 6,0 |
| Carlos Mendes | 7,0 |
| Daniel Oliveira | 5,5 |
| Eduarda Santos | 9,0 |

A tabela deve ser construída dinamicamente a partir dos dados recebidos pelo `fetch()`.

---

## 6. Exibir o status do aluno

Para cada aluno, exiba também o seu status:

- **Aprovado** → nota maior ou igual a 7;
- **Reprovado** → nota menor que 7.

O resultado final deverá apresentar, por exemplo:

| Aluno | Nota | Status |
|---|---:|---|
| Ana Souza | 8,5 | Aprovado |
| Bruno Lima | 6,0 | Reprovado |
| Carlos Mendes | 7,0 | Aprovado |
| Daniel Oliveira | 5,5 | Reprovado |
| Eduarda Santos | 9,0 | Aprovado |

### Primeira implementação

Inicialmente, faça o cálculo do status **no JavaScript**.

Exemplo:

```javascript
const status = aluno.nota >= 7 ? 'Aprovado' : 'Reprovado';
```

---

# 7. Desafio — Regra de negócio no backend

Agora modifique a aplicação para que o **PHP seja responsável pelo cálculo do status**.

Em vez de o JavaScript decidir se o aluno foi aprovado ou reprovado, o backend deverá retornar essa informação.

O JSON poderá ter a seguinte estrutura:

```json
[
    {
        "id": 1,
        "nome": "Ana Souza",
        "nota": 8.5,
        "status": "Aprovado"
    },
    {
        "id": 2,
        "nome": "Bruno Lima",
        "nota": 6.0,
        "status": "Reprovado"
    }
]
```

O JavaScript deverá apenas **exibir** o status recebido.

---

# 8. Comparação das duas abordagens

Compare as duas implementações:

### Abordagem 1 — Regra no JavaScript

```text
Banco de dados
      ↓
     PHP
      ↓
   JSON
      ↓
 JavaScript
      ↓
Calcula status
      ↓
   Página
```

### Abordagem 2 — Regra no PHP

```text
Banco de dados
      ↓
     PHP
      ↓
Calcula status
      ↓
   JSON
      ↓
 JavaScript
      ↓
   Página
```

---

# 9. Questão para discussão

Responda:

> **Onde a regra de negócio deve ficar: no frontend (JavaScript) ou no backend (PHP)? Por quê?**

Na resposta, considere aspectos como:

- segurança;
- reutilização da regra;
- consistência dos dados;
- manutenção do sistema;
- possibilidade de existirem diferentes clientes consumindo a mesma API;
- responsabilidade do frontend e do backend.

---

# 10. Entrega

A entrega deverá conter:

- [ ] Script SQL para criação da tabela `alunos`;
- [ ] Script SQL com pelo menos 5 registros;
- [ ] Arquivo PHP responsável pelo acesso aos dados;
- [ ] Página HTML;
- [ ] JavaScript utilizando `fetch()`;
- [ ] Listagem dos alunos;
- [ ] Exibição das notas;
- [ ] Exibição do status;
- [ ] Implementação inicial com o status calculado no JavaScript;
- [ ] Implementação final com o status calculado no PHP;
- [ ] Resposta à questão sobre onde deve ficar a regra de negócio.

## Estrutura sugerida

```text
atividade/
├── index.html
├── js/
│   └── app.js
├── api/
│   └── alunos.php
└── banco/
    └── alunos.sql
```

---

## Resultado esperado

Ao acessar a página, o sistema deverá consultar o backend utilizando `fetch()`, recuperar os alunos cadastrados no banco e apresentar uma tabela contendo:

**Nome | Nota | Status**

Na versão final, o **PHP deverá ser responsável pela regra de aprovação**, enquanto o JavaScript ficará responsável principalmente pelo consumo da API e pela apresentação dos dados.
