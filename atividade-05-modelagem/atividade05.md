# 1. Definição dos atributos

## PASSAGEIRO
1. nome_completo
2. data_nascimento
3. CPF_(id)
4. genero

## VOO
1. numero_voo (id)
2. origem
3. destino
4. horario_partida
5. horario_chegada

## AERONAVE
1. fabricante
2. modelo
3. numero_aeronave (id)

# 2. Identificação dos relacionamentos

## PASSAGEIRO <-> VOO
Um passageiro(0,N) pode realizar vários voos.
Um voo(1,N) pode possuir vários passageiros.
- A cardinalide então é **N:N**.

## AERONAVE <-> VOO
Uma aeronave(0,N) pode realizar vários voos.
Cada voo(1,1) é realizado por uma aeronave.
- A cardinalide então é **1:N**.

# 3. Resolvendo o relacionamento N:N
Para resolver o relacionamento N:N do PASSAGEIRO <-> VOO, vamos usar uma tabela associativa que vai quebrar o N:N em dois 1:N.


**PASSAGEM**
|Atributo |	Tipo de chave|
|---------|--------------|
|id_passagem |	PK |
|CPF |	FK → PASSAGEIRO|
|numero_voo |	FK → VOO|
|numero_assento |	atributo simples|
|classe |	atributo simples (econômica, executiva, primeira classe)|
|status_checkin |	atributo simples (pendente, realizado)|
|valor_pago |	atributo simples|
|data_reserva | atributo simples|


# 4. Modelo lógico

## PASSAGEIRO
1. CPF (PK)
2. nome_completo
3. data_nascimento
4. genero

## AERONAVE
1. numero_aeronave (PK)
2. fabricante
3. modelo

## VOO
1. numero_voo (PK)
2. origem
3. destino
4. horario_partida
5. horario_chegada
6. numero_aeronave (FK -> AERONAVE)

## PASSAGEM
1. id_passagem (PK)
2. CPF (FK -> PASSAGEIRO)
3. numero_voo (FK -> VOO)
4. numero_assento
5. classe
6. status_checkin
7. valor_pago
8. data_reserva

# 5. Questões finais
1. Por que não podemos simplesmente colocar id_passageiro dentro da tabela VOO ?
Porque um voo pode ter vários passageiros, e uma coluna só guarda um valor por linha. Se eu colocasse CPF em VOO, cada voo só poderia ter 1 passageiro — o que está errado, já que a relação é N:N.

2. Por que precisamos de uma tabela associativa entre PASSAGEIRO e VOO?
Porque nenhuma FK simples resolve N:N. A tabela associativa (PASSAGEM) fica "no meio", guardando pares (passageiro, voo), transformando o N:N em dois relacionamentos 1:N. Assim cada passageiro pode estar em vários voos e cada voo pode ter vários passageiros.

3. Qual é a diferença entre uma chave primária (PK) e uma chave estrangeira (FK)?
- PK: identifica de forma única cada registro da própria tabela. Não pode se repetir nem ser nula.
- FK: é uma coluna que referencia a PK de outra tabela, criando a ligação entre elas. Pode se repetir (ex: o mesmo numero_voo aparece várias vezes em PASSAGEM, uma vez pra cada passageiro daquele voo).

**Desafio**
Considere agora a seguinte regra:
Um passageiro não pode ocupar dois assentos diferentes no mesmo voo.
Como você poderia modificar o modelo para garantir essa regra?
- Do jeito que está atualmente, um pasageiro poderia apareçer duas vezes no mesmo voo, com assentos diferentes. Para corrigir isso, é preciso utilizar o UNIQUE juntamente com o CPF e o número do voo, assim fazendo a combinação CPF+VOO aparecer apenas uma vez na tabela.