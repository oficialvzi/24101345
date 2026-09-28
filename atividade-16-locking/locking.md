# Locking, Deadlocks e MVCC — Projeto Aeroporto

Situação-problema do enunciado: dois passageiros tentando reservar o mesmo assento de um voo ao mesmo tempo.

O modelo sugerido na aula (`aeronaves`, `voos`, `assentos`, `reservas`) já existe na prática neste projeto desde a atividade 08, com outros nomes: `AERONAVE`, `VOO`, `PASSAGEIRO` e `PASSAGEM`. Aqui "reservar um assento" é simplesmente inserir uma linha em `PASSAGEM` para aquele voo — não existe uma tabela `assentos` separada com status `DISPONIVEL`/`RESERVADO`, então "verificar se o assento existe" virou "verificar o formato do assento" (já garantido pelo `CHECK` da atividade 10) e "verificar disponibilidade" virou "verificar se já existe uma `PASSAGEM` para aquele voo + assento".

A restrição de unicidade do item 13 do enunciado (`UNIQUE` pra impedir reserva duplicada) também já existia: `uq_passagem_assento_voo` foi criada na atividade 10.

Banco: `aeroporto`, MariaDB 10.4 (XAMPP). Isolamento padrão do servidor: `REPEATABLE-READ`.

---

## A procedure (`sp_reservar_assento`)

Ficou em [locking.sql](locking.sql). Ela recebe CPF do passageiro, número do voo, número do assento e valor pago, e faz tudo dentro de uma transação:

1. Trava a linha do `VOO` com `SELECT ... FOR UPDATE` — assim só uma venda por vez acontece para aquele voo, e uma segunda sessão que tentar mexer no mesmo voo fica esperando.
2. Com o lock na mão, confere de novo se já existe uma `PASSAGEM` para aquele assento (é a revalidação que o enunciado pede depois que a primeira sessão libera o lock).
3. Se estiver tudo certo, insere a `PASSAGEM` e dá `COMMIT`.
4. Um `EXIT HANDLER FOR SQLEXCEPTION` cobre qualquer erro no meio do caminho (voo inexistente, assento já vendido, CPF que não existe, formato de assento inválido etc.): desfaz tudo com `ROLLBACK` e devolve o erro original pra quem chamou.

Os triggers da atividade 15 (`trg_passagem_valida_partida`, `trg_passagem_atualiza_assentos`) continuam rodando normalmente dentro da procedure, porque eles disparam no `INSERT` de `PASSAGEM` de qualquer jeito.

---

## Teste 1 — condição de corrida, sem passar pela procedure

Mesma coisa do item 10 do enunciado: uma transação manual (sem a procedure) pra deixar bem visível o `FOR UPDATE` segurando a segunda sessão.

**Cenário:** Ana Souza e Diego Farias tentando o mesmo assento `7A` do voo 100. A sessão 1 trava o voo, espera 4 segundos de propósito (`SLEEP(4)`) antes de inserir e comitar, e a sessão 2 é aberta ~1 segundo depois.

**Sessão 1 (Ana):**
```
inicio_sessao1        2026-09-28 10:49:49
numero_voo | assentos_disponiveis
100        | 178
segurando_o_lock_por_4s   0
fim_sessao1            2026-09-28 10:49:53
```

**Sessão 2 (Diego), rodando ao mesmo tempo:**
```
inicio_sessao2         2026-09-28 10:49:50
numero_voo | assentos_disponiveis
100        | 177                          -- só leu depois que a sessão 1 comitou
liberou_o_lock_sessao2  2026-09-28 10:49:53
assento_ja_vendido      1
fim_sessao2             2026-09-28 10:49:53
```

**Resultado:** a sessão 2 abriu às `10:49:50`, mas o `SELECT ... FOR UPDATE` dela só voltou às `10:49:53` — exatamente quando a sessão 1 comitou. Os quase 3 segundos de espera mostram o bloqueio acontecendo de verdade. Ao revalidar, a sessão 2 viu que o assento já tinha sido vendido (`assento_ja_vendido = 1`) e desistiu com `ROLLBACK`, em vez de simplesmente inserir sem checar.

---

## Teste 2 — mesmo assento, via procedure, concorrência real

Agora sem `SLEEP` nenhum: as duas chamadas de `CALL sp_reservar_assento(...)` foram disparadas praticamente ao mesmo tempo (dois processos `mysql` abertos juntos), pedindo o mesmo assento `8A` do voo 100.

**Sessão 1 (Elisa Prado, cpf 44455566677):**
```
inicio   2026-09-28 10:50:19
fim      2026-09-28 10:50:19
```
Passou.

**Sessão 2 (Diego Farias, cpf 33344455566):**
```
inicio   2026-09-28 10:50:19
ERROR 1644 (45000) at line 3: Assento ja vendido para esse voo.
```

**Resultado:** só uma linha foi criada pro assento `8A` (a da Elisa, `id_passagem = 8`). O Diego não tomou um erro genérico de chave duplicada — recebeu a mensagem tratada pela própria procedure, porque a revalidação dentro do lock pegou o conflito antes do `INSERT`.

---

## Teste 3 — assentos diferentes, concorrência real

Mesma ideia do teste 2, mas cada sessão pedindo um assento diferente do mesmo voo (`8B` e `8C`), pra mostrar que travar a linha do voo não impede vendas de assentos diferentes — só serializa rapidinho, sem falhar nenhuma das duas.

**Sessão 1 (Fabio Nogueira → 8B)** e **Sessão 2 (Gabriela Rocha → 8C)**, disparadas juntas: as duas terminaram no mesmo segundo (`10:50:37`), sem erro nenhum. Resultado final:

| id_passagem | assento | passageiro |
|---|---|---|
| 9 | 8C | Gabriela Rocha |
| 10 | 8B | Fabio Nogueira |

---

## Teste 4 — deadlock

Baseado no item 15 do enunciado, usando duas passagens que já existiam (`id_passagem = 4`, assento `5A`, e `id_passagem = 5`, assento `5B`, ambas do voo 100) como os dois recursos disputados:

- Sessão 1: trava o `id 4` primeiro, espera 2s, tenta travar o `id 5`.
- Sessão 2 (aberta ~0,3s depois): trava o `id 5` primeiro, espera 1s, tenta travar o `id 4`.

Ou seja, cada sessão pega um lock e depois tenta pegar o lock que a outra está seguranda — ordem invertida de propósito, pra fechar o ciclo.

**Sessão 1:**
```
inicio_s1                2026-09-28 10:50:54
(trava id 4, assento 5A)
segurando_5A              0
tentando_travar_5B_s1     2026-09-28 10:50:56
ERROR 1213 (40001): Deadlock found when trying to get lock; try restarting transaction
```

**Sessão 2:**
```
inicio_s2                2026-09-28 10:50:55
(trava id 5, assento 5B)
segurando_5B              0
tentando_travar_5A_s2     2026-09-28 10:50:56
(conseguiu travar id 4, assento 5A)
conseguiu_travar_5A_s2    2026-09-28 10:50:56
fim_s2                    2026-09-28 10:50:56
```

**Resultado:** o MariaDB detectou o ciclo de espera sozinho e cancelou a Sessão 1 (`ERROR 1213 — Deadlock found`), deixando a Sessão 2 seguir e comitar. Isso confirma o que o item 14 do enunciado descreve: o SGBD identifica o ciclo e cancela uma das transações pra liberar a outra, sem precisar de nada manual.

---

## Estado final das tabelas depois dos testes

```
PASSAGEM (voo 100): 5A, 5B, 7A, 8A, 8B, 8C vendidos
VOO 100: assentos_disponiveis = 174  (180 - 6 passagens, atualizado pelo trigger da atividade 15)
```

---

## Perguntas para discussão (resumo)

- **Por que só o `SELECT` de disponibilidade não basta?** Porque duas transações podem ler o mesmo assento como livre antes de qualquer uma escrever — é exatamente o teste 1 sem o `FOR UPDATE` fazendo a segunda sessão esperar.
- **Pra que serve o `FOR UPDATE`?** Trava a linha lida até o fim da transação, pra ninguém mais mexer nela enquanto a primeira sessão decide o que fazer.
- **Quando o lock é liberado?** No `COMMIT` ou `ROLLBACK` (visto nos 4 testes: a segunda sessão só anda depois que a primeira termina).
- **O que a segunda sessão faz enquanto espera?** Fica parada esperando o lock (teste 1: ~3 segundos de espera visível).
- **Por que revalidar depois do lock?** Porque o estado pode ter mudado enquanto a sessão esperava — é o que evita inserir em cima de um assento que acabou de ser vendido (teste 1 e 2).
- **Condição de corrida?** Duas transações concorrentes cujo resultado depende da ordem/tempo de execução — o cenário do teste 1 sem proteção.
- **Diferença entre lock e MVCC?** Lock bloqueia fisicamente quem pode mexer numa linha; MVCC deixa cada transação enxergar sua própria versão consistente dos dados sem travar leituras. Não são excludentes: o MariaDB usa MVCC pra leitura e locks explícitos (`FOR UPDATE`) quando é preciso garantir escrita exclusiva, como nessa atividade.
- **Como surge um deadlock?** Duas transações travando recursos em ordem invertida e esperando uma pela outra — exatamente o teste 4.
- **Por que travar sempre na mesma ordem ajuda?** Se as duas sessões do teste 4 tivessem travado `id 4` antes do `id 5`, uma simplesmente esperaria a outra terminar, sem nunca fechar o ciclo.
- **READ COMMITTED x REPEATABLE READ x SERIALIZABLE?** Em ordem crescente de rigidez: READ COMMITTED só garante leitura de dado confirmado (cada comando vê o estado mais recente); REPEATABLE READ (padrão do MariaDB, usado nesses testes) mantém a mesma visão dos dados durante toda a transação; SERIALIZABLE tenta simular execução totalmente sequencial das transações, podendo abortar mais operações por conflito.
- **Por que manter o `UNIQUE` mesmo com a procedure validando?** Porque ele é a última linha de defesa: se por algum motivo a validação da aplicação falhar ou for pulada, o banco ainda impede duas linhas pro mesmo assento — já era esse o papel do `uq_passagem_assento_voo` desde a atividade 10.
- **Como tratar transação abortada por deadlock?** Detectar o erro (`1213` no MariaDB) e reexecutar a transação — o MariaDB já resolve o impasse cancelando uma das duas, cabe à aplicação tentar de novo.

## Conclusão

A procedure resolveu o problema de concorrência combinando o que o enunciado pede: transação, `FOR UPDATE` pra travar a linha do voo, revalidação depois do lock e tratamento de erro com `ROLLBACK`. Os quatro testes mostraram cada peça funcionando: a espera real pelo lock, a resolução limpa quando dois passageiros disputam o mesmo assento (sem duplicar nada, graças também ao `UNIQUE` da atividade 10), a ausência de bloqueio real entre assentos diferentes, e o MariaDB detectando e resolvendo um deadlock provocado de propósito.
