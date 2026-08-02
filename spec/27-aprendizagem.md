# 27 — Aprender a jogar (WP11B)

> **Autor:** Claude, tudo `[CLAUDE]` salvo indicação. A Lei 1 obriga a este documento: se ganhar depende de perícia, o jogo tem de **ensinar** essa perícia — senão "habilidade acima de nível" degrada em "sorte acima de nível", que é pior do que grind, porque o jogador nem sabe o que fez mal.

## As três proibições (primeiro o que NUNCA se faz)

1. **Paredes de texto.** Nenhum ecrã de tutorial com parágrafos. O máximo permitido: uma linha discreta, uma vez (ver §3).
2. **Tirar o controlo.** Zero cutscenes de ensino, zero "aperta X para continuar" com o boneco congelado.
3. **Marcadores a apontar o caminho.** Nada de setas, brilhos de objectivo, minimapa com rota. A descoberta da Toca **é** o conteúdo (WP0: "porque exploraram, não porque uma seta apontou").

O género ensina fazendo, e a morte é o professor — barata em **tempo** (WP0: retry < 30 s), mas com as almas na mancha segundo o [`33`](33-morte-e-almas.md). É barata o bastante para ensinar sem fingir que nada está em risco.

## §1. Os primeiros cinco minutos, batida a batida

A orla de Brumal é o tutorial — sem nunca se anunciar como tal.

| Min | O que acontece | O que ensina | Desenho que o garante |
|---|---|---|---|
| 0:00–0:30 | Aparecem na orla. Caminho de terra à frente, floresta densa aos lados | Mover + câmara | Espaço aberto, zero ameaças. A bruma fecha as direcções erradas (Lei 4 a fazer level design) |
| 0:30–1:30 | **Um** orc lanceiro sozinho, no caminho, virado de costas | Aproximação + primeiro ataque | De costas = o jogador escolhe quando começa. Vida baixa: morre em 3–4 golpes leves |
| 1:30–2:30 | **Dois** lanceiros, de frente | **Esquiva.** A estocada do lanceiro é linear e telegrafada → esquiva lateral resolve | Dois ao mesmo tempo tornam "só atacar" caro; a estocada falhada deixa-o exposto — a recompensa da esquiva é visível já |
| 2:30–4:00 | **Um** brutamontes sozinho, a guardar um arco de pedra no caminho | **Parry.** O armar exagerado por cima da cabeça da ficha `orc_brute` — conceito real [`orc-brutamontes.png`](../art/concept/inimigos/orc-brutamontes.png) — é a janela desenhada | Lento demais para ser morto à pressa: rodeá-lo é possível mas o arco é estreito — o jogo *convida* a experimentar o parry sem o exigir |
| 4:00–5:00 | Clareira com ponto de descanso e bivaque de orcs ao longe | Respirar, curar, olhar o mundo | Primeira pausa segura; o Frasco de Bruma usa-se aqui se sobreviveu arranhado |

O aspecto final do ponto de descanso continua autoria visual; a função já está decidida: renascimento, reposição do frasco/mana/tentativas e reaparecimento dos inimigos (`→WP1`, [`33`](33-morte-e-almas.md), [`54`](54-mana-meditacao-e-tracos-de-classe.md)).

**Regra de ouro do troço:** cada inimigo novo aparece primeiro **sozinho e em espaço aberto**. Combinações vêm depois de cada peça ter sido lida uma vez.

## §2. Como se ensina sem dizer — os professores

Formaliza a ideia do WP0 (os dois orcs são professores) como **padrão reutilizável** para todo o jogo:

> **Todo o conceito novo entra com um inimigo/situação cujo desenho torna esse conceito a resposta óbvia — e as outras respostas caras.**

- **Lanceiro → esquiva:** ataque linear, rápido de arrancar mas com recuperação longa. Bloquear com escudo funciona *mal* de propósito (empurra e come stamina); esquivar lateral abre as costas dele. A lição paga-se sozinha.
- **Brutamontes → parry:** todos os golpes têm preparação longa, inconfundível, com som próprio (`→WP12`). Neste inimigo, esquivar continua a funcionar, mas o parry mata-o em metade do tempo. **Isso não torna a esquiva uma resposta universal:** perseguidores, áreas e volumes persistentes exigem o vector de fuga escrito na ficha do [`67`](67-catalogo-do-bestiario.md). Parry é atalho neste professor, nunca chave única.
- **Vorgar fase 1 → exame** dos dois: alterna golpes "de lanceiro" (esquivar) e "de brutamontes" (aparar). A fase 2 muda padrões (WP0) — o exame é "leste o novo padrão?", não "tens número maior?".

`→WP6`: cada inimigo novo do bestiário declara **que conceito ensina ou que combinação examina**. Um inimigo que não ensina nem examina nada é decoração cara.

## §3. A única linha de texto permitida

Primeira vez que cada acção fica disponível, uma linha discreta no fundo do ecrã, 4 s, uma única vez por perfil:

> `Espaço — esquiva` · `Q — aparar` · `R — Frasco de Bruma`

São **exemplos dos valores de fábrica**, nunca texto fixo. A linha lê as acções `dodge_sprint`, `parry` e `use_item` de `controls.json` através de `SettingsSystem`; se o jogador remapear, a tecla mostrada muda no mesmo acto, como manda o [`45`](45-controlos-configuraveis.md).

Nunca em combate — aparece no momento calmo *antes* do inimigo-professor. Desactivável nas opções (`→WP11`). *Alternativa descartada: zero texto absoluto — puro, mas com teclado+rato há teclas literalmente indescobríveis (parry por toque vs manter), e um jogador que nunca descobre o parry perdeu metade do jogo.*

## §4. O primeiro erro barato

O jogador **tem** de morrer cedo — de preferência no brutamontes — e perceber duas coisas: porquê morreu, e que morrer custa pouco.

- A morte no troço de ensino devolve ao último descanso (< 20 s de caminho); as almas ficam na mancha e uma segunda morte substitui-a
- O ecrã de morte é seco e rápido (baseline executável **1,2 s**, sem sermão) — a punição é o risco sobre as almas, não uma espera longa
- **Porquê morri:** o golpe fatal repete a sua telegrafia — o último som/flash do ataque que matou fica 0,5 s no ecrã de morte (barato: é texto+ícone, não replay). `[CLAUDE]`, a validar no protótipo; se poluir, corta-se

## §5. Curva — introduzir, verificar, combinar

Cada conceito segue o mesmo ciclo: **introduzir sozinho → deixar praticar sem pressa → examinar em combinação.** A fatia 1 inteira, mapeada:

| Conceito | Introduz | Examina |
|---|---|---|
| Mover/câmara | Orla vazia | sempre |
| Ataque | Lanceiro solitário de costas | tudo |
| Esquiva | 2 lanceiros | Vorgar f1 |
| Parry | Brutamontes no arco | Vorgar f1 |
| Frasco sob pressão | Clareira (calma) → 2.ª zona (pressão) | Toca sala 3 |
| Magia/mana (Feiticeiro) | Primeiro lanceiro (custo baixo de errar) | Toca; meditação ensina-se só no descanso |
| Combinações | Toca salas 1–3 (lanceiros+brutamontes juntos) | Vorgar f2 |

Verificação de que "foi apanhado": **posicional, não por contador** — a porta seguinte do troço só é alcançável passando pelo professor. Não há "faz 3 parries para continuar" (é grind de tutorial, e o jogador que passou sem parry fez uma escolha válida).

## §6. Ensinar o co-op

O que ninguém descobre sozinho, ensinado pelo desenho:

- **Reviver o parceiro** (`→WP10` define o sistema): a primeira vez que um cai perto do outro, a linha única do §3 aparece — é a excepção de contexto: só surge quando acontece
- **Agro e flanco:** o bivaque de orcs da clareira (§1) tem 3 lanceiros — a dois, a divisão de atenção acontece naturalmente; nenhum texto necessário
- **Recompensa reduzida ao ajudar** (12:34, `→WP9`): mostrada no primeiro drop partilhado com o valor visível — números ensinam sozinhos
- O troço de ensino **funciona igual a dois**: os professores não assumem 1 jogador (brutamontes com 2 alvos alterna — coerente com Vorgar, `→WP7`)

## §7. Comandos a meio do jogo

- Pausa (Esc) mostra o esquema completo numa imagem única — sem submenus
- Mochila (Tab) mostra as teclas contextuais no rodapé
- `→WP11` detalha; a regra daqui é só uma: **ver os comandos nunca custa mais de uma tecla**

## §8. Recuperação — preso há uma hora

Sem sistema activo de dicas (seria a antítese do género). Três válvulas passivas:

1. **O mundo aberto é a válvula:** preso no Vorgar → Brumal inteira continua lá para praticar, farmar coragem, trocar de arma (Lei 3 — experimentar outra arma é replanear de graça)
2. **Co-op é a válvula social:** "chama o outro" é legítimo — com o chefe escalado (`→WP7`), ajudar não é batota
3. **A telegrafia do ecrã de morte** (§4) diz sempre *o que* matou — o jogador preso sabe pelo menos qual padrão falha

Se os testes do WP15B mostrarem >2 h presos na média (critério 2 do WP0 violado), a resposta é **afinar números do chefe**, nunca acrescentar dicas — o contrato da Lei 1 é esse.

## Pronto quando (herda o WP15B)

- [ ] Teste com pessoa de fora (protocolo WP15B): chega ao fim do troço de ensino **sem nenhuma pergunta em voz alta**
- [ ] ≥ 8/10 no teste de telegrafia do brutamontes (critério 6 do WP0)
- [ ] Ninguém do teste diz "não sabia que havia parry"
- [ ] O troço de ensino a dois funciona sem texto adicional

## Ligações

WP0 fatia ([`10-fatia-1.md`](10-fatia-1.md)) · WP1 frames (Fable, em curso) · WP6 telegrafias · WP11 opções · WP12 som · WP15B protocolos de teste · Leis: [`../CLAUDE.md`](../CLAUDE.md)
