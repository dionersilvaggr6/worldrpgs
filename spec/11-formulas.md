# 11 — Atributos e fórmulas

> **WP2 · Fable** (31-07-2026). Este documento resolve a sobreposição de atributos da sessão 1, fixa a fórmula de dano, e escreve as curvas dos inimigos da fatia 1 **a partir das restrições que o WP1 impôs** ([`01-combate.md`](01-combate.md), secção Ataques). Tudo `[FABLE]` salvo indicação; valida-se no protótipo (marco 2) junto com os números do combate.

## Os atributos — de 4 confusos para 6 claros

O que eles decidiram: modelo Dark Souls, pontos por nível, distribuídos à escolha `[DECIDIDO]` (sessão 1 · 06:33), com quatro nomes ditos: vida, sabedoria, constituição, stamina. E o sistema de requisitos de arma do Dark Souls `[DECIDIDO]` (06:14). A sobreposição Vida/Constituição era a pergunta 12; os requisitos pedem atributos de ataque que ninguém nomeou.

| Atributo | O que faz, exactamente | Origem |
|---|---|---|
| **Vida** | PV máximos: `PV = 200 + 22×Vida` (após 30: +8/ponto) | `[DECIDIDO]` 06:33 |
| **Stamina** | Stamina máxima: `STA = 80 + 2×Stamina`. A regeneração (40/s) **não escala** | `[DECIDIDO]` 06:33 |
| **Constituição** | Defesa física: `DEF = 2×Constituição`, subtraída por golpe, **nunca acima de 40% do dano do golpe** | `[DECIDIDO]` 06:33 · papel `[FABLE]` |
| **Sabedoria** | Cargas de magia totais: `cargas = 4 + ⌊Sabedoria/4⌋` + requisito das magias | `[DECIDIDO]` 06:33, 03:50 |
| **Força** | Requisito e escala das armas pesadas | `[FABLE]` |
| **Destreza** | Requisito e escala das armas rápidas | `[FABLE]` |

**Resolução da pergunta 12** `[FABLE]`: Vida = margem total (quantos golpes aguentas); Constituição = dureza por golpe (quanto dói cada um). Papéis distintos, os dois nomes deles sobrevivem. *Alternativa descartada:* fundir os dois num só — perdia um nome que eles disseram, e perdia a escolha "tanque de PV vs tanque de casca".

**Força e Destreza** `[FABLE]`: o sistema de requisitos que eles próprios escolheram (06:14, "o mesmo sistema que o Dark Souls") não funciona sem atributos de ataque. *Alternativa descartada:* escalar armas por skills — menos legível numa ficha, e as skills já têm o seu papel (WP3).

- Todos os atributos começam em **8**; a classe distribui **+14** iniciais (WP3). Máximo por atributo: **50**. *Soft cap:* acima de 30, o ganho por ponto cai (Vida +8 em vez de +22; escala de arma a metade).
- A regeneração de stamina, as janelas de esquiva/parry e a velocidade **nunca escalam com atributos** — são a gramática do jogo, igual do nível 1 ao 100. É a Lei 1 em fórmula: o nível compra margem (PV, STA, defesa, cargas), nunca compra as ferramentas.

## Nível e pontos

| Parâmetro | Valor |
|---|---|
| Pontos por nível | **1** (num atributo à escolha) |
| Nível máximo | **100** `[FABLE]` — eles sugeriram "100 ou, sei lá, 150" (06:33); adopto o mais baixo. *Alternativa descartada:* 150 — mais níveis com soft caps é só mais grind aparente |
| Fatia 1 | níveis 1–10 |
| Custo do nível n | `custo = 80 + 20×n` **almas** (nível 2 custa 120, nível 10 custa 280; total 1→10: **1.880**; total 1→100: **~109.000**) — o nome fechou em [`33-morte-e-almas.md`](33-morte-e-almas.md): almas = experiência e moeda |

**Almas na fatia:** lanceiro 25 · brutamontes 45 · Vorgar 400. Uma travessia limpa de Brumal + Toca rende ~350; zerar a fatia com as mortes normais deixa o jogador por volta do **nível 6–8, não do 10**. *Teste da Lei 1:* o cap da fatia não é garantido nem necessário — o critério 3 da fatia (nível 1, zero pontos, mata o Vorgar) continua a ser a prova de que nível nenhum é obrigatório. ✅

## A fórmula de dano

Interface fixada no WP1:

```
dano_por_golpe = MV × dano_base_da_arma × escala_de_atributos − DEF_do_alvo
escala_de_atributos = 1 + 0,015 × (atributo_relevante − 8) × peso_da_escala
```

- `MV` — do golpe, tabela do WP1.
- `peso_da_escala` — da arma: **forte 1,0 · médio 0,6 · fraco 0,3**.
- Dano mínimo após defesa: **60% do dano calculado** (a DEF corta no máximo 40% — ninguém fica imune a nada).
- **Abaixo do requisito da arma:** dano ×0,6 e escala = 1 (sem bónus). É o "quão mau" da Lei 3: qualquer um pega em qualquer arma, e paga-se em números, não em proibição.

### As armas da fatia

| Arma | Dano base | Requisito | Escala | Peso | Fatia 1? |
|---|---|---|---|---|---|
| Adaga | 32 | Des 10 | Destreza | forte 1,0 | ✅ |
| Espada longa | 40 | For 10 · Des 8 | Força | médio 0,6 | ✅ |
| Machadão | 52 | For 14 | Força | forte 1,0 | ✅ |
| Cajado (pancada) | 30 | — | Sabedoria | fraco 0,3 | ✅ |
| Escudo (bash) | 25 | For 8 | Força | fraco 0,3 | ✅ |
| Arco | 38 | Des 12 | Destreza | médio 0,6 | ⬜ fatia 2 |

O dano das **magias** escala com Sabedoria (peso forte 1,0) sobre o dano base de cada magia — catálogo no WP4.

### Exemplo resolvido, ponta a ponta

Guerreiro nível 1 (For 12), espada longa, ataque leve (MV 1,0), contra um lanceiro (DEF 4):

```
escala = 1 + 0,015 × (12−8) × 0,6 = 1,036
dano   = 1,0 × 40 × 1,036 − 4 = 41,4 − 4 ≈ 37
```

Lanceiro tem 135 PV → morre em **4 golpes** (⌈135/37⌉). A restrição do WP1 pedia 3–5. ✅

Mesmo guerreiro com o cajado (não cumpre nada, peso fraco, For não conta): `1,0 × 30 × 1 − 4 = 26` → 6 golpes. Pior, mas funciona — Lei 3 em números. ✅

## Tipos de dano e resistências

| Tipo | Na fatia 1 | Fonte |
|---|---|---|
| Físico | ✅ | todas as armas |
| Mágico | ✅ | Dardo, Ruína |
| Raio | ✅ | habilidade do Paladino ("um pouco de raio", 08:39) |
| Fogo | ⬜ | encantamentos (espada de fogo, 00:45) — WP5 |
| Bem / Mal | ⬜ | espera pela pergunta 8 |

Resistência por inimigo = DEF separada por tipo (WP6 preenche). O princípio "a magia certa para o inimigo certo" (05:04) implementa-se aí: fraqueza = DEF negativa a um tipo.

## As curvas dos inimigos da fatia — derivadas, não inventadas

As restrições do WP1 (nível 1, espada, zero pontos) resolvem-se com o dano ≈ 37 do exemplo:

| Inimigo | PV | Derivação | DEF | Dano (leve/pesado) | Postura | Fatia 1? |
|---|---|---|---|---|---|---|
| Orc lanceiro | **135** | 4 leves × 37 (pedido: 3–5) | 4 | 55 / — | 40 | ✅ |
| Orc brutamontes | **260** | 7 leves (pedido: 6–9) | 8 | — / 130 | 70 | ✅ |
| **Vorgar** (solo) | **1.950** | 53 leves (pedido: 45–70) | 10 | 120 / 190 | 100, ×0,5 dano de postura recebido | ✅ |
| Vorgar (co-op) | **3.510** | ×1,8 (fatia 1) | 10 | idem, alterna alvo | idem | ✅ |

Contra o jogador nível 1 (Vida 10 → **420 PV**, Con 10 → DEF 20):

- Lanceiro: 55−20 = 35 → mata em **12 golpes**. Morrer para ele é distracção prolongada, não emboscada. Professor de esquiva pode sê-lo sem executar.
- Brutamontes: 130−20 = 110 → mata em **4**. Respeita-se; todos os golpes dele são aparáveis (WP1/WP6).
- Vorgar: 120−20 = 100 (leve), 190−20 = 170 (pesado) → mata em **3–4 golpes**. Uma tentativa a nível 1 dura 4–7 min de leitura quase perfeita: exigente, possível, e é exactamente o critério 3 da fatia.

*Teste da Lei 1, escrito:* a nível 1 nada é impossível por números — o Vorgar morre em 53 leves (~35 s de frames activos dentro de 4–7 min de dança) e os 300 ms de i-frames da esquiva não dependem de atributo nenhum. A nível 10 (+9 pontos, p. ex. Vida→14, For→14, Con→13), o dano sobe ~5% e os PV ~20%: **margem de erro, não porta.** Se o protótipo mostrar TTK fora das janelas do WP1, ajusta-se `dano_base` das armas — **nunca** as janelas de esquiva/parry. ✅

## O que este documento entrega aos outros

| Para | O quê |
|---|---|
| **WP3** | os 6 atributos, o 8 base + 14 pontos iniciais por classe, requisitos das armas por classe de arranque |
| **WP4** | `cargas = 4 + ⌊Sab/4⌋`; escala de magia = Sabedoria peso 1,0 |
| **WP5** | a tabela de armas (dano base, requisitos, escala) pronta a estender |
| **WP6/WP7** | PV, DEF, dano e postura dos 3 inimigos da fatia, com a derivação à vista |
| **Protótipo (marco 2)** | tudo isto em dados afináveis — se os TTK falharem as janelas do WP1, mexe-se aqui primeiro |

## O que continua aberto

- **Pergunta 7** (como se recupera vida) — decide o valor real dos 420 PV; WP5 propõe.
- **Pergunta 8** (bem/mal) — os tipos de dano ficam com o lugar reservado na tabela.
- Escala de armas élite (graus S/A/B) e armas a duas mãos com bónus de Força: **fora da fatia**, notas para o WP5 quando o catálogo crescer.
