# LACUNAS — o que falta, e ninguém está a fazer

**Actualizado: 01-08-2026, Revisão 3.** Mantido pelo **Claude/Codex**. É a lista de tudo o que foi identificado como buraco e **ainda não tem dono**.

> **Porque existe:** as lacunas que eu encontro a rever viviam em **comentários de PR**. Um comentário lê-se uma vez e desaparece — e uma lacuna esquecida é uma lacuna que se descobre no fim, quando custa dez vezes mais.
>
> ⭐ **A regra:** encontrei uma lacuna → escrevo-a aqui **no mesmo acto**. Quando alguém a resolve, risca-se com o commit ao lado.

**Legenda:** 🔴 trava alguma coisa · 🟠 devia entrar na volta indicada · 🔵 quando houver tempo · ⏳ é dos donos, não dos agentes

---

## 🔎 Auditoria de 01-08 — 23 achados confirmados

**Corrida pelo Fable com 35 agentes em quatro lentes** (a camada de rede nova · privacidade e licenças num repo público · coerência da spec · a regra dos números em dados). ⭐ **Cada achado foi verificado por um segundo agente que abriu o ficheiro** — os que não se confirmaram foram deitados fora, e alguns eram do próprio auditor a não perceber o contexto.

### ✅ Já corrigidos neste PR

| | O quê |
|---|---|
| 🔒 | **O `BRAIN.md` dizia onde existia uma chave Gemini válida em texto simples**, com o caminho do ficheiro. A chave **não** está neste repositório — mas a linha era um mapa para quem procura, e o repo é público. ⚠️ **A chave tem de ser rodada pelo Mateus:** apagar a linha não a apaga do histórico do git |
| 🔒 | **`BRAIN.md`** tinha um caminho absoluto com o nome de utilizador real de uma das máquinas |
| 🔒 | **`CLAUDE.md` e `memory/context.md`** ligavam o nome próprio real do Rico à conta de GitHub. A regra *"não lhe chames X"* nomeava X para o proibir — reescrita para funcionar sem o nomear |
| 🔒 | **O `LACUNAS.md` repetia 9 vezes os nomes das transcrições privadas** que o `.gitignore` protege. Falha minha: limpei o `MAPA.md` e deixei estas |
| ✅ | O gerador do mapa (secção abaixo) |

### 🔴 Para quem tem o ficheiro — os dois que travam

| | Achado | Dono |
|---|---|---|
| 🔴 | ⭐ **O guarda da regra de ouro nunca falha nada.** O `game_data.gd` acumula os problemas de coerência em `load_errors` e faz `push_error` — mas **`push_error` não muda o código de saída do Godot**, e `grep -rn "load_errors"` mostra que **ninguém lê essa lista**. O `self_test.gd` sai pelo seu próprio contador. Ou seja: os dados podem divergir da spec e **tudo passa a verde**. Correcção de uma linha: `_check(GameData.load_errors.is_empty(), …)` no `self_test.gd` | dono do `self_test.gd` |
| 🔴 | ⭐ **O `spec/56` ensina o contrário de um `[DECIDIDO]`.** A §6 inteira especifica o desbloqueio de loja por tomos — *"o vendedor vende o que TU encontraste"* — e o Mateus revogou isso a 01-08 (*"os vendedores vendem tudo do jogo nao so o que eu achei"*). O documento **não tem banner de camada histórica**, ao contrário do 13/16/17/34. ⚠️ **E o `SPEC.md` é pior:** resume o 56 pela regra revogada **e carimba-o 🟢** — quem lê o índice sai já com a regra errada sem abrir o ficheiro. *Atenuante: a loja ainda não existe em código, portanto é risco e não regressão* | dono do `56` e do `SPEC.md` |

### 🟠 Coerência — o que a spec afirma e não bate com o disco

| | Achado | Dono |
|---|---|---|
| 🟠 | **O `ESTADO.md` conta mal o projecto:** diz *"18 ficheiros `.gd` · 17 catálogos JSON"*; são **121** `.gd` em `game/src/` e **19** JSON. É a tabela que o próprio documento apresenta como *"o retrato do projecto"* | dono do `ESTADO.md` |
| 🟠 | **O número de testes está desactualizado em nove sítios:** `9531` no `ESTADO.md` (×6), `44`, `60`, `63`, `99`; e **`8435`** no `game/CLAUDE.md` e no `CODEX-CONTEXTO.md` — que são lidos no arranque de cada tarefa. O valor real é **9703** | vários |
| 🟠 | **O `spec/64` proíbe nominalmente a 7.ª origem que o Mateus decidiu.** Diz *"só aparecem as seis classes"*; o `DECISOES.md` diz que o Mago do Mal entra no ecrã de criação. ⚠️ **Não é para reescrever já** — o `weapons.json` declara o cartão impossível por falta de relicário, atributos e postura. Precisa de banner, não de reescrita | dono do `64` |
| 🟠 | **O `ESTADO.md` diz que não existem coisas que existem:** o ecrã de criação (`game_shell.gd`), o `appearance.json` e a roda de feitiços (`spell_wheel.gd`) estão todos no disco e testados | dono do `ESTADO.md` |
| 🟠 | **A minha própria entrada anterior sobre o 19.º catálogo estava meia errada** — o guarda já conta 19. O que ainda vale: `status_effects.json` é **contado e não verificado**, e o `game_data.gd` não o expõe | Fable *(corrijo)* |

### 🟠 A regra de ouro — números de combate fora dos dados

| | Achado | Dono |
|---|---|---|
| 🟠 | **`player.gd:765` tem o arco de ataque `110°` escrito em código.** Não existe chave em JSON nenhum. ⭐ O caminho do inimigo faz o contrário e faz bem: lê `arc_degrees` do `enemies.json`, declarado 79 vezes | dono do `player.gd` |
| 🟠 | **`player.gd:308,311` tem o limiar toque-vs-segurar como `9` à mão, duplicado em duas linhas que têm de concordar.** São os 150 ms que o `spec/25` fixa | dono do `player.gd` |
| 🟠 | **`combat.json` tem `cast_move_multiplier` que ninguém lê** — o runtime usa outra chave, no `spells.json`. O único leitor é um teste, que assim verifica um número morto | dono do combate |
| 🟠 | ⭐ **16 testes tautológicos** no `status_effect_self_test.gd`: comparam um bloco do JSON com outro bloco do **mesmo** JSON. Passam sempre e não provam nada — o valor devia estar ancorado ao literal da spec | dono dos estados |

### 🌐 Na minha camada de rede — corrijo eu

Sete achados, todos reais. Estão na secção da rede, mais abaixo, e vão no PR seguinte.

---

## 🔒 O gerador do mapa publicava nomes de ficheiros privados — corrigido 01-08

**Encontrado ao investigar um link partido, e é maior do que o link.**

O `MAPA.md` é gerado pelo [`tools/mapa.mjs`](tools/mapa.mjs), que **varria o disco** com uma lista de exclusões escrita à mão. Essa lista **não batia com o `.gitignore`** — e o `.gitignore` exclui `design/transcripts/` e `design/ideas/` **por privacidade**: são conversas privadas dos donos num repositório público.

| | |
|---|---|
| **O sintoma** | dois links partidos, e o guarda da spec a falhar para toda a gente, para sempre |
| ⚠️ **O problema a sério** | o mapa **publicava os nomes e as datas** das transcrições privadas na `main`. Fuga de metadados exactamente daquilo que o `.gitignore` protegia |
| **A causa** | uma lista de exclusões à mão que diverge do `.gitignore` diverge **sempre**, mais cedo ou mais tarde |
| ✅ **A correcção** | o gerador passa a perguntar ao git (`git ls-files`) em vez de varrer o disco. Estruturalmente, **não consegue** listar um ficheiro que não está no repositório |
| **A prova** | criei um ficheiro em `design/transcripts/`, corri o gerador, e ele **não entrou** no mapa |

⭐ **A lição, que vale para outras ferramentas:** qualquer coisa que gere conteúdo para um repositório público a partir do disco tem de perguntar ao git o que é público, não adivinhar.

---

## 🌐 A camada de rede — o que ficou por ligar

**Escrito 01-08 pelo Fable, ao entregar `game/src/net/`.** A camada existe, tem 26 verificações e o orçamento de banda está **medido**. O que falta é **ligá-la ao jogo**, e cada linha aqui precisa de um ficheiro que **tem outro dono** ([`prompts/PARA-O-OPUS-DO-RICO.md`](prompts/PARA-O-OPUS-DO-RICO.md) §3) — por isso está escrito aqui em vez de eu lhe mexer.

| | O que falta | De quem preciso |
|---|---|---|
| 🔴 | **O corpo do parceiro não aparece em cena.** A rede transporta a pose e interpola-a; falta alguém instanciar um `Player` remoto e alimentá-lo com `NetSession.partner_body()` a cada frame | dono do `game/src/coop/` |
| 🔴 | **Os eventos de combate não estão ligados.** O `NetSession.combat_event` dispara com golpes, parries e mortes, e **ninguém o ouve.** O contrato da autoridade está implementado e testado; falta o outro lado do fio | dono do `game/src/coop/` e do combate |
| 🟠 | ⭐ **A vida do chefe não reescala quando o parceiro cai.** O [`19`](spec/19-rede.md) manda: de ×1,8 para ×1,0 **proporcionalmente ao que falta**. A rede emite `session_ended`/`peer_disconnected`; falta o chefe ouvir | dono do `game/src/enemies/boss*.gd` |
| 🟠 | **O menu de rede não tem tecla.** O `net_menu.gd` existe e funciona, mas nada o abre — é a pergunta 1 do fio solto por atar, e a tecla vive no mapa de comandos, que não é meu | dono do `data/controls.json` e do `game_shell.gd` |
| 🟠 | **O aviso de latência vive num `CanvasLayer` próprio** (`net_hud.gd`), porque o `src/ui/hud.gd` tem dono. Quando quiserem absorvê-lo, são dez linhas | dono do `hud.gd` |
| 🟠 | **O save não sabe de sessões.** O [`19`](spec/19-rede.md) separa o saco *personagem* do saco *mundo*; o `save_system.gd` guarda um só. Quem entra no mundo do outro **não pode** gravar por cima do mundo dele | dono do `save_system.gd` |
| ⏳ | ⭐ **O transporte é decisão dos donos** — porta aberta no router **ou** VPN de amigos. O código é agnóstico e liga a qualquer endereço, portanto isto **não trava nada**; mas até alguém abrir a porta, ninguém joga a dois | Mateus + Rico |

⚠️ **E o que a camada NÃO prova:** os 26 testes verificam o formato do fio, a interpolação, a tolerância do parry e as regras de autoridade — **sem nunca ligar duas máquinas**. A latência real entre as duas casas só existe quando as duas casas existirem, e é aí que o `< 80 ms` da spec passa de alvo a facto.

---

## 🔴 Travam

**Da auditoria independente do Codex** ([`docs/AUDITORIA-CODEX-2026-08-01.md`](docs/AUDITORIA-CODEX-2026-08-01.md), 01-08). ⚠️ **As quatro primeiras são erros meus, não do Fable.**

| | Lacuna | Origem |
|---|---|---|
| ✅ | ~~"Rolar para o lado funciona sempre"~~ **CORRIGIDO 01-08** — cada ataque declara **momento de compromisso, curva de seguimento e vector de fuga**, escolhido de uma lista de 9. E o vector **tem de ser legível na animação** | [`38`](spec/38-ataques-e-honestidade.md) §2b |
| ✅ | ~~A hitbox de 3–6 frames é regra de espada aplicada a tudo~~ **CORRIGIDO 01-08** — três tipos de contacto: **instantâneo** (3–6 frames), **volume móvel** (uma vez por passagem), **volume persistente** (dano por intervalos declarados). A regra unificadora: *a hitbox vive exactamente enquanto o efeito se vê* | [`38`](spec/38-ataques-e-honestidade.md) §1b |
| ✅ | ~~⭐ **A fórmula da estabilidade estava invertida**~~ **CORRIGIDO 01-08** para `dano × (1 − estabilidade/100)`; o broquel já não bloqueia melhor que o escudo grande | [`41`](spec/41-estudo-armas-e-golpes.md) §6 · `3f7fe16` |
| ✅ | ~~O espelho é mais fácil do que o parry~~ **RESOLVIDO 01-08** — janela de 0,25 s, recuperação se falhar, escala pelo instrumento, e recompensa maior quando acerta | [`53`](spec/53-chefes-ritmo-e-o-mago-forte.md) §4 |
| ✅ | ~~O intervalo de 0,20 s entre atacantes não chega~~ **CORRIGIDO 01-08** — conta-se a partir de **quando o jogador pode agir**, não do relógio. E o tecto de 2 agressores passa a garantir **rota de fuga** em vez de um número | [`38`](spec/38-ataques-e-honestidade.md) §3 |
| ✅ | ~~⚠️ **Melhoria de armas (+10%/nível) era a Lei 2 quebrada**~~ **RESOLVIDO 01-08** — base + seis níveis abrem postura/moveset, arte, troca de escala ou conversão elemental; zero aumento de dano base | [`68`](spec/68-catalogo-de-armas-armaduras-e-aneis.md) §3 |
| ✅ | ~~61 chefes = um encontro a cada 30–40 s~~ **RESOLVIDO 01-08** — 13 verdadeiros + 12 subchefes + ~36 nomeados, travessia de 8–12 min, e **30 portas de história catalogadas** para crescer no futuro | [`53`](spec/53-chefes-ritmo-e-o-mago-forte.md) · [`69`](spec/69-catalogo-do-mundo.md) |
| ✅ | ~~**Doze feitiços prometiam efeitos sem mecanismo executável**~~ **RESOLVIDO NA TAREFA 5** — os 12 têm `effect_type`, números, expiração/saída e baseline M2; Chama Faminta usa postura/guarda e Espelho aplica 0,25 s/0,6 s com escala pelo instrumento | [`74`](spec/74-fecho-da-revisao-2.md) §3 · `spells.json` |
| ✅ | ~~**As melhorias dos 53 feitiços fingiam semântica pronta**~~ **FECHADO COM GATE HONESTO** — só o nível 0 está disponível; +1–+5 não chegam ao runtime enquanto Mateus + Rico não resolverem a `[TENSÃO]` 41 | [`74`](spec/74-fecho-da-revisao-2.md) §3 · pergunta 41 |
| ✅ | ~~**Escudos aplicavam 50% mágico global apesar da afinidade não decidida**~~ **FECHADO SEM DECIDIR 43** — fallback passa a 0% e declara `blocked_owner_q43`; afinidade futura continua decisão dos donos, sem comportamento fantasma hoje | [`74`](spec/74-fecho-da-revisao-2.md) §3 · pergunta 43 |
| ✅ | ~~**A garantia “fugir funciona sempre” não tinha mecanismo em 18/33 fichas comuns**~~ **RESOLVIDO NA TAREFA 5** — as 18 recebem velocidade por papel e o auto-teste simula a fuga até ao leash, não só `<5,0` | [`74`](spec/74-fecho-da-revisao-2.md) §4 |
| ✅ | ~~**Cinco garantias visíveis apontavam para acessórios fantasma**~~ **RESOLVIDO NA TAREFA 5** — quatro sinos migrados para anéis existentes; o baralho da lanterna usa consumível + anel; `acessorio:*` é agora erro, não aviso | [`74`](spec/74-fecho-da-revisao-2.md) §2 |
| ✅ | ~~⭐ **Projécteis e formas de entrega não tinham física executável**~~ **RESOLVIDO NA TAREFA 5** — `tiro`, `perseguidor` e as 12 formas declaram movimento, colisão, cadência, pulso e expiração; projéctil móvel deixou de ser instantâneo | [`74`](spec/74-fecho-da-revisao-2.md) §1.2–1.3 · pergunta 46 continua dos donos |
| ✅ | ~~**Onze guardiões e doze subchefes deixavam IDs pendurados**~~ **DEPENDÊNCIA FECHADA** — 24 slots estáveis; Vorgar implementado, 23 com `enemy_id:null` + `blocked_owner_q52`, sem contar como conteúdo pronto | [`74`](spec/74-fecho-da-revisao-2.md) §2 · pergunta 52 |
| ✅ | ~~**As ameaças ambientais tinham 18 parâmetros por decidir**~~ **RESOLVIDO NA TAREFA 5** — as 12 têm `runtime_type`, números e `unresolved_parameters: []`; valores `[CODEX]` validam-se no M2 | [`74`](spec/74-fecho-da-revisao-2.md) §1.5 |
| ✅ | ~~**Habilidades/Eco não declaravam compromisso comum**~~ **RESOLVIDO COMO BASELINE M2** — seis activações/compromissos e Eco com fonte, alvo, tempo, custos e falha explícitos; 45 continua decisão dos donos | [`74`](spec/74-fecho-da-revisao-2.md) §1.1 |
| ✅ | ~~**Afinidade dos 70 anéis não tinha namespace nem semântica**~~ **RESOLVIDO SEM GATING** — nove etiquetas fechadas, só recomendação/bias de loot, validadas em todas as fichas | [`74`](spec/74-fecho-da-revisao-2.md) §2 · pergunta 48 |
| 🟠 | ~~**Percepção/retorno não tinham parâmetros completos**~~ **CÉREBRO M2 IMPLEMENTADO, LIGAÇÃO PENDENTE** — `game/src/ai/` executa cone/LOS, audição, alerta, chamada, desistência, regresso, pulso/cura, reaquisição, espera/órbita/recuo, oportunidade visível, vagas e intervalo pós-acção; 31/31 provas próprias + sonda real de multidão passam. **O dono de `game/src/enemies/enemy.gd` ainda tem de substituir o raio directo pela nova fronteira**, apresentar os `readable_cue`, propagar chamadas e fornecer a transição real `can_act`; esta árvore não pode editar esse ficheiro. | [`74`](spec/74-fecho-da-revisao-2.md) §1.4 · [`enemy_perception.gd`](game/src/ai/enemy_perception.gd) · [`enemy_combat_brain.gd`](game/src/ai/enemy_combat_brain.gd) |
| ✅ | ~~**As 57 armaduras futuras fingiam habilidade**~~ **RESOLVIDO** — dizem `effect_type:none`, `implemented:false`; as 11 iniciais continuam honestamente activas até 44/54 | [`74`](spec/74-fecho-da-revisao-2.md) §2 |
| ✅ | ~~**Os 70 anéis não tinham cliente e cinco inventavam sistemas**~~ **RESOLVIDO** — vocabulário fechado de clientes; cinco efeitos reescritos sem travessia/matchmaking novos | [`74`](spec/74-fecho-da-revisao-2.md) §2 · pergunta 55 |
| ✅ | ~~**Cinco dos seis instrumentos mágicos não existiam**~~ **DEPENDÊNCIA FECHADA** — só `cajado` é prometido e tem ficha 1,0; os outros cinco saíram das escolas até 56 lhes dar slot/comportamento | [`74`](spec/74-fecho-da-revisao-2.md) §2 |
| 🔴 | ⚠️ **O limitador de 60 de `settings_system.gd` colide com FIFO:** na zona completa limpa, FIFO + `Engine.max_fps=60` deu p99 **29,691 ms** e 1% low 32,9; cap 120 deu p99 **16,666 ms** e 1% low 56,6, mas ainda um pico isolado de 33,33 ms. `[CODEX]` recomenda omissão 120 quando FIFO está activo (razão: única variante que fez passar p99 sem cortar imagem; sem cap foi rejeitado a 19,469 ms). **Falta o dono de `game/src/autoload/settings_system.gd` consumir `presentation.recommended_engine_cap_with_fifo`; esta árvore não pode editar esse ficheiro.** O teste quente integrado 2+5 e o tecto de pior frame continuam abertos | [`PERF`](game/PERF.md) · [`74`](spec/74-fecho-da-revisao-2.md) §5 · [`medição`](medicoes/animacao-esqueleto-2026-08-01.json) |
| 🔴 | ⚠️ **O guarda de coerência não passa na `main` actual:** `MAPA.md` ainda liga a *(um registo de sessão privado, gitignored)* e *(um registo de sessão privado, gitignored)*, mas ambos estão ausentes. Regenerar o mapa ou restaurar as fontes na árvore que possui esses ficheiros; desempenho não lhes mexeu | `node tools/check-coerencia.mjs` em 01-08-2026 · `MAPA.md` linhas 47–48 |
| 🔴 | ⚠️ **O novo catálogo autorizado `game/data/status_effects.json` eleva `game/data` de 18 para 19 JSON, mas o guarda tem o total 18 hardcoded e `GameData` ainda não o inclui na validação central.** O dono de `tools/check-coerencia.mjs` deve aceitar/validar o 19.º catálogo e o dono de `game/src/autoload/game_data.gd` deve expô-lo ou reconhecer que `StatusEffectManager` o carrega; esta árvore só pode escrever no catálogo e em `game/src/status/`. Até lá, o auto-teste passa 9703/9703 mas o guarda acrescenta este terceiro erro aos dois links já conhecidos. | `game/data/status_effects.json` · `node tools/check-coerencia.mjs` em 01-08-2026 |
| 🔴 | ⚠️ **O conjunto residente “zona actual + todas as vizinhas” ganhou orçamento e fail-safe, mas não ganhou a decisão nem a prova no alvo.** `[CODEX]` reservou 1 638/2 560 MiB para mundo/arte: Fojo com 6 zonas impõe **256 MiB incrementais por zona**; a proposta `actual + transição` permite 512 MiB por zona. Na Iris Xe/15,73 GiB local, uma Brumal elevou working set **481,1→550,2 MiB** e a candidata partilhada chegou a **619,4 MiB**; memória passou, mas `Greybox.build()` publicou a vizinha em **113,004 ms** e foi recusado pelo gate de 20 ms. **Falta repetir no i5-1334U/8 GiB do Rico e medir seis zonas finais distintas, que ainda não existem.** | [`ORCAMENTO`](game/src/world/zones/ORCAMENTO.md) · [`medição local`](game/src/world/zones/medicao-streaming-local.json) · revisão 2 · [`69`](spec/69-catalogo-do-mundo.md) §6 · pergunta 50 |
| 🔴 | ⚠️ **Invocações sem tecto colidem com o máximo de oito actores animados.** Um encontro de 2 jogadores + 5 inimigos já ocupa 7; sobra uma vaga para invocações dos dois, chefe portátil e qualquer reserva. Sem orçamento global, a promessa do mago pode exceder a Lei 4 na primeira conjuração extra | revisão 2 · [`21`](spec/21-arte-render.md) §2 · [`52`](spec/52-mago-do-mal.md) §10 · pergunta 51 |
| 🟠 | ⚠️ **Os 53 VFX não têm política de residência.** Não é o número de feitiços que custa por frame, é pré-carregá-los: uma implementação ingénua com 3 texturas RGBA8 1024² + mipmaps por feitiço rondaria **848 MiB**, acima do orçamento residente de texturas de 500 MB antes de cenário/personagens. Usar atlas partilhado e carregar só favoritos/escola/encounter; medir antes de produzir 50 VFX futuros | revisão 2 · [`21`](spec/21-arte-render.md) §2 · [`66`](spec/66-catalogo-de-magia.md) |
| ⏳ | ⭐ **Ordem de corte com menor perda**, se for preciso cortar: 1.ª pessoa → 48 chefes reclassificados → 5 slots de armadura → 6 slots de anel → armas acima de 24 → feitiços acima de 24. **Não cortar:** co-op, esquiva/parry/stamina, as 8 famílias, a identidade dos 12 biomas | auditoria §4 |

---

## 🎮 Da Revisão 3 — lacunas de experiência

Relatório completo: [`docs/REVISAO-3.md`](docs/REVISAO-3.md). As linhas `⏳` são decisões dos donos; não autorizam um agente a redesenhar a spec.

| | Lacuna | Origem |
|---|---|---|
| 🔴 | **A abertura jogável está pronta como fronteira, mas ainda não está ligada pela casca.** `IntroSequence` conserva o controlo, consome `strings.pt.json`, serve as cinco dicas remapeadas e liga descrições aos cinco IDs dos kits; hoje `game_shell.gd` ainda mostra o prólogo estático/hardcoded, `main.gd` ainda bloqueia o despertar e pede dicas à casca, e a mochila ainda não pede `item_description()`. Os donos desses ficheiros têm de substituir essas três chamadas; esta árvore não lhes pode escrever. | [`26`](spec/26-narrativa.md) §§1.1–1.2 · `game/src/ui/intro_sequence.gd` |
| ⏳ | 🔴 **O combate comum ainda não prova co-op:** nenhum encontro da Fatia 1 exige salvar, preparar uma abertura ou executar tarefas simultâneas; o jogador melhor pode limpar o caminho enquanto o outro acompanha | revisão 3 · perguntas 59/32 |
| ⏳ | 🔴 **Brumal pede densidade larga com só dois tipos `fatia_1:true`.** O Batedor e um nomeado que depende dele aparecem no orçamento, mas continuam fora da fatia; decidir promover o terceiro papel ou cortar para 6–7 batidas | revisão 3 · pergunta 57 |
| ⏳ | 🔴 **Meditação segura cria até 80 s de espera para o parceiro; ressurreição exige 5–7 s onde Vorgar/refúgios só declaram janelas abaixo de 2 s.** Falta agência do caído e uma janela executável | revisão 3 · perguntas 58/60 |
| 🔴 | **O orçamento de almas não pode ser pago pelo runtime corrente:** baralho/transacção fecham após 10 derrotas do tipo; `souls_ten_rewarded_clears` multiplica cada colocação por 10. Separar almas de cartas depois de Mateus + Rico fecharem o contador | revisão 3 · pergunta 23 · [`67`](spec/67-catalogo-do-bestiario.md) §6 · [`72`](spec/72-materiais-consumiveis-e-economia.md) §4 |
| ⏳ | 🟠 **Mochila infinita + loot instanciado + garantia + chefe que larga tudo transforma descoberta em checklist.** Falta uma escolha que preserve a garantia contra azar | revisão 3 · pergunta 61 |
| ⏳ | 🟠 **“Nunca se zera” não tem exemplar jogável:** recompensas/corpos esgotam, as 30 portas não devem resposta e a segunda leitura de Brumal não está autorada | revisão 3 · pergunta 62 |
| ⏳ | 🟠 **A promessa mais própria — cadáveres/Voto/chefe portátil — não é testada pela Fatia 1.** Decidir spike/epílogo antes de produzir 50 feitiços futuros | revisão 3 · pergunta 63 |
| 🟠 | **Vorgar ainda não tem as sequências SEPARAR/JUNTAR nem uma janela de ressurreição materializadas no greybox.** O contrato já as exige; falta autoria/prova M2 | revisão 3 · [`61`](spec/61-arenas-de-chefe.md) §7 |
| ⏳ | 🟡 **Até dez anéis + nove peças + oito favoritos podem transformar build em espera de menu co-op.** Validar 4 anéis/presets no descanso antes de abrir a escala toda | revisão 3 · pergunta 64 |
| ✅ | ~~O teste de honestidade só provava a esquiva certa~~ **CORRIGIDO** — agora duas esquivas sem sobreposição com o activo têm de falhar 10/10; um teste verde deixa de aceitar janela/hitbox que não discrimina timing | revisão 3 · [`38`](spec/38-ataques-e-honestidade.md) cláusula 5 |
| ✅ | ~~O fecho do `72` ainda dizia que cinco acessórios ficavam fora do contrato~~ **CORRIGIDO** — a fronteira reconhece a migração já feita pelo `74` | revisão 3 · [`72`](spec/72-materiais-consumiveis-e-economia.md) §6 |

---

## 🟠 Para as voltas que aí vêm

### Volta 2 — fichas de raça 🔨 *em curso*

| | Lacuna | Origem |
|---|---|---|
| ✅ | ~~⚠️ **A linha "porque está neste bioma"**~~ **RESOLVIDA** — as 12 fichas ligam origem/necessidade ao bioma e a validação cruza `races.json` ↔ `biomes.json` nos dois sentidos | [`50`](spec/50-racas.md) · `664ec7e` |
| ✅ | ~~**Em que biomas cada raça aparece, e o que muda em cada variante**~~ **RESOLVIDO** — variantes têm papel/ataques próprios nas fichas do bestiário, não apenas cor | [`50`](spec/50-racas.md) · [`67`](spec/67-catalogo-do-bestiario.md) · `d7088b7` |
| ✅ | ~~⚠️ **Santuário Branco e A Raiz sem raça própria**~~ **RESOLVIDO** — Penitentes e Sem-rosto são habitantes dominantes e têm fichas/combate | [`50`](spec/50-racas.md) · [`67`](spec/67-catalogo-do-bestiario.md) · `d7088b7` |
| ✅ | ~~**Mímicos e Minotauros sem ficha adequada**~~ **RESOLVIDO 01-08** — mímico é praga com duas fichas de encontro; minotauros comuns variam por bioma e o guardião singular continua WP7 | [`50`](spec/50-racas.md) · [`67`](spec/67-catalogo-do-bestiario.md) |

### Volta 3 — armas e armaduras

| | Lacuna | Origem |
|---|---|---|
| ✅ | ~~**Os 7 golpes por declarar**~~ **RESOLVIDO 01-08** — 88 fichas, onze por cada uma das oito famílias; runtime continua abaixo | [`68`](spec/68-catalogo-de-armas-armaduras-e-aneis.md) §2 |
| ✅ | ~~**Melhoria de armas**~~ **RESOLVIDO 01-08** — seis escolhas sem força | [`68`](spec/68-catalogo-de-armas-armaduras-e-aneis.md) §3 |
| ✅ | ~~**Estados alterados**~~ **RESOLVIDO 01-08** — veneno, sangramento e queimadura com barra, disparo, saída e simetria | [`68`](spec/68-catalogo-de-armas-armaduras-e-aneis.md) §4 |
| 🟠 | **Integração M2 dos estados está fora da árvore dona:** `game/src/status/` já entrega acumulação/decadência/disparo, consequências simétricas, descanso, quatro consumíveis, cinco anéis, barras e PCM (65 provas; Iris Xe 1080p: 454,4 fps com três barras, +0,659 ms sobre baseline vazio, 53,16 µs por evento após cache). Falta aos donos de `player.gd`/`enemy.gd` aplicar os outcomes a PV/stamina/IA e escolher autoridade co-op; inventário/equipamento chamar `use_consumable`/`equip_rings`; a esquiva passar a etiqueta da superfície a `finish_dodge`; a fogueira chamar `clear_on_rest`; e a scene/HUD montar `StatusEffectPresenter`. Sem estas ligações, o módulo está provado mas ainda não é alcançável a jogar.** | `game/src/status/status_effect_manager.gd` · `game/src/status/status_effect_presenter.gd` · `game/src/status/status_effect_self_test.gd` |
| ✅ | ~~**Requisitos de atributo**~~ **RESOLVIDO** — abaixo do requisito continua utilizável a ×0,6 sem escala; nenhum catálogo passa 18 | [`11`](spec/11-formulas.md) · [`68`](spec/68-catalogo-de-armas-armaduras-e-aneis.md) |
| 🟠 | **Produção M2: ligar ao jogador os sete golpes novos, estados, segunda adaga e as assinaturas de arma.** `WeaponProgression.moveset()` já resolve 15 assinaturas distintas sobre os 120 perfis e declara verbo/compromisso; `player.gd`, animações e `GameplayCue` ainda só executam leve/pesado/cadeia/bash | encontrado ao fechar o [`68`](spec/68-catalogo-de-armas-armaduras-e-aneis.md) · integração fora de `game/src/weapons/` |
| 🟠 | **Equipar, votos de melhoria, 2→10 dedos e persistência ainda não fecham o circuito.** `upgrade_menu.gd` já prova base +6, custo e reversão no altar sem aumentar dano base; faltam a cena chamar o ecrã, o save v2 persistir escolhas por instância e o inventário consumir material atomicamente | encontrado ao fechar o [`68`](spec/68-catalogo-de-armas-armaduras-e-aneis.md) · integração fora de `game/src/ui/upgrade*.gd` |
| 🟠 | **O catálogo de armadura cresceu do alvo `[DECIDIDO]` de ~30 para 68 peças** porque o WP6 já prometia 57 IDs além das 11 iniciais. A coluna `Fatia 1?` contém a produção (só 11 agora), mas Mateus + Rico têm de aceitar a expansão ou mandar consolidar IDs | [`34`](spec/34-catalogo-e-comandos.md) · [`67`](spec/67-catalogo-do-bestiario.md) · pergunta 44 |
| 🟠 | **Integração do peso no jogador:** `ArmorSystem.load_profile_for_weight()` já entrega distância, duração, recuperação, regeneração e i-frames a partir de `armor.json`, mas `Player`/`InventorySystem` ainda consomem o perfil antigo. O dono desses ficheiros tem de ligar `dodge_distance` e `dodge_duration_frames` à esquiva e conservar `iframe_start_frame`/`iframe_end_frame`. `[CODEX]` Propõe-se actualizar `spec/70` para a decisão mais recente do Mateus: pesado = 70% da distância em 125% da duração; i-frames 5–23. Razão: o pedido actual decidiu “rola mais devagar”. Alternativa: manter a recuperação invisível de +8 f e distância normal descrita na versão anterior do `70` | entrega da armadura 01-08 · `game/src/equipment/armor_system.gd` · `armor.json` |
| 🟠 | **Integração das resistências no dano:** o cálculo por tipo, tecto por peça, acumulação multiplicativa e piso corporal está isolado em `ArmorSystem`, mas o receptor de dano do jogador/inimigo vive fora da árvore deste agente. O dono do combate deve chamar o perfil tipado antes de retirar PV; nunca converter isto em defesa plana | entrega da armadura 01-08 · `game/src/equipment/armor_system.gd` |
| 🟠 | **Integração visual que preciso do dono de `player.gd`/`character_visual.gd`:** criar/obter uma instância de `ArmorCharacterVisual` no jogador e, em `player.gd::apply_inventory_state(equipment, load_profile)`, chamar `apply_armor(equipment.get("armor", []))`; repetir no spawn inicial. Hoje esse método actualiza IDs de armas/carga/feitiços, mas não chama a camada visual de armadura. A extensão já troca malhas no mesmo rig e conserva a chave de silhueta; não alterei os ficheiros-base proibidos | entrega da armadura 01-08 · `game/src/visual/armor_character_visual.gd` · verificação do circuito de acesso rápido 01-08 |
| 🟠 | **Abrir o ecrã WP11 no jogo:** `ArmorEquipmentScreen` usa os nove slots canónicos, compara vestido/candidato e mostra carga antes de confirmar, mas falta ao dono de `inventory_menu.gd`/`game_shell.gd` expor a acção navegável que o abre. Não há tecla nova: deve reutilizar a acção configurável `inventory_menu` e a mesma entrada de Armadura da mochila/loja | entrega da armadura 01-08 · `game/src/equipment/armor_equipment_screen.gd` |
| 🟠 | **Arte modular honesta:** os 39 modelos KayKit Adventurers referidos no pedido são 6 personagens + props; nos personagens importados só existem malhas independentes para cabeça, rosto, peito e capa. Ombros, mãos, cintura, pernas e pés não têm modelo encaixável por slot, e as 57 peças futuras não têm receita visual. Não fingir esses cinco slots: precisam de arte CC0 nova ou produção própria antes de aparecerem | sonda `game/src/visual/armor_asset_probe.gd` · KayKit Adventurers 2.0 CC0 |
| 🔵 | **Como a mira do arco comunica a queda da flecha** — sem isso o jogador aprende "o arco falha às vezes" | [`36`](spec/36-fisica.md) §3 |

#### Armas iniciais — entrega de 01-08

| | Lacuna | Origem |
|---|---|---|
| 🟠 | **Integrar a prova no `repro-inicio.tscn`.** Esta árvore não pode escrever em `game/scenes/repro-inicio.tscn` nem em `game/src/tests/repro_inicio.gd`. O contrato reutilizável ficou em `game/src/weapons/starting_loadouts.gd` e o teste isolado `starting_loadouts_test.gd` prova as seis origens, unicidade, katana e save; o dono do repro deve chamar `StartingLoadouts.contract_errors(GameData.weapons, GameData.equipment)` antes de instanciar a casca. | pedido directo do Mateus · fronteira de propriedade desta árvore |
| 🟠 | **As armas continuam invisíveis nas mãos.** Os GLB KayKit das seis silhuetas não trazem armas embutidas; `CharacterVisual` só anexa `shield_badge_color.gltf` ao Paladino. Não há modelo exacto de katana, Espada de Vigília ou Espada de Prata importado em `game/`; `presentation.model_asset` fica honestamente `null`. O dono de personagens/render deve escolher/importar modelos licenciados, ligar cada ID a `handslot.r/l` e medir FPS/p99 na Iris Xe. | auditoria dos 176 assets importados · Lei 4 |
| 🟠 | **Artes de arma têm dados, mas não têm acção de input/runtime.** `controls.json` não declara `weapon_art` e `player.gd` não executa `arte_1mao`/`arte_2maos`; os perfis iniciais marcam `blocked_missing_input_action` em vez de fingir que a arte funciona. | quatro perguntas do fio solto · `spec/34` §2b |
| 🟠 | **Alinhar a spec antiga com a decisão nova.** `spec/12`, `51` e `64` ainda dizem três `longsword`/exactamente seis origens; a decisão do Mago do Mal e a queixa de 01-08 são posteriores. Esta árvore não é dona desses ficheiros. | `DECISOES.md` 01-08 · pedido directo do Mateus |
| 🟠 | **O agente `armas-e-melhorias` deve reconciliar os perfis e posturas `[CODEX]` do Tanque/Paladino e a stamina/base da katana.** Razão dos perfis: a origem tem de se sentir na mão; alternativa descartada: três IDs diferentes com o mesmo ataque ou pose genérica. Não sobrescrever silenciosamente os frames/posturas que esse agente medir. | possível colisão anunciada pelo Mateus |
| 🟠 | **O guarda global está vermelho por dois links partidos em `MAPA.md`.** Os alvos *(um registo de sessão privado, gitignored)* e *(um registo de sessão privado, gitignored)* não existem. Os 18 JSON/2797 contratos deram 0 erros; `MAPA.md` é gerado e não pertence a esta árvore. | `node tools/check-coerencia.mjs` em 01-08 |
| 🟠 | **O Godot gerou três sidecars `.gd.uid` não rastreados.** São `game/src/tests/repro_inicio.gd.uid` e os dois `game/src/weapons/starting*.gd.uid`; a propriedade concedida cobre apenas os `.gd`, por isso não os incluí. Os donos devem decidir se estes UIDs gerados entram ou se a política de `.gitignore` os cobre. | import obrigatório + execução directa do contrato |
| 🟠 | **O repro termina com `9 ObjectDB instances were leaked at exit`.** Todas as seis origens chegaram a `ARRANQUE OK` e os saves foram limpos, mas a fuga pertence ao ciclo de vida do repro/casca, fora dos ficheiros desta árvore; o dono deve fechar os nós/referências e voltar a medir. | `repro-inicio.tscn` headless em 01-08 |
| ⏳ | **Mago do Mal preparado, não inventado.** `loadouts._pending_mago_do_mal` regista a 7.ª origem `[DECIDIDO]`, mas não contém `main/offhand`: falta o relicário no catálogo, atributos e postura executável. Activar só quando esses contratos existirem. | `DECISOES.md` 01-08 · Lei 3 |
| ⏳ | **[CODEX] Recomendação para a katana: futura origem Espadachim, sem a criar nesta tarefa.** Razão: o Mateus ligou explicitamente “Espadachim = destreza” ao capricho nas katanas; é a associação mais reconhecível. **Alternativa descartada:** trocar as duas adagas do Assassino pela katana — apagava a identidade de offhand/Corte Alternado já desenhada e confundia furtividade com duelo. Até decisão do dono, a katana fica sem origem e acessível a qualquer uma pelo ciclo livre `[`/`]` (Lei 3). | `[CODEX]` · `DECISOES.md` linhas 114–115 |

**As quatro perguntas do fio solto desta entrega:**

1. **Como usa:** a origem deriva a arma no novo save; ataque leve é rato esquerdo/R1, pesado é `Shift` + ataque/R2, e `[`/`]` percorre também a katana sem bloqueio de classe. Artes continuam bloqueadas como indicado acima.
2. **Como prova:** `starting_loadouts_test.gd` deu **19/19**; verifica seis saves reais, seis armas principais únicas, assinaturas distintas, katana 14+5+16/2,1 m e o placeholder não inventado. Falta apenas a chamada dentro do repro, fora desta propriedade.
3. **Arte e som:** descrições vêm do catálogo `68/equipment.json`; modelos exactos estão em falta e declarados `null`; swing/hit corrente é o som sintetizado por `Sfx`, sem fingir áudio de pack por arma.
4. **Custo no Rico:** esta entrega acrescenta só JSON + validação, portanto **0 nós, 0 meshes e 0 draw calls** no render. Não se declara FPS novo porque a arma ainda não foi anexada; essa integração visual tem de medir p99/FPS na Iris Xe.

### Volta 4 — magia

⭐ **A forma de entrega é obrigatória em toda a ficha** — [`55-formas-de-feitico.md`](spec/55-formas-de-feitico.md). 12 formas, e o dano é o que menos as separa.

| | Lacuna | Origem |
|---|---|---|
| ✅ | ~~⭐ **Três formas em falta**~~ **RESOLVIDO 01-08** — Caçador Carmim, Granizo Carmim e Cutelo Carmim ocupam perseguidor, chuva e forma de arma; as 12 formas têm pelo menos um feitiço | [`66`](spec/66-catalogo-de-magia.md) §4–6 |
| 🟠 | ⚠️ **O traçado das zonas passa a afectar a magia** — tectos, corredores, terreno partido. A chuva morre debaixo de tecto | [`55`](spec/55-formas-de-feitico.md) §2 |

⭐ **A escola vermelha já está desenhada** — [`52-mago-do-mal.md`](spec/52-mago-do-mal.md), feita pelo Claude a pedido do Mateus (é o personagem dele). O WP4 herda-a; **não a reescreve.**

| | Lacuna | Origem |
|---|---|---|
| ⏳ | ~~As 6 perguntas do mago do mal~~ ✅ **4 respondidas 31-07** (chefe portátil · sem tecto de invocados · Voto empilha 3× · instrumento livre). Faltam: que feitiços cortar, e o tecto de máquina | [`52`](spec/52-mago-do-mal.md) §11 |
| ⏳ | **Quem manda nos invocados em co-op?** *(proposta: quem os levantou)* — não decidido pelo agente | [`52`](spec/52-mago-do-mal.md) §9 · pergunta 35 |
| ✅ | ~~**Inimigos que lançam magia usam as mesmas regras?**~~ **FECHADO** — partilham honestidade/contacto/interrupção; IA declara padrão/cooldown/usos e não finge mana/meditação | [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §1 |
| ✅ | ~~**Quantos feitiços na fatia 1**~~ **RESOLVIDO 01-08** — Dardo, Ruína e Égide; os três têm ícone aprovado e ficha completa | [`66`](spec/66-catalogo-de-magia.md) |
| ✅ | ~~**O material de melhoria de feitiço é o mesmo das armas, ou outro?**~~ **RESOLVIDO NA TAREFA 4** — catálogo regional partilhado; evita uma moeda paralela e conserva preferência marcial/arcana nas cartas `bias:classe` | [`72`](spec/72-materiais-consumiveis-e-economia.md) §2.1 |
| 🟠 | **Produção M3/fatias futuras: executar os 50 feitiços fora da Fatia 1.** Cada nova forma só entra com comportamento, hitbox e cue; a dívida tem autoridade e prova de saída no [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §8 | encontrado ao implementar o [`66`](spec/66-catalogo-de-magia.md) |
| 🟠 | **Produção WP11: roda e edição dos 8 favoritos.** A regra “só fora de combate/no descanso” está fechada; falta a UI que a aplique e a prova negativa em combate | [`66`](spec/66-catalogo-de-magia.md) · [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §8 |
| 🟠 | **HUD/arte: os slots já mostram activo, oito posições, custos, mana disponível e bindings actuais por marcas vetoriais, mas os três PNG aprovados continuam fora de `res://`.** A árvore dona de assets/HUD deve importar `dardo.png`, `ruina.png` e `egide.png` de `art/ui/icons/spells/` para `game/assets/ui/` e deixar `hud.gd` montar `SpellHud`; enquanto isso, o fallback em código é honesto e o `LockOn` local é a costura temporária. Não foi inventado som de interface sem cue aprovado | `game/src/ui/spell_hud.gd` · [`20`](spec/20-interface.md) §HUD · [`66`](spec/66-catalogo-de-magia.md) |
| ✅ | ~~**Escolas declaravam cinco instrumentos sem ficha**~~ **FECHADO NA TAREFA 5** — só o cajado baseline 1,0 é declarado; sino/talismã/chama/relicário/híbrido só regressam depois da decisão e spike 56 | [`74`](spec/74-fecho-da-revisao-2.md) §2 |

### Volta 5 — bestiário

| | Lacuna | Origem |
|---|---|---|
| ✅ | ~~**Som + sinal visual em cada ataque**~~ **RESOLVIDO 01-08** — 105 fichas compiladas têm cue ID/descrição e seis campos visuais | [`67`](spec/67-catalogo-do-bestiario.md) §4–7 |
| ✅ | ~~⭐ **`GameplayCue` + renderer e migração**~~ **RESOLVIDO 01-08** — faixa/área, glifo no mundo, bordo fora do ecrã, cancelamento 0,15 s e cinco perfis sonoros | [`67`](spec/67-catalogo-do-bestiario.md) §7 |
| ✅ | ~~**Massa de cada inimigo**~~ **RESOLVIDO 01-08** — 33 comuns + Vorgar, em kg, validada positiva | [`67`](spec/67-catalogo-do-bestiario.md) §3 |
| ✅ | ~~**Almas por inimigo e total por zona**~~ **RESOLVIDO 01-08** — primeira limpeza + limite de dez nas 12 zonas, recalculados no teste | [`67`](spec/67-catalogo-do-bestiario.md) §6 |
| ✅ | ~~**Ligar morte → compra do baralho → recibo/save**~~ **RESOLVIDO NA TAREFA 4** — `Enemy.died` chama compra idempotente; almas, item, índice e recibo são publicados na mesma geração atómica e a falha repõe o snapshot | [`72`](spec/72-materiais-consumiveis-e-economia.md) §4 · 9531 testes correntes |
| ✅ | ~~**Resolver os IDs de materiais e consumíveis dos cartões**~~ **RESOLVIDO NA TAREFA 4** — 40 materiais; os 17 tokens antigos eram 15 objectos + Brasa ilegal + grafia acentuada duplicada, ambos corrigidos | [`72`](spec/72-materiais-consumiveis-e-economia.md) §§2–3 |
| 🟠 | **31 fichas fora da Fatia 1 já têm perfil de silhueta distante e assinatura sonora sintetizada, mas ainda reutilizam corpos de protótipo; animação própria e hitbox de cada ataque continuam por produzir.** Os quatro esqueletos e 13 peças KayKit já entram no runtime; modelo final específico só quando `Fatia 1?` mudar | [`67`](spec/67-catalogo-do-bestiario.md) §8 · `game/src/enemies/enemy_visual.gd` · `→WP15B` |
| 🟠 | **Brumal continua a colocar só lanceiros e brutamontes no nível, apesar de o orçamento do bestiário declarar dois `goblin_mist_scout`.** O perfil visual/sonoro do Batedor está pronto, mas a composição vive em `game/src/main.gd`, fora da árvore do agente de inimigos; o dono do mundo deve colocar o terceiro papel sem empilhar pontos | [`67`](spec/67-catalogo-do-bestiario.md) §6 · `game/src/main.gd` |

### Volta 7 — chefes

| | Lacuna | Origem |
|---|---|---|
| ✅ | ~~⚠️ **Desenho de arena de chefe**~~ **RESOLVIDO 01-08** — tamanho por camada, obstáculos/refúgios, duas rotas e perguntas SEPARAR/JUNTAR para co-op | [`61`](spec/61-arenas-de-chefe.md) |
| ✅ | ~~**Um subchefe pode ser fugido de vez, ou reaparece?**~~ **FECHADO** — fugir recompõe no descanso; matar persiste no ciclo; Brasa/NG+ volta a colocá-lo com uma recompensa fixa por ciclo | [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §3 · `world.json` |
| ✅ | ~~**Como se sinaliza um precipício**~~ **RESOLVIDO 01-08** — faixa ≥ empurrão máximo + 0,5 m, padrão sem depender de cor, silhueta, movimento e som redundante | [`61`](spec/61-arenas-de-chefe.md) §5 |
| 🟠 | **As 12 fichas de arena depois de Vorgar** — 11 guardiões + Ultra; quais usam queda, obstáculos, SEPARAR/JUNTAR e prova em ambas as perspectivas | [`61`](spec/61-arenas-de-chefe.md) §7 |

### Volta 8 — sistemas

| | Lacuna | Origem |
|---|---|---|
| ✅ | ~~**A curva de nível era linear e chamava “XP”**~~ **CORRIGIDO** — custo cúbico em almas, com marcos 20/40/70/100 executáveis | [`72`](spec/72-materiais-consumiveis-e-economia.md) §2 · `860204f` |
| ✅ | ~~**Sistema de saves sem uma linha**~~ **RESOLVIDO 01-08** — formato campo a campo, morte sem save-scumming, escrita atómica, recuperação e migração, com código e testes | [`59`](spec/59-saves.md) · `game/src/autoload/save_system.gd` |
| ✅ | ~~**A migração de `sabedoria` não tinha algoritmo**~~ **FECHADO NO CONTRATO** — v2 move o valor para o eixo mágico da origem, repõe o outro na base e prova que não duplicou pontos; implementação entra com `appearance` | [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §7 |
| ✅ | ~~⚠️ **A leitura do mapa tinha de ser decidida antes do traçado**~~ **RESOLVIDO NO CONTRATO 01-08** — vista inclinada a ~40°, só terreno percorrido, andar actual realçado; a escolha zona/mundo continua dos donos sem bloquear a geometria | [`57`](spec/57-mapa-e-minimapa.md) §5 · [`69`](spec/69-catalogo-do-mundo.md) §1 |
| ⏳ | ⚠️ **[PROTO] O runtime de orientação implementa o mapa por zona em Brumal.** Isto permite construir e medir sem decidir a pergunta 38: se os donos escolherem mapa mundial, o bitset por zona continua válido e muda apenas o índice/agregador. Alternativa descartada: um bitset global provisório, porque misturaria escalas e tornaria a migração mais cara | [`57`](spec/57-mapa-e-minimapa.md) · pergunta 38 |
| 🟠 | **As opções de orientação ainda têm de chamar o cliente de mapa.** O runtime já expõe `set_minimap_enabled()` e `set_north_up()` e o aro funciona como bússola; a árvore `casca-do-jogo`, dona de `settings_system.gd`, deve ligar “minimapa desligado” e “norte em cima” sem duplicar estado aqui | [`57`](spec/57-mapa-e-minimapa.md) · integração entre worktrees |
| 🟠 | ⚠️ **A selecção visual da Fatia 1 já está integrada em `game/`; sons e conteúdo posterior continuam apenas em `art/`.** Biblioteca não é runtime: cada asset restante ainda precisa de importação deliberada, orçamento e prova no motor | [`22`](spec/22-assets.md), `game/assets/models/ASSETS.md` |
| 🟠 | ⚠️ **Ligar os produtores restantes ao `SaveSystem`.** Morte de inimigo → almas/inventário/baralho/recibo já é atómica; a exploração por zona do mapa também grava o bitset e os marcos descobertos com rollback. Restam HP zero → mancha, equipamento e UI quando esses clientes forem construídos. O toast já deixou de prometer falsamente que nada se perdeu | [`59`](spec/59-saves.md) · [`57`](spec/57-mapa-e-minimapa.md) · [`72`](spec/72-materiais-consumiveis-e-economia.md) |
| 🟠 | **Baús e feedback de espólio estão implementados mas a casca ainda não os monta.** `WorldChestManager.setup(world, player, hud, "brumal")` instancia os três baús desenhados, usa `interact`, grava abertura+conteúdo e mostra comparação; `present_enemy_reward(receipt, defeated.global_position, snapshot)` apresenta a carta comum contra o equipamento capturado antes da transacção. O dono de `game/src/main.gd` tem de guardar o gestor, chamar `setup` depois de mundo/jogador/HUD existirem e chamar `present_enemy_reward` no ramo `awarded`. Esta árvore não pode editar esse ficheiro; até essa ligação os contratos passam isolados, mas os baús não aparecem na cena jogável. | `game/src/world/chest_manager.gd` · `game/src/loot/loot_self_test.gd` · propriedade entre worktrees |
| ✅ | ⚠️ ~~**O catálogo de 120 armas não declara peso numérico e `InventorySystem` ignora a arma principal.**~~ **RESOLVIDO 01-08** — `weapons.json::_catalogo_runtime.weapons` dá `peso` explícito aos 120 IDs e `inventory_system.gd::load_profile()` passou a consumi-lo, conservando o fallback data-driven para famílias de escudo; nenhum peso foi duplicado em `.gd` | [`40`](spec/40-decisoes-espolio-magia-inventario.md) §9 · [`68`](spec/68-catalogo-de-armas-armaduras-e-aneis.md) · árvore `acesso-rapido` |
| 🔴 | ⚠️ **A quarta direcção ainda não existe nos dados:** `quick_slots.gd` procura a acção `next_item`, mas `controls.json` não a declara e `meditate` já ocupa o d-pad baixo/M. Por isso mão direita, mão esquerda e feitiço trocam sem menu; o item activo mostra `use_item`, mas não pode percorrer consumíveis. `[TENSÃO]` `[CODEX]` recomenda criar `next_item` no d-pad baixo e realojar meditação numa acção contextual de descanso, porque restitui as quatro direcções pedidas sem esconder função; alternativa: manter meditação global e escolher outro binding remapeável para `next_item`. Não decidido nem alterado nesta árvore. | `game/data/controls.json` · `game/src/player/player.gd` · pedido directo do Mateus |
| 🟠 | **O jogador ainda executa o selector de loadout de teste além da caixa:** `player.gd` consome `loadout_next/loadout_prev` e percorre `weapons.test_loadouts`, enquanto `QuickSlots` consome as mesmas acções depois e repõe o estado persistente da mochila. O resultado final é correcto, mas há duas autoridades no mesmo frame. O dono de `player.gd` deve remover/gatear `_cycle_loadout()` e delegar estas acções a `InventorySystem.cycle_quick_slot`; prova: uma pressão muda exactamente uma mão e não avança `_loadout_index`. | `game/src/player/player.gd` linhas das acções `loadout_*` · propriedade entre worktrees |
| 🔴 | **Seleccionar e usar um consumível recolhido ainda não fecha o circuito:** baús já entregam itens a `InventorySystem` e favoritar um consumível coloca-o em `inventory.quick_slots`, mas `player.gd` trata `use_item` sempre como Frasco de Bruma. Depois de resolver `next_item`, o dono do jogador/status deve pedir o item activo a `InventorySystem`, consumir uma unidade atomicamente e aplicar o efeito data-driven; o frasco conserva o caminho actual. | `game/src/player/player.gd::use_item` · `game/src/world/chest.gd` · integração fora dos ficheiros desta árvore |
| 🟠 | **Contagem de flechas está preparada mas sem autoridade de dados:** a caixa mostra munição quando a ficha de arma declara `ammo_item_key`; nenhuma arma nem `economy.json` declara hoje esse vínculo/stock. O dono dos dados deve criar IDs de munição, origem de stock e `ammo_item_key` nas armas à distância; sem isso a UI não inventa flechas. | `game/data/weapons.json` · `game/data/economy.json` · Lei 2 |
| 🟠 | **O kit inicial não declara um consumível comum além do frasco:** a normalização garante o recipiente Frasco de Bruma no inventário e a quantidade de usos continua a vir de `combat.json`, mas `weapons.json::loadouts` só declara armas/armadura. `[CODEX]` propõe acrescentar a cada loadout um mapa `starting_items` com IDs e quantidades em dados; razão: diferenças de origem ficam auditáveis e não viram números em `.gd`. Alternativa: um `starting_items` universal em `economy.json`. O dono dos dados tem de escolher o conteúdo/quantidade. | pedido directo do Mateus · `game/data/weapons.json::loadouts` · `game/data/economy.json` |
| 🟠 | ⚠️ **A acção `weapon_art` ainda não existe em `controls.json` nem é tratada por `player.gd`.** As 8 famílias já têm artes diferentes para uma e duas mãos, com mana e compromisso em `weapons.json`, e `WeaponProgression.perform_art()` prova cobrança/recusa; falta o dono dos controlos ligar uma tecla/remapeamento e o jogador emitir a `GameplayCue` devolvida | quatro perguntas do fio solto 1–3 · [`34`](spec/34-catalogo-e-comandos.md) |
| 🟠 | ⚠️ **`limalha_nobre` não existe em `economy.json`.** O altar usa a progressão `[DECIDIDO]` da spec — `limalha_ferro` em +1–+3 e `limalha_nobre` em +4–+6 — mas só o primeiro material tem definição económica. O dono da economia tem de criar fonte/stock/valor antes de activar +4; o UI bloqueia honestamente quando o inventário não declara a unidade | [`68`](spec/68-catalogo-de-armas-armaduras-e-aneis.md) · [`72`](spec/72-materiais-consumiveis-e-economia.md) |
| 🟠 | `[TENSÃO]` **O loadout do Paladino está rotulado como carga leve, mas o kit completo declarado soma 20,5/50 e cai em carga média:** armadura 12 + elmo 2 + escudo 5 + espada 1,5. `[CODEX]` recomenda corrigir o rótulo para média porque preserva os pesos agora explícitos e a Lei 3; alternativa: Mateus/Rico escolherem peças mais leves sem bloquear a espada. Não alterado nesta árvore porque seria decidir uma tensão e mexer em dados `[DECIDIDO]` de loadout | `weapons.json::loadouts.paladin` · [`51`](spec/51-familias.md) |
| 🟠 | ⭐ **Produção M2: construir `TuningRecorder`.** CSV, `tp arena_vorgar`, `latencia`, overlays e fixtures A/B já têm contrato; até existirem, os números dizem **baseline**, nunca “confirmado” | [`63`](spec/63-como-se-afinam-os-numeros.md) · [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §8 |
| 🟠 | **Produção WP11: construir o criador.** Ecrã/slots, `appearance.json`, nome, save v2/migração e matriz 6 origens × armas têm contrato e prova de saída | [`64`](spec/64-criacao-de-personagem.md) · [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §§7–8 |
| ✅ | ~~**As origens trocavam o corpo por personagens KayKit completos**~~ **RESOLVIDO 01-08** — masculino e feminino usam sempre o corpo Quaternius/UAL; a origem acrescenta por cima 2–6 peças procedurais presas aos ossos. A pré-visualização encontra o `class_id` no rascunho da casca sem alterar `game_shell.gd`. Sete assinaturas geométricas únicas foram vistas a 30 m; `lei4` na Iris Xe, Mobile/1080p sem VSync: 106,2 fps médios, p99 14,942 ms, 58 draws, quatro picos >20 ms. `[CODEX]` Razão: corpo humano vestido já, sem fingir compatibilidade entre rigs; alternativa descartada: KayKit completo como fato. | `game/src/visual/character_visual.gd` · decisão directa do Mateus, 01-08-2026 |
| 🟠 | **Faltam as malhas finais UAL das 11 peças e os dois conjuntos de voz.** O acervo não contém roupa modular compatível com os 65 ossos; peitorais, capas, botas, máscara e ombreiras são geometria simples honesta. O agente de armaduras deve substituir cada placeholder pelas peças finais através de `get_equipment_skeleton()`, `attach_equipment_to_bone()` e `clear_generated_origin_outfit()`, sem reinstanciar o corpo. | conteúdo exigido pelo [`64`](spec/64-criacao-de-personagem.md) · passagem para a árvore `armaduras` |
| 🟠 | **O `repro-inicio` ainda não guarda a regressão KayKit/Quaternius.** Esta árvore só possui `character_visual.gd`; o dono de `game/src/tests/repro_inicio.gd` deve chamar `CharacterVisual.outfit_contract_errors(GameShell.CLASS_IDS)` e, para cada origem/corpo, confirmar `uses_quaternius_body()` e que `get_body_source_path()` fica sob `characters/quaternius/`. O repro corrente abre e limpa os seis saves, mas não instancia/inspecciona cada visual. | pedido directo do Mateus, 01-08-2026 · integração entre worktrees |
| 🟠 | **A decisão “jogáveis são humanos adultos Quaternius vestidos” ainda não aparece no `DECISOES.md` desta worktree**, embora o prompt de execução diga que está no topo de 01-08. Integrar o registo da árvore que o possui antes do merge para a autoridade não ficar só no código/prompt. O perfil da 7.ª origem reserva o ID técnico `evil_mage`; a árvore que acrescenta a origem aos dados deve confirmar esse ID ou renomeá-lo no mesmo merge. `[CODEX]` Razão: deixar já uma silhueta coberta para a origem decidida; alternativa descartada: inventar a ficha de dados fora da árvore dona. | `DECISOES.md` desta worktree, verificado 01-08-2026 |
| 🟠 | **Produção WP12/15: fechar a arquitectura de áudio.** O runtime já separa `GameplayInfo`/`Impact`/`Ambience`/`Music`/`Voice`, envia-os para os cinco sliders existentes e faz ducking de música/ambiente durante cues informativos. Ainda faltam `audio_catalog.json`, `AudioDirector`/`MusicDirector`, reserva de 8 vozes e stress de 24 vozes | [`65`](spec/65-musica-e-ambiente.md) · `game/src/autoload/sfx.gd` · [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §8 |
| ✅ | ~~**Volumes separados ainda sem fronteira runtime**~~ **RESOLVIDO 01-08** — o menu já expunha Geral/Música/Efeitos/Ambiente/Vozes; `Sfx.volume_bus_contract()` expõe a árvore interna e cada som novo usa o pai correcto, sem alterar o menu | `game/src/autoload/sfx.gd` · [`20`](spec/20-interface.md) |
| 🟠 | **Produção/autoria: Brumal já tem vento, folhas, água, corvos raros e fogueiras 3D sintetizados; Toca, vozes e materiais próprios continuam em falta.** Até existir evento autoritativo de transição, a cama de Brumal acompanha a cena `Gameplay` também dentro da Toca — não se codificou a fronteira geométrica de outro agente no som. Música continua a zero. `[CODEX]` Razão: sem composição, estados e audição A/B, um drone não passa a prova de não mascarar combate. Alternativa descartada: alongar impactos ou empilhar senos para fingir uma faixa; o silêncio musical honesto cumpre o [`65`](spec/65-musica-e-ambiente.md) | [`65`](spec/65-musica-e-ambiente.md) · pergunta 34 |
| 🟠 | **Mochila: consumir os ícones das oito famílias.** Os SVG 32×32 e `WeaponFamilyIcons.texture_for(family_id)` já vivem em `game/assets/ui/`; `inventory_menu.gd` ainda só chama `ItemList.add_item(texto)` e pertence ao agente de UI, por isso esta árvore não o alterou | `game/assets/ui/weapon_family_icons.gd` · `game/src/ui/inventory_menu.gd` |
| 🟠 | **Documentação fora da árvore de som precisa de sincronização.** `ESTADO.md` §1/§1h ainda diz “17 sons”, “Master” e “zero loop”; `art/MANIFESTO.md` regista os oito PNG-fonte, mas não os oito derivados SVG de runtime. Esta árvore não lhes mexeu por pertencerem a outros agentes | `ESTADO.md` · `art/MANIFESTO.md` |
| 🔴 | ⚠️ **A arma visível e o feedback de impacto estão construídos e provados, mas `player.gd` ainda não os instancia/chama.** `WeaponVisual` resolve `handslot.r/l` e `hand_r/l`, acompanha o loadout e esconde o escudo decorativo do paladino; `HitFeedback` partilha o relógio da hitbox, reage, toca a superfície e mostra a origem do dano. A integração exacta está abaixo. Esta árvore não pode escrever em `player.gd` nem em `character_visual.gd` | `game/src/visual/weapon_visual.gd` · `game/src/combat/impact*.gd` · `game/src/combat/hit_feedback*.gd` |
| 🟠 | **A proveniência runtime ainda omite os quatro props KayKit usados pelos cinco IDs de `WeaponVisual`.** Os ficheiros e o `License.txt` CC0 já estão em `game/assets/models/enemies/kaykit-skeletons/props/`, mas o dono de `game/assets/models/ASSETS.md` deve acrescentar `Skeleton_Blade`, `Skeleton_Axe`, `Skeleton_Staff` e `Skeleton_Shield_Small_A` (a lâmina serve também a adaga por escala data-driven), sem copiar o pack inteiro | `game/assets/models/ASSETS.md` · `game/assets/models/enemies/kaykit-skeletons/License.txt` |
| 🟠 | **Inimigos/equipamento ainda não declaram `impact_surface`.** O renderer já tem assinaturas distintas para carne, metal e madeira, e os ramos autoritativos distinguem corpo/bloqueio/parry; porém um golpe normal em armadura metálica não pode ser classificado sem inventar pelo nome da classe/modelo. Acrescentar material de contacto às fichas antes de prometer som correcto em todos os 33 tipos | `enemies.json` · `armor.json` · `equipment.json` · `game/src/combat/hit_feedback_audio.gd` |
| 🟠 | **Mochila/equipamento: ligar os 11 ícones de armadura.** Os PNG RGBA 128×128 já vivem em `game/assets/ui/icons/armor/`, com fontes SVG arquivadas e IDs iguais às chaves de `armor.json`; o agente de UI tem de os passar ao `ItemList`/ecrã de equipamento. Esta árvore de imagens não alterou `game/src/` | `art/MANIFESTO.md` · `game/data/armor.json` · `game/src/ui/inventory_menu.gd` |
| 🟠 | **Documentação fora da árvore de som precisa de sincronização.** `ESTADO.md` §1/§1h ainda diz “17 sons”, “Master” e “zero loop”. O manifesto dos oito SVG de famílias já foi sincronizado pela árvore de imagens; `ESTADO.md` pertence a outro agente | `ESTADO.md` · `art/MANIFESTO.md` |
| 🟠 | **Lock-on em 1.ª pessoa** — duas opções propostas, nenhuma escolhida | [`29`](spec/29-perspectiva.md) |
| 🟠 | ⚠️ **Lock-on em 1.ª pessoa continua `[TENSÃO]`; não foi implementado.** `[CODEX]` recomenda a opção (a): lock rígido só em 3.ª pessoa e mira livre + indicador em 1.ª. **Razão:** conserva agência do olhar, evita a câmara arrastar o jogador e permite medir primeiro a referência de 3.ª pessoa já decidida. **Alternativa descartada por agora:** assistência suave (b), porque introduz força/limiar de assistência ainda sem decisão nem teste de enjoo; continua válida se os donos a escolherem | [`29`](spec/29-perspectiva.md) |
| 🟠 | **Integração da mira livre com `player.gd`:** a versão executável orienta o corpo e usa um alvo transitório apenas no frame de entrega, porque esta árvore não pode alterar `player.gd`. O dono do jogador deve expor `spell_origin`, `aim_direction/aim_point` e um sinal de compromisso da conjuração; depois `LockOn` deixa de consultar `state_frame`/`_cast_frames_total` privados. **Prova de saída:** Dardo e Ruína acertam o ponto mostrado depois da troca, sem alvo transitório nem acesso a membros privados | `game/src/player/lock_on.gd` · `game/src/player/player.gd` · [`55`](spec/55-formas-de-feitico.md) |
| 🔴 | ⚠️ **Lei 4 ainda não fecha para lock-on + cinco inimigos numa corrida concorrida.** Na Iris Xe, 1080p/Mobile, repetição sem VSync confirmou 5 activos + lock activo e deu **102,4 fps médios, p99 15,937 ms, 1% low 42,4, pior 61,30 ms e 0,8% dos frames >16,67 ms**; o controlo sem lock deu 135,5 fps/p99 15,696 ms. Uma corrida com VSync sob mais contenção deu 56,4 fps/p99 32,601 ms. Havia sete auto-testes headless de outras worktrees a consumir CPU, portanto os picos não podem ser atribuídos à mira nem usados para fechar 60 estáveis. Repetir em host limpo e guardar o JSON na árvore de medições; a sonda reproduz-se com `--aim-bench-enemies=5 --aim-bench-lock` | `game/src/player/lock_on.gd` · Lei 4 · medição local 01-08-2026 |
| ✅ | ~~**A cura à distância funciona com que latência?**~~ **FECHADO** — evento fiável/ordenado, `cast_id`, validação anfitriã e aplicação pelo dono no tempo de voo; nunca rebobina morte, >150 ms avisa | [`42`](spec/42-estudo-magia.md) · [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §1.1 |

### Caixa de acesso rápido — protocolo do [`31`](spec/31-referencias.md)

| | Eles | Nós antes desta árvore | Diferença / nossa versão |
|---|---|---|---|
| **Leitura simultânea** | O guia oficial de DS3 identifica no HUD equipamento da mão direita, mão esquerda, feitiço e item; os quatro permanecem legíveis durante exploração/combate ([guia oficial DS3, pp. 4–5](https://d1vtv52f4vjbmu.cloudfront.net/manuals/darksouls3/goty/ps4/DarkSouls3Goty_PS4_StarterGuide_GBQS.pdf)) | Não existia caixa; só textos separados de magia/equipamento e o inventário podia começar vazio | `[CODEX]` Caixa compacta em cruz no canto inferior esquerdo, sempre com quatro células: mão direita, mão esquerda, feitiço e item. Razão: conserva a leitura de estado sem abrir menu. Alternativa descartada: uma célula rotativa, porque esconderia três estados pedidos pelo Mateus |
| **Acção sem pausa** | No campo, d-pad cima percorre feitiços, baixo itens, esquerda arma esquerda e direita arma direita; usar item é uma acção separada ([manual web da FromSoftware](https://www.fromsoftware.jp/manual/darksouls3/win/operation.html), [tabela de controlos DS3](https://darksouls3.wikidot.com/controls)) | `next_spell` e `loadout_*` existiam, mas `[ ]` percorriam loadouts de teste inteiros; não havia `next_item` | A caixa lê sempre os bindings runtime de `controls.json` e nunca pausa. Três categorias já percorrem; a quarta continua bloqueada pela `[TENSÃO]` de `next_item` registada acima. Não se escreveu uma tecla física no código |
| **Quantidade** | O item seleccionado apresenta quantidade restante; munição é parte da leitura operacional de armas à distância no HUD ([guia oficial DS3, p. 5](https://d1vtv52f4vjbmu.cloudfront.net/manuals/darksouls3/goty/ps4/DarkSouls3Goty_PS4_StarterGuide_GBQS.pdf)) | O runtime sabia `flask_uses`, mas o frasco nem era um item de mochila; não havia contrato de munição | O Frasco de Bruma entra na mochila/caixa e mostra usos reais; consumíveis mostram stock; armas mostram munição quando `ammo_item_key` existir. A ausência actual de dados de flechas fica visível como lacuna, não como número inventado |
| **Identidade visual** | DS3 usa silhuetas imediatas e hierarquia discreta no canto, subordinadas à cena | Não havia arte nem superfície reservada | `[CODEX]` Silhuetas vetoriais sintetizadas em `quick_slots.gd`, fundo translúcido e cor por categoria; sem asset ou som novo. Razão: leitura barata e transparente no renderer Mobile. Alternativa testada e descartada: SVG das famílias no `CanvasItem`, que perdeu alpha no Mobile e virou um bloco branco |

**As quatro perguntas do fio solto:**

1. **Como usa?** Em jogo, sem abrir menu: `loadout_prev`, `loadout_next` e `next_spell` percorrem as categorias configuradas; `use_item` usa o activo. A direcção de percorrer itens espera a decisão de `next_item` acima.
2. **Como se prova?** `quick_slots_self_test.gd` parte de mochila/equipamento vazios e prova todas as seis origens, posse e equipamento dos kits declarados, Frasco de Bruma, quatro células preenchidas, acções vindas dos dados, ausência de pausa e que uma arma desequipada não volta sozinha: **52/52**. O agregador mantém **9703/9703**. Captura visual a 1920×1080 inspeccionada em `game/captures/01-spawn-3a-pessoa.png`.
3. **Arte/som?** Armas, escudo, frasco, feitiço e estados são geometria 2D sintetizada em `quick_slots.gd`; zero binários e zero som novo. A caixa reutiliza apenas os dados/nome do conteúdo activo.
4. **Quanto custa no Rico?** Iris Xe, Vulkan Mobile, 1920×1080, VSync off, aquecimento 8 s + amostra 30 s: **118,2 fps médios**, **8,46 ms médios**, **p99 14,684 ms**, 0,4% dos frames acima de 16,67 ms, 105 draw calls no benchmark e 136,1 MiB de VRAM. É medição da árvore completa, não A/B isolado da caixa.

### Golpe que se sente — protocolo do [`31`](spec/31-referencias.md)

| | Eles | Nós antes desta árvore | Diferença / nossa versão |
|---|---|---|---|
| **Contacto** | No estudo frame a frame de DS3, a fase activa rápida usa **2–4 frames**; o próprio estudo critica hitboxes várias vezes maiores que a arma porque quebram a leitura ([Game Developer](https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3)) | 3/6/8 frames de hit-stop já existiam nos dados, mas o acerto era uma consulta de cone sem apresentação no ponto tocado | `ImpactEvent` nasce no mesmo tick do dano e `ImpactEffect` vive só os frames activos restantes; o ponto vem da ponta da arma à superfície da cápsula. Não se copiou o inchaço da hitbox: prevalece o contrato ≤10% do [`38`](spec/38-ataques-e-honestidade.md) |
| **Reacção / confirmação** | DS3 organiza VFX por prioridade e conserva UI secundária; a análise pergunta explicitamente qual inimigo bateu, quanto dano e quanto stagger houve ([Game Developer](https://www.gamedeveloper.com/game-platforms/why-do-we-play-dark-souls-)). DS2, o chão aceitável, tem uma crítica pública antiga precisamente a golpes que parecem “pás”, apontando som e falta de sangue/faísca como causas ([GameFAQs](https://gamefaqs.gamespot.com/boards/693331-dark-souls-ii/70084339)) | Inimigo só mostrava dor ao partir postura; golpe normal tocava `hit_flesh`, tirava PV e congelava lógica, sem arma, pulso ou origem do dano recebido | `[CODEX]` Escolha: reacção `Hit_Chest` durante a paragem local, pulso mínimo no contacto, som carne/metal/madeira e seta de origem ao levar dano. Razão: dá peso, confirmação e causalidade sem esconder a próxima telegrafia. Alternativas descartadas: números flutuantes (tom `[EM ABERTO]`) e tremor global por golpe (ruído/enjoo, sem informação nova) |
| **Arma** | A arma visível e a pose do atacante são a primeira língua do alcance; o estudo de DS3 mede a fase pela animação da própria arma | O único `BoneAttachment3D` era `ClassProp`, exclusivo do escudo decorativo do paladino; nenhuma arma do loadout era instanciada | `WeaponVisual` usa os props CC0 já importados, encontra os dois rigs, mostra espada/adaga/machado/cajado/escudo e actualiza `[ ]`/equipamento no mesmo frame. Falta apenas o dono de `player.gd` instanciá-lo |
| **Fonte do golpe recebido** | A análise de clareza de DS3 exige que a derrota permita identificar qual inimigo acertou; em 1.ª pessoa esta informação não pode depender de visão periférica | O jogador mudava de PV/estado e ouvia um som plano; um atacante atrás não deixava direcção pós-contacto | `HitFeedbackIndicator` aponta para a posição real do atacante desde o frame do dano até acabar o hit-stun real; é reacção, não uma hitbox ou promessa de novo golpe |

**Integração exacta que falta em `player.gd` (não alterar `character_visual.gd`):**

1. Depois de `_visual.setup(...)`, criar `WeaponVisual.new()`, adicioná-lo ao jogador e chamar `setup(self, _visual)`; em `_build_children()`, chamar `HitFeedback.install(self)` e guardar a referência.
2. Em `_deal_damage_to()`, imediatamente depois de `e.call("take_damage", info)`, chamar `_hit_feedback.present_hit(self, e, info, "flesh")`. `ImpactEvent` lê `state_frame/_atk_*`, portanto a chamada fora do activo falha em vez de aproximar. Remover o `Sfx.play("hit_flesh", ...)` anterior para não duplicar som.
3. Em `take_damage()`, chamar o mesmo coordenador **apenas nos ramos que aceitaram contacto**: `"wood"` depois de bloqueio e `"flesh"` depois de perda real de PV, antes do retorno de hiper-armadura. Nunca chamar no retorno de i-frames; parry continua com a assinatura própria existente. Remover os dois SFX substituídos para não duplicar.
4. Acrescentar ao agregador alheio `self_test.gd` uma prova integrada: ataque real → dano e `last_impact_physics_frame` no mesmo tick; impor hit-stop durante `DODGE` → `state_frame` não avança. As sondas isoladas já passam **26/26 arma + 24/24 impacto**, mas a ligação real precisa desta regressão depois de o dono editar o chamador.

**As quatro perguntas do fio solto:**

1. **Como usa?** Ataque leve/pesado já mapeado (clique esquerdo / modificador + clique); não nasce tecla nova. A arma segue o loadout/equipamento que já existe.
2. **Como se prova?** `weapon_visual_self_test.gd` 26/26, `impact_self_test.gd` 24/24, capturas locais `weapon-visual.png` e `impact-autoritative-frame.png`; auto-teste global mantém **9703/9703**. Falta a prova integrada do ponto 4 acima.
3. **Arte/som?** Quatro props do KayKit Skeletons para cinco IDs visuais, **CC0**, já em `game/assets/models/`; carne/madeira reutilizam síntese existente e metal é sintetizado em `hit_feedback_audio.gd`. Zero binários novos e zero conteúdo de jogo comercial.
4. **Quanto custa no Rico?** A/B 1920×1080 Mobile na **Intel Iris Xe**, seis esqueletos (jogador + cinco atacantes), 12 s úteis ×2: feedback `on` deu **179,6–202,8 fps médios**, **1% low 75,1–92,3**, p99 **8,839–11,423 ms** e 0 frames >16,67 ms sem vsync. No frame com cinco pulsos: **+4 draw calls**, **+26 primitivas**, **+1,1 MiB RAM**, **+5,8 MiB VRAM**. Com vsync: 59,9 fps médios mas p99 **18,918 ms**, portanto a estabilidade de seis esqueletos continua a falhar — coerente com a lacuna de animação/FIFO já registada; não se declara 60 estáveis.

### Volta 9 — mundo

| | Lacuna | Origem |
|---|---|---|
| ✅ | ~~**Nadar, escalar, saltar: existem?**~~ **FECHADO** — sem verbos livres; passo automático ≤0,45 m e ligações verticais autoradas; “a saltar” é golpe terrestre | [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §2 · `world.json` |
| 🔴 | ⚠️ **Traçado e memória já têm um orçamento executável, mas o pior conjunto continua sem conteúdo para medir.** Tectos: 1 638 MiB para mundo/arte; 256 MiB por zona com Fojo+5 ou 512 MiB com actual+transição. A prova local mediu uma Brumal e uma cópia de assets partilhados, não seis biomas finais, e a máquina tinha 15,73 GiB; repetir no Rico mantém-se gate | [`ORCAMENTO`](game/src/world/zones/ORCAMENTO.md) · [`medição local`](game/src/world/zones/medicao-streaming-local.json) · [`43`](spec/43-estudo-espolio-inventario-mundo.md) §6 · [`69`](spec/69-catalogo-do-mundo.md) §2 · pergunta 50 |
| 🟠 | **A infraestrutura WP8 existe, mas o compositor ainda não a chama.** `streaming_manager.gd` faz I/O threaded, orçamento, confirmação do peer lento, retenção de fuga e descarga; `streaming_gate.gd` cria proximidade/bruma/colisão. Esta árvore não pode editar `main.gd`/`greybox.gd`: falta o dono integrar o registo de cenas e substituir a construção monolítica por `PackedScene` autorada ou construção incremental. A sonda mediu **113,004 ms** para publicar a segunda Brumal e recusou-a; as outras 11 zonas continuam sem cena | [`README`](game/src/world/zones/README.md) · [`medição`](game/src/world/zones/medicao-streaming-local.json) · [`69`](spec/69-catalogo-do-mundo.md) · [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §8 |
| 🟠 | **O adaptador de Brumal liberta a candidata, mas `greybox.gd` deixa 20 recursos pré-carregados vivos no fecho do processo.** A prova isolada do streaming termina sem aviso; com Brumal, depois da rejeição, a contagem regressa de 2 030 para 1 030 nós e de 209 para 109 recursos, mas `--verbose` ainda lista 20 `RefCounted` no encerramento — número que coincide com os assets pré-carregados pelo compositor monolítico. O dono do renderer deve confirmar a vida desses preloads quando separar Brumal em `PackedScene`; não se mascara o aviso no gestor | `game/src/world/greybox.gd` · `streaming_benchmark.gd --verbose` · [`medição`](game/src/world/zones/medicao-streaming-local.json) |
| 🟠 | **Integração da Toca modular espera o dono de `greybox.gd`.** `lair.gd` já constrói entrada, três salas, dois atalhos interiores e arena, com benchmark/capturas próprios; `greybox.gd` ainda chama a Toca provisória interna. Substituir essa chamada por uma instância de `Lair`, ligar os marcadores aos encontros/save e actualizar `game/assets/models/ASSETS.md`, sem manter as duas geometrias sobrepostas | [`lair.gd`](game/src/world/lair.gd) · restrição de ficheiros do trabalho paralelo (01-08) |
| 🟠 | **Brumal cresceu do greybox de 2–3/4–6 min para uma travessia catalogada de 8 min.** O nível actual tem de ganhar círculos horizontal/vertical, atalho por dentro, segundo descanso e densidade sem virar corredor; só fica confirmado depois de cinco corridas medidas em ambas as perspectivas | [`10`](spec/10-fatia-1.md) · [`53`](spec/53-chefes-ritmo-e-o-mago-forte.md) §3 · [`69`](spec/69-catalogo-do-mundo.md) §3.1 |
| 🟠 | **As 30 portas são malha estática e escrita, não conteúdo futuro construído.** Quando uma for promovida, precisa de novo `Fatia 1?`, orçamento, destino e revisão da promessa; hoje nenhuma entra na primeira fatia | [`69`](spec/69-catalogo-do-mundo.md) §4 |

---

## 🔵 Quando houver tempo

| | Lacuna | Origem |
|---|---|---|
| 🟠 | **`[CODEX]` O céu/luz novo está implementado e medido, mas ainda não entra no nível enquanto o dono de `greybox.gd` não o ligar.** Substituir a construção local de `WorldEnvironment`/`Sun` por `EnvironmentAtmosphere.build_world_environment(preset, palette, biome)` e `EnvironmentAtmosphere.build_sun(preset, biome)`. Razão: céu procedural com sol baixo, bruma por altura e gradação literal dos presets ficaram isolados nos ficheiros do agente do céu; alternativa descartada: editar `greybox.gd` nesta árvore e colidir com o agente de desempenho | `game/src/visual/environment_atmosphere.gd` · `game/src/visual/sky_atmosphere.gd` · `environment_atmosphere_probe.gd` |
| ✅ | ~~⚠️ **A conversão visual, passos 1–3**~~ **FEITA E MEDIDA 01-08** — paleta de luz/névoa vem da ficha do bioma; contraste, dessaturação e vinheta são graduados; Kenney/KayKit substituem chão, árvores, rochas e Toca com rugosidade. A primeira versão falhou a Lei 4 a 57,4 fps e foi optimizada até 60/60/60 | [`47`](spec/47-do-greybox-ao-visual.md) §4 · [`PERF`](game/PERF.md) |
| ✅ | ~~**Capturas em todo o marco**~~ **FEITAS 01-08** — seis pontos canónicos revistos depois de cada passo; os PNG finais ficam em `game/captures/` fora do git | [`47`](spec/47-do-greybox-ao-visual.md) §5 |
| 🔵 | **`MAPA.md` aponta para dois registos de sessão que não existem nesta worktree** — *(um registo de sessão privado, gitignored)* e *(um registo de sessão privado, gitignored)*; a guarda tem 0 erros novos de JSON/contratos, mas termina com estes 2 links partidos preexistentes | `node tools/check-coerencia.mjs` · 01-08 |
| 🔵 | **Os 11 documentos antigos não trazem tabela `eles·nós·diferença` nem citam fontes** | [`31`](spec/31-referencias.md) |
| 🔵 | **Economia de vendedores** — a loja vende conveniência, nunca poder | [`39`](spec/39-estudo-profundo.md) §11 |
| 🔵 | **Validar as constantes de física a jogar** (marco 2) | [`36`](spec/36-fisica.md) |

---

## ⏳ Dos donos — não são para os agentes resolverem

Estão no [`99-perguntas-abertas.md`](spec/99-perguntas-abertas.md). As que mais mudam o jogo:

| # | | |
|---|---|---|
| **32** | ⚠️ Matar um chefe no mundo do outro muda o teu próprio mundo? | proposta: vitória/recompensa viaja; mundo e atalhos não |
| **28** | ⚠️ Se a magia faz tudo, como é que o mago não é a classe correcta? | cinco travões propostos |
| **24** | Chefe a dois: +40% de vida ou zero? | proposta: +40%, e desce quando um morre |
| **37** | O Mateus confirma o Assassino do catálogo? | proposta completa no `68`, sem fingir aprovação |
| **38** | Mapa por zona ou do mundo inteiro; mostra nomes não visitados? | proposta: por zona, nomes só depois de vistos |
| **39** | Os vendedores morrem e o stock pode desaparecer? | proposta: sem morte acidental; consequência só explícita |
| **40** | O Coveiro fecha acesso por origem/classe? | proposta: qualquer origem depois de descobrir a Escola vermelha |
| **41** | `[TENSÃO]` Melhorias de feitiço: três eixos ou Lei 2? | recomendação: escolhas com perda/verbo; runtime fica no nível 0 |
| **43** | `[TENSÃO]` Afinidade elemental por família ou instância de escudo? | recomendação: instância; fallback mágico fica 0 até resposta |
| **44** | `[TENSÃO]` ~30 ou 68 armaduras? | recomendação: produzir só 11 e consolidar futuras por escolha real |
| **45** | Compromisso das habilidades e semântica do Eco | baseline/recomendação: repete compromisso/tempo e conserva custos não-mana |
| **46** | Física de projécteis e formas de entrega | baseline M2 escrito; donos confirmam antes de produção larga |
| **47–48** | Categoria de acessórios e afinidade dos anéis | acessórios fantasma removidos; recomendação: afinidade nunca faz gating |
| **49** | Parâmetros ambientais | baselines escritos; uma família por spike e lista vazia como gate da zona |
| **50–51** | Streaming e orçamento global de actores | proposta: actual + transição; oito actores incluindo invocados |
| **52** | Identidade de onze guardiões e doze subchefes | 23 slots bloqueados, sem IDs de inimigo fingidos; conteúdo é dos donos |
| **53** | Percepção, retorno e cura dos inimigos | baseline 2 m/regresso/cura total escrito; donos confirmam antes do runtime M2 |
| **54–55** | Habilidades de armadura e alcance dos sistemas de anel | futuros bloqueados/clientes fechados; donos só decidem expandir capacidades |
| **56** | Slots, força e velocidade de instrumentos futuros | só cajado 1,0 existe; recomendação: spike sino/talismã antes de reabrir IDs |

E as **7 perguntas de narrativa** ([`26`](spec/26-narrativa.md) §3), que precisam de uma gravação — **o nome do jogo incluído**.

---

---

---

## 📦 Os packs CC0 — o que entrou e o que ficou de fora

**01-08.** Os dez packs entraram no repositório (PR #19), com uma limpeza feita no merge.

| | |
|---|---|
| Descarregado pelo Fable | **571 MB** · 6511 ficheiros |
| ⭐ **Removido no merge** | **~120 MB** · 3213 ficheiros — os formatos `.fbx` `.obj` `.mtl` `.stl` `.dae` que **o Godot não lê** |
| **Ficou no merge** | **~452 MiB** · 3298 ficheiros; o working tree corrente tem 3310 ficheiros / **466,1 MiB** depois dos ícones posteriores |
| ⚠️ **Preservados de propósito** | **5** ficheiros `.obj` do pack de masmorra que **não têm equivalente** em `.gltf` — peças soltas (tampa de baú, porta) |

⭐ **Porque é que não se perdeu nada:** o `.glb`/`.gltf` é o **mais completo** dos formatos — carrega malha, materiais, esqueleto e animações. O `.obj` não tem esqueleto nem animação; o `.stl` só tem a malha. **Os apagados eram versões com menos informação do que a que ficou.**

| | Lacuna | |
|---|---|---|
| 🔵 | ⚠️ **411 MB dos 460 são texturas PNG** — algumas acima do orçamento de 1024–2048 do [`30`](spec/30-qualidade-visual.md). **Reduzi-las é a próxima poupança grande**, e ao contrário dos formatos duplicados **isto mexe na qualidade** — decisão dos donos | [`30`](spec/30-qualidade-visual.md) |
| 🔵 | **Se algum dia se reescrever o histórico por outra razão**, aproveitar para tirar o resto | — |

---

## 🔬 Da auditoria de comparação com DS2/DS3 (01-08)

[`docs/AUDITORIA-CODEX-COMPARACAO-2026-08-01.md`](docs/AUDITORIA-CODEX-COMPARACAO-2026-08-01.md). ⚠️ **A primeira é um erro de conta meu, já corrigido.**

| | Achado | Origem |
|---|---|---|
| ✅ | ~~*"do 70 ao 100 custa 3× tudo o que gastaste do 1 ao 70"*~~ **ERRO MEU, CORRIGIDO** — somei só o termo cúbico e ignorei `3,06N²` e `105,6N`, que pesam mais nos níveis baixos. **A conta certa é 1,92×** (680 663 contra 1 308 518). Refiz-a e confirma | [`58`](spec/58-fim-do-jogo-ciclos-e-a-curva.md) §2 |
| ✅ | ~~⭐ **Meditação infinita + artes a gastar “energia” revogada**~~ **RESOLVIDO 01-08** — 2 tentativas por descanso, consumidas ao sentar; 40 s/100% preservados por serem decisão dos donos; interrupção guarda o parcial; artes gastam mana | [`66`](spec/66-catalogo-de-magia.md) §3 · runtime testado |
| ✅ | ~~⭐ **Uma mão / duas mãos não tinha comando nem estado**~~ **RESOLVIDO NA TAREFA 4** — `T`/`Y`, estado próprio de 12 f interrompível, offhand recolhido e arte seleccionada pela empunhadura | [`70`](spec/70-fecho-dos-sistemas-de-combate.md) §2 · 9531 testes correntes |
| ✅ | ~~⭐ **8 favoritos mudáveis a qualquer momento**~~ **RESOLVIDO NO CONTRATO 01-08** — só mudam fora de combate/no descanso; a UI que aplica a regra está registada acima como construção em falta | [`66`](spec/66-catalogo-de-magia.md) §3 |
| ✅ | ~~⚠️ **Parry com 4 frames de arranque**~~ **CORRIGIDO** — baseline executável **8/8/40**, falha total 56 f | [`70`](spec/70-fecho-dos-sistemas-de-combate.md) §1 |
| ✅ | ~~⚠️ **Soft cap de 40 em tudo**~~ **CORRIGIDO** — Vida 20/50 · Stamina 20/40 · Constituição 25/50 · mana 35 · dano 40/60 · Carga 30/50/70 | [`70`](spec/70-fecho-dos-sistemas-de-combate.md) §1 |
| ✅ | ~~**Queda fatal aos 25 m**~~ **CORRIGIDO** — zero até 5 m, progressiva abaixo de 20 m, fatal absoluta aos 20 m | [`70`](spec/70-fecho-dos-sistemas-de-combate.md) §1 · `progression.json` |
| ✅ | ~~⚠️ **Faltava sobrecarga (>100%)**~~ **RESOLVIDO** — sem esquiva/corrida/sprint; marcha 3 m/s e regen 26/s | [`70`](spec/70-fecho-dos-sistemas-de-combate.md) §1.1 |
| ✅ | ~~**NG+ somava vida e dano por igual**~~ **CORRIGIDO** — +30% PV/+15% dano, depois +5%/+3% até +7 | [`70`](spec/70-fecho-dos-sistemas-de-combate.md) §1 |
| ✅ | ~~**Contra-ataque +30% universal**~~ **CORRIGIDO** — só perfuração: ×1,30; haste ×1,40; só estocada da katana ×1,45 | [`70`](spec/70-fecho-dos-sistemas-de-combate.md) §3 |
| ✅ | ~~⭐ **Contra-ataque e instável estavam misturados**~~ **SEPARADOS** — instável ×1,25 só nas quatro fontes declaradas | [`70`](spec/70-fecho-dos-sistemas-de-combate.md) §3 |
| ✅ | ~~⭐ **Ressalto não tinha contrato**~~ **ESCRITO** — parede/deflexão/corpo duro, primeira colisão e 12–18 f; varredura geométrica continua M2 | [`70`](spec/70-fecho-dos-sistemas-de-combate.md) §3 |
| ✅ | ~~**O piso corporal estava aplicado a escudos**~~ **SEPARADO** — seleccionados chegam a 100% físico; estabilidade continua ≤85 | [`70`](spec/70-fecho-dos-sistemas-de-combate.md) §3 |
| ✅ | ~~**Carga média perdia 10% de regeneração**~~ **CORRIGIDO** — leve/média 40/s; pesada 31/s | [`70`](spec/70-fecho-dos-sistemas-de-combate.md) §1.1 |

### ⭐ Gramática de combate que nos falta (secção 4 da auditoria)

Vocabulário de situações que o DS tem e a nossa spec **não menciona em lado nenhum**:

| | |
|---|---|
| ✅ | ~~**Ataques inimigos que atravessam escudo**~~ — `sea_orc_hookbearer/hook_pull`, 40% |
| ✅ | ~~**Esmagamento de guarda dedicado**~~ — `orc_brute/slam`, custo ×2,5 |
| ✅ | ~~⭐ **Mesmo aviso, dois tempos de largada**~~ — `vorgar/overhead_crush`, f56/f72 com segundo sinal |
| ✅ | ~~**Ramos condicionais de combo**~~ — `orc_spearman/double_thrust`, distância/ângulo, nunca input |
| ✅ | ~~⭐ **Falsa recuperação**~~ — `skeleton_swordsman/bone_rattle`, pose diferente e extensão legível |
| ✅ | ~~⭐ **Castigo de cura**~~ — `orc_spearman/closing_lunge`, estado visível + LOS + 9 f |
| ✅ | ~~**Fingir morte e atacar ao levantar**~~ — `ancient_skeleton/black_cut`, colocação determinística |

### ⭐ Inteligência entre golpes — protocolo do [`31`](spec/31-referencias.md)

| Situação | Eles | Nós antes desta árvore | Diferença / nossa versão |
|---|---|---|---|
| **Neutro e deslocação (DS2)** | Uma observação publicada dos primeiros encontros descreve inimigos que se aproximam, **circulam durante alguns segundos** e só depois avançam com golpe telegrafado ([Ars Technica](https://arstechnica.com/gaming/2014/03/learning-how-to-die-in-dark-souls-ii/)) | `_tick_chase()` só encarava, avançava em linha até `preferred_distance` e travava; não existia espera, órbita nem recuo táctico | `EnemyCombatBrain` escolhe `approach/orbit/withdraw/wait` por distância, vaga e estado visível; `EnemyCrowdSteering.tactical_velocity()` materializa a intenção com `chase_speed/strafe_speed` dos dados. Diferença não intencional: faltava o neutro que faz um duelo respirar |
| **Compromisso e oportunidade (DS3)** | A análise frame a frame separa pose, sinal, activo, pose final e regresso; o regresso é explicitamente a janela de oportunidade do adversário ([Game Developer](https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3)) | As fichas já tinham as cinco fases, mas a escolha do inimigo vinha de um padrão aleatório sem observar se o jogador se tinha comprometido | A nossa IA aumenta a prioridade quando vê `ataque/conjuração/meditação/parry/troca`, nunca quando recebe a tecla. Diferença não intencional e agora resolvida no módulo: os dados tinham compromisso, a decisão não o usava |
| **Contra-jogo ao círculo (DS3)** | A análise crítica nota que inimigos de DS3 ganharam respostas específicas ao *circle strafing* e cadeias mais longas, embora também critique quando a resposta ultrapassa as opções do jogador ([Game Developer](https://www.gamedeveloper.com/design/the-successes-and-failures-of-dark-souls-3-s-design)) | Parar em frente ao alvo tornava costas/flanco gratuitos; deixar todos perseguir só criava um novelo | Órbitas alternam lado deterministicamente e os não-atacantes fecham ângulos sem activar hitbox. Não copiamos cadeias agressivas: prevalecem aviso ≥0,50 s, compromisso e fuga legível do [`38`](spec/38-ataques-e-honestidade.md) |
| **Cura** | As fontes públicas não demonstram uma regra universal e justa de “ler Estus”; por isso não se promove a impressão de jogadores a mecanismo canónico. O padrão verificável é mais geral: acções comprometidas abrem oportunidade | O [`70`](spec/70-fecho-dos-sistemas-de-combate.md) já decidiu uma excepção concreta: `closing_lunge` reage a `USING_ITEM` **visível**, LOS e 9 f; `enemy.gd` ainda não a executa | `[CODEX]` Ataques com `heal_punish` declarado avançam após a latência; todos os restantes recuam perante `a beber`. Razão: conserva a excepção decidida sem dar leitura omnisciente a 33 tipos. Alternativa descartada: toda a IA atacar no frame da tecla |
| **Múltiplos (DS3)** | A orientação oficial descreve emboscadas de vários inimigos como algo que pode exigir recuar para uma passagem e fazê-los chegar um a um; não oferece uma garantia universal de turnos ([Xbox Wire](https://news.xbox.com/en-us/2016/04/19/the-three-cs-of-multiplayer-of-dark-souls-iii/)) | O coordenador bloqueava dois activos no mesmo frame e previa hit-stun, mas começava pelo relógio estimado; os telegraphs podiam formar fila e não se media saída geométrica | A nossa versão é deliberadamente mais explícita que a referência: transição real `can_act` → 0,20 s, duas intenções simultâneas e abertura angular ≥100°. Se a abertura fecha, a intenção é recusada e o inimigo continua a pressionar sem atacar |
| **Legibilidade** | A clareza de DS3 nasce da silhueta de abertura, do arco visível e de uma recuperação reconhecível; ataques sem regras visuais quebram a justiça ([Game Developer](https://www.gamedeveloper.com/design/the-design-lessons-designers-fail-to-learn-from-dark-souls)) | Só `ATTACK/STAGGER/BROKEN` mudavam cor/animação; alerta, chamada, regresso, cura, espera e recuo eram invisíveis porque nem existiam | Cada decisão nova devolve `readable_cue` estável (`alert_posture`, `call_shout`, `guarded_hold`, `side_on_steps`, `weapon_lowered_return`, `home_heal_pulse`). O módulo cumpre o contrato; falta o dono visual/runtime apresentar esses IDs com os renderers sintetizados existentes |

⚠️ **`[TENSÃO]` de formulação, não decidida aqui:** o pedido actual diz “recua quando bebes”, enquanto o [`70`](spec/70-fecho-dos-sistemas-de-combate.md) já fecha um castigo de cura para o lanceiro. **Proposta e recomendação `[CODEX]`:** a solução híbrida acima — recuo por omissão, avanço só na ficha declarada. Razão: obedece às duas intenções sem alterar `[DECIDIDO]`; alternativa válida para os donos: retirar `CASTIGO_CURA` numa decisão nova e fazer todos recuarem.

#### As quatro perguntas do fio solto

1. **Como usa o jogador?** Não há tecla nova: andar, atacar, conjurar, aparar e beber já são as acções. A IA responde ao estado/animação que qualquer jogador também vê.
2. **Como se prova?** `enemy_ai_self_test.gd` cobre 31 decisões observáveis; `enemy_crowd_probe.tscn` cobre cinco corpos reais e a janela activa; o auto-teste agregado passou **9703/9703** em 01-08-2026. A integração final precisa ainda de uma prova jogada: oito encontros em 1.ª/3.ª pessoa, sem morte cuja causa não se consiga nomear.
3. **Arte e som?** Zero binários novos. O cérebro emite IDs; alerta/chamada/ataque/regresso reutilizam `EnemyVisual`, `GameplayCue` e SFX sintetizado. Até o dono os ligar, não se afirma que a leitura está no ecrã.
4. **Custo no Rico?** Benchmark reproduzível em `enemy_ai_benchmark.tscn`, 8 inimigos, Mobile/1080p. A corrida final gráfica feita com sete auto-testes alheios concorrentes deu sem VSync **226,1 fps**, média **4,423 ms**, p99 **9,059 ms**, pior **13,098 ms**, 78 draws e 79,2 MiB VRAM; uma corrida FIFO anterior deu **60,0 fps**, p99 **18,506 ms**, pior **19,540 ms**. A folga bruta passa, mas estes números ficam marcados **contaminados** até repetição em host limpo; não fecham a lacuna global de FIFO.

#### Ligação que falta ao dono de `enemy.gd`

1. Instanciar `EnemyPerception`, substituir `aggro_range → CHASE` pelo resultado de alerta/chamada/combate/regresso/cura e enviar `call_recipients()` aos aliados elegíveis.
2. Passar `target.state_name()` e LOS a `EnemyCombatBrain.decide()`; pedir/libertar intenção no `EnemyAttackCoordinator`, incluindo as posições de todos os corpos de pressão; aplicar `tactical_velocity()` antes da separação corporal.
3. Expor a capacidade real de agir do alvo e chamar `update_target_actionability()` em cada transição. `record_hitstun()` continua compatível, mas é previsão e não fecha sozinho o requisito de “quando pode agir”.
4. Apresentar cada `readable_cue` fora do cérebro. Cancelar uma intenção antes do activo tem de chamar `release_attack_intent()` para não prender a vaga.

### E os sistemas deles que o Codex diz para **não** copiar

Atributo que controla i-frames *(viola a nossa Lei 1)* · durabilidade *(só gera viagens ao descanso)* · invasões, pactos e sinais de invocação *(resolvem emparelhamento público — nós somos dois)* · penalização de vida máxima por morrer *(espiral de fracasso)*.

⭐ **E disse que o nosso mapa é melhor do que não ter mapa**, para dois amigos. Fica.

---

| ✅ | ~~⭐ **A semente fixa do acaso**~~ **RESOLVIDO 01-08** — greybox, escolha de padrões e ordem do baralho aceitam semente; 42 repete e 43 diverge no auto-teste | [`60`](spec/60-o-agente-que-joga.md) §2 · [`67`](spec/67-catalogo-do-bestiario.md) §5 |

---

## ⭐ Queda e limite do mundo — implementação `[CODEX]` (01-08)

### Eles / nós / diferença

| | Dark Souls | Queda e Morte |
|---|---|---|
| Faixas | **DS1:** até 5 unidades não causa dano; acima de 5 até 20 causa dano; acima de 20 mata. O dano sobrevivível é percentagem da vida máxima, aumenta com a carga e ignora defesa. Há ainda `kill boxes` separadas em abismos/fora do mapa. [Fonte](https://darksouls.wikidot.com/fall-damage) | **0–5 m:** zero; **>5 e <20 m:** curva híbrida fixa + percentagem da vida máxima; **≥20 m:** morte absoluta. Os valores e nós da curva vivem em `game/data/progression.json`; a defesa não reduz queda e a carga multiplica o dano até ×1,40. |
| Variação útil | **DS2:** dano sobrevivível plano, não percentagem de PV; carga aumenta-o, equipamento pode reduzi-lo, mas existe um corte fatal absoluto que ignora redução. [Fonte](https://darksouls2.wikidot.com/falling-damage) | A parte fixa impede que subir Vida apague a queda; a parte proporcional conserva a decisão do Mateus de Vida continuar relevante antes dos 20 m. |
| Protecção | **DS3:** Spook/Anel do Gato anulam quedas não fatais, nunca tornam sobrevivível uma queda letal. [Fonte](https://darksouls3.wikidot.com/falling) | A topologia fatal também não depende de vida, carga ou equipamento. O gancho de redução já existe na fórmula de dados, mas nenhum anel implementado declara ainda esse valor executável. |
| Diferença deliberada | DS1 aceita caixas de morte que podem não corresponder à altura realmente percorrida. | O vazio exterior usa a mesma medição física desde o ponto mais alto da queda; não há teletransporte nem `kill box` silenciosa. A inclusão exacta difere em 20 m: nós matamos já em **20,0 m**, como manda o `spec/70`. |

`[CODEX]` **Limite escolhido: queda e morte, não parede invisível.** Razão: o chão e a colisão terminam juntos, a imagem diz a verdade e a consequência usa uma regra que o jogador pode aprender em qualquer queda. Alternativa descartada: parede invisível com sinalização; impediria o bloqueio, mas mostraria precipício aberto enquanto a colisão dizia “parede”, contra a cláusula de honestidade do `spec/38`. Ao chegar a 20 m desde o último apoio, `Player` emite o mesmo `died` que `main.gd` já liga a `SaveSystem.commit_death`: larga as almas e regressa à última fogueira depois do fade normal. Não há reposicionamento especial da queda. O gancho seguro da mancha está pronto; falta o consumidor fora desta árvore indicado abaixo.

### As quatro perguntas do fio solto

1. **Como usa o jogador:** anda/corre/esquiva com as acções remapeáveis já existentes e pode atravessar a orla; não foi inventada uma tecla de “cair”. A última célula de 4 m avisa passivamente com padrão partido âmbar, estacas, folhas a correr para fora e vento 3D. A arena de afinação fica excluída.
2. **Como se prova:** `game/src/world/bounds_self_test.gd` prova as três faixas e simula a gravidade a 60 Hz. O probe opt-in `--bounds-player-probe` criou um `Player` isolado fora do chão, deixou correr `move_and_slide()` e recebeu `Player.died` em **1,417 s**, antes do prazo **1,481 s**; não está ligado ao `main`, portanto não escreve save. O auto-teste geral continua em **9703/9703**.
3. **De onde vêm arte e som:** nenhuma descarga nova. Faixa, estacas e folhas são primitivas/shader/partículas sintetizadas em `bounds_warning.gd`; o vento direccional reutiliza `amb_wind`, já sintetizado por `procedural_audio.gd` e carregado pelo `Sfx`.
4. **Quanto custa no Rico:** Iris Xe, Mobile/Vulkan, 1080p, zona completa, 5 s de aquecimento + 15 s: variante final **130,1 fps**, p99 **11,413 ms**, 51 draws, 273 306 primitivas e 123,2 MB VRAM. Contra o probe desligado são **+5 draws, +2 864 primitivas e +0,1 MB VRAM**. Os controlos `off` deram 72,2–83,3 fps/p99 32,992–33,681 ms enquanto sete Godot de outros agentes estavam órfãos a consumir CPU; por isso não se atribui um delta de FPS falso. A variante entregue passa 60 fps com margem, mas a sessão não isola um custo causal fino.

| | Lacuna | Origem |
|---|---|---|
| 🔴 | **O dono de `game/src/tests/self_test.gd` ainda tem de incorporar `BoundsSelfTest.run_suite()` e somar cada `failures` ao contador central.** Esta árvore não pode escrever nesse ficheiro. Até isso acontecer, a regressão corre separadamente com `godot --headless --audio-driver Dummy --path game --script res://src/world/bounds_self_test.gd`, e a física real com `--bench --scene=zone --bounds-player-probe`, mas ainda não impedem um merge que só execute `scenes/selftest.tscn`. | pedido directo do Mateus · ownership paralelo |
| 🔴 | **O dono do ciclo de almas tem de gravar `player.death_stain_position`, não `player.global_position`, em `_on_player_died`.** O `Player` já conserva o último apoio para uma queda fatal; o `main.gd` actual continua a passar a posição no vazio a `SaveSystem.commit_death`, o que criaria uma mancha irrecuperável. Não foi alterado aqui porque `main.gd` e fogueiras pertencem a outro agente. | `game/src/main.gd::_on_player_died` · ownership paralelo |
| 🟠 | **Uma redução de dano de queda por anel ainda não tem fonte executável.** `GameData.fall_damage()` aceita o parâmetro, mas `equipment.json` só tem descrições editoriais relacionadas com queda. Não transformar prosa em número sem ficha/decisão. | `game/data/equipment.json` · `GameData.fall_damage()` |

---

## 🕳️ Buracos de sistema — coisas que NUNCA foram escritas

**Varrimento de 01-08.** Não são detalhes por afinar: são sistemas inteiros que a spec assume e nunca definiu. Ordenados por quanto custa descobri-los tarde.

| | Buraco | Porque dói tarde |
|---|---|---|
| ✅ | ~~⭐ **Sistema de saves**~~ **ESCRITO E IMPLEMENTADO 01-08** — dois domínios, escrita atómica, backup, checksum, recuperação e migrações | [`59`](spec/59-saves.md) · 19 auto-testes novos |
| ✅ | ~~⭐ **Packs CC0 por descarregar**~~ **RESOLVIDO 01-08** — modelos e 182 OGG estão em `art/`; integração no jogo continua nas linhas próprias abaixo/acima | [`CREDITS`](CREDITS.md), [`22`](spec/22-assets.md), [`65`](spec/65-musica-e-ambiente.md) |
| ✅ | ~~⚠️ **O `.gitignore` e o `game/CLAUDE.md` contradiziam-se sobre binários**~~ **RESOLVIDO** — os packs CC0 entram deliberadamente no repositório; `game/CLAUDE.md` já distingue builds ignoradas de assets versionados | `953589c` |
| ✅ | ~~⭐ **Os orcs eram variantes nuas do corpo-base humano**~~ **RESOLVIDO 01-08** — `Orc_Small`, `Orc` e `Orc_Skull` do Ultimate Monsters substituem lanceiro, brutamontes e Vorgar. Só 2,8 MiB/3 GLTF entraram; o `License.txt` interno declara CC0 e fica junto das fontes. A floresta recebeu ainda seis famílias Kenney em MultiMesh, sem importar o pack inteiro | [`CREDITS`](CREDITS.md) · [`ASSETS`](game/assets/models/ASSETS.md) · [`PERF`](game/PERF.md) |
| 🔴 | **O runtime deixou `monster_visual.gd` órfão e continua a mostrar os orcs-sapo.** O commit de identidade inimiga posterior trocou `Enemy` para `game/src/enemies/enemy_visual.gd`; por isso a correção de arte, escala e pés preparada no renderer atribuído a `arte-dos-inimigos` não aparece na arena até o dono dessa fronteira mudar o preload para `res://src/visual/monster_visual.gd`. A nova classe aceita já a assinatura de cinco argumentos. Não alterado aqui porque `enemy.gd`/`enemy_visual.gd` pertencem a outro agente | integração entre `game/src/enemies/enemy.gd` e [`monster_visual.gd`](game/src/visual/monster_visual.gd) |
| 🟠 | **Falta um pack final de orcs que cumpra a barra visual.** O inventário inteiro só traz Ultimate Monsters (olhos redondos, sorriso, proporções de mascote); KayKit traz esqueletos e Kenney traz zombies/vampiros ainda mais estilizados. A correção por código cobre a cara, estreita os corpos, escurece materiais e dá armadura/arma legível, mas continua low-poly. Pack exacto em falta: licença CC0/redistribuível no ficheiro, orcs humanoides sem olhos exagerados, 8–15 mil tri por personagem, texturas 1–2K, três silhuetas armadas e rig retargetável à UAL | [`30`](spec/30-qualidade-visual.md) · [`CREDITS`](CREDITS.md) |
| 🟠 | **A fotografia `05-arena-vorgar` fabrica uma escala enganadora.** Coloca um inimigo quase encostado à câmara e os restantes no fundo; a perspectiva faz um parecer gigante e outro minúsculo embora as alturas declaradas sejam 1,90/2,30/3,00 m. A visita deve enquadrar os três a profundidade comparável ou incluir uma vista ortográfica de auditoria; `photo_tour.gd` está fora da árvore deste agente | `game/src/tools/photo_tour.gd` · `game/captures/05-arena-vorgar.png` |
| ✅ | ~~⭐ **A animação de esqueleto estava por medir**~~ **MEDIDA NA IRIS XE E NO NÍVEL** — UAL Standard, Mobile/Vulkan, 1920×1080: 5 e 10 actores deram ambos 60,0 fps médios; p95 17,773/16,666 ms, pior 20,619/18,539 ms. A prova `lei4` com 2 jogadores + 3 inimigos importados manteve média, mínimo e 1% low de 60,0 durante 30 s; os picos sem vsync ficam documentados, não escondidos | [`PERF`](game/PERF.md) · [`animacao-esqueleto-2026-08-01.json`](medicoes/animacao-esqueleto-2026-08-01.json) · [`44`](spec/44-prototipo.md) |
| 🔵 | **120 MB dos 410 são formatos que o Godot não usa** — `.fbx`, `.obj`, `.mtl`, `.stl`, `.dae`, duplicados do `.glb` que já lá está. Entraram porque a decisão foi *"tudo no repositório"*, e limpar depois obriga a reescrever a história. *Se algum dia se reescrever o histórico por outra razão, aproveita-se* | fase 1.2, 01-08 |
| ⏳ | ~~⭐ **Onde vivem os modelos CC0: no repositório ou em `_local/`?**~~ ✅ **DECIDIDO 01-08 pelo Rico** — no repositório, com o custo à vista. A estimativa preliminar foi 410 MB/6451 ficheiros; a medição final do import e da limpeza está na tabela acima. *(registo do que era:)* O [`22`](spec/22-assets.md) diz que CC0 *pode* entrar, mas ninguém pesou o tamanho nem o facto de o git nunca esquecer. **É decisão dos donos** porque é praticamente irreversível: 1 pack Kenney ≈ 2–10 MB, mas o conjunto de personagens+animações+natureza+dungeon anda pelas **centenas de MB**, e um `git clone` passa a custar isso a toda a gente, para sempre. *Proposta: `art/models/` no repo só para o que o jogo carrega mesmo (poucos MB, optimizado), e os packs crus em `_local/`* | encontrado 01-08 |
| ✅ | ~~⭐ **Desenho de arena de chefe**~~ **ESCRITO 01-08** — 13 arenas seladas, bolsas abertas para subchefes, bordo legível, nevoeiro/carregamento e espaço desenhado para dois | [`61`](spec/61-arenas-de-chefe.md) |
| ✅ | ~~O fim do jogo~~ **ESCRITO 01-08** — escolha final que **os dois têm de concordar**; estrutura fixada, conteúdo depende das 7 perguntas de narrativa | [`58`](spec/58-fim-do-jogo-ciclos-e-a-curva.md) |
| ✅ | ~~Ciclo novo (NG+)~~ **FECHADO 01-08** — ciclo 2: PV ×1,30/dano ×1,15; ciclos 3–7: +5% PV/+3% dano, com tecto no ciclo 7. A **Brasa** sobe uma zona sem recomeçar o jogo | [`70`](spec/70-fecho-dos-sistemas-de-combate.md) §1 · `progression.json` |
| ✅ | ~~**Criação de personagem**~~ **ESCRITO 01-08** — seis presets sem caminhos fechados, aspecto finito, voz independente, nome seguro, revisão e save atómico | [`64`](spec/64-criacao-de-personagem.md) |
| ✅ | ~~⭐ **Quem afina os números**~~ **ESCRITO 01-08** — inventário, ordem causal, papéis, passos máximos, A/B, diagnóstico e critério para congelar sem transformar partidas em finais | [`63`](spec/63-como-se-afinam-os-numeros.md) |
| ✅ | ~~⚠️ **Desligar a meio de um chefe**~~ **RESOLVIDO 01-08** — sem progresso parcial; commit autoritativo em HP zero; recibo persistente e idempotente para a queda depois da morte | [`59`](spec/59-saves.md) §8 |
| 🔵 | **Medir p95 da escrita com o mapa completo na máquina do Rico** — a fixture actual tem guarda < 64 KiB; o orçamento cheio é 2 MiB e ainda não existe conteúdo para o medir | [`59`](spec/59-saves.md) §10 |
| ✅ | ~~**Música e ambiente**~~ **ESCRITO 01-08** — inventário real, mapa de uso, estados/transições, camadas, buses, ducking e prova; produção em falta fica vermelha acima | [`65`](spec/65-musica-e-ambiente.md) |
| ✅ | ~~⭐ **Acessibilidade auditiva**~~ **ESCRITA 01-08** — cada tipo de som informativo tem equivalente próprio de forma/direcção/timing; sem legendas genéricas e com ficha de ataque alterada já | [`62`](spec/62-acessibilidade-auditiva.md) |
| ✅ | ~~**Onde vivem os textos**~~ — `strings.<locale>.json` por ID estável; HUD/toasts já consomem português e IDs obrigatórios falham o teste | [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §4 · `strings.pt.json` |
| ✅ | ~~**Comando / gamepad**~~ — todas as acções nucleares, incluindo câmara, têm teclado/rato + botão/eixo, construídos do mesmo catálogo; conforto/deadzone esperam comando físico no M2 | [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §5 · 9531 testes correntes |
| ⏳ | **Os vendedores morrem?** — não decidido pelo agente; morte pode destruir stock e é irreversível | pergunta 39 dos donos |
| ✅ | ~~**Voz: Godot faz nativamente?**~~ — captura/microfone sim; Opus/AEC/jitter/transporte completos exigem integração e possível GDExtension nativa, com spike/licença no WP14 | [`56`](spec/56-voz-e-vendedores.md) · [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §6 |

### ⚠️ E três que são de coerência, não de conteúdo

| | Buraco | |
|---|---|---|
| ✅ | ~~⭐ **A fatia 1 foi aprovada antes de ~40 decisões**~~ **RESOLVIDO NA TAREFA 4** — o `10` e os WP2–WP11 (`11`–`20`) preservam o texto histórico, mas abrem agora com aviso e apontam às autoridades/dados actuais | [`10`](spec/10-fatia-1.md) · [`11`](spec/11-formulas.md)–[`20`](spec/20-interface.md) |
| ✅ | ~~**Os ~36 "nomeados" que substituíram os chefes de campo**~~ **RESOLVIDO NA TAREFA 4** — 36 fichas, exactamente 3 por zona, com tipo-base, localização, multiplicadores curtos, um ataque extra e carta garantida | [`71`](spec/71-encontros-nomeados.md) |
| ⏳ | **O Assassino** — proposta completa escrita e testada; **falta o Mateus confirmar** Passo Mudo, Corte Alternado, Cruz Carmesim e Entre Sombras | [`68`](spec/68-catalogo-de-armas-armaduras-e-aneis.md) §5 · pergunta 37 |

---

## ✅ Fechadas

| Lacuna | Fechada em |
|---|---|
| ~~O código vive fora do repositório~~ | PR #13 |
| ~~A medição 0b não tem artefacto~~ | PR #12 *(metade — falta a animação de esqueleto)* |
| ~~Arcos, bestas e escudos sem mecânica~~ | [`48`](spec/48-arcos-bestas-escudos.md) |
| ~~6 zonas contra 10+ biomas~~ | PR #14 — **12 biomas** |
| ~~Quantos chefes ao todo~~ | PR #14 — **61, derivado do mapa** |
| ~~O parry tem dois botões~~ | [`45`](spec/45-controlos-configuraveis.md) — controlos configuráveis |
| ~~Sem sistema de interrupção~~ | [`39`](spec/39-estudo-profundo.md) §4 · [`41`](spec/41-estudo-armas-e-golpes.md) §4 *(escrito; falta implementar)* |
| ~~Espólio sem garantia~~ | [`43`](spec/43-estudo-espolio-inventario-mundo.md) §2 — o baralho de 10 |
| ~~WP6 sem catálogo executável~~ | [`67`](spec/67-catalogo-do-bestiario.md) — 33 tipos, 100 ataques comuns, 33 baralhos e 12 orçamentos |
| ~~Ataques dependiam de áudio~~ | [`67`](spec/67-catalogo-do-bestiario.md) §7 — `GameplayCue` apresenta som e visual equivalentes |

---

## ⚔️ Artes de arma e movesets — fronteiras para os outros donos (01-08-2026)

`weapon_art_system.gd` fecha a fronteira pura: recebe `GameData.weapons`, `GameData.equipment`, arma, melhoria, empunhadura, recursos e estado; devolve arte/moveset e uma sessão comprometida. O teste dedicado percorre as 119 armas principais: **848 passaram, 0 falharam**, **31,275 µs p95/resolução**, catálogo **17 487 B**. Nada abaixo foi alterado nesta árvore.

| Estado | Trabalho fora da posse desta árvore | Contrato já pronto |
|---|---|---|
| 🔴 | **Controlos/UI:** declarar a acção remapeável `weapon_art` em `controls.json`/`project.godot`, mostrar o comando no ecrã de controlos e consumir o estado de mana. Não ligar uma tecla física directamente. | `_artes.input_action = weapon_art`; `begin(...)` recusa sem mana e conserva stamina |
| 🔴 | **Player:** em `LIVRE`, resolver `is_two_handed`, chamar `begin(...)`, conservar `session.locked` até `completed`/`interrupted` e avançar frames de simulação. Não permitir esquiva/troca/item/cancelamento enquanto a sessão está presa. | `begin`, `advance`, `request_cancel`, `try_interrupt`; o efeito emite exactamente uma vez em `effect_emitted_this_step` |
| 🟠 | **Armas/melhorias:** `weapon_progression.gd` ainda contém a fronteira anterior `weapon_art()`/`perform_art()`, que cobra mana mas não declara compromisso, curva, fuga, som ou duas fases. O dono desse ficheiro deve delegar artes/movesets em `WeaponArtSystem` para não haver duas autoridades. | `WeaponArtSystem.art_for()` e `moveset_for()` já consomem `_weapon_improvements` base + seis |
| 🔴 | **Animação de jogador:** criar/retargetar os clips de 1.ª e 3.ª pessoa para os IDs `moveset/<familia>/<one_hand|two_hands>`, e ligar `momento_compromisso_frame`, activos e recuperação. Não editar `character_visual.gd` nesta árvore. | 8 famílias × 2 empunhaduras; nove movimentos comuns + arte atribuída por arma |
| 🔴 | **GameplayCue/Sfx/acessibilidade:** encaminhar `som_anuncio.cue_id/perfil/alcance_m/inicio_frame` e `sinal_visual_equivalente` sem substituir o som por legenda genérica. | cada uma das 16 combinações família/empunhadura declara som, forma, âncora, início, compromisso, fim e fora de ecrã |
| 🟠 | **Rede:** o anfitrião valida arma/empunhadura/mana e replica início; o evento autoritativo de efeito nasce uma vez no frame de compromisso. Input tardio não pode voltar a apontar a arte. | `effect_committed`, `effect_emissions`, `effect_emitted_this_step`; estado puro e serializável |
| 🟠 | **Auto-teste central:** o dono de `game/src/tests/self_test.gd` deve incorporar esta regressão ou acrescentar o script dedicado ao gate de CI. Até lá, os 848 casos correm separadamente e os 9703 globais não os contam. | `godot --headless --audio-driver Dummy --path game/ --script res://src/weapons/weapon_art_selftest.gd` |
| 🟠 | **Índices de spec:** `SPEC.md` ainda não lista `spec/75-artes-de-arma-e-movesets.md` e `99-perguntas-abertas.md` não referencia a tensão 70 armas pedidas versus 120 fichas decididas. O agente de coerência deve ligá-los; não se alteraram ficheiros fora da posse. | `node tools/check-coerencia.mjs` reporta exactamente esses dois pontos; os três links partidos antigos em `MAPA.md` são também alheios |
| 🟠 | **Lei 4 integrada:** este pacote não muda render e só mediu catálogo/estado. Quando os clips finais existirem, medir 2 jogadores + 3 inimigos, Iris Xe/8 GB, 1080p60, com apenas família/artes equipadas residentes. | tecto conservador medido/projetado em `spec/75`: 48,4 MiB para 70 armas por família+artes contra 175,9 MiB para 70 conjuntos únicos |

`[TENSÃO]` **O pedido directo fala em 70 armas/movesets; o catálogo `[DECIDIDO]` tem 120 fichas (119 armas com família + escudo).** Não se cortou nenhuma. `[CODEX]` recomenda moveset por família e arte atribuída por arma, partilhável e com poucas excepções; razão: reduz pelo menos 72,5% dos clips sem reduzir identidades jogáveis. Alternativa descartada nesta proposta: produzir todos os conjuntos únicos desde a Fatia 1; se Mateus mantiver essa escolha, fasear uma arma vertical por família e autorizar as seguintes só depois de medir produção/feel.

# Casca do jogo — decisões de implementação a rever

- `[CODEX]` **Pausa solo/co-op (01-08-2026):** a implementação pausa a árvore do mundo em solo e mantém o mundo a correr em co-op, com o estado escrito no próprio ecrã. Razão: o pedido actual do Mateus distingue explicitamente os dois modos e uma sessão de rede não pode congelar o parceiro. Alternativa descartada: nunca pausar, como recomenda a camada histórica de `spec/20-interface.md`; conserva um único hábito, mas deixa o pedido de pausa sem efeito no único modo onde parar é tecnicamente honesto. Se Mateus e Rico preferirem a regra histórica, mudar `GameShell.pause_world_for_mode()` para devolver sempre `false` é a única fronteira funcional.

---

## 🏟️ Arena do Vorgar — comparação, implementação e coordenação (01-08-2026)

### Protocolo do `31`: eles · nós · diferença

| Foco | Eles — dados observáveis em DS2/DS3 | Nós antes desta árvore | Diferença e nossa resposta |
|---|---|---|---|
| **Entrada e fecho** | As portas de nevoeiro de chefe são de sentido único e ficam intransponíveis até à vitória; em co-op delimitam quem pode entrar. [DS2 bosses](https://darksouls2.wikidot.com/bosses/noredirect/true) · [fog gates](https://darksouls.wikidot.com/fog-gate) | Plano aberto, sem limiar, compromisso ou fecho visível | `arena_vorgar.tscn` tem vão real, nevoeiro, colisão coincidente, patamar de 4 m e sinais `threshold_entered/exited`. O controlador co-op chama `set_gate_closed()`; a cena não inventa a sincronização |
| **Forma segue o alcance** | Uma perseguição circular usa uma pista inteira e alcovas largas para sobreviver à passagem; uma criatura que investe usa um espaço comprido; uma arena pequena com ataques largos torna o bordo o verdadeiro inimigo. [Executioner's Chariot](https://darksouls2.wikidot.com/bosses%3Aexecutioner-s-chariot) · [Old Iron King](https://darksouls2.wikidot.com/bosses%3Aold-iron-king) | O modo `combat` era chão verde sem arquitetura; a Toca antiga reservava apenas o mínimo histórico de 20 × 16 m | `[CODEX]` **24 × 22 m**, alvo normal do `61`, com centro contínuo e 4,75 m livres em cada flanco. Razão: conserva 16 m entre marcas SEPARAR e duas fugas ≥3 m. Alternativa descartada: 20 × 16 m passa o mínimo, mas aperta dois jogadores + chefe + volume persistente |
| **Cobertura que dá e tira** | A pista circular tem alcovas de largura para dois; outra sala tem exactamente duas balistas que transformam a linha do chefe em oportunidade co-op; colunas defendem de uma família, mas não de tudo. [Executioner's Chariot](https://darksouls2.wikidot.com/bosses%3Aexecutioner-s-chariot) · [The Pursuer](https://darksouls2.wikidot.com/bosses%3Athe-pursuer) · [Dancer arena analysis](https://www.school-xyz.com/blog/kak-ustroen-dizayn-bossa-tancovshchica-holodnoy-doliny-iz-dark-souls-iii) | Nenhum obstáculo funcional no plano verde | Dois pilares KayKit visíveis um do outro criam refúgios temporários. `set_cover_broken(left/right, true)` troca malha por ruína e desliga a colisão; a contagem de choques continua nos dados/agente do Vorgar, nunca neste `.gd` |
| **Leitura e mudança do chão** | Uma transição de fase pode partir o piso inteiro e levar a uma segunda geometria; o bom contraponto encosta detrito às margens para não prender câmara/pés. [Curse-rotted Greatwood](https://darksouls3.wikidot.com/bosses%3Acurse-rotted-greatwood) · [Dancer arena analysis](https://www.school-xyz.com/blog/kak-ustroen-dizayn-bossa-tancovshchica-holodnoy-doliny-iz-dark-souls-iii) | Verde uniforme até ao horizonte; o fim do chão não se via | Trinta lajes KayKit, oito incrustações partidas nos flancos, anel de pedra embutido para JUNTAR, centro sem detrito, ruína só nas margens, paredes de 4 m e portão norte legível. Não há queda letal nesta arena, como manda a ficha do Vorgar |

**A nossa versão não copia nenhuma planta ou conteúdo:** adopta apenas os padrões “compromisso visível”, “forma ao serviço do alcance”, “refúgio com contra-resposta” e “chão que anuncia a regra”.

### As quatro perguntas do fio solto

1. **Como usa o jogador:** caminha para o patamar; o `Area3D` reconhece corpos do grupo `player` e emite entrada/saída. Quando o controlador confirma os dois carregados, abre o vão com `set_gate_closed(false)`; o fecho atrás usa a mesma fronteira. As marcas do chão dão dois destinos SEPARAR e um centro JUNTAR sem texto nem tecla nova.
2. **Como se prova:** `godot --headless --audio-driver Dummy --path game/ scenes/arena_vorgar.tscn -- --arena-audit` deu **23/23**; inclui dimensão, limiar, flancos, separação, distância ao chefe, dois refúgios, nevoeiro/colisão, limite, sinais reais do patamar, abertura/fecho e troca independente de pilar/ruína. Seis capturas canónicas foram vistas em `user://arena-vorgar-captures/`.
3. **Arte e som:** arquitetura usa a selecção runtime CC0 do **KayKit Dungeon 1.1** já presente em `game/assets/models/dungeon/`; nevoeiro e incrustações são sintetizados em GDScript; o vento de pedra da pré-visualização é PCM sintetizado em código. **Nenhum binário novo.** ⚠️ Os 76 Kenney Castle existem em `art/`, mas nenhum está importado no runtime e esta árvore não possui `game/assets/`; copiar um `.glb` violaria a posse desta tarefa. Se for preciso misturar os dois kits, o dono de assets deve importar só as peças escolhidas e registar a proveniência.
4. **Quanto custa na máquina do Rico:** Iris Xe, 1920×1080, Mobile/Vulkan. Cena final isolada em posição de combate: sem VSync **205,8 fps**, 4,86 ms médios, p95 6,185 ms, p99 8,032 ms, pior 10,09 ms, 19 draws, 8 239 primitivas, 40,8 MiB VRAM e **zero** frames >16,67 ms; com FIFO: **60,0 fps médios/mínimo/1% low**, p95/p99 16,666 ms e também **zero** frames >16,67 ms em 30 s.

### Diagnóstico dos “34 fps” antes de acrescentar

- **Não se reproduziu 34 fps sustentado.** A arena verde deu **182,5 fps médios**, p99 8,033 ms, 19 draws e 11 720 primitivas.
- O pior caso `vorgar` corrente deu **128,3 fps médios**, mas um pior frame de 34,17 ms (**29,3 fps**) e p99 19,641 ms. Havia sete auto-testes Godot antigos ainda vivos e vários trabalhos de agentes; não foram terminados porque pertencem a outras árvores.
- A primeira sonda da arena nova mediu erradamente através do nevoeiro em ecrã inteiro: 127,9 fps/p99 25,201 ms. Mover a sonda para dentro e tirar três senos por píxel do nevoeiro subiu para 145,1 fps/p99 17,576 ms sob carga concorrente; a repetição final limpa chegou aos **205,8 fps/p99 8,032 ms** acima. Portanto geometria não era o estrangulamento; apresentação transparente e concorrência explicavam os picos.

### Para o agente `vorgar` e os donos dos ficheiros de integração

| Estado | Trabalho que não pertence a esta árvore | Fronteira pronta |
|---|---|---|
| 🔵 | Instanciar `res://scenes/arena_vorgar.tscn` no lugar da arena embutida em `greybox.gd`/`lair.gd` e usar os marcadores para posicionar corpos | `marker_position(entry/partner_entry/boss/separate_left/separate_right/join/refuge_left/refuge_right)` |
| 🔵 | Ligar prontidão/carregamento co-op e o fecho atrás dos dois; a cena não decide rede | sinais `threshold_entered/exited` · `set_gate_closed(bool)` |
| 🔵 | Depois de a ficha de ataques declarar SEPARAR/JUNTAR, apontar as sequências aos marcadores; **não há número de ataque nesta arena** | marcas a 16 m · centro comum limpo · duas rotas de 4,75 m |
| 🔵 | Contar nos dados os choques da investida e partir o pilar no evento anunciado | `set_cover_broken(&"left"/ &"right", bool)`; malhas intacta/ruína pré-feitas, zero rigid bodies |
| 🔵 | Medir **a cena integrada** com 2 jogadores + Vorgar + 2 orcs depois da ligação; a posse impediu alterar `main.gd`/`greybox.gd` nesta árvore | baseline corrente acima; gate final continua 1080p/60, p99 ≤16,67 ms |
| 🔵 | `game/src/tests/repro_inicio.gd.uid` apareceu durante `--import`; não pertence à arena e fica intocado/não incluído no commit | dono de `repro_inicio.gd` decide se versiona ou remove o UID gerado |

---

## ⚔️ Arma na mão, famílias e encadeamento — entrega desta árvore (01-08-2026)

### Protocolo do `31`: eles · nós · diferença

| Foco | Eles — dados observáveis em DS2/DS3 | Nós antes desta árvore | Diferença e resposta preparada |
|---|---|---|---|
| **Segundo golpe da corrente** | Em DS2, o exemplo da família Axe muda de diagonal no primeiro leve para vertical no segundo; a própria referência avisa que a sequência varia por arma ([DS2 Move Set](https://darksouls2.wikidot.com/move-set)). Em DS3, a espada recta muda o sentido entre o primeiro e o segundo R1 ([DS3 Move Sets](https://darksouls3.wikidot.com/move-sets-template)) | `_combo_index` já avançava e o dano final podia mudar, mas `_refresh_animation()` pedia sempre `Sword_Attack`: a corrente era numericamente diferente e visualmente igual | `AttackAnimationController` declara `leve_1` e `leve_2` para as oito famílias e gera curvas opostas de tronco/braços. O teste compara as rotações reais, não o nome ou a velocidade. Diferença restante: falta o dono instanciar o componente no `Player` |
| **Pesado** | As tabelas dos dois jogos separam a sequência pesada da leve por arma, não apenas por velocidade | O runtime distinguia frames/MV, mas apresentava o mesmo `Sword_Attack` | Cada família tem `pesado` próprio. O machadão carregável fica congelado no último quadro do aviso e só retoma o arco quando a hitbox também pode avançar |
| **Corrida** | DS2 separa Run-Light, Roll-Light e Backstep/Run-Light; DS3 declara Dashing/Backstep R1 fora da cadeia parada ([DS2 melee guide](https://www.gamerguides.com/dark-souls-2/guide/beginners-guide/combat-101/exploring-your-melee-moveset)) | Não havia golpe em corrida; atacar fazia `_tick_attack()` travar a velocidade, e a animação continuava `Sword_Attack` | As oito famílias usam a base locomotora real `Sprint` da UAL e um arco superior próprio — não é o leve acelerado. **Falta ao dono de `player.gd` materializar o avanço declarado em `weapons.json::golpes_universais.em_corrida`; sem isso a apresentação existe, mas o verbo espacial ainda não está completo** |
| **Honestidade do contacto** | A arma e a pose são a leitura do alcance; a nossa cláusula do [`38`](spec/38-ataques-e-honestidade.md) é a autoridade, mesmo quando é mais estrita que a referência | A consulta de dano já usava `state_frame > startup && <= startup + active`, mas o clip genérico não respeitava esses limites | A curva ofensiva tem chaves exactamente em `startup` e `startup + active`, sempre vindas da ficha equipada. A pose é procurada pelo `state_frame` autoritativo, não pelo FPS do render. Carga prolonga apenas o aviso. **Efeito e hitbox coincidiram quadro a quadro em todas as 14 fichas executáveis** |

`[CODEX]` **Curvas sintetizadas sobre o rig UAL.** A biblioteca importada traz 42 clips, mas só `Sword_Attack`, `Punch_Jab` e `Punch_Cross` são golpes corpo-a-corpo; não traz golpes próprios de adaga, machado, katana, haste, cajado ou arco. Foram preservados esqueleto, clips-base e locomação CC0 e sintetizadas 32 assinaturas de pose (8 famílias × leve 1/leve 2/pesado/corrida). Razão: uma família tem de mudar a silhueta e o arco. Alternativa descartada: repetir `Sword_Attack` com outra velocidade, porque falharia a queixa do Mateus e o teste de rotações.

`[CODEX]` **Resolver o prop por família quando o ID exacto não tem modelo.** Razão: as espadas novas e a katana já entravam no ciclo de loadout, mas o mapa antigo só conhecia cinco IDs e fazia-as desaparecer. `WeaponAttach` usa lâmina/machado/cajado/besta/escudo KayKit já importados, reduz a adaga pela proporção de alcance dos dados e troca a instância no mesmo quadro. Alternativa descartada: manter uma lista fechada de IDs, porque cada nova arma voltaria a ficar invisível. Katana→lâmina e haste→cajado são proxies visíveis temporários, não se afirmam como arte final.

### As quatro perguntas do fio solto

1. **Como usa o jogador:** os comandos já existentes são suficientes: ataque leve em rato esquerdo/RB-R1; pesado segurando Shift/RT-R2 ao atacar; corrida segurando Espaço/A-cruz enquanto se move e atacando; `[`/`]` ou d-pad muda o loadout. `WeaponAttach` observa `main_weapon`, `offhand_weapon` e `is_two_handed`, portanto a malha acompanha a troca sem tecla nova. **Até o dono fazer a ligação abaixo, estas acções continuam a usar a apresentação antiga no jogo integrado.**
2. **Como se prova:** `attack_family_self_test.gd` passa **186/186**: oito famílias presentes, 32 recursos com curvas distintas, base UAL existente, corrente diferente, corrida com locomação, fronteiras exactas, carga honesta e arbitragem contra o `Sword_Attack` genérico. `weapon_attach_self_test.gd` passa **42/42** sobre a ordem inteira de `test_loadouts`, mão direita/esquerda, troca no mesmo quadro, duas mãos e ponta da arma. As capturas reproduzíveis `attack_animation_capture.gd` e `weapon_attach_benchmark.gd` foram vistas a 1080p; o agregado continua a exigir a integração alheia indicada abaixo.
3. **De onde vêm arte e som:** props de arma são KayKit Skeletons CC0 já em `game/assets/models/enemies/kaykit-skeletons/props/`; corpo/esqueleto/clips-base são Quaternius Universal Animation Library CC0 já importados. As curvas adicionais são sintetizadas em GDScript, sem binário novo. O som continua a usar `swing_light`/`swing_heavy` sintetizado já chamado pelo `Player`; não foi inventado nem copiado som comercial.
4. **Quanto custa na máquina do Rico:** Intel Iris Xe, Mobile/Vulkan, 1920×1080, sem VSync, 3 s de aquecimento + 10 s. Um corpo: base **291,4 fps / 3,432 ms**, p95 5,408 ms, p99 10,705 ms; espada+escudo **245,0 fps / 4,081 ms**, p95 7,201 ms, p99 10,259 ms. Custo observado: **+0,649 ms médios, +2 draws, +957 primitivas e +4,0 MiB VRAM**; p99 fica abaixo de 16,67 ms. Stress de cinco corpos armados deu 184,3 fps numa passagem e 93,8 fps noutra enquanto um render de outro agente estava activo; não se usa essa variação como delta causal.

### Ligações que pertencem a outros donos

| Estado | Trabalho fora desta árvore | Fronteira pronta |
|---|---|---|
| 🔴 | **O dono de `game/src/player/player.gd` tem de instanciar os dois componentes depois de `_visual.setup()`.** Criar `WeaponAttach.new()` e `AttackAnimationController.new()`, adicioná-los ao `Player` e chamar `setup(self, _visual)`. Não é preciso alterar `_refresh_animation()`: o controlador já vence a chamada genérica e sincroniza pelo `state_frame` | `game/src/visual/weapon_attach.gd` · `game/src/player/attack_animation_controller.gd` |
| 🔴 | **O golpe em corrida ainda precisa de mecânica espacial.** Capturar que o ataque começou em sprint e consumir `golpes_universais.em_corrida.avanco_m`/a ficha familiar durante o golpe; hoje `_tick_attack()` trava o corpo. Não pôr esse número em `.gd` | `game/src/player/player.gd::_start_attack/_tick_attack` · `game/data/weapons.json` |
| 🔴 | **O dono de `game/src/tests/self_test.gd` tem de incorporar o contrato de famílias no agregado.** Enquanto isso, a regressão que falha quando uma família omite animações corre isolada com `--script res://src/player/attack_family_self_test.gd`; o teste central não pode ainda impedir esse merge | `game/src/player/attack_family_self_test.gd` · ownership paralelo |
| 🟠 | **Arco exacto existe no pack cru, mas não nos assets importados.** Importar selectivamente `bow_withString.gltf` de KayKit Adventurers para `game/assets/` e registar a proveniência. Até lá `arco` fica deliberadamente sem prop em vez de mentir com uma besta. Katana e haste também pedem modelos finais próprios | `art/models/kaykit-adventurers/` · dono de assets/`ASSETS.md` |
| 🟠 | **O som ainda só distingue leve/pesado, não família.** Se a identidade sonora por família for exigida, o dono de áudio/dados deve declarar os cues e o dono do `Player` consumi-los; não derivar pelo nome da arma nem hardcodar ficheiros | `game/src/player/player.gd` · catálogo de áudio/dados |
| 🟠 | **A captura revela roupa procedural negra e blocos de botas/ombro que escondem parte da silhueta.** Não vem dos componentes de arma/golpe e não foi alterado porque `character_visual.gd` pertence a outro agente | `game/src/visual/character_visual.gd` |
| 🟠 | **A guarda de coerência geral termina com dois links partidos anteriores a esta árvore.** Os alvos *(um registo de sessão privado, gitignored)* e *(um registo de sessão privado, gitignored)* não existem. Os 19 JSON/2797 contratos passam; o dono do mapa deve corrigir ou retirar os dois links | `MAPA.md` · `node tools/check-coerencia.mjs` |
## 🌲 Exploração de Brumal — comparação, implementação e coordenação (01-08-2026)

### Protocolo do `31`: eles · nós · diferença

| Foco | Eles — dados observáveis em DS1/DS3 | Nós antes desta árvore | Diferença e nossa resposta |
|---|---|---|---|
| **O caminho dobra e regressa** | Em DS1, a escada derrubada por dentro liga a ponte à fogueira anterior; a muralha curva deixa depois olhar para baixo e reconhecer o percurso feito. É a relação espacial, não um mapa abstrato, que faz Undead Burg/Parish parecer um sítio. [Análise da verticalidade de Undead Burg](https://www.pcgamesn.com/dark-souls-remastered/undead-burg-level-design-verticality) | Brumal tinha uma linha de sete pontos por cerca de 200 m e dois pequenos desvios sem consequência; correr sempre para a frente resolvia a zona | `ExplorationBrumal` dobra **2 398,7 m** da rota segura dentro dos mesmos 220 × 220 m, separa duas rotas em `(-75, 0)` e volta a juntá-las em `(-67, -84)`. A rota arriscada totaliza **1 439,5 m**: é um corte real, não uma esquerda/direita cosmética |
| **Atalho aberto por dentro** | DS3 é mais linear à escala do mundo, mas os níveis locais voltam à base: Cathedral of the Deep usa uma fogueira de preparação e regressa a ela por escada, elevadores e portas abertas do interior; Grand Archives empilha vários atalhos na mesma progressão. [Análise estrutural de DS3](https://jphanderson.wordpress.com/2016/07/30/dark-souls-3-script/) | `world.json` prometia o Portão da Árvore e o save já tinha `shortcuts_open`, mas não existia portão, interação nem persistência ligada | `ExplorationShortcut` é uma grade física com trinco orientado. Do exterior, a ação explica que o trinco está do outro lado; apenas posição interior + ação `interact` a abre. Não consulta nível, chave, inventário ou menu. Aberto, o percurso Árvore → Orla mede **200,9 m / 40,18 s** à velocidade dos dados |
| **O horizonte promete um destino** | DS1 usa vistas que mais tarde se tornam chão percorrido; DS3 mostra várias áreas antes de as explorar e conserva marcos que orientam a progressão. [DS1](https://www.pcgamesn.com/dark-souls-remastered/undead-burg-level-design-verticality) · [DS3](https://jphanderson.wordpress.com/2016/07/30/dark-souls-3-script/) | Os três marcos estavam descritos nos dados, mas a linha do greybox não os transformava em destinos de rota | O módulo ancora Arco, Farol e Árvore junto de troços alcançáveis; o auto-teste prova que cada marco fica a ≤16 m de uma rota. As formas atuais são volumes de greybox sintetizados, não arte final |
| **Desvio visível, risco e pagamento físico** | Em Undead Burg, itens e escadas chamam a atenção para caminhos futuros; objetos guardados, iscos e passagens parcialmente tapadas fazem o jogador ler a geometria antes de receber a recompensa. [Análise de Undead Burg](https://slickaria.blog/2020/09/30/analysis-random-design-tidbits-from-a-dark-souls-level-undead-burg/) | As duas pontas laterais acabavam sem contrato próprio; inimigos premiavam imediatamente o save/HUD, portanto nada permanecia no chão para ser descoberto | A rota segura custa mais tempo, oferece descanso e recompensas distribuídas; a rota curta expõe dois pontos de pressão e um achado físico atrás de geometria. `SecretsGroundItem` apresenta silhueta por categoria, feixe emissivo que respeita profundidade e toque 3D sintetizado; não usa marcador invisível, partícula ou luz dinâmica |

**A nossa versão não copia plantas, nomes, arte ou conteúdo:** adopta os padrões de ligação espacial, promessa visual, desvio com custo e descoberta atrás de geometria.

### As quatro perguntas do fio solto

1. **Como usa o jogador:** anda até à bifurcação e escolhe uma rota; chega ao outro lado do portão e usa a ação configurável `interact` para levantar o trinco; aproxima-se do achado legível no chão e usa a mesma ação para o reclamar ou dispensar o recibo já atribuído. Não há tecla nova fixa, nível mínimo, chave nem menu.
2. **Como se prova:** `exploration_self_test.gd` deu **25/25**. A prova lê `world.json` e `combat.json`, mede 479,74 s na rota segura e 40,18 s no atalho, verifica separação/reunião, lança raios físicos para provar “escondido” e “revelado”, abre o portão somente do interior e confirma restauração persistente. O auto-teste central continua a ser a autoridade final desta árvore.
3. **De onde vêm arte e som:** caminho, bloqueadores, grade, silhuetas e feixe são primitivas sintetizadas em GDScript; os toques reutilizam o PCM sintetizado por `LootAudio`. O conceito existente `art/concept/brumal-caminho.png` orienta cor/névoa, sem introduzir binário. O dono do greybox pode trocar os volumes de marco pelos modelos Kenney já importados, conservando os mesmos pontos.
4. **Quanto custa na máquina do Rico:** Iris Xe, 1920×1080, Mobile/Vulkan: o módulo ligado acrescenta **4 draws visíveis, 34 nós e 0,848 MiB**, com zero luz dinâmica e zero partículas. A última amostra ligada mediu 103,8 fps/p99 13,676 ms, mas a amostra desligada imediatamente anterior ficou anormalmente pior (62,9 fps/p99 36,348 ms) sob trabalhos paralelos; logo **não é lícito atribuir um ganho ou custo de FPS**. O delta estrutural é repetível; o gate de frame pacing integrado fica aberto até repetir sem concorrência depois da ligação ao greybox.

### Decisões `[CODEX]` propostas, não `[DECIDIDO]`

- `[CODEX]` **Rota segura de oito minutos versus corte arriscado de 4,8 minutos.** Razão: cada direção muda tempo, descanso, pressão e pagamento. Alternativa: duas rotas de duração igual, descartada por repetir a escolha cosmética que motivou esta tarefa.
- `[CODEX]` **Trinco físico com `interact`, aberto do interior.** Razão: descoberta + habilidade de chegar ao lado certo responde à Lei 1 e deixa a ação remapeável. Alternativa: nível, chave de inventário ou abertura automática, descartada por gating ou por retirar a ação ao jogador.
- `[CODEX]` **Espólio no chão em modo recibo após o commit corrente.** Razão: hoje `main.gd` atribui a queda atomicamente na morte; mostrar depois o objeto torna a queda legível sem abrir duplicação. Alternativa futura: reclamar antes do commit, apenas quando o dono do save criar uma transação pendente idempotente.

### Para o dono do greybox, save, encontros e integração

| Estado | Trabalho que não pertence a esta árvore | Fronteira pronta |
|---|---|---|
| 🔴 | Instanciar `ExplorationBrumal` **antes** de dispersar a floresta, usar todos os `route_segments()` na distância de limpeza e deixar de desenhar a linha antiga. O overlay isolado atual atravessa árvores aleatórias e não é uma apresentação final aceitável | `route_segments()` · `tutorial_path_points()` · `landmarks()`; não alterar `exploration_brumal.gd` para compensar a ordem do greybox |
| 🔵 | Substituir os sete pontos antigos usados pelo tutorial, acrescentar os três marcos sem duplicar os existentes e conservar árvores/rochas entre corredores paralelos para que a dobra se revele por etapas | `tutorial_path_points()` devolve oito pontos compatíveis; marcos têm `id`, `position` e `kind` |
| 🔵 | Materializar os custos das duas rotas com encontros reais; esta árvore não possui inimigos nem números de combate | `encounter_markers()` expõe um ponto seguro e dois pontos de pressão na rota arriscada; números continuam em `game/data/*.json` |
| 🔴 | Mostrar `SecretsGroundItem` na posição da morte depois de `commit_enemy_defeat`, em `already_committed = true`, e ligar prompt/ação configurada. Sem esta integração, a morte ainda só mostra toast e a queixa “não vejo o que caiu” permanece no jogo principal | `setup_from_loot(...)` · `try_interact(...)` · sinal `presentation_finished`; quatro apresentações simultâneas custaram os 4 draws medidos |
| 🔵 | Se for desejado apanhar antes de atribuir, criar no save um recibo pendente atómico/idempotente e só então usar `claim_requested`/`resolve_claim`. Não atrasar o commit atual sem essa proteção | o objeto permanece no chão após `resolve_claim(false)` e desaparece apenas após confirmação positiva |
| 🔴 | Persistir `SHORTCUT_ID` em `world.shortcuts_open` quando `shortcut_opened` disparar e chamar `restore_shortcuts(...)` ao carregar. O campo existe, mas não há hoje API de commit; sem dono do save, a prova de restauro só é isolada | sinal `shortcut_opened(shortcut_id)` · `restore_shortcuts(PackedStringArray)` |
| 🔴 | Repetir captura e medição integradas, sem outros Godot/agentes a renderizar, depois de o greybox limpar a floresta pelas novas rotas. As capturas atuais provam silhueta/grade, mas não podem aprovar a leitura do percurso completo | auditoria do módulo: 5 instâncias de malha; atalho: 2; achado: 2; zero luz dinâmica/partículas |
| 🔵 | Incluir `exploration_self_test.gd` no agregador central se os donos quiserem que as 25 provas corram dentro de `selftest.tscn`; esta árvore não possui o agregador | comando isolado documentado no ficheiro; o gate central de 9 703 não deve regredir |
| 🔵 | `node tools/check-coerencia.mjs` encontrou dois links já partidos em `MAPA.md`: *(um registo de sessão privado, gitignored)* e o transcript homónimo. Não pertencem à exploração e esta árvore não altera `MAPA.md` | dono do mapa decide restaurar os dois documentos ou retirar as referências; 19 JSON e 2 797 contratos passaram, estes foram os únicos erros |
