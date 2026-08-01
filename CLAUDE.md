# CLAUDE.md — contexto do repositório

Lê isto antes de responder ou de rever seja o que for. É daqui que vem o contexto, não do prompt do workflow — regra nova escreve-se aqui.

## O que é este repositório

**WorldRPGs** — RPG 3D para PC, **primeira ou terceira pessoa à escolha**, souls-like, co-op para dois. Projeto hobby do **Mateus** e do **Rico**.

**Era um repositório só de especificação. Desde 31-07-2026 tem spec e código.** Os 20 pacotes estão escritos, o jogo já se joga, e `[DECIDIDO]` (Mateus, 31-07) **o código vive aqui, em `game/`** — o repositório separado `worldrpgs-game` que o WP14/WP15 planeavam foi abandonado. Razão: a regra do "mesmo PR" (abaixo) é impossível em dois repositórios, e um disco não é uma cópia de segurança. Regras da fase em [`spec/32-construcao.md`](spec/32-construcao.md).

A spec continua a mandar: se o código e a spec discordarem, **muda-se a spec primeiro**, no mesmo PR.

Fluxo: eles falam numa chamada → o OBS grava → transcrição → o que ficou decidido entra em `spec/` com o timestamp de origem → o que ficou por decidir entra em `spec/99-perguntas-abertas.md`.

## Quem é quem

| | |
|---|---|
| **Mateus** (`MateusJuni0`) | Dono. Aprova tudo. Faz o merge. |
| **Rico** | Co-autor do design. Abre PRs. **Tratar sempre por Rico.** |
| **Fable** | Agente do Rico. Detalha a spec, seguindo `prompts/BRIEFING-FABLE.md`. |
| **Opus 5** | Quem vai construir, depois da spec estar feita. |

## As quatro leis

Estão desenvolvidas em [`spec/00-visao.md`](spec/00-visao.md) e em [`prompts/BRIEFING-FABLE.md`](prompts/BRIEFING-FABLE.md). Resumo, para reveres contra elas:

1. **Ganha-se com habilidade, não com nível.** O nível reduz a margem de erro, nunca abre uma porta. Nada de gating, nada de grind obrigatório.
2. **As melhorias dão opções, não números.**
3. **Qualquer classe pega em qualquer arma.** Diferenciação por atributos e skills, nunca por bloqueio.
4. **A máquina alvo manda:** as duas medidas — **a do Rico é o alvo (8 GB, Iris Xe integrados, 1080p @ 60 Hz)**, por ser a mais fraca. E queda de fotogramas num souls-like não é feio, é injusto — ataca a lei 1.

## As etiquetas

| | | |
|---|---|---|
| `[DECIDIDO]` | **Fechado pelo Mateus** | **Ninguém mexe** sem uma decisão nova, registada. **Indica sempre a fonte.** ⭐ **Quem decide é o Mateus, e a decisão dele vale sozinha** (instrução dele, 01-08-2026: *"o rico nao confirma, quem decide é a gente"*). O que vier do Rico é contributo — fica ⏳ até o Mateus confirmar, nunca o contrário |
| `[SUGERIDO]` | Dito, não confirmado | Pode ser adoptado, virando `[FABLE]` |
| `[EM ABERTO]` | Por decidir | É trabalho a fazer |
| `[TENSÃO]` | Duas decisões que não encaixam | Propõe-se, **não se decide** |
| `[FABLE]` | Decidido pelo Fable | Tem de trazer razão e alternativa descartada |

## O que verificar numa revisão

Por ordem de gravidade:

1. **Mexeu num `[DECIDIDO]`?** É o mais grave. Corre `node tools/check-coerencia.mjs --base origin/main`. Se mexeu, o PR tem de dizer qual foi a decisão nova que o substitui. Se não disser, é motivo para não entrar.
2. **Contradiz alguma das quatro leis?** Sobretudo a 1 e a 4, que são as fáceis de quebrar sem dar por isso.
3. **Inventou coisas como se fossem deles?** Tudo o que vem do Fable é `[FABLE]`, com justificação. Um `[DECIDIDO]` novo tem de dizer a fonte — e se só um dos dois decidiu, tem de estar marcado que falta o outro. O guarda assinala as linhas promovidas a `[DECIDIDO]` em cada PR.
4. **Decidiu sozinho uma `[TENSÃO]`?** Não é dele para decidir. Tem de propor e recomendar.
5. **Adjectivos onde deviam estar números?** "Combate responsivo" não é spec. "0,60 s, invencibilidade nos frames 5–23 inclusivos (317 ms)" é.
6. **Falta a coluna `Fatia 1?`** nos catálogos? É o que trava o escopo.
7. **O código corresponde à spec?** Desde 31-07 escreve-se código aqui. Se ele diverge do que está escrito, o PR tem de trazer a mudança da spec junto — nunca só o código.
8. **Actualizou o `SPEC.md` e o `99-perguntas-abertas.md`?** Devem ir no mesmo PR.

## O que não fazer

- **Não faças merge.** Quem aprova é o Mateus. Comentas o veredito e ficas por aí.
- **Não reescrevas a spec ao rever.** Aponta, não corrijas por cima.
- **Trata-o sempre por Rico** — nunca por outro nome, mesmo que apareça numa conta, num commit ou numa citação. *(A regra dizia o outro nome para o proibir, o que o punha num repositório público. Funciona igual sem ele.)*

## Coordenação entre agentes

Dois agentes escrevem aqui — o Fable (lado do Rico) e o Claude (lado do Mateus). **Antes de começar um pacote, reserva-o em [`COORDENACAO.md`](COORDENACAO.md)** com um commit pequeno e imediato; antes de reservar, `git pull` e vê se já está reservado. O desempate é a ordem de chegada à `main`. Numa revisão, um PR que faz um pacote reservado por outro merece esse reparo.

## Documentos importantes

| | |
|---|---|
| ⭐ [`LACUNAS.md`](LACUNAS.md) | **O que falta e ninguém está a fazer** — agrupado por volta. Encontraste um buraco? Escreve lá no mesmo acto |
| ⭐ [`MAPA.md`](MAPA.md) | A estrutura e **as fundações** — quem cita quem. Gerado por `node tools/mapa.mjs`, não se edita à mão |
| [`prompts/CODEX-CONTEXTO.md`](prompts/CODEX-CONTEXTO.md) | **O contexto permanente do executor** — lê-se no início de cada tarefa |
| ⭐ [`ESTADO.md`](ESTADO.md) | **Lê primeiro.** O que é verdade hoje, o que falta e por que ordem |
| [`prompts/TERMINAR-A-SPEC.md`](prompts/TERMINAR-A-SPEC.md) | **Prompt histórico concluído** — preserva as 4 tarefas que fecharam a primeira versão da spec; não é estado corrente |
| [`LACUNAS.md`](LACUNAS.md) | O que falta e ninguém está a fazer. Encontraste um buraco? Escreve lá no mesmo acto |
| [`prompts/BRIEFING-FABLE-2.md`](prompts/BRIEFING-FABLE-2.md) | O briefing das voltas 1–3 (feitas) |
| [`SPEC.md`](SPEC.md) | Índice, e o estado de cada área |
| [`spec/00-visao.md`](spec/00-visao.md) | Os pilares. O documento mais importante. |
| [`spec/99-perguntas-abertas.md`](spec/99-perguntas-abertas.md) | O que falta decidir |
| [`prompts/BRIEFING-FABLE.md`](prompts/BRIEFING-FABLE.md) | A raiz do projeto — o que o Fable tem de fazer |
| [`PARA-O-RICO.md`](PARA-O-RICO.md) | As tensões e o risco de escopo |
| [`PONTE-CLAUDE.md`](PONTE-CLAUDE.md) | Como o Rico usa isto |
| [`prompts/REALINHAMENTO.md`](prompts/REALINHAMENTO.md) | **O plano de realinhamento** — parte A escrita, parte B por preencher com a análise dos commits |
| [`DECISOES.md`](DECISOES.md) | **Registo de decisões** — o que foi decidido, por ordem, e o que substitui. Comparar trabalho antigo contra isto |
| [`spec/31-referencias.md`](spec/31-referencias.md) | Como usar o Dark Souls, e a linha que não se atravessa |
| [`COORDENACAO.md`](COORDENACAO.md) | Quem está a fazer o quê — reservar antes de começar |
