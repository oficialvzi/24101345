# Atividade 23 — SQL Injection no sistema do Aeroporto

Busca de voos por **destino** feita de duas formas no mesmo sistema da atividade 22: **versão A** sem prepared statements (vulnerável) e **versão B** com prepared statements (segura). Os mesmos 4 ataques foram aplicados nas duas.

## 1. Implementação

**Model (`models/Voo.php`)**

```php
// Versão A: sem prepared statements (vulnerável)
public function buscarVulneravel(string $destino): array
{
    $sql = "SELECT v.numero_voo, v.origem, v.destino, v.horario_partida, v.horario_chegada
            FROM VOO v WHERE " . self::ATIVOS . " AND v.destino = '$destino'";

    return $this->db->query($sql)->fetchAll();
}

// Versão B: com prepared statements (seguro)
public function buscarSeguro(string $destino): array
{
    $stmt = $this->db->prepare(
        "SELECT v.numero_voo, v.origem, v.destino, v.horario_partida, v.horario_chegada
         FROM VOO v WHERE " . self::ATIVOS . " AND v.destino = :destino"
    );
    $stmt->execute([':destino' => $destino]);

    return $stmt->fetchAll();
}
```

**Controller (`controllers/VooController.php`)**: a ação `buscar()` escolhe a versão pelo parâmetro `versao` (padrão `b`) e mostra o resultado em `views/voos/buscar.php`. Para a aula, o erro do banco é exibido na tela.

---

## 2. Comparação

| Payload | Versão A (sem prepared) | Versão B (com prepared) |
|---|---|---|
| 1 `Salvador` | 1 voo (voo 3) | 1 voo (voo 3) |
| 2 `'` | Erro de sintaxe do MySQL (1064) exibido na tela | 0 resultados, sem erro |
| 3 `' OR '1'='1` | Todos os 5 voos, o filtro foi ignorado | 0 resultados |
| 4 `x' UNION SELECT id_usuario, email, senha_hash, 4, 5 FROM USUARIO -- ` | Vazou o e-mail e o hash da senha dos 2 usuários | 0 resultados |

---

## 3. Respostas

**1. Por que a versão B se comporta diferente com o mesmo texto de entrada?**

Na versão B o SQL é enviado ao banco com um marcador (`:destino`) e o texto digitado vai separado, como valor. O banco compara o destino com o texto inteiro (`' OR '1'='1`, por exemplo), e como nenhum voo tem esse destino, volta vazio. Na versão A o texto é colado dentro do SQL, e as aspas fecham a string e mudam a consulta.

**2. O que o banco recebe como comando e o que recebe como dado em cada versão?**

- **Versão A:** recebe tudo como comando. Com o payload 3, o comando vira `... WHERE deleted_at IS NULL AND destino = '' OR '1'='1'`, e o `OR '1'='1'` faz parte da consulta.
- **Versão B:** o comando é só `... WHERE deleted_at IS NULL AND destino = :destino`. O que o usuário digitou é sempre dado, nunca vira SQL.

**3. Se só a versão A existisse em produção, qual seria o pior dano do payload 4?**

O atacante leria qualquer tabela que o usuário `app_aeroporto` pode ler, sem login: e-mails e hashes de senha dos usuários (para tentar quebrar as senhas offline e entrar no sistema) e os dados pessoais dos passageiros (nome, CPF, data de nascimento), o que é um vazamento de dados pela LGPD.

---

## 4. Evidências

### 01 — Payload 1 (`Salvador`), versão A

![Payload 1 versão A](<imagens-evidencias/01-payload1-versao-a.jpg>)

### 02 — Payload 1 (`Salvador`), versão B

![Payload 1 versão B](<imagens-evidencias/02-payload1-versao-b.jpg>)

### 03 — Payload 2 (`'`), versão A: erro de sintaxe

![Payload 2 versão A](<imagens-evidencias/03-payload2-versao-a.jpg>)

### 04 — Payload 2 (`'`), versão B: nenhum resultado

![Payload 2 versão B](<imagens-evidencias/04-payload2-versao-b.jpg>)

### 05 — Payload 3 (`' OR '1'='1`), versão A: todos os voos

![Payload 3 versão A](<imagens-evidencias/05-payload3-versao-a.jpg>)

### 06 — Payload 3 (`' OR '1'='1`), versão B: nenhum resultado

![Payload 3 versão B](<imagens-evidencias/06-payload3-versao-b.jpg>)

### 07 — Payload 4 (`UNION`), versão A: e-mails e hashes de senha vazados

![Payload 4 versão A](<imagens-evidencias/07-payload4-versao-a.jpg>)

### 08 — Payload 4 (`UNION`), versão B: nenhum resultado

![Payload 4 versão B](<imagens-evidencias/08-payload4-versao-b.jpg>)
