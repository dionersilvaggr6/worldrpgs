# Coordenação — quem está a fazer o quê

Dois agentes escrevem nesta spec — o **Fable** (do lado do Rico) e o **Claude** (do lado do Mateus) — e o perigo não é pisarem-se por maldade, é fazerem **o mesmo pacote ao mesmo tempo** sem saberem um do outro.

A regra é uma só:

> **Antes de começar um pacote, reserva-o aqui, num commit pequeno e imediato. Antes de reservar, faz `git pull` e vê se já está reservado.**

Uma reserva é uma linha na tabela. Custa trinta segundos e evita deitar fora um dia de trabalho.

## Reservas

> **Desde 31-07: reserva-se por MARCO (M0…M7) ou por sistema, não por pacote de spec.** Os 20 pacotes estão escritos — ver [`spec/32-construcao.md`](spec/32-construcao.md).

| Pacote | Documento | Quem | Desde | Estado |
|---|---|---|---|---|
| WP0 | `spec/10-fatia-1.md` | Fable | 30-07 | ✅ entregue (`e49e6c1`), reparos na revisão do PR #1 |
| WP1 | `spec/01-combate.md` | Fable | 31-07 | ✅ entregue (PR #5, `0de11ef`) |
| WP1B | `spec/25-controlo.md` | Claude | 31-07 | ✅ entregue — números `[CLAUDE]`, afinam-se no protótipo |
| WP2 | `spec/11-formulas.md` | Fable | 31-07 | ✅ entregue (PR #6, `dc710d2`) |
| WP3 | `spec/12-classes.md` | Fable | 31-07 | ✅ entregue (PR #8, `dc710d2`) |
| WP4 | `spec/13-magia.md` | Fable | 31-07 | ✅ entregue (PR #9, `dc710d2`) |
| — | `spec/04-inimigos-chefes.md` (7 raças + Ceifador) | Fable | 31-07 | ✅ entregue (PR #7, `dc710d2`) — aprovado pelos dois |
| WP13 | `art/` + `spec/22-assets.md` | Claude | 31-07 | ✅ entregue — manifesto, prompts, fontes/licenças **e as 25 imagens geradas** (`83df034`) |
| WP11B | `spec/27-aprendizagem.md` | Claude | 31-07 | ✅ entregue — valida-se com teste de pessoa de fora (WP15B) |
| WP8B | `spec/26-narrativa.md` | Claude | 31-07 | ✅ entregue — guião de gravação de 7 perguntas para os donos |
| — | `spec/29-perspectiva.md` (1.ª/3.ª pessoa) | Claude | 31-07 | ✅ entregue — decisão nova do Mateus, com o que obriga |
| — | `spec/30-qualidade-visual.md` (barra visual) | Claude | 31-07 | ✅ entregue — desfaz o mal-entendido do "baixo poligonal" |
| — | `spec/31-referencias.md` (protocolo de investigação) | Claude | 31-07 | ✅ entregue — o que estudar do Dark Souls, e a linha |
| WP5 | `spec/14-equipamento.md` | Fable | 31-07 | ✅ entregue no branch `claude/game-spec-completa-81xz3g` — alinhado aos números do WP1/WP2 |
| WP12 | `spec/21-arte-render.md` | Fable | 31-07 | ✅ entregue no branch — animações, efeitos e som (pedido do Rico 31-07) |
| WP6 | `spec/15-inimigos.md` | Fable | 31-07 | ✅ entregue no branch — bestiário das 7 raças, IA comum, encontros da fatia |
| WP7 | `spec/16-chefes.md` | Fable | 31-07 | ✅ entregue no branch — regras de camada + ficha completa do Vorgar |
| WP8 | `spec/17-mundo.md` | Fable | 31-07 | ✅ entregue no branch — rede de zonas, dungeons, traçado de Brumal |
| WP9 | `spec/18-progressao.md` | Fable | 31-07 | ✅ entregue no branch — curva, loot instanciado, recompensa de ajuda a 40% |
| WP10 | `spec/19-rede.md` | Fable | 31-07 | ✅ entregue no branch — progresso individual resolvido, autoridade dividida, transporte |
| WP11 | `spec/20-interface.md` | Fable | 31-07 | ✅ entregue no branch — HUD, mochila, menus, configurações |
| WP14 | `spec/23-tecnico.md` | Fable | 31-07 | ✅ entregue no branch — Godot escolhido com dados, sistemas, dados afináveis, ferramentas |
| WP15 | `spec/24-plano.md` | Fable | 31-07 | ✅ entregue no branch — M0–M7, M1 já medido, riscos com resposta |
| WP15B | `spec/28-testes.md` | Fable | 31-07 | ✅ entregue no branch — protocolos, sintomas, ordem de afinação. **Todos os 20 pacotes do briefing estão escritos.** |

| **Realinhamento A3** | os 11 docs do PR #11 vs `DECISOES.md` | Fable | 31-07 | ✅ entregue no branch — almas/ressurreição (WP9/WP10/WP6/WP7), catálogo+comandos (WP3/WP4/WP5), perspectiva+qualidade+10 zonas (WP12/WP11/WP8). **Falta do A3: a passagem do protocolo de referências (31) pelos 11 docs** — é o próximo pacote |

*Estados: 🔨 em curso · ✅ entregue · ⏸️ parado (dizer porquê)*

> Nota (31-07, Fable): uma segunda sessão do Fable chegou a duplicar WP1–WP4 sem ver estas reservas (os branches ainda não estavam na `main`). Resolvido a favor das versões com PR aberto e protótipo — as duplicadas foram descartadas no merge, e é por casos destes que a reserva se faz com push imediato.

## Como reservar

1. `git pull origin main`
2. Confirma que o pacote não está 🔨 por outro
3. Acrescenta a linha com o teu nome e a data
4. Commit + push imediato, só com esta mudança: `chore: reserva WP<N> (<quem>)`
5. Trabalha no teu branch normalmente

## Se os dois reservarem ao mesmo tempo

Acontece — dois pulls no mesmo minuto. O desempate é simples: **vale a reserva cujo commit chegou primeiro à `main`**. O outro escolhe outro pacote, ou comenta no PR do primeiro em vez de duplicar.

## Regra que faltava

**Quem faz o merge actualiza a linha desta tabela no mesmo acto.** A tabela ficou quatro pacotes atrasada a 31-07 e deu a impressão de que havia trabalho por entrar quando estava tudo dentro. Uma tabela de estado errada é pior do que não ter tabela nenhuma.

## Quem trata das entregas

O **Claude** (lado do Mateus) verifica o repositório em ciclo: PRs novos são revistos e, com a autorização permanente do Mateus (31-07), integrados quando estão bem. Não é preciso esperar por ninguém para entregar — abre o PR e ele será visto.

## Pacotes livres

Tudo o que não está na tabela está livre. A ordem recomendada continua a ser a do [`prompts/BRIEFING-FABLE.md`](prompts/BRIEFING-FABLE.md), mas dois pacotes independentes podem correr em paralelo sem problema — é para isso que isto existe.
