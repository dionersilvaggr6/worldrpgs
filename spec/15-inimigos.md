# 15 — Inimigos: o bestiário

> **WP6 · Fable** (31-07-2026). O bestiário completo, construído sobre: as **7 raças** do Rico ([`04-inimigos-chefes.md`](04-inimigos-chefes.md), aprovadas pelos dois a 31-07), as restrições que o WP1 impôs a todo o inimigo, e os números dos 3 da fatia já derivados no WP2 ([`11-formulas.md`](11-formulas.md)). Chefes têm documento próprio (WP7); o Vorgar aparece aqui só como referência de zona. Tudo `[FABLE]` salvo indicação.

## As regras herdadas — nenhum inimigo escapa a estas

1. **Telegrafia ≥ 0,5 s legível na silhueta** em todo o ataque (WP1). O aviso é pose + som distinto (WP12); a cara não conta, a cor sozinha não conta.
2. ⚠️ **Som direccional antes do campo de visão** — acrescentado por [`29-perspectiva.md`](29-perspectiva.md) depois deste documento ter sido escrito. O jogador pode estar em **primeira pessoa**, e aí não tem visão periférica: **todo o ataque que venha de fora do ecrã tem de ser anunciado por som direccional antes de entrar**. Sem isto, um golpe de fora do enquadramento é injusto — e injusto é o que a Lei 1 recusa. Cada ficha do bestiário tem de dizer **que som anuncia cada ataque**, ao lado da telegrafia visual. `[CLAUDE]` — a completar pelo autor do WP6.

3. **Cada ataque traz a marca `aparável` ou `só esquiva`** (WP1). A língua visual é fixa (WP12): `só esquiva` = brilho vermelho curto; aparável = silhueta sem vermelho.
4. **Velocidade:** patrulha < 5,0 m/s — **fugir a correr é sempre possível e grátis** (WP1). Perseguição ≤ 5,0 m/s sustentada; só o **fecho** (anti-kite dos 4 s, WP1) pode ser mais rápido, e é curto e telegrafado.
5. **Postura 0–100** por inimigo; dano de postura = MV × 10, bash ×2, martelos ×1,5 (WP1/WP5). A zero → **Cambaleio 1,2 s**, ripostável.
6. **Tecto de cena:** ≤ 5 inimigos animados em combate ao mesmo tempo (orçamento do WP12). Encontros desenham-se dentro disto.
7. **Nenhum inimigo é desenhado para ser repetido** (Lei 1: sem grind). O XP é o que é; a razão de voltar a uma zona é o mundo, não a mochila.

## IA — o cérebro comum, uma vez só

Todos os inimigos correm a mesma máquina; cada ficha muda os números, nunca as regras.

| Estado | Comportamento | Números por omissão |
|---|---|---|
| **Patrulha** | rota fixa curta ou posto parado; 2,0 m/s | — |
| **Alerta** | viu/ouviu qualquer coisa: vira-se, avança 2 passos, espreita 2 s | visão: cone 90°, 15 m · audição: passos a correr 8 m, combate 20 m |
| **Chamada** | ao confirmar o alvo, grita — **o grito é o aviso ao jogador** (WP12: é mecânica) e acorda aliados num raio de 10 m | 0,8 s vulnerável durante o grito |
| **Combate** | aproxima, orbita, ataca pela ficha própria | perseguição 4,5–5,0 m/s |
| **Fecho** | 4 s sem alcançar o alvo (WP1): investida/salto/projéctil próprio, telegrafado | por ficha |
| **Desistência** | 6 s sem ver o alvo, ou a 30 m do posto: regressa, e **cura ao chegar** | evita luta de atrito à distância |

**Regra de grupo — o círculo de agressão:** por muito grande que o grupo seja, **no máximo 2 atacam ao mesmo tempo**; os outros orbitam a 3–5 m, visíveis, à espera de vaga. *Porquê:* 5 golpes simultâneos não se lêem — a leitura é a Lei 1; o grupo pressiona pelo cerco, não pela chuva. *Alternativa descartada:* todos atacam à vontade — é como os jogos maus fazem multidões, e é injusto exactamente da maneira que este jogo recusa.

**Fraquezas legíveis no corpo** — a regra que faz o "tem que ver a magia que tu usa nele" (05:04) funcionar: toda a resistência/fraqueza da tabela **vê-se no modelo** (o zumbi escorre; o esqueleto é osso seco; o mímico tem dentes na fresta). Fraqueza escondida em tabela invisível é design partido.

## O bestiário

Números à escala da **zona ×1,0** (a linha de base da fatia — WP2); zonas futuras multiplicam pela curva do WP8. PV/DEF/dano dos 3 da fatia são os derivados do WP2, repetidos aqui para o bestiário viver num sítio só.

### Orcs — a raça da fatia `[DECIDIDO]` (02:25)

| | **Orc lanceiro** ✅ | **Orc brutamontes** ✅ | Orc xamã ⬜ |
|---|---|---|---|
| Papel | o professor da esquiva | o professor do parry | o primeiro conjurador |
| PV / DEF / Postura | 135 / 4 / 40 | 260 / 8 / 70 | 110 / 2 / 30 |
| Almas | 25 | 45 | 35 |
| Peças que usa (= pode largar) | grevas de couro, tiras do braço | **espaldar de ferro**, cinturão de placas | amuletos de osso (acessório) |
| Velocidade | 4,5 m/s | 3,2 m/s | 3,5 m/s |

**Lanceiro — os ataques:**

| Ataque | Aviso | Marca | Dano | O que ensina |
|---|---|---|---|---|
| Estocada | 0,5 s — recua a lança à anca **· som: raspar da lança na braçadeira** | aparável | 55 | esquiva lateral (a estocada é uma linha) |
| Combo picado ×2 | 0,6 s — bate a lança no chão **· som: os dois toques secos no solo** | aparável | 40+40 | esperar o segundo antes de responder |
| Fecho: arremesso da lança | 0,8 s — arma o braço atrás **· som: grunhido de arranque + assobio no voo** | aparável (desvia) | 45 | não se fica parado ao longe; ele recupera a lança do chão ou saca uma curta (dano 40) |

**Brutamontes — os ataques (todos aparáveis, todos lentos — WP1):**

| Ataque | Aviso | Marca | Dano | O que ensina |
|---|---|---|---|---|
| Pancada vertical | 0,9 s — ergue o tronco todo **· som: arrasto grave do ferro a subir** (a lição de ouvido do WP12) | aparável | 130 | o parry: é o convite mais lento e mais telegrafado do jogo |
| Varrido horizontal | 0,6 s — roda os ombros **· som: rangido do cinturão + sopro** | aparável | 100 | esquivar **para dentro** também funciona |
| Fecho: passo esmagador | 0,7 s — salta com o peso **· som: o chão a queixar-se no impulso** | aparável | 110 | a distância não é abrigo |

**Xamã** ⬜: projéctil lento (1,2 s de conjuração audível, aparável — devolve-se com o parry, sem dano ao xamã mas cancela e tira 30 de postura), e **totem** que dá +20% de velocidade aos orcs num raio de 8 m — morre num golpe. Ensina prioridade de alvo. Entra na expansão da zona orc.

### Goblins ⬜ — o cerco (nota do Rico: "ataca em grupos")

| | Goblin faca | Goblin fundíbulo |
|---|---|---|
| PV / DEF / Postura | 60 / 0 / 20 | 50 / 0 / 15 |
| Almas | 15 | 15 |
| Velocidade | 5,0 m/s | 3,8 m/s |
| Ataques | facada (0,5 s, aparável, 35) · salto às costas (0,7 s, **só esquiva**, 45 — larga-se com o dano) | pedra (1,0 s a rodar a funda, audível, aparável, 30) |

Aparecem **3 a 5**, nunca menos de 3. Com o círculo de agressão (2 de cada vez), o grupo ensina o que o lock-on não faz sozinho: soltar o alvo, ler a sala, usar o varrido do machadão. Fogem a 20% de PV do grupo (moral de bando) — perseguir ou deixar ir é escolha do jogador.

### Kobolds ⬜ — o terreno (nota: "covarde que gosta de armadilhas")

| | Kobold armadilheiro |
|---|---|
| PV / DEF / Postura | 70 / 2 / 20 · almas 20 · 4,2 m/s |
| Comportamento | **não procura combate**: foge para junto das armadilhas que armou e espera |
| Armadilhas | espinhos (marca vermelha ténue no chão — vê-se a andar devagar, não a correr; 60 de dano, `só esquiva` no sentido literal) · corda de tropeço (derruba 1,0 s) |
| Ataques | facada curta (0,4 s, aparável, 30) — só se encurralado |

Ensina a **andar** — a zona dele pune o sprint cego. Par natural das dungeons (05-mundo): a Toca 2.0 e labirintos.

### Mortos-vivos ⬜ — a raça que responde à magia (e ao mal, quando entrar)

Fraqueza de escola herdada do WP4: **bem: DEF −20 · mal: DEF +20**. É a raça onde a pergunta 8 se joga.

| | Esqueleto de espada | Esqueleto arqueiro | Zumbi | Zumbi inchado |
|---|---|---|---|---|
| PV / DEF / Postura | 90 / 6 físico cortante ×0,5 dano recebido* / 30 | 70 / 4 / 20 | 180 / cortante ×0,5, contundente ×1,5, fogo ×2 / 60 | 120 / idem / 40 |
| Almas | 30 | 30 | 20 | 25 |
| Velocidade | 4,0 m/s | 3,0 m/s | 1,8 m/s (anda, nunca corre) | 2,2 m/s |

\* **Osso não se corta, parte-se:** cortante faz metade, **contundente (martelos, bash) faz ×1,5** — a Lei 2 do lado do inimigo: a resposta é trocar de ferramenta, não subir número.

- **Esqueleto de espada:** golpes rápidos (0,5 s, aparáveis, 45). **Reergue-se uma vez** 3 s depois de "morrer", com 50% de PV — a não ser que o golpe final seja contundente ou o corpo seja pisado no chão. Ensina a acabar o trabalho.
- **Arqueiro:** seta (1,1 s a puxar, postura de arco visível, aparável — desvia). Recoloca-se a cada 2 setas.
- **Zumbi:** agarrão lento (0,9 s, **só esquiva**, 70 + segura 1,5 s — o parceiro pode bater para soltar já: gancho de co-op). Nunca desiste, nunca cura ao regressar — a pressão dele é o relógio.
- **Zumbi inchado:** ao morrer, **incha 1,5 s e rebenta** (nova vermelha no corpo — `só esquiva`, raio 3 m, 90). Matar ao pé do parceiro é erro de equipa.

### Minotauro ⬜ — subchefe de labirinto

Registado no bestiário; a ficha completa (arena, fases, drops) é do **WP7**, ao lado do Ceifador. O que fica já: PV ~800 à escala da zona, investida em linha recta (1,0 s de patada no chão, **só esquiva**, 160) que **choca com paredes** — o labirinto é a arma do jogador contra ele. Cambaleio de 3,0 s ao chocar: o único inimigo em que o cenário é a janela de dano.

### Mímico ⬜ — o castigo da ganância

| PV / DEF / Postura | 240 / 10 / 80 · almas 80 |
|---|---|

Baú falso. **Sempre detectável antes** (regra de justiça): respira devagar — a tampa sobe 2 px a cada 3 s — e a fechadura é diferente da dos baús verdadeiros (uma língua visual a fixar no WP13, igual no jogo inteiro). Abrir sem olhar: mordida (**só esquiva**, 110) e o combate começa. Quem bate primeiro no baú em vez de o abrir ganha o primeiro golpe de borla. Larga loot de baú real + o dobro. Ensina: no mundo deste jogo, olhar primeiro é sempre opção — e paga.

## Reaparecimento

Herdado do WP1: inimigos normais renascem quando o jogador **descansa ou morre**; não renascem por tempo nem por distância. Mímicos e subchefes **não renascem** (são encontros, não recursos). *Porquê:* renascer por descanso mantém o mundo perigoso sem nunca obrigar a re-limpar por obrigação — quem não descansa atravessa zonas limpas. ✅ Lei 1.

## O que cada inimigo dá

Almas na tabela de cada ficha (os da fatia: derivados no WP2; almas nunca são a razão de repetir — ver regra 8). **Drops de item são do WP9**, com duas regras fixadas aqui: inimigo comum larga materiais, consumíveis e **as peças que usa no corpo** (regra 7), **nunca** skills/pergaminhos (esses são de chefes e exploração).

## Encontros da fatia 1 — a colocação exacta

(O traçado da zona é do WP8; isto fixa **composição**, para o tecto de 5 e o círculo de agressão serem verificáveis.)

| Onde | Composição | Intenção |
|---|---|---|
| Orla de Brumal | 1 lanceiro | o primeiro duelo limpo — a esquiva aprende-se aqui (27-aprendizagem) |
| Caminho do meio | 2 lanceiros | o círculo de agressão apresenta-se |
| Clareira da árvore morta | 1 brutamontes | o professor do parry, sozinho de propósito |
| Entrada da Toca | 1 brutamontes + 1 lanceiro | o exame: dois ritmos ao mesmo tempo |
| Toca, sala 2 | 2 lanceiros (emboscada às costas) | o som antes da vista — a chamada ouve-se primeiro |
| Toca, sala 3 | 1 brutamontes + 2 lanceiros | o encontro máximo antes do chefe (3 ≤ tecto 5, com folga para o co-op) |

## O que este documento entrega aos outros

| Para | O quê |
|---|---|
| **WP7** | Minotauro e Ceifador à espera de ficha de chefe; a régua de telegrafia por camada |
| **WP8** | raças por bioma (kobolds → dungeons; mortos-vivos → a zona do Ceifador; goblins → campo aberto) e os encontros como grelha de povoamento |
| **WP9** | XP por inimigo; a regra "comuns largam materiais, nunca verbos" |
| **WP12/WP13** | por raça: variações de malha, grito de chamada, sons de esforço; as línguas visuais novas (fechadura de mímico, marca ténue de armadilha) |
| **Protótipo (marco 2)** | lanceiro e brutamontes com fichas completas de ataque — são eles o teste dos números do WP1 |

## O que continua aberto

- **A confirmação do Mateus** às 7 raças e ao Ceifador (⏳ da instrução do Rico)
- Sons dos ataques das raças ⬜ (goblins/kobolds/mortos-vivos) — fecham-se com as fichas completas, mesma regra 6
- Camada exacta do Minotauro e do Ceifador na pirâmide → pergunta 13, deles
- Quantos inimigos novos por zona futura → WP8, com a escala do mundo (pergunta 4)

## Ligações

[`04-inimigos-chefes.md`](04-inimigos-chefes.md) (raças, sessão de ideias) · [`01-combate.md`](01-combate.md) (regras herdadas) · [`11-formulas.md`](11-formulas.md) (derivação dos números) · [`13-magia.md`](13-magia.md) (fraquezas de escola) · [`27-aprendizagem.md`](27-aprendizagem.md) (os professores) · [`10-fatia-1.md`](10-fatia-1.md)
