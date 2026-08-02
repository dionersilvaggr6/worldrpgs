# 24 — Plano de construção

> **WP15 · Fable** (31-07-2026). **Opus 5: começa aqui.** Este é o documento que ordena tudo o resto — cada marco diz o que existe no fim, como se verifica a jogar, e o que faz parar. As regras que não se negoceiam em nenhum marco: a simulação manda (WP14), os números vivem em `data/` (WP14), os tectos da Lei 1 validam ao carregar (WP2/WP14), e **nada de arte antes do combate ser bom** — greybox até prova em contrário. Tudo `[FABLE]`.

## A ordem, numa linha

Fundação → ~~desempenho~~ (✅ já medido) → **combate** → co-op → chefe → zona → arte → fatia 1 inteira.

O combate vem antes de tudo o que se vê porque é o risco nº 1 do projeto (WP0): se o marco 2 não for divertido, mais nenhum marco importa.

## Os marcos

### M0 — Fundação (a semana de alicerces)

**Existe no fim:** código em `game/` no repositório `worldrpgs` — `[DECIDIDO]` (Mateus, 31-07-2026), substitui o repositório separado previsto na primeira versão —; projecto Godot 4.7.1-stable com renderer Mobile (WP14); `data/*.json` carregados com os números da spec e **validação dos tectos da Lei 1 ao carregar**; consola (F1), overlays (F2/F3), registo CSV e escrita atómica de saves (WP14) — as ferramentas primeiro, porque todos os marcos seguintes as usam.
**Verifica-se:** boneco-cápsula anda numa sala vazia; mudar um número em `weapons.json` e recarregar a quente muda o jogo sem reiniciar; um `enemies.json` com golpe acima do tecto recusa carregar.
**Risco:** nenhum técnico; o risco é saltar os alicerces por parecerem lentos. Não saltar.

### M1 — Desempenho ✅ **já feito, antecipado** (31-07-2026)

O teste que este marco pedia correu antes do plano existir ([`09-tecnico.md`](09-tecnico.md), pergunta 0b): greybox na máquina do Rico, 60 fps cravados no cenário da fatia, 20 min quente sem degradação, renderer escolhido com dados. **O que fica pendente dele:** a ressalva escrita — animação de esqueleto não foi medida. Herdada pelo M6, que a mede em primeiro lugar.

### M2 — O protótipo de combate (o coração; o marco mais longo)

**Existe no fim:** a FSM completa do WP1 (esquiva, parry, bloqueio, stamina, as 5 armas com frames e MV de `data/`); lanceiro e brutamontes com as fichas do WP6 (IA de estados, círculo de agressão, fecho); postura e Cambaleio; as 3 magias com mana e meditação (WP4); frasco (WP5); HUD mínimo (vida, stamina, mana, frasco e tentativas de meditação). Tudo greybox — cápsulas com armas visíveis chegam.
**Verifica-se a jogar, por esta ordem:**
1. O overlay F2 confirma os frames do WP1 ao frame exacto (a esquiva tem **19 i-frames**, 5–23 inclusivos; o parry 8 activos).
2. Um lanceiro morre em 3–5 leves de espada a nível 1 (a restrição do WP1 ao WP2).
3. **O teste do divertido:** Mateus e Rico, uma noite, 3 lanceiros + 1 brutamontes em sala greybox. Se ao fim de uma hora não estiverem a repetir por gosto, **pára-se e afina-se `data/` até estarem** — avançar com combate mau é construir um jogo mau maior.
**Risco:** ser divertido tarde. Resposta: iterar dados (a ordem de afinação do WP15B), nunca avançar "para já".

### M3 — Co-op (as duas casas)

**Existe no fim:** hospedar/juntar por código (< 2 min, WP10); autoridade dividida a funcionar (i-frames do convidado avaliados localmente); os dois sacos de estado; sincronização do combate do M2 a 20 Hz; quedas tratadas (reescala, re-entrada).
**Verifica-se:** os dois, cada um em sua casa, matam o brutamontes juntos; com `latencia 100` na consola, a esquiva do convidado continua justa (o protocolo de latência do WP15B); um dos dois desliga a meio e nada se perde.
**Risco:** CGNAT na ligação directa. Resposta: plano B do WP10 (VPN de amigos), já escrito.

### M4 — Vorgar e a Toca (o primeiro chefe)

**Existe no fim:** a Toca em greybox (4 salas do WP8, tecto ≥ 2,5 m); Vorgar completo pela ficha do WP7 (8 ataques, 2 fases, pilares e alternância em co-op; o ×1,8 continua só baseline `[PROTO]` da pergunta 24); morte e renascimento < 30 s; a skill que ele larga.
**Verifica-se:** **o critério 3 da fatia, em greybox** — um dos dois, nível 1, zero pontos, mata o Vorgar. Tentativas e causas de morte saem do CSV. Se falhar por números, o WP2 volta atrás — é para isso que está em `data/`.
**Risco:** o chefe ser pior de ler em greybox sem animação final. Mitigação: as telegrafias fazem-se já aqui com as poses-chave (a antecipação de 0,5–0,9 s), mesmo toscas — a legibilidade testa-se antes da beleza.

### M5 — Brumal (a zona)

**Existe no fim:** Brumal greybox ao traçado do WP8 (600×400 m, caminho, bruma a 60 m, os 6 encontros do WP6, os 3 segredos, o atalho, pontos de descanso, streaming da garganta).
**Verifica-se:** travessia limpa em 2–3 min; um jogador novo encontra a Toca sem ajuda (as duas pistas funcionam — teste com pessoa de fora se houver uma à mão); renascer no chefe continua < 30 s com o atalho.

### M6 — Arte e som (greybox morre)

**Existe no fim:** os modelos e animações reais (WP12/WP13: packs CC0 + as feitas à mão), VFX pelas fichas do WP12, o som completo (matriz de impactos, telegrafias audíveis, as 6 peças + stingers), skybox e paletas.
**Verifica-se — e começa por medir a incógnita da 0b:** primeiro dia do marco: **8 personagens animados em cena, quente, 20 min** (o tecto do WP12). Se o p99 passar de 16,7 ms, opera-se aqui (menos ossos, menos influências) antes de vestir mais nada. No fim: o critério 6 da fatia (telegrafia dita antes do golpe, ≥ 8/10) e 60 fps quentes com tudo vestido.
**Risco:** é o marco onde a Lei 4 morre se ninguém medir. A medição é a primeira tarefa, não a última.

### M7 — A fatia 1 inteira

**Existe no fim:** tudo dos marcos anteriores, junto: as **sete origens catalogadas** com habilidades (WP3), incluindo o Mago do Mal decidido a 01-08, criação de personagem, menus completos (WP11), e todos os produtores ligados à gravação atómica do [`59`](59-saves.md).
**Verifica-se:** **os 7 critérios do WP0, um a um, com o CSV a prová-los** — rede < 2 min, jogador novo < 2 h, nível-1-zero-pontos, morte < 30 s, 60 fps quentes nas duas máquinas, telegrafia 8/10, e o voto dos dois ("queremos a fatia 2?").
**Depois disto:** a gravação da sessão 2 (as decisões pendentes do 99) e a fatia 2 (Selva ou Campas — deles).

## Dependências, num desenho

```
M0 ─→ M2 ─→ M3 ─→ M7
       │      ↘
       └─→ M4 ─→ M5 ─→ M6 ─→ M7
(M1 ✅ já feito; M4 pode começar com M3 a meio — o Vorgar afina-se a solo primeiro)
```

A regra de paralelismo para dois construtores (ou um agente e dois donos): **arte (M6) nunca antes do seu greybox validado**; de resto, M3 e M4 sobrepõem-se bem.

## Riscos do plano inteiro — e a resposta escrita

| Risco | Sinal | Resposta |
|---|---|---|
| Combate não diverte | o teste da noite no M2 falha | itera `data/` pela ordem de afinação do WP15B; o plano espera |
| Animação derruba o desempenho | p99 > 16,7 ms no 1.º dia do M6 | cortar ossos/influências/personagens em cena — o conteúdo espera |
| Rede frustra | esquiva injusta a 100 ms no M3 | rever a tolerância do parry (WP10) antes de culpar o transporte |
| Escopo cresce | "já agora mete-se…" | a fatia 1 é a linha; tudo o resto vai para o 99 ou para "ideias" |
| Decisões pendentes bloqueiam | uma pergunta 🔴 do 99 trava um marco | nenhuma trava a fatia — foi desenhada assim de propósito (WP0); se travar, é sinal de desvio da fatia |

## O que continua aberto

- O repositório `worldrpgs` e Godot 4.7.1-stable estão materializados; já não são trabalho de M0.
- O carimbo dos dois nas propostas 🔴 do 99 — não travam a fatia, mas a **sessão 2 gravada** deve acontecer antes do fim do M5, para a fatia 2 ter chão

## Ligações

Tudo — este documento é o índice de execução. Em particular: [`10-fatia-1.md`](10-fatia-1.md) (os critérios) · [`23-tecnico.md`](23-tecnico.md) (com quê) · [`28-testes.md`](28-testes.md) (como se mede) · [`99-perguntas-abertas.md`](99-perguntas-abertas.md) (o que falta decidir).
