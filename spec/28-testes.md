# 28 — Testar e equilibrar

> **WP15B · Fable** (31-07-2026). A Lei 1 é uma afirmação empírica — *um jogador bom com um personagem fraco vence* — e uma afirmação empírica só vale com forma de a testar. Este documento é essa forma: protocolos, métricas, sintomas e a ordem de mexer. Assume as ferramentas do WP14 (consola com `latencia`, overlays, **registo CSV sempre ligado**, salto ao chefe) — sem elas, equilibrar é palpite com opinião. Tudo `[FABLE]`.

> **COMPLETADO 01-08:** o [`63`](63-como-se-afinam-os-numeros.md) é o manual operativo deste pacote: inventaria os valores, separa guardas de conteúdo, atribui papéis, isola uma variável, limita o tamanho da mudança, faz A/B e diz quando congelar. Este `28` continua a mandar nos protocolos, métricas e tectos; não se duplicam lá.

## O protocolo do teste da Lei 1 — ao pormenor

**Quando:** no fim do M4 (greybox) e outra vez no fim do M7 (com arte) — a arte muda a leitura, o teste repete-se.

| Passo | Regra |
|---|---|
| Quem joga | um dos dois, **depois de já ter zerado a fatia** com um personagem normal (o teste mede números, não aprendizagem — o padrão já tem de estar sabido) |
| Personagem | nível 1, **zero pontos gastos**, arma inicial da classe, frasco base (3), sem skills encontráveis |
| O alvo | Vorgar, solo, via `tp arena_vorgar` |
| Tentativas | máximo **10**, seguidas, com pausas livres |
| Regista-se (o CSV faz sozinho) | por tentativa: duração, % de vida tirada ao chefe, ataque que matou o jogador, stamina no momento da morte, parries tentados/acertados, goles de frasco |
| **Passa se** | matar em ≤ 10 tentativas |
| **Falha por números** (o WP2 volta atrás) | não matou E o CSV mostra: TTK projectado > 8 min por tentativa, ou mortes com stamina cheia em golpes lidos (dano alto de mais), ou vida do chefe a descer < 8% por tentativa boa |
| **Falha certa** (não se mexe em nada) | não matou E as mortes são de padrão mal lido (o mesmo ataque mata repetidamente, com stamina disponível) — isso é o jogo a exigir mais leitura, que é o contrato |

O veredicto escreve-se no repositório (uma linha na COORDENACAO ou no PR do marco): data, resultado, CSV anexo. **A Lei 1 passa a ter historial, não opinião.**

## O que se mede em toda a sessão — as métricas de sempre

O CSV do WP14 acumula por sessão, sem ninguém pedir:

- **Mortes:** causa (inimigo + ataque), zona, stamina no momento, vida do atacante restante
- **Chefes:** tentativas, duração de cada, % alcançada, fase em que morreu
- **Parry:** tentados, acertados, contra que ataque — a taxa por ataque diz se a telegrafia funciona
- **Esquiva:** total, quantas usaram i-frames de facto (atravessaram um golpe) — a razão diz se há spam
- **Frasco:** goles por tentativa, quantos interrompidos
- **Desempenho:** p99 do frame time por zona, memória no fim

**Regra de leitura:** uma sessão não decide nada; três sessões com o mesmo sintoma decidem. Os números afinam-se em `data/` e o CSV seguinte confirma ou desmente.

## Sintomas de desequilíbrio — e onde mexer primeiro

A tabela de diagnóstico, para não se mexer em tudo ao mesmo tempo:

| Sintoma (no CSV) | Diagnóstico provável | Mexe-se primeiro | Nunca se mexe |
|---|---|---|---|
| Taxa de parry < 10% num ataque desenhado para isso | recompensa não paga o risco, ou aviso ilegível | recompensa (Postura Quebrada mais longa), depois o aviso (WP12) | a janela dos 133 ms por nível |
| Parry > 60% em tudo | de graça | recuperação do falhado (mais longa) | — |
| Esquivas com i-frames usados < 30% das esquivas | spam de pânico | nada — é o jogador a aprender; só se persistir: custo | i-frames |
| "Segurar bloqueio" resolve salas inteiras | bloqueio barato | custo por golpe do escudo, regeneração a bloquear | absorção física (a leitura binária fica) |
| TTK de chefe > 8 min em tentativa boa | esponja | PV do chefe em `data/` | dano dos jogadores (mexe em tudo ao mesmo tempo) |
| Morte típica em < 20 s de arena | dano do chefe alto | dano por golpe (tecto 60% da vida, WP2) | — |
| Frasco nunca usado | cura não vale o risco de 1,2 s | valor do gole (40% → 50%) | duração do gole (é a decisão-com-corpo) |
| Frasco esvaziado sempre | dano ambiente alto de mais | dano dos comuns da zona | cargas (3 é identidade da fatia) |
| Jogador foge de grupos sempre | grupos ilegíveis | composição/curva da zona em `world.json`; se for um rosto único, a ficha em `named_encounters.json` | o círculo de agressão (2 é a regra de justiça) |

**Resumo da ordem de afinação:** 1.º correcção técnica → 2.º leitura e resposta executável → 3.º recompensa/custo do erro → 4.º duração/recursos → 5.º co-op → 6.º progressão. A árvore completa e os passos máximos vivem no [`63`](63-como-se-afinam-os-numeros.md) §3–6. **Nunca** se usa janela de esquiva/parry ou i-frames como botão de dificuldade; mexer-lhes é mudar de jogo.

## O teste com alguém de fora — o antídoto contra os dois

O Mateus e o Rico vão saber o jogo de cor: são os piores juízes possíveis da curva de aprendizagem (o WP11B/27-aprendizagem já assume este teste — aqui está o protocolo).

- **Quando:** fim do M5 (a zona inteira em greybox) e fim do M7.
- **Quem:** uma pessoa que nunca viu o jogo, meia hora, sozinha ao comando.
- **A regra de ouro: silêncio.** Ninguém explica nada. Cada vez que alguém sentir vontade de dizer "carrega em Espaço", aponta-se num papel — **cada vontade é um defeito do jogo**, não da pessoa.
- **Observa-se (papel e caneta):** encontrou a Toca sem ajuda? (as duas pistas do WP8) · esquivou por leitura ao fim de quanto tempo? · tentou o parry sozinha? no brutamontes? · o critério 6 da fatia: antes de cada golpe do brutamontes, diz se dá para aparar — ≥ 8/10 · onde parou sem saber o que fazer (cada paragem > 60 s regista-se)
- **Depois, três perguntas só:** o que foi injusto? o que foi confuso? voltavas a jogar?
- O resultado corrige o **27-aprendizagem** primeiro (os professores), o mundo (pistas) segundo, os números por último.

## Teste de desempenho — o protocolo quente

Formaliza o que a 0b começou; corre no fim de **cada** marco a partir do M2, **nas duas máquinas**, primeiro na do Rico:

1. 20 minutos de jogo contínuo real (não idle) — combate, morte, renascimento, streaming da garganta.
2. F3 regista: fps médio, p99, 1% low, memória no minuto 1 vs 20, draw calls máximas.
3. **Verde:** p99 ≤ 16,7 ms e memória estável. **Amarelo:** p99 ≤ 20 ms — optimiza-se antes do marco seguinte. **Vermelho:** p99 > 20 ms (< 50 fps, o mínimo do WP0) ou memória a crescer > 100 MB/h — **pára-se o conteúdo e optimiza-se já** (a regra do WP12/WP14, com o gatilho medível).
4. O resultado escreve-se no PR do marco. Sem excepção "desta vez não deu para medir" — medir É o marco.

## Teste de rede — latência artificial

No M3 e sempre que a rede mude: consola `latencia 80`, `150`, `250` (ida), o convidado luta com o brutamontes:

- **80 ms:** tudo justo — é o alvo entre as duas casas.
- **150 ms:** esquiva e parry do convidado continuam justos (autoridade local, WP10); o aviso de latência aparece (WP11).
- **250 ms:** o jogo continua correcto (sem mortes fantasma), ainda que arrastado — a degradação é honesta, nunca injusta.

Passa se, às cegas (um dos dois sem saber a latência do dia), o convidado não conseguir dizer se está a 0 ou a 80 ms.

## O que este documento entrega aos outros

| Para | O quê |
|---|---|
| **WP15** | os testes de cada marco referem-se daqui; o veredicto escrito é parte da entrega do marco |
| **WP14** | a lista fechada de ferramentas que os protocolos assumem |
| **Mateus + Rico** | o teste de fora precisa de uma terceira pessoa — escolher quem, sem lhe mostrar nada antes |
| **Opus 5** | os "nunca se mexe" desta página são contrato, não sugestão |
| **Quem afina** | papéis, baseline, hipótese, A/B, artefacto e condição de fecho no [`63`](63-como-se-afinam-os-numeros.md) |

## O que continua aberto

- Nada deste pacote depende de decisão deles — é método. A única coisa que pede acção: **arranjar a pessoa de fora** antes do fim do M5.

## Ligações

[`24-plano.md`](24-plano.md) (quando cada teste corre) · [`23-tecnico.md`](23-tecnico.md) (as ferramentas) · [`10-fatia-1.md`](10-fatia-1.md) (os 7 critérios) · [`27-aprendizagem.md`](27-aprendizagem.md) (quem o teste de fora corrige) · [`11-formulas.md`](11-formulas.md) (os tectos que os vereditos protegem) · [`63-como-se-afinam-os-numeros.md`](63-como-se-afinam-os-numeros.md)
