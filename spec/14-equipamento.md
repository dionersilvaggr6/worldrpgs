# 14 — Armas e equipamento

> **WP5 · Fable** (31-07-2026). O catálogo completo, construído **por cima** dos números já fixados: frames e MV das armas da fatia no [`01-combate.md`](01-combate.md) (WP1), fórmula e pesos de escala no [`11-formulas.md`](11-formulas.md) (WP2), encantamentos no [`13-magia.md`](13-magia.md) (WP4). Nada daqui altera esses documentos — estende-os. Tudo `[FABLE]` salvo indicação; fontes dos modelos 3D no [`22-assets.md`](22-assets.md) (WP13).

## A Lei 3 em números (herdada, num sítio só)

Qualquer classe pega em qualquer arma `[DECIDIDO]` (05:44 → 06:17). Quem **não cumpre o requisito**: dano **×0,6** e escala = 1 (sem bónus de atributo) — regra do WP2. O moveset **nunca muda** com atributos: a velocidade da arma é da arma, senão a leitura em co-op quebrava.

*Teste da Lei 1/Lei 3:* nenhuma arma "não funciona" — funciona a 60% e sem crescimento. A porta não existe; existe física. ✅

## Famílias de moveset

Uma família = um conjunto de animações (a unidade de custo do WP12/WP13). A fatia 1 usa **5**; o catálogo completo pede mais **3**.

| Família | Identidade de movimento | Combo | Fatia 1? |
|---|---|---|---|
| Adagas | curtíssimo alcance, o parry de risco (WP1: adaga apara) | ×4 | ✅ |
| Espadas retas | o metro do jogo | ×3 | ✅ |
| Machados grandes | lentos, pesado carregável com hiper-armadura | ×2 | ✅ |
| Cajados | pancada fraca + conjuração; duas mãos | ×2 | ✅ |
| Escudos | bloqueio 100% físico + bash (postura ×2) | — | ✅ |
| Lanças | **ataca com o escudo erguido** (golpe de estocada, MV baixo) — a única família que o faz | ×2 | ⬜ |
| Martelos | dano de postura ×1,5 em todos os golpes; frames de machadão | ×2 | ⬜ |
| Arcos | puxar 0,9 s parado a 30%, aljava 15, setas recuperáveis ~70% (regras já no WP1) | — | ⬜ fatia 2 |

Famílias novas entram com os frames fechados **no WP1** (é ele o dono de frames e MV) — este catálogo fixa identidade, números de dano e requisitos.

## A arte de arma — a tecla partilhada (regra dos comandos, 34 §2)

**Cada arma tem uma arte, activada numa tecla só — `V`** `[FABLE]` (livre no mapa do WP1; o WP11 valida). O que a tecla faz depende da arma na mão — é o único modo que escala para as **~20 armas por classe (~120)** decididas no 34. A arte é da **família** por omissão (variações por arma são a excepção, não a regra):

| Família | Arte de arma (na tecla `V`) | Custo |
|---|---|---|
| Espadas retas | **Guarda-alta** — postura 1,2 s: o próximo golpe recebido é aparado como parry de escudo | 20 stamina |
| Adagas | **Passo-navalha** — passo lateral curto (1,5 m) + corte no mesmo tempo | 15 |
| Machados grandes | **Giro** — 360°, acerta tudo em 2,3 m, MV 1,8 | 35 |
| Cajados | **Varrer arcano** — empurra 2 m tudo em cone (0 dano, espaço) | 15 |
| Lanças | **Muralha de pontas** — recuo + estocada dupla | 22 |
| Martelos | **Terramoto** — pancada no chão, postura em área | 30 |
| Arcos | **Tiro carregado** — a puxa segura vira perfurante | munição |
| Escudos | a investida já é a arte (tabela do WP1) | 15 |

O catálogo das 120 constrói-se **arma a arma por cima da fatia** (34 §1: "nunca de uma vez"); cada arma nova traz a linha completa — dano, requisito, escala, **e a arte, com a coluna "tecla existe? ✅ partilhada"**.

## Catálogo de armas

As 5 da fatia repetem os valores já fixados (WP1/WP2), para o catálogo viver num sítio só. Colunas: dano base · requisito · escala (atributo + peso do WP2: forte 1,0 · médio 0,6 · fraco 0,3) · alcance.

| Arma | Família | Dano | Requisito | Escala | Alcance | Fatia 1? |
|---|---|---|---|---|---|---|
| **Adaga** | adaga | 32 | Des 10 | Des · forte | 1,4 m | ✅ |
| **Espada longa** | espada reta | 40 | For 10 · Des 8 | For · médio | 2,0 m | ✅ |
| **Machadão** | machado grande | 52 | For 14 | For · forte | 2,3 m | ✅ |
| **Cajado (pancada)** | cajado | 30 | — | Sab · fraco | 1,8 m | ✅ |
| **Escudo (bash)** | escudo | 25 | For 8 | For · fraco | 1,2 m | ✅ |
| Espada curta | espada reta | 34 | For 8 · Des 8 | Des · médio | 1,7 m | ⬜ |
| Montante | espada reta | 50 | For 16 · Des 10 | For · forte | 2,2 m | ⬜ |
| Maça | martelo | 44 | For 12 | For · médio | 1,6 m | ⬜ |
| Martelão | martelo | 60 | For 18 | For · forte | 2,3 m | ⬜ |
| Lança | lança | 36 | For 8 · Des 10 | Des · médio | 2,6 m | ⬜ |
| Alabarda | lança | 46 | For 14 · Des 8 | For · médio | 2,5 m | ⬜ |
| Cajado de Carvalho | cajado | 32 | Sab 14 | Sab · fraco · **poder arcano 115%** | 1,8 m | ⬜ |
| Cajado de Espinhos | cajado | 30 | Sab 18 | Sab · fraco · **mal +20%, bem −10%** | 1,8 m | ⬜ |
| Arco | arco | 38 | Des 12 | Des · médio | 25 m (queda além de 18 m) | ⬜ fatia 2 |
| Arco longo | arco | 46 | Des 16 · For 10 | Des · médio | 32 m (queda além de 24 m) | ⬜ |

**Cajados como catalisadores** `[FABLE]`: o dano das magias multiplica pelo *poder arcano* do cajado (o do Aprendiz, da fatia: 100%). É onde "achar um cajado bom" vale — e a objecção do Rico (05:57, "tu pegar um cajado bom, tu vai ser melhor com o mago?") continua respondida pelo sistema: sem Sabedoria não há cargas nem escala; o cajado bom na mão errada é um pau. *Alternativa descartada:* cajados com magias próprias embutidas — mistura duas gavetas (arma e pergaminho) e rouba o loot de verbos ao WP4.

**Requisitos verificados contra as fichas do WP3:** cada arma ⬜ tem pelo menos uma classe que a cumpre entre os níveis 5–15 sem build dedicada (ex.: montante For 16 = Berserker +2 pontos; lança Des 10 = qualquer um com 2 pontos). Nenhum requisito acima de 18 — requisito alto demais é bloqueio disfarçado, e a Lei 3 não o quer.

## Escudos

O modelo do WP1: escudo absorve **100% físico / 50% mágico**, custo de stamina por golpe = `15 × peso do golpe` (leve 1,0 · pesado 1,8). O catálogo varia o **custo** e a **absorção mágica** — nunca a física (bloquear-ou-não tem de ser leitura binária, não conta de percentagens):

| Escudo | Custo por golpe | Absorção mágica | Requisito | Extra | Fatia 1? |
|---|---|---|---|---|---|
| **De madeira** | 15 × peso | 50% | For 8 | — | ✅ |
| De ferro | 13 × peso | 60% | For 12 | — | ⬜ |
| De torre | 11 × peso | 70% | For 16 | sprint −15% com ele equipado | ⬜ |

## Melhoria de armas ⬜ (fatia 2, com a exploração)

- Níveis **+1 a +5**, **+6% de dano base por nível** (tecto +30%).
- Materiais: **Limalha** (+1 a +3 — baús e cantos de zona) e **Limalha Nobre** (+4/+5 — dungeons). **Encontram-se a explorar, nunca caem de inimigos repetíveis** — melhorar a arma não pode ser um motivo para farmar (Lei 1).
- Faz-se no ponto de descanso; sem ferreiro enquanto o WP8B não decidir se há NPCs.
- *Verificação do tecto:* atributo 50 em escala forte dá ×1,63 (WP2); com +30% chega a ~×2,1 sobre a arma de nível 1. Margem, não porta — e o chão do ×0,6 mantém qualquer arma utilizável. ✅
- *Alternativa descartada:* árvores de forja com ramos elementais — os encantamentos (WP4: vêm no item, um por arma) já dão o sabor elemental sem UI nova.

## Cura e consumíveis — a proposta para a pergunta 7

`[DECIDIDO]` que há itens de cura (00:26 → 00:32). O modelo `[FABLE]`, a fechar com o sim dos dois:

| Parâmetro | Valor |
|---|---|
| **Frasco de Bruma** | 3 cargas na fatia 1; ampliável até 5 (ampliações escondidas, uma por zona — Lei 2: exploração paga em opções permanentes). **Fecha o `[EM ABERTO]` do 33 §2: melhorar = MAIS frascos, nunca mais fortes** `[FABLE]` — a cura fixa em 40% mantém a conta de TTK legível para quem desenha chefes; *alternativa descartada:* frascos mais fortes — cura variável esconde a margem real do jogador ao parceiro e ao WP15B |
| Cura por gole | 40% dos PV máximos |
| Beber | 1,2 s (estado UsoDeItem do WP1), movimento a 50%; **dano interrompe e perde a carga** — beber é decisão, não reflexo |
| Recarrega | ao descansar no ponto de renascimento (o mesmo que restaura cargas de magia — WP4 — e renasce inimigos) |

*Porquê frasco e não poções compráveis:* poções finitas criam o incentivo exacto que a Lei 1 proíbe — farmar stock antes do chefe; o frasco faz de cada tentativa um recomeço igual e mensurável (o WP15B agradece). *Alternativa descartada:* poções de loja — pedem economia que não existe e pagam-se em grind. **A decisão de tom é deles — pergunta 7 continua no [`99-perguntas-abertas.md`](99-perguntas-abertas.md).**

Outros consumíveis (facas de arremesso, bombas, antídotos) ⬜ — entram com a economia (WP9), debaixo da regra: consumível dá conveniência, **nunca a única resposta a um padrão**.

## Armadura — DECIDIDA (31-07): existe, por peças, e cada uma é uma escolha

A pergunta 14 fechou ao contrário da minha recomendação, e fechou bem: [`33-morte-e-almas.md`](33-morte-e-almas.md) §3 e [`34-catalogo-e-comandos.md`](34-catalogo-e-comandos.md) §1 mandam — **armadura existe, ~30, por peças (elmo/peito/mãos/pernas), inimigos largam o que vestem, e nenhuma peça existe só para dar +2 de defesa.** O sistema `[FABLE]`, sobre a saída `[CLAUDE]` do 33:

**As regras do corpo:**

| Regra | Valor |
|---|---|
| Peças | 4 espaços: elmo, peito, mãos, pernas — misturáveis à vontade |
| **Peso total** → esquiva | leve (0–8): rolamento base do WP1 · médio (9–16): distância 3,0 m · pesado (17+): **0,66 s, i-frames 15** (frames 5–20), distância 2,6 m — troca, não upgrade |
| Resistências | **por tipo** (corte, contundente, fogo, raio, mal/bem), nunca "defesa" plana — escolher armadura é ler o inimigo que vem |
| Tecto da Lei 1 | nenhuma peça reduz > **10%** do dano de um golpe; o conjunto todo > **25%** — dentro do padrão dos 40% da Constituição (WP2) |
| **Habilidade por peça** (34 §1) | **passiva ou condicional, nunca de tecla** — 30 armaduras com 30 teclas era impossível; com 30 efeitos passivos é trivial. Cada peça responde a "porque usaria esta?" sem ser com número maior |
| Drop | o que o inimigo veste pode cair (fichas no WP6); chefes largam uma peça garantida (WP7) |

**Esqueleto do catálogo** — ~30 peças = ~7 conjuntos temáticos × 4 + avulsas; os três primeiros, para dar chão (o resto cresce zona a zona, com os inimigos que as vestem):

| Conjunto | Origem | Peso | Exemplo de habilidade (tipo) |
|---|---|---|---|
| **Couro do Lanceiro** | orcs de Brumal | leve | grevas: *sprint custa −20% de stamina* (passiva) |
| **Placas do Brutamontes** | orcs de Brumal | pesado | espaldar: *o primeiro golpe que te interromperia por segundo não interrompe, 1×/20 s* (condicional) |
| **Elmo do Guarda-Portão** | Vorgar (peça única) | médio | *a Investida do Guarda quebra +10 de postura* (passiva — casa com a skill dele) |

**Fatia 1:** as vestes iniciais de classe (sem stats) + **as 3 linhas acima como drops** — 9 peças, chega para provar o sistema sem crescer a fatia. *Teste da Lei 1:* peso compra-se com esquiva, resistência tem tecto, habilidade nunca é número puro — a armadura muda **como se joga**, nunca decide se se vence. ✅ Os **talismãs** da secção de ideias continuam válidos como loot sem malha.

## Montarias

O cavalo (05:15, `[SUGERIDO]`) continua guardado — um mapa de minutos não precisa dele. Reavalia-se no WP8, quando a escala do mundo (pergunta 4) tiver número. Registado para não se perder; nada a especificar ainda.

## Ideias para depois (não pedidas — não crescem sozinhas)

- **Talismãs** (2 espaços): efeitos laterais equipáveis — "parry devolve 10 de stamina", "as setas recuperam-se a 90%" — loot de corpo sem custo de malha nem de equilíbrio de i-frames
- Armas de chefe (a lâmina de Vorgar) — só se a recompensa-verbo por chefe (WP3/WP9) souber a pouco
- Dual-wield de adagas (a ideia já registada no WP3)
- Durabilidade: **descartada** — manutenção sem decisão interessante

## O que este documento entrega aos outros

| Para | O quê |
|---|---|
| **WP1** | as 3 famílias novas (lança, martelo, arco longo) à espera de frames e MV quando entrarem |
| **WP6/WP7** | dano de postura ×1,5 dos martelos e ×2 do bash nas contas de Cambaleio |
| **WP9** | Limalha, ampliações de frasco, pergaminhos (WP4) e talismãs como espinha das tabelas de loot |
| **WP12/WP13** | 5 famílias de animação na fatia; ícones das armas já especificados em `art/prompts/04` |
| **Protótipo (marco 2)** | o Frasco de Bruma entra com as 5 armas — a cura muda o TTK real do Vorgar |

## O que continua aberto

- ~~Perguntas 7 e 14~~ — **fechadas em 31-07** ([`33-morte-e-almas.md`](33-morte-e-almas.md)): frascos recarregáveis ✅ (o Frasco de Bruma é a implementação) e armadura por peças ✅ (sistema acima)
- O catálogo das ~120 armas e ~30 peças — cresce arma a arma por cima da fatia (34 §1)
- Preços e drops de tudo isto → WP9 · Frames das famílias novas → WP1 quando entrarem

## Ligações

[`06-itens-inventario.md`](06-itens-inventario.md) (sessão 1) · [`01-combate.md`](01-combate.md) · [`11-formulas.md`](11-formulas.md) · [`13-magia.md`](13-magia.md) · [`22-assets.md`](22-assets.md) · [`10-fatia-1.md`](10-fatia-1.md)
