# Atividade 21 — Estrutura de Arquivos para Sistemas Web

Sistema web do projeto **Aeroporto** organizado em camadas (Model, View, Controller), com o CRUD completo de **voos**: listar, cadastrar, editar e excluir pelo navegador.

**Tecnologias:** PHP 8.5 (PDO) · MySQL 8.4 · HTML/CSS

---

## 1. Como rodar

### 1.1 Banco de dados

1. Criar o schema do aeroporto com o script da atividade 10 (tabelas + regras de integridade):
   `atividade-10-integridade/sql_integridade.sql`
2. Inserir os dados de teste (3 aeronaves, 4 voos, 1 passageiro e 1 passagem no voo 1):
   `aeroporto/banco/dados-teste.sql`
3. Criar o usuário da aplicação, com privilégios mínimos (somente o CRUD, somente no banco `aeroporto`):

   ```sql
   CREATE USER 'app_aeroporto'@'localhost' IDENTIFIED BY 'sua_senha_aqui';
   GRANT SELECT, INSERT, UPDATE, DELETE ON aeroporto.* TO 'app_aeroporto'@'localhost';
   ```

### 1.2 Configuração

Copiar o modelo de configuração e preencher a senha definida acima:

```bash
cp aeroporto/.env.example aeroporto/.env
```

### 1.3 Servidor

Dentro da pasta `aeroporto/`, subir o servidor com a pasta `public/` como raiz do site:

```bash
php -S localhost:8000 -t public
```

Acessar `http://localhost:8000`.

---

## 2. Estrutura de pastas

```text
aeroporto/
├── .env                      (não versionado)
├── .env.example
├── .gitignore
├── banco/
│   └── dados-teste.sql
├── config/
│   └── database.php
├── models/
│   ├── Voo.php
│   └── Aeronave.php
├── controllers/
│   └── VooController.php
├── views/
│   └── voos/
│       ├── listar.php
│       ├── criar.php
│       ├── editar.php
│       └── _formulario.php
├── includes/
│   ├── header.php
│   └── footer.php
└── public/
    ├── index.php
    └── css/
        └── estilo.css
```

### Justificativa de cada arquivo

| Arquivo | Por que está aí |
|---|---|
| `.env` | Guarda as credenciais do banco fora do código e fora do Git (listado no `.gitignore`). |
| `.env.example` | Modelo sem senha que mostra quais configurações o sistema precisa; esse sim vai para o Git. |
| `.gitignore` | Impede que o `.env` seja enviado ao repositório por engano. |
| `banco/dados-teste.sql` | Script SQL fica separado do código da aplicação; é usado só para preparar o banco. |
| `config/database.php` | Único lugar que sabe conectar no banco; mudar a senha ou o servidor exige editar só o `.env`. |
| `models/Voo.php` | Concentra todo o SQL da tabela `VOO` (listar, buscar, criar, editar, excluir). |
| `models/Aeronave.php` | SQL da tabela `AERONAVE`, separado do model de voos (cada model cuida da sua tabela). |
| `controllers/VooController.php` | Recebe a requisição, lê `$_GET`/`$_POST`, chama o model e escolhe a view; não tem SQL. |
| `views/voos/listar.php` | Só exibe a tabela de voos recebida do controller. |
| `views/voos/criar.php` | Só exibe o formulário de cadastro (envia para `salvar`). |
| `views/voos/editar.php` | Só exibe o formulário de edição preenchido (envia para `atualizar`). |
| `views/voos/_formulario.php` | Campos do formulário escritos uma única vez e incluídos por `criar.php` e `editar.php`, evitando código duplicado entre telas. O `_` indica que é um pedaço de tela, não uma tela inteira. |
| `includes/header.php` | Cabeçalho, menu e mensagens de aviso compartilhados por todas as telas. |
| `includes/footer.php` | Rodapé compartilhado por todas as telas. |
| `public/index.php` | Única porta de entrada do sistema; decide qual ação do controller executar. |
| `public/css/estilo.css` | Arquivo que o navegador precisa baixar, por isso fica dentro de `public/`. |

---

## 3. Camadas e fluxo de uma requisição

| Camada | Arquivo(s) | Responsabilidade |
|---|---|---|
| Config | `config/database.php` | Conexão PDO única, lida do `.env` |
| Model | `models/` | Todo o SQL; recebe e devolve dados |
| Controller | `controllers/` | Orquestra: entrada do usuário → model → view |
| View | `views/` e `includes/` | Só HTML com os dados recebidos |

Exemplo: clicar em **Editar** no voo 2.

```text
Navegador ── GET index.php?acao=editar&id=2 ──► public/index.php
                                                      │  match ($acao)
                                                      ▼
                                          VooController->editar()
                                                      │  (int) $_GET['id']
                                                      ▼
                                             Voo->buscar(2) ──► MySQL
                                                      │
                                                      ▼
                                         views/voos/editar.php ──► Navegador
```

---

## 4. Adaptação ao schema do aeroporto

O model foi escrito para o schema criado na atividade 10, e não para o exemplo genérico do roteiro:

| Exemplo do roteiro | Tabela `VOO` do projeto |
|---|---|
| `id` | `numero_voo` (chave primária, `AUTO_INCREMENT`) |
| `numero` | Não existe: o próprio `numero_voo` identifica o voo |
| `data_partida` | `horario_partida` e `horario_chegada` (`DATETIME`) |
| — | `AERONAVE_numero_aeronave` (chave estrangeira obrigatória) |

Por causa da chave estrangeira para `AERONAVE`, o formulário mostra uma lista com as aeronaves existentes em vez de um campo numérico livre. A listagem usa um `JOIN` no model para exibir fabricante e modelo da aeronave.

---

## 5. Model de Voos

| Método | SQL | Uso |
|---|---|---|
| `listar()` | `SELECT ... JOIN AERONAVE ... ORDER BY horario_partida` | Tela de listagem |
| `buscar($numeroVoo)` | `SELECT * ... WHERE numero_voo = :numero_voo` | Preencher a tela de edição |
| `criar($dados)` | `INSERT INTO VOO ...` | Cadastro |
| `editar($numeroVoo, $dados)` | `UPDATE VOO ... WHERE numero_voo = :numero_voo` | Edição |
| `excluir($numeroVoo)` | `DELETE FROM VOO WHERE numero_voo = :numero_voo` | Exclusão |

O model não gera HTML e não lê `$_POST`. Ele recebe um array do controller e usa apenas as chaves que conhece, ignorando qualquer campo extra enviado no formulário.

---

## 6. Segurança

| Prática | Onde |
|---|---|
| **Prepared statements** em todas as consultas, inclusive no `listar()` | `models/Voo.php`, `models/Aeronave.php` |
| **`htmlspecialchars()`** em todo dado do banco exibido, dentro de células e de atributos `value` | `views/voos/*.php`, `includes/header.php` |
| **Credenciais no `.env`**, fora do código e ignoradas pelo Git | `.env`, `.gitignore`, `config/database.php` |
| **Usuário do banco com privilégio mínimo** (`app_aeroporto`, só SELECT/INSERT/UPDATE/DELETE, nunca root) | Seção 1.1 |
| **Só `public/` exposta**: o servidor roda com `-t public` | `public/` |
| **Lista branca de ações**: só as 6 ações do `match` existem; qualquer outra cai na listagem | `public/index.php` |
| **IDs convertidos para inteiro** com `(int)` antes de chegar ao model | `controllers/VooController.php` |

**Teste de XSS:** foi cadastrado direto no banco um voo com origem `<b>Hacker</b><script>alert(1)</script>`. A página exibiu o texto literalmente, sem negrito e sem executar o script (evidência 02).

**O que acontece ao acessar `/config/` ou `/.env` pela URL?** Como a raiz do site é `public/`, esses arquivos não têm endereço. Ao acessar `http://localhost:8000/.env` ou `/config/database.php`, o servidor embutido do PHP não encontra o arquivo dentro de `public/` e executa o `index.php`. A senha e o código de conexão nunca são enviados ao navegador.

---

## 7. Tratamento de erros do banco

As regras de integridade continuam no banco (atividade 10). O controller captura a `PDOException` e traduz o código do MySQL em uma mensagem para o usuário. A regra não é duplicada no PHP.

| Código | Situação | Regra | Mensagem exibida |
|---|---|---|---|
| 1451 | Excluir voo com passagens vendidas | FK `PASSAGEM → VOO` com `ON DELETE RESTRICT` | "Não é possível excluir: este voo possui passagens vendidas." |
| 1452 | Aeronave inexistente | FK `VOO → AERONAVE` | "A aeronave escolhida não existe." |
| 3819 | Origem igual ao destino ou chegada antes da partida | `chk_voo_rota`, `chk_voo_horarios` | "Dados inválidos: ..." |
| 1048 | Campo obrigatório vazio | `NOT NULL` | "Preencha todos os campos." |

**Como foi tratada a exclusão de voos com chaves estrangeiras:** a exclusão é **bloqueada**, e não feita em cascata. Apagar um voo junto com as passagens (`ON DELETE CASCADE`) faria sumir, sem aviso, registros de clientes que já pagaram. Com `RESTRICT`, as passagens precisam ser canceladas ou remarcadas antes. O sistema mostra o motivo em vez de uma tela de erro (evidência 08).

Depois de cada cadastro, edição ou exclusão, o controller redireciona para a listagem (padrão Post/Redirect/Get). Assim, recarregar a página não reenvia o formulário. A mensagem de sucesso ou erro é guardada na sessão e exibida uma única vez.

---

## 8. Evidências

### 01 — Listagem de voos

![Listagem dos voos](<imagens-evidencias/01-listagem-voos.jpeg>)

### 02 — Saída escapada com `htmlspecialchars()` (teste de XSS)

O voo 6 tem HTML e JavaScript na origem; a página mostra o texto sem executá-lo.

![Teste de XSS](<imagens-evidencias/02-teste-xss-htmlspecialchars.jpeg>)

### 03 — Cadastro de voo (Brasília → Recife)

![Cadastro com sucesso](<imagens-evidencias/03-cadastro-sucesso.png>)

### 04 — Cadastro recusado pelo `CHECK` do banco (origem = destino)

![Erro de origem igual ao destino](<imagens-evidencias/04-erro-check-origem-destino.png>)

### 05 — Formulário de edição preenchido (voo 2)

![Formulário de edição](<imagens-evidencias/05-edicao-formulario-preenchido.png>)

### 06 — Edição salva (partida 14:00, chegada 15:10)

![Edição com sucesso](<imagens-evidencias/06-edicao-sucesso.png>)

### 07 — Exclusão de voo sem passagens (voo 6)

![Exclusão com sucesso](<imagens-evidencias/07-exclusao-sucesso.png>)

### 08 — Exclusão bloqueada pela chave estrangeira (voo 1 tem passagem vendida)

![Exclusão bloqueada](<imagens-evidencias/08-exclusao-bloqueada-fk.png>)

---

## 9. Checklist de entrega

- [x] Estrutura de pastas organizada
- [x] Conexão em um único arquivo (`config/database.php`)
- [x] Model `Voo` com listar, buscar, criar, editar e excluir
- [x] Todas as consultas com prepared statements
- [x] Nenhum SQL dentro das views
- [x] Saída de dados com `htmlspecialchars()`
- [x] Projeto funcionando: é possível listar, criar, editar e excluir voos pelo navegador

---

## 10. Limitações e melhorias possíveis

- Quando o banco recusa um cadastro ou edição, o formulário volta sem os valores digitados. Uma melhoria seria guardar os dados na sessão e preencher o formulário de novo.
- A exclusão usa um link (GET) com `confirm()`, como no exemplo do roteiro. Em produção, o ideal seria um formulário POST com token CSRF, para que um link aberto sem querer não apague dados.
- O model `Aeronave` tem apenas `listar()`. O CRUD das demais entidades (aeronaves, passageiros, passagens) é o tema da próxima aula e segue o mesmo padrão do model de voos.
