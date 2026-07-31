# WorldRPGs — Especificação

RPG 3D para PC, **primeira ou terceira pessoa à escolha**, souls-like, co-op para dois. Índice mestre.

> 📋 **Todas as decisões dos donos, por ordem, em [`DECISOES.md`](DECISOES.md)** — é contra essa lista que se compara trabalho feito antes delas.

> **Fase: construção.** Os 20 pacotes de spec estão escritos (31-07-2026). Regras da fase nova em [`spec/32-construcao.md`](spec/32-construcao.md); o plano é o [`spec/24-plano.md`](spec/24-plano.md), M0 a M7.

> Cada afirmação nos documentos abaixo traz a origem: `(sessão N · MM:SS)`. Nada entra por invenção.

## Etiquetas

| | |
|---|---|
| `[DECIDIDO]` | Fechado numa conversa. Muda-se com uma decisão nova, registada. |
| `[SUGERIDO]` | Foi dito, ninguém contrariou, ninguém confirmou. |
| `[EM ABERTO]` | Falta decidir. Está em [`spec/99-perguntas-abertas.md`](spec/99-perguntas-abertas.md). |
| `[TENSÃO]` | Duas coisas decididas que ainda não encaixam. |

## Os documentos

| # | Documento | Do que trata | Estado |
|---|---|---|---|
| 00 | [Visão](spec/00-visao.md) | Pitch, os três pilares, referências, risco de escopo | 🟢 base sólida |
| 01 | [Combate](spec/01-combate.md) | Máquina de estados, esquiva, parry, stamina, as 5 armas | 🟠 números de partida `[FABLE]` (WP1) — validam-se no protótipo (marco 2) |
| 02 | [Personagem](spec/02-personagem.md) | Atributos, classes, evoluções, skills | 🟡 muito nomeado, pouco definido |
| 03 | [Magia](spec/03-magia.md) | Bem e mal, usos, encantamentos | 🟡 conceito sem mecânica |
| 04 | [Inimigos e chefes](spec/04-inimigos-chefes.md) | Raças, hierarquia de chefes | 🟡 quantidades por acertar |
| 05 | [Mundo](spec/05-mundo.md) | Mapa, biomas, dungeons, 3D | 🟢 forma decidida, escala não |
| 06 | [Itens e inventário](spec/06-itens-inventario.md) | Armas, mochila, montarias, drops | 🟢 a regra das armas está fechada |
| 07 | [Multiplayer](spec/07-multiplayer.md) | Co-op, sincronização, recompensas | 🟠 sistema complexo em uma frase |
| 08 | [Interface](spec/08-ui.md) | HUD, hotbar, mochila | 🟡 esqueleto |
| 09 | [Técnico](spec/09-tecnico.md) | **Restrição de hardware**, engine, rede | 🟠 restrição fixa, resto por decidir |
| 10 | [Fatia 1](spec/10-fatia-1.md) | O primeiro jogável: sistemas completos, conteúdo mínimo, critérios de feito | 🟢 **aprovada pelos dois** (31-07) |
| 11 | [Atributos e fórmulas](spec/11-formulas.md) | Os 6 atributos, fórmula de dano, curvas dos inimigos da fatia | 🟠 números de partida `[FABLE]` (WP2) — validam-se no protótipo |
| 12 | [Classes](spec/12-classes.md) | As 8 fichas, habilidades especiais, skills, e a tensão das evoluções proposta | 🟠 `[FABLE]` (WP3) — evoluções aguardam decisão A/B dos dois |
| 13 | [Magia, por dentro](spec/13-magia.md) | Bem/mal **aprovado** — a fatia usa as duas escolas (a Ruína passou ao mal), catálogo, cargas, pergaminhos | 🟢 `[FABLE]` (WP4), realinhado 31-07 |
| 14 | [Armas e equipamento](spec/14-equipamento.md) | Catálogo de armas, Lei 3 em números, frasco, **armadura por peças (decidida)**, artes de arma na tecla V (WP5) | 🟢 `[FABLE]`, realinhado 31-07 ao 33/34 |
| 15 | [Bestiário](spec/15-inimigos.md) | IA comum, as 7 raças em fichas com telegrafias, encontros da fatia (WP6) | 🟠 proposta `[FABLE]` — raças aguardam o sim do Mateus |
| 16 | [Chefes](spec/16-chefes.md) | Regras de camada da pirâmide, regras de todo o chefe, ficha completa do Vorgar (WP7) | 🟠 proposta `[FABLE]` — total da pirâmide (pergunta 13) fica com os dois |
| 17 | [Mundo e mapa](spec/17-mundo.md) | **10 zonas + núcleo (~30 min, decidido)**, dungeons com a regra das duas pistas, pontos de descanso, traçado de Brumal (WP8) | 🟢 `[FABLE]`, realinhado 31-07 — a divergência 6-vs-10 fechou para cima |
| 18 | [Progressão e loot](spec/18-progressao.md) | Curva por zona **em almas**, loot instanciado, o 40% de quem ajuda, o que se larga ao morrer (WP9) | 🟠 `[FABLE]`, realinhado 31-07 — pergunta 5 continua deles |
| 19 | [Multiplayer e rede](spec/19-rede.md) | O 12:34 resolvido (dois sacos de estado), transporte, autoridade dividida, quedas (WP10) | 🟠 proposta `[FABLE]` — transporte e fogo amigo aguardam os dois |
| 20 | [Interface](spec/20-interface.md) | HUD ao pixel, mochila 24, magias 3-visíveis, menus, configurações completas (WP11) | 🟠 proposta `[FABLE]` — resolve o 04:55 das magias no ecrã |
| 21 | [Arte, render, animação, efeitos e som](spec/21-arte-render.md) | Direcção de arte, orçamentos da Lei 4, lista de animações, fichas de efeitos, som completo (WP12) | 🟠 proposta `[FABLE]` — estilo (pergunta 15) aguarda os dois |
| 22 | [Origem dos assets](spec/22-assets.md) | Modelos 3D, animações e áudio — fontes e licenças (WP13) | 🟢 regras fixas; inventário confirma-se no download |
| 23 | [Arquitectura técnica](spec/23-tecnico.md) | Engine (Godot, com a medição 0b), sistemas, dados afináveis, saves, ferramentas (WP14) | 🟠 proposta `[FABLE]` — engine aguarda o carimbo dos dois (pergunta 17) |
| 24 | [Plano de construção](spec/24-plano.md) | M0–M7 com verificação jogável por marco; M1 já medido; riscos com resposta (WP15) | 🟢 pronto para o Opus 5 — é o documento de arranque da construção |
| 25 | [Câmara, controlo e game feel](spec/25-controlo.md) | Câmara, input buffer, latência, hit-stop (WP1B) | 🟠 proposta `[CLAUDE]`, números afinam-se no protótipo |
| 26 | [Narrativa e NPCs](spec/26-narrativa.md) | Proposta mínima + as 7 perguntas que só uma gravação responde (WP8B) | 🟠 guião de gravação pronto, decisões são dos donos |
| 34 | [**Catálogo e comandos**](spec/34-catalogo-e-comandos.md) | 30 armaduras, ~20 armas/classe, e a regra de que toda a habilidade diz como se activa | 🟢 escala e regra fixadas |
| 33 | [**Morte e almas**](spec/33-morte-e-almas.md) | Almas, frascos, armadura, ressurreição em co-op | 🟢 fecha as perguntas 7, 10 e 14 |
| 32 | [**Construção**](spec/32-construcao.md) | **A fase nova** — regras de código, o que muda no fluxo | 🟢 arrancou 31-07 |
| 29 | [Perspectiva](spec/29-perspectiva.md) | 1.ª ou 3.ª pessoa à escolha — e o que isso obriga | 🟠 decidido; lock-on em 1.ª pessoa em aberto |
| 30 | [Qualidade visual](spec/30-qualidade-visual.md) | A barra: orçamento consciente, **não** PlayStation 1 | 🟢 orçamento fixado |
| 31 | [Referências](spec/31-referencias.md) | Como usar o Dark Souls: o que estudar, e a linha que não se atravessa | 🟢 protocolo definido |
| 27 | [Aprender a jogar](spec/27-aprendizagem.md) | Os professores, os 5 primeiros minutos, curva e recuperação (WP11B) | 🟠 proposta `[CLAUDE]`, valida-se com gente de fora |
| 28 | [Testar e equilibrar](spec/28-testes.md) | Protocolo da Lei 1, métricas de sessão, sintomas→onde mexer, teste de fora, desempenho quente (WP15B) | 🟢 método fechado — só pede a pessoa de fora |
| 99 | [**Perguntas em aberto**](spec/99-perguntas-abertas.md) | Guião para a próxima sessão | — |

## O que está fechado

Dezasseis coisas estão fechadas — onze da sessão 1, mais a restrição de hardware:

1. RPG de acção 3D para PC, **primeira ou terceira pessoa à escolha do jogador**, souls-like, fantasia medieval
2. **Ganha-se com habilidade, não com nível.** Sem gating, sem grind obrigatório
3. Co-op para dois, sempre disponível
4. Esquiva e parry no corpo a corpo
5. Espada, escudo, arco e flecha, magia
6. **Qualquer classe pega em qualquer arma.** A diferença vem das skills e atributos, não de bloqueios
7. Atributos ao estilo Dark Souls, distribuídos por nível
8. Escolha de classe, cada uma com uma habilidade especial
9. Magia do bem e do mal, com usos limitados, magias desenhadas à mão
10. Mundo aberto grande, por biomas, com dungeons escondidas em pontos do mapa
11. Hotbar no fundo do ecrã + mochila de capacidade limitada
12. **A máquina alvo é PC sem placa gráfica dedicada** — Iris Xe integrados, 1080p @ 60 Hz. Manda em toda a arte, render e escolha de engine
13. **Primeira ou terceira pessoa, à escolha do jogador** — ver [`spec/29-perspectiva.md`](spec/29-perspectiva.md)
14. **Plataforma: PC.** Sem consolas, sem telemóvel
15. **A barra visual não é PlayStation 1** — 8–15 mil tri por personagem, ver [`spec/30-qualidade-visual.md`](spec/30-qualidade-visual.md)
16. **Dark Souls 2 é o chão de qualidade aceitável**, e cada pacote investiga a referência antes de escrever — [`spec/31-referencias.md`](spec/31-referencias.md)

## O que trava

**Nada.** Todas as perguntas bloqueantes caíram a 31-07-2026, com a aprovação do Mateus e do Rico.

| | |
|---|---|
| Máquinas | as duas medidas; o alvo é a do Rico (8 GB) |
| O 3D aguenta-se? | **caminho A** — 3D estilizado optimizado. ⚠️ a medição que o sustenta não tem prova no repositório; o marco 1 do WP15 dá-a |
| A fatia 1 | aprovada: 1 zona, 1 dungeon, 1 chefe, 6 classes, 5 armas, 3 magias |
| Evoluções de classe | **opção A** — dão opções, não números; sobem por marco, não por nível |
| Magia do bem e do mal | aprovada — o preço do mal é PV, à vista. A fatia usa as duas escolas |
| Quantas classes na fatia | seis |
| Sete raças + o Ceifador | aprovadas para o bestiário do WP6 |
| **Biomas por nível?** | **soft gating** — mapa todo aberto, dificuldade sugerida e não exigida |
| **Tamanho do mapa** | **~30 min a pé, 10+ biomas.** Fatia 1 continua a ser Brumal sozinha |
| **Tom** | **sombrio a sério** — sem piscadelas. Frase de estilo das imagens já reescrita |
| **Idioma** | **português**, tudo |

Continua em aberto, mas **não trava ninguém**: o nome do jogo, a história dos personagens, o que a Toca era, o porquê do co-op, e os nomes provisórios — [`spec/26-narrativa.md`](spec/26-narrativa.md) §3.

## A construir

[`prompts/BRIEFING-FABLE.md`](prompts/BRIEFING-FABLE.md) — o prompt-raiz: 20 pacotes, do combate ao plano de construção.

**Estado (31-07-2026): os 20 pacotes estão escritos** — ver a tabela acima e as reservas em [`COORDENACAO.md`](COORDENACAO.md). O que falta não é escrita, é decisão: as propostas 🔴/🟠 do [`99-perguntas-abertas.md`](spec/99-perguntas-abertas.md) esperam o sim (ou o corte) do Mateus e do Rico numa sessão 2 gravada. Depois disso, [`spec/24-plano.md`](spec/24-plano.md) é o ponto de partida do Opus 5.

## Sessões

| # | Data | Duração | Transcrição | Ideias |
|---|---|---|---|---|
| 1 | 30-07-2026 | 13m13s | local | local |
