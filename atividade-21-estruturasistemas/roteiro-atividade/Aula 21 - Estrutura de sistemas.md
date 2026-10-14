# Aula 21 - Estrutura de sistemas

**Disciplina:** Projeto de Sistemas / Banco de Dados
**Tecnologias:** PHP + MySQL
**Projeto:** Aeroporto (projeto individual)

---

## 1. Objetivos da aula

Ao final desta aula, o aluno será capaz de:

- Explicar por que um sistema precisa ter uma estrutura organizada de pastas e arquivos.
- Separar responsabilidades: conexão, acesso a dados, lógica e apresentação.
- Refatorar o projeto do aeroporto para uma estrutura em camadas.
- Criar um **model de Voos** com as operações **listar, criar, editar e excluir**.

---

## 2. Por que estruturar um sistema?

Até agora, é comum que cada arquivo PHP misture tudo: conexão com o banco, SQL, regras e HTML. Isso funciona em exemplos pequenos, mas gera problemas quando o projeto cresce:

| Problema                            | Consequência                                         |
| ----------------------------------- | ---------------------------------------------------- |
| Conexão repetida em vários arquivos | Mudar a senha do banco exige editar vários arquivos  |
| SQL misturado com HTML              | Difícil de ler, testar e reaproveitar                |
| Código duplicado entre telas        | Um erro corrigido em um lugar continua nos outros    |
| Sem padrão de pastas                | Ninguém (nem você) acha as coisas depois de um tempo |

**Ideia central:** *separação de responsabilidades*. Cada arquivo faz uma coisa só e faz bem.

---

## 3. Camadas do sistema

```
Navegador  →  View (HTML)  →  Controller  →  Model  →  Banco de Dados
```

- **Config:** dados de conexão e configurações gerais.
- **Model:** classe que conversa com o banco (SQL fica aqui).
- **Controller:** recebe a requisição, chama o model e decide qual tela mostrar.
- **View:** arquivos que só exibem HTML com os dados recebidos.

---

## 4. Estrutura de pastas sugerida

```
aeroporto/
├── config/
│   └── database.php
├── models/
│   └── Voo.php
├── controllers/
│   └── VooController.php
├── views/
│   └── voos/
│       ├── listar.php
│       ├── criar.php
│       └── editar.php
├── public/
│   └── index.php
└── includes/
    ├── header.php
    └── footer.php
```

> Cada aluno tem seu próprio schema do aeroporto. Adaptem nomes de tabelas e colunas ao seu projeto.

---

## 5. Conexão centralizada (config/database.php)

A conexão passa a existir em **um único lugar**.

```php
<?php

class Database
{
    private static ?PDO $conexao = null;

    public static function conectar(): PDO
    {
        if (self::$conexao === null) {
            $host    = 'localhost';
            $banco   = 'aeroporto';
            $usuario = 'root';
            $senha   = '';

            self::$conexao = new PDO(
                "mysql:host=$host;dbname=$banco;charset=utf8mb4",
                $usuario,
                $senha,
                [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                ]
            );
        }

        return self::$conexao;
    }
}
```

---

## 6. O Model de Voos (models/Voo.php)

O model concentra **todo o SQL** relacionado a voos. Os nomes das colunas abaixo são um exemplo: ajustem ao seu schema.

```php
<?php

require_once __DIR__ . '/../config/database.php';

class Voo
{
    private PDO $db;

    public function __construct()
    {
        $this->db = Database::conectar();
    }

    // LISTAR
    public function listar(): array
    {
        $sql = "SELECT * FROM voo ORDER BY data_partida";
        return $this->db->query($sql)->fetchAll();
    }

    // BUSCAR UM (usado na tela de edição)
    public function buscar(int $id): ?array
    {
        $stmt = $this->db->prepare("SELECT * FROM voo WHERE id = :id");
        $stmt->execute([':id' => $id]);
        $voo = $stmt->fetch();

        return $voo ?: null;
    }

    // CRIAR
    public function criar(array $dados): bool
    {
        $sql = "INSERT INTO voo (numero, origem, destino, data_partida)
                VALUES (:numero, :origem, :destino, :data_partida)";

        $stmt = $this->db->prepare($sql);

        return $stmt->execute([
            ':numero'       => $dados['numero'],
            ':origem'       => $dados['origem'],
            ':destino'      => $dados['destino'],
            ':data_partida' => $dados['data_partida'],
        ]);
    }

    // EDITAR
    public function editar(int $id, array $dados): bool
    {
        $sql = "UPDATE voo
                SET numero = :numero,
                    origem = :origem,
                    destino = :destino,
                    data_partida = :data_partida
                WHERE id = :id";

        $stmt = $this->db->prepare($sql);

        return $stmt->execute([
            ':numero'       => $dados['numero'],
            ':origem'       => $dados['origem'],
            ':destino'      => $dados['destino'],
            ':data_partida' => $dados['data_partida'],
            ':id'           => $id,
        ]);
    }

    // EXCLUIR
    public function excluir(int $id): bool
    {
        $stmt = $this->db->prepare("DELETE FROM voo WHERE id = :id");
        return $stmt->execute([':id' => $id]);
    }
}
```

### Pontos de atenção

- Use sempre **prepared statements** (`prepare` + `execute`). Nunca concatene variáveis direto no SQL (risco de **SQL Injection**).
- O model **não** gera HTML e **não** lê `$_POST` diretamente. Ele recebe dados e devolve dados.
- Se o voo tiver chaves estrangeiras (aeronave, portão, companhia), a exclusão pode falhar. Pensem em como tratar isso.

---

## 7. Exemplo de uso (controller simples)

```php
<?php

require_once __DIR__ . '/../models/Voo.php';

class VooController
{
    private Voo $voo;

    public function __construct()
    {
        $this->voo = new Voo();
    }

    public function listar(): void
    {
        $voos = $this->voo->listar();
        require __DIR__ . '/../views/voos/listar.php';
    }

    public function salvar(): void
    {
        if ($_SERVER['REQUEST_METHOD'] === 'POST') {
            $this->voo->criar($_POST);
        }
        header('Location: index.php?acao=listar');
        exit;
    }

    public function excluir(): void
    {
        $id = (int) ($_GET['id'] ?? 0);
        $this->voo->excluir($id);
        header('Location: index.php?acao=listar');
        exit;
    }
}
```

E a view `views/voos/listar.php` apenas percorre o array recebido:

```php
<table>
  <tr><th>Número</th><th>Origem</th><th>Destino</th><th>Partida</th><th>Ações</th></tr>
  <?php foreach ($voos as $v): ?>
    <tr>
      <td><?= htmlspecialchars($v['numero']) ?></td>
      <td><?= htmlspecialchars($v['origem']) ?></td>
      <td><?= htmlspecialchars($v['destino']) ?></td>
      <td><?= htmlspecialchars($v['data_partida']) ?></td>
      <td>
        <a href="index.php?acao=editar&id=<?= $v['id'] ?>">Editar</a>
        <a href="index.php?acao=excluir&id=<?= $v['id'] ?>"
           onclick="return confirm('Excluir este voo?')">Excluir</a>
      </td>
    </tr>
  <?php endforeach; ?>
</table>
```

> Use `htmlspecialchars()` ao exibir dados vindos do banco, para evitar XSS.

---

## 8. Atividade prática

### Parte 1: Refatorar o projeto

1. Crie a estrutura de pastas da seção 4 no seu projeto do aeroporto.
2. Crie `config/database.php` e remova a conexão repetida dos demais arquivos.
3. Mova o HTML repetido (cabeçalho e rodapé) para `includes/`.
4. Garanta que **nenhum arquivo de view** contenha SQL.

### Parte 2: Model de Voos

Crie a classe `Voo` em `models/Voo.php` com os métodos:

| Método                | O que faz                 |
| --------------------- | ------------------------- |
| `listar()`            | Retorna todos os voos     |
| `buscar($id)`         | Retorna um voo pelo ID    |
| `criar($dados)`       | Insere um novo voo        |
| `editar($id, $dados)` | Atualiza um voo existente |
| `excluir($id)`        | Remove um voo             |

### Parte 3: Telas

Crie as telas de listagem, cadastro e edição de voos, usando o model.

---

## 9. Checklist de entrega

- [ ] Estrutura de pastas organizada
- [ ] Conexão em um único arquivo
- [ ] Model `Voo` com listar, criar, editar e excluir
- [ ] Todas as consultas com prepared statements
- [ ] Nenhum SQL dentro das views
- [ ] Saída de dados com `htmlspecialchars()`
- [ ] Projeto funcionando: é possível listar, criar, editar e excluir voos pelo navegador

---

## 10. Critérios de avaliação

| Critério                                                | Peso |
| ------------------------------------------------------- | ---- |
| Refatoração e organização da estrutura                  | 30%  |
| Model de Voos completo e funcional                      | 40%  |
| Segurança básica (prepared statements, escape de saída) | 20%  |
| Clareza e legibilidade do código                        | 10%  |

---

## 11. Próxima aula

Inserção de dados e CRUD completo no projeto, estendendo o padrão do model de Voos para as demais entidades do aeroporto.