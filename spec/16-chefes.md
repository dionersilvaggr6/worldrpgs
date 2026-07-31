# 16 — Chefes

> **WP7 · Fable** (31-07-2026). O sistema de chefes e a primeira ficha completa — **Vorgar, o Guarda-Portão**, o chefe da fatia 1. A pirâmide (~61) fica com **regras de camada** em vez de um roster inventado: 58 chefes com nome escritos por mim seriam exactamente o "inventar como se fosse deles" que este repositório proíbe. Os chefes desenham-se um a um, com eles, por cima destas regras. Tudo `[FABLE]` salvo indicação.

## A pirâmide — a pergunta 13 arrumada, não decidida

O que foi dito: 1 + 10 + 20 + 30 (Rico, 03:25) vs 1 + 30 + 20 (Mateus, 11:54); "a gente vai acertar isso" (12:05). **A decisão do total é deles.** O que a spec pode fixar já é o que **distingue uma camada da outra** — porque isso é desenho, não contagem:

| Camada | Nome de trabalho | O que é | Fases | Arena | Exemplo já em cima da mesa |
|---|---|---|---|---|---|
| 1 | **O Ultra** | zerar o jogo (03:25) | 3 | própria, única | — (desenha-se por último, com eles) |
| 2 | **Subchefes** | os donos de região; a música pára quando morrem | 2 | dedicada, com regra própria | o Ceifador (Rico, 31-07 ⏳) |
| 3 | **Guardiões** | fecham dungeons; um por Toca | 1–2 | a última sala da dungeon | Minotauro (labirinto) · **Vorgar** |
| 4 | **Chefes de campo** | encontros marcados no mundo aberto; sem porta, tropeça-se neles | 1 | o próprio terreno | — |

- **A hierarquia é de dificuldade e de identidade — nunca de acesso.** Nenhum chefe verifica nível, nenhuma camada tranca a seguinte por número (`[DECIDIDO]` 01:17 → 04:28). Se os dois quiserem que ela seja também **narrativa** (capangas de capangas), isso decide-se na gravação do WP8B — as camadas aguentam as duas leituras.
- **Como a dificuldade sobe entre camadas** (Lei 2 aplicada a chefes): mais **padrões e sequências**, mais fases, arenas com mais regra — **nunca** só mais vida e mais dano por cima do mesmo boneco. O aviso mínimo de 0,5 s (WP1/WP6) vale do campo ao Ultra: em cima, os ataques não ficam ilegíveis — ficam mais **encadeados**.
- *Teste da Lei 1:* qualquer camada é vencível a nível 1 por leitura — os tectos do WP2 (chão de dano 60%, TTK 45–70 golpes por chefe) escalam com a curva de zona e mantêm a conta possível. ✅

**Total de chefes:** fica **em aberto de propósito** (pergunta 13). A fatia prova um; a fatia 2 acrescenta 2–3 (Ceifador e Minotauro são os candidatos naturais); o total real acerta-se quando houver mapa (pergunta 4) — contar chefes antes de haver mundo é contar telhas sem casa.

## As regras de todo o chefe

| Regra | Valor | Porquê |
|---|---|---|
| Entrada | portão de bruma (atravessável só para dentro); nome no ecrã; a música do chefe entra | compromisso legível — começou |
| Vida em co-op | **×1,8** + alternância de alvo (provisório da fatia, pergunta 6) | "chamar o outro" não pode ser a resposta |
| Alternância | troca de alvo após cada sequência; **nunca o mesmo ataque `só esquiva` duas vezes seguidas no mesmo jogador** | em co-op, o que não se está a olhar tem de ser sobrevivível |
| Postura | barra própria; dano de postura recebido **×0,5**; Cambaleio de chefe: **2,5 s**, riposte aberto | o crítico em chefe é conquista acumulada, não spam de bash |
| Fases | mudam **padrões**, não números — a fase 2 traz ataques novos, não os velhos mais rápidos | Lei 2; e é o que faz a segunda hora de tentativas ser descoberta, não repetição |
| Morte do jogador | reset total do chefe (WP1); nova tentativa < 30 s (critério 4 da fatia). **As almas ficam na arena** ([`33-morte-e-almas.md`](33-morte-e-almas.md) §4) — recuperá-las é entrar outra vez, e isso é de propósito | a tentativa é a unidade de aprendizagem |
| **Ressurreição na arena** | o chefe **prioriza o ressuscitador** durante a canalização de 5–7 s `[FABLE]` — cabe ao par criar a janela (afastar, esperar o fim de um padrão longo). *Alternativa descartada:* o chefe ignorar a canalização — tirava à jogada exactamente o risco que a torna jogada ([`33-morte-e-almas.md`](33-morte-e-almas.md) §4) | a ressurreição é uma jogada, não um botão |
| Recompensa | **um verbo** — skill ou pergaminho, uma vez — + almas + **uma peça do que veste** (33 §3); nunca "+X% de dano" | Lei 2 na economia (WP3/WP4/WP9) |
| Whiff punível | todo o chefe tem ≥ 1 ataque que, falhado, o deixa ≥ 1,0 s exposto | agressão premiada: a janela de dano não é só pós-parry |
| Sem lixo na arena | nenhum inimigo comum entra durante a luta | a leitura é do duelo; adds são regra de camada 2+, e mesmo aí anunciados |

## Vorgar, o Guarda-Portão — a ficha completa

Guardião (camada 3) da **Toca**, fatia 1. Orc de guerra a 1,6× a escala do brutamontes, machado enorme; a "porta" que ele guarda é literal — o portão de pedra no fundo da arena, fechado até ele cair (gancho de mundo para o WP8).

| | Solo | Co-op |
|---|---|---|
| PV | **1 950** | **3 510** (×1,8) |
| DEF | 10 | 10 |
| Dano | leve 120 · pesado 190 | idem, alterna alvo |
| Postura | 100 (recebe ×0,5) | idem |
| Almas | 400 | 400 a cada um |
| Recompensa | skill **Investida do Guarda** + **o elmo dele** (peça de armadura — [`33-morte-e-almas.md`](33-morte-e-almas.md) §3: larga o que usa) + abre o portão | idem (loot instanciado, WP0) |

**Arena:** a última sala da Toca — círculo de 20 × 16 m, 2 pilares de pedra, tochas nas paredes (âmbar alto — WP12). Os pilares **param a investida dele** e partem-se ao segundo choque: a arena abre ao longo da luta. Chão limpo, sem buracos — a morte aqui é dele, não da câmara (WP1B).

**Skill que larga — Investida do Guarda** `[FABLE]`: avanço de ombro de 3 m (0,5 s), 30 de dano de postura, quebra guardas erguidas; 20 stamina, qualquer classe. O verbo dele, herdado por quem o vence. *Alternativa descartada:* largar o machado dele como arma — órfão de família de animação (WP12 não orça uma família para um item), fica em "ideias" no WP5.

### Fase 1 — 100% → 60%

| # | Ataque | Aviso (≥ 0,5 s) | Marca | Dano | A resposta certa |
|---|---|---|---|---|---|
| 1 | Cutilada dupla | 0,6 s — o ombro direito recua · **som: duplo silvo curto** | aparável | 120 + 120 | aparar o 2.º (o 1.º vem 0,4 s antes — aparar cedo é o erro clássico) |
| 2 | Pancada do portão | 0,9 s — ergue o machado a duas mãos · **som: arrasto grave** | aparável | 190 | o convite de parry; **falhada, crava no chão: 1,2 s exposto** (o whiff punível) |
| 3 | Investida de ombro | 0,7 s — patada no chão, baixa a cabeça · **som: bufo + patada** | **só esquiva** 🔴 | 140 | esquiva lateral tardia; guiá-lo a um pilar = Cambaleio grátis de 1,5 s |
| 4 | Agarrão | 0,25 s de brilho 🔴 + 0,5 s de braço aberto · **som: silvo agudo** (a regra de ouvido) | **só esquiva** | 170 + arremesso 3 m | a esquiva **para dentro** do braço contrário |
| 5 | Varrido baixo | 0,5 s — agacha e roda o tronco · **som: raspar circular no chão** | aparável | 100 | pune circular colado; salta-se com a esquiva (i-frames), não com salto — não há salto |

Sequências típicas: 1→5 (anti-colagem) · 3→2 (chega e pune) · 5→4 (o varrido empurra para o agarrão — a armadilha da fase).

### Transição — aos 60%

Grito de 2,5 s (**invulnerável**, a música troca de faixa no compasso — WP12): parte o cinto e saca o **segundo machado**. É pausa de respiração e anúncio — nada o interrompe, nada dele sai durante o grito.

### Fase 2 — 60% → 0

Mantém 1, 3 e 4. O 2 e o 5 saem; entram:

| # | Ataque | Aviso | Marca | Dano | A resposta certa |
|---|---|---|---|---|---|
| 6 | Tempestade | 0,8 s — cruza os machados no peito · **som: zumbido crescente** | **só esquiva** 🔴 | 90 ×3 toques | gira em espiral 4 m para fora — corre-se para **longe**, não à volta |
| 7 | Arremesso | 0,7 s — braço atrás, um machado só · **som: assobio no voo — e no regresso** | aparável (desvia) | 130 | **o machado volta** 1,2 s depois: segunda esquiva sem novo aviso visual — o som (assobio) é o aviso; a lição de ouvido do WP12 |
| 8 | Fúria do portão (1× por luta, aos 30%) | salto + marca 🔴 no chão 1,2 s · **som: silêncio de 0,3 s e queda** | **só esquiva** | 200 | a área é grande (r 4 m) mas a marca é honesta; em co-op cai no jogador **sem** o alvo actual |

*Teste da Lei 1, por escrito:* nível 1, zero pontos — dano recebido 100–170 por golpe contra 420 PV (morre em 3–4 erros, nunca em 1); TTK 53 golpes leves = 4–7 min de leitura (WP2); todos os avisos ≥ 0,5 s contra 300 ms de i-frames; os `só esquiva` têm marca vermelha; o whiff do ataque 2 e os pilares dão janelas de dano a quem não apara. Vence-se sem um único ponto gasto — mais devagar, com menos margem. É o critério 3 da fatia, e esta ficha é o contrato dele. ✅

*Teste de co-op:* ×1,8 de PV mantém ~30 s de luta por jogador a mais; a alternância + a regra do "nunca o mesmo `só esquiva` seguido" garante que estar fora do foco nunca é morte cega; a Fúria (8) cai de propósito em quem se julga seguro. ✅

## Ceifador e Minotauro — o que fica reservado (fichas na fatia 2)

- **Ceifador** (subchefe, camada 2 — Rico 31-07 ⏳): os ganchos do [`04-inimigos-chefes.md`](04-inimigos-chefes.md) mantêm-se — varridos `só esquiva` com o espaço seguro **dentro** do arco (ensina a esquivar para a frente), overhead aparável como única janela de parry, corte da zona morta-viva. A ficha completa faz-se quando a zona dele existir (WP8).
- **Minotauro** (guardião, camada 3): a investida que choca com paredes (WP6) vira regra de arena — o labirinto é a arma. Cambaleio de 3,0 s ao chocar; o resto da ficha com a dungeon dele.

## O que este documento entrega aos outros

| Para | O quê |
|---|---|
| **WP8** | o portão de Vorgar como saída da Toca; arenas de camada 2/3 como pedido de traçado |
| **WP9** | recompensa-verbo por chefe (Investida do Guarda é a primeira) + XP 400 |
| **WP11** | barra de chefe com nome; em co-op, indicador de quem é o alvo |
| **WP12** | por chefe: intro, transição no compasso, o assobio do arremesso; Vorgar tem 14 clips orçados |
| **WP15B** | esta ficha é o guião do teste da Lei 1 jogado: as métricas (tentativas, onde morre, que ataque mata) medem-se contra ela |

## O que continua aberto

- **Pergunta 13** — o total e a forma final da pirâmide: deles, com o mapa à frente
- **Pergunta 6** — o ×1,8 é provisório da fatia; fecha-se a jogar
- Ceifador e Minotauro ⏳ confirmação do Mateus; fichas completas com as zonas deles

## Ligações

[`04-inimigos-chefes.md`](04-inimigos-chefes.md) · [`15-inimigos.md`](15-inimigos.md) · [`01-combate.md`](01-combate.md) · [`11-formulas.md`](11-formulas.md) · [`10-fatia-1.md`](10-fatia-1.md) · [`27-aprendizagem.md`](27-aprendizagem.md)
