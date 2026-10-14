# Atividade 20 — Alunos, Notas e Status

Aplicação simples que lista alunos, suas notas e o status acadêmico (Aprovado/Reprovado), usando **MySQL**, **PHP (PDO)** e **JavaScript (`fetch()`)**.

## Estrutura

```text
atividade-20-frontback/
├── index.html          # página com a tabela (tbody vazio, preenchido pelo JS)
├── js/app.js           # fetch() no backend e montagem da tabela
├── api/alunos.php      # endpoint que consulta o banco e devolve JSON
├── config.php          # conexão PDO com o banco
├── banco/alunos.sql    # criação do banco, da tabela e dos 5 registros
└── imagens-evidencias/ # prints do resultado
```

## Como rodar

1. Iniciar o MySQL (instalado pelo Homebrew):

   ```bash
   brew services start mysql@8.4
   ```

2. No MySQL Workbench, executar o script `banco/alunos.sql` (cria o banco `escola`, a tabela `alunos` e insere os 5 alunos).

3. Ainda no Workbench, criar o usuário da aplicação. A aplicação não usa o `root` (menor privilégio), e esse usuário só tem permissão de leitura:

   ```sql
   CREATE USER 'app_escola'@'localhost' IDENTIFIED BY 'senha_forte';
   GRANT SELECT ON escola.* TO 'app_escola'@'localhost';
   ```

4. Na pasta `atividade-20-frontback`, subir o servidor embutido do PHP:

   ```bash
   php -S localhost:8000
   ```

5. Abrir no navegador:
   - `http://localhost:8000/api/alunos.php` → JSON retornado pelo backend;
   - `http://localhost:8000` → página com a tabela.

## Resultado

A página consulta o backend com `fetch()` e monta a tabela dinamicamente. Nenhum aluno está escrito no HTML: o `<tbody>` começa vazio e é preenchido pelo JavaScript com `createElement` e `textContent`.

![Tabela de alunos gerada pelo JavaScript](<imagens-evidencias/Screenshot 2026-10-14 at 10.50.03.png>)

O resultado visual é **o mesmo nas duas versões**. O que muda é qual camada decide o status.

## Comparação das duas abordagens

### Abordagem 1 — Regra no JavaScript (commit `04d5848`)

```text
Banco de dados → PHP → JSON → JavaScript → calcula status → Página
```

Nessa versão, o PHP devolvia apenas `id`, `nome` e `nota`. Quem sabia que a nota de corte é 7 era o JavaScript, com a linha:

```javascript
const status = aluno.nota >= 7 ? 'Aprovado' : 'Reprovado';
```

Ou seja, o backend só entregava dados crus, e a decisão de aprovar ou reprovar acontecia no navegador do usuário.

### Abordagem 2 — Regra no PHP (commit `ace1aad`)

```text
Banco de dados → PHP → calcula status → JSON → JavaScript → Página
```

Nessa versão, o PHP calcula o status antes de gerar o JSON:

```php
$alunos[$i]['status'] = $alunos[$i]['nota'] >= 7 ? 'Aprovado' : 'Reprovado';
```

O JSON passou a trazer o campo `status` pronto:

![JSON retornado pelo endpoint api/alunos.php, já com o campo status](<imagens-evidencias/Screenshot 2026-10-14 at 10.52.14.png>)

No JavaScript, eu apaguei o cálculo e ele passou só a exibir o que recebe (`colunaStatus.textContent = aluno.status`). O frontend não sabe mais qual é a nota de corte.

Para confirmar que a decisão estava mesmo no backend, troquei temporariamente o `7` por `6` no `alunos.php`. O Bruno Lima (nota 6,0) passou a aparecer como **Aprovado** sem que eu mexesse em nenhuma linha do JavaScript. Mudar a regra exigiu alterar **um único arquivo**.

Detalhe observado: no print, notas inteiras aparecem no JSON como `6`, `7` e `9` (sem o `.0`). Como o valor é um número e não um texto, o JavaScript formata com `toFixed(1)` e a página mostra `6,0`, `7,0` e `9,0` corretamente.

## Onde a regra de negócio deve ficar?

**No backend (PHP).** O frontend deve ser responsável pela apresentação e pela interação. A decisão sobre se um aluno foi aprovado é uma regra de negócio e precisa ficar no servidor.

**Segurança.** O JavaScript roda no navegador do usuário. Qualquer pessoa pode abrir o DevTools (F12), ver o `app.js` e alterá-lo. Na abordagem 1, bastaria trocar `>= 7` por `>= 0` para que todos aparecessem como aprovados na tela. No PHP, o código roda no servidor e o usuário só recebe o resultado, sem acesso à regra. Como diz o slide 4, o frontend nunca é confiável.

**Reutilização.** Com a regra no PHP, qualquer parte do sistema que precisar do status (outra página, um relatório, uma exportação) só consome o mesmo endpoint e recebe o valor pronto. Com a regra no JavaScript, cada tela nova teria que reescrever o mesmo cálculo.

**Consistência dos dados.** Se a regra estiver copiada em vários lugares e alguém atualizar só um deles, o mesmo aluno pode aparecer como Aprovado em uma tela e como Reprovado em outra. Com uma única fonte da verdade no backend, todos recebem a mesma resposta.

**Manutenção.** No teste de trocar 7 por 6, alterei apenas o `alunos.php` e a mudança valeu para toda a aplicação. Se a regra estivesse espalhada pelos clientes, seria preciso encontrar e alterar cada cópia, e o risco de esquecer alguma seria grande.

**Diferentes clientes consumindo a mesma API.** A API é o contrato entre frontend e backend (slide 8). Um aplicativo de celular, outro site ou um sistema da secretaria poderiam consumir o mesmo `api/alunos.php`, mas nenhum deles executaria o meu `app.js`. Se a regra estivesse só no JavaScript, cada cliente teria que reimplementá-la, possivelmente de formas diferentes. Com a regra no PHP, todos recebem o `status` já calculado.

**Responsabilidade do frontend e do backend.** Pela divisão em camadas (slide 6), o frontend cuida da interface e **não decide regra de negócio**. O backend cuida das regras, da validação e do acesso ao banco. O banco cuida do armazenamento e da integridade. Na versão final, cada camada faz só o seu papel: o MySQL guarda as notas, o PHP decide o status e o JavaScript apenas consome a API e exibe a tabela.

**Ressalva.** O frontend pode *repetir* uma regra para melhorar a experiência do usuário, por exemplo validar um formulário antes de enviar e mostrar o erro na hora. Mesmo assim, essa verificação é só uma conveniência: a decisão oficial precisa existir também no servidor, porque o que vem do navegador pode ter sido alterado.

### Observação sobre o próprio projeto

O `config.php` com as credenciais do banco foi versionado no Git. Aqui a senha é de teste e só vale na máquina local, mas em um projeto real isso deveria ser evitado (slide 21). As credenciais iriam para um arquivo `.env` ou para um `config.php` listado no `.gitignore`, fora da pasta pública.
