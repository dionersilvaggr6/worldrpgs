# LACUNAS — o que falta, e ninguém está a fazer

**Actualizado: 01-08-2026, Revisão 3.** Mantido pelo **Claude/Codex**. É a lista de tudo o que foi identificado como buraco e **ainda não tem dono**.

> **Porque existe:** as lacunas que eu encontro a rever viviam em **comentários de PR**. Um comentário lê-se uma vez e desaparece — e uma lacuna esquecida é uma lacuna que se descobre no fim, quando custa dez vezes mais.
>
> ⭐ **A regra:** encontrei uma lacuna → escrevo-a aqui **no mesmo acto**. Quando alguém a resolve, risca-se com o commit ao lado.

**Legenda:** 🔴 trava alguma coisa · 🟠 devia entrar na volta indicada · 🔵 quando houver tempo · ⏳ é dos donos, não dos agentes

---

## 🐛 O ecrã de inventário rebenta ao seleccionar itens — apanhado a jogar, 01-08

**O Rico abriu o jogo para ver como estava e apanhou isto em segundos.** Não foi um auditor: foi alguém a carregar num item.

```
SCRIPT ERROR: Invalid call 'String' constructor: espada recta
   at: InventoryMenu._show_detail (res://src/ui/inventory_menu.gd:218)
```

Dispara em `_select_item` **e** em `_set_filter`, ou seja **sempre que se abre a lista ou se muda de filtro**. O painel de detalhe fica sem as linhas de facto.

### A causa, verificada e não adivinhada

⭐ **Em Godot 4, `String(x)` não é uma conversão universal — é um construtor com assinaturas fixas, e `String(int)` não existe.** Confirmei-o a correr:

```
Parse Error: No constructor of "String" matches the signature "String(int)".
```

E o `weapons.json` declara `"hands": 1` — um inteiro. Como vem de `data.get()`, o tipo é `Variant` e o compilador **não pode apanhar**; falha só em runtime, na mão do jogador. Foi por isso que passou nos 9703 testes: nenhum exercita este caminho com uma arma real.

### A correcção

**`String(…)` → `str(…)`** nas linhas de `src/ui/inventory_menu.gd` que recebem valores de dados: **218** (`hands`, int), **219** (`range`, float) e **227** (`refinement`). O `str()` aceita qualquer `Variant`; é essa a função de conversão.

⚠️ **As outras oito ocorrências do ficheiro (186, 187, 213, 217, 221, 223, 225, 229, 231) são seguras hoje** porque os valores são texto — mas são a mesma armadilha à espera do primeiro campo numérico. Trocar todas por `str()` custa o mesmo e fecha a classe inteira.

⭐ **E o teste que faltava**, para isto não voltar: um caso que abra o detalhe de **uma arma, uma armadura e um material reais do catálogo** e verifique que as linhas de facto saem preenchidas. O painel a ficar vazio é o sintoma, e é silencioso.

**⛔ Não lhe toquei:** `inventory_menu.gd` está na lista de ficheiros com dono do [`prompts/PARA-O-OPUS-DO-RICO.md`](prompts/PARA-O-OPUS-DO-RICO.md) §3.

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
| ✅ | ~~**O corpo do parceiro não aparece em cena.**~~ **RESOLVIDO 02-08** — `CoopPlayerRuntime` encontra o `Player` que a cena publica, envia pose/estado/vida, troca identidade versionada e cria um `CoopRemotePlayer` visível com a origem correcta. A prova oficial abre dois processos do jogo real, usa F3 + Hospedar/Entrar, move os dois jogadores e observa movimento remoto nos dois sentidos | `game/src/coop/coop_online_gameplay_proof.tscn` · `game/src/net/net_selftest.gd` (passo 7 do `VERIFICAR.bat`) |
| 🔴 | **Os eventos de combate não estão ligados.** O `NetSession.combat_event` dispara com golpes, parries e mortes, e **ninguém o ouve.** O contrato da autoridade está implementado e testado; falta o outro lado do fio | dono do `game/src/coop/` e do combate |
| 🟠 | ⭐ **A vida do chefe não reescala quando o parceiro cai.** O [`19`](spec/19-rede.md) manda: de ×1,8 para ×1,0 **proporcionalmente ao que falta**. A rede emite `session_ended`/`peer_disconnected`; falta o chefe ouvir | dono do `game/src/enemies/boss*.gd` |
| ✅ | ~~**O menu de rede não tem tecla.**~~ **RESOLVIDO 02-08** — a integração corrente abre Jogar a dois por F3, liberta o rato, suspende o input local e devolve-o ao fechar. A prova de dois processos exerce esse percurso e confirma também que Entrar vazio escreve “Falta o endereço” no ecrã | `main.gd::_unhandled_input` · `game/src/coop/coop_online_gameplay_proof.tscn` |
| 🟠 | **O aviso de latência vive num `CanvasLayer` próprio** (`net_hud.gd`), porque o `src/ui/hud.gd` tem dono. Quando quiserem absorvê-lo, são dez linhas | dono do `hud.gd` |
| 🟠 | **O save não sabe de sessões.** O [`19`](spec/19-rede.md) separa o saco *personagem* do saco *mundo*; o `save_system.gd` guarda um só. Quem entra no mundo do outro **não pode** gravar por cima do mundo dele | dono do `save_system.gd` |
| 🟠 | **O corpo remoto mostra corpo/origem, mas ainda não o equipamento corrente.** A identidade fiável transporta `profile_id`, `class_id` e `body_id`; arma, armadura trocada, conjuração e impacto continuam a precisar do contrato de inventário/combate dos respectivos donos. Não inventar uma lista paralela de itens na rede | donos de `inventory_system.gd`, `visual/weapon_attach*.gd`, `visual/armor_visual*.gd` e combate |
| ⏳ | ⭐ **O transporte é decisão dos donos** — porta aberta no router **ou** VPN de amigos. O código é agnóstico e liga a qualquer endereço, portanto isto **não trava nada**; mas até alguém abrir a porta, ninguém joga a dois | Mateus + Rico |

### 02-08 — prova jogável do fio ligado

1. **Como usa o jogador:** dentro do mundo, carrega F3; um hospeda e lê a ajuda de rede local/Tailscale/porta UDP, o outro escreve o endereço e escolhe Entrar. O mesmo F3/Fechar devolve o controlo.
2. **Como se prova:** `game/src/coop/coop_online_gameplay_proof.tscn` abre **dois processos Godot**, instancia `gameplay.tscn` com jogador+mundo+inimigos, usa os controlos e botões reais, escolhe duas origens diferentes, exige dois corpos visíveis e move anfitrião e convidado por input. Passou repetidamente, incluindo duas verificações simultâneas, e entra no passo 7 já existente do `VERIFICAR.bat`; `net_selftest.gd` terminou **27/27** nas duas. Cada prova usa uma porta temporária própria; os slots temporários ficam fora de 0–2 e são apagados, e nenhum perfil `prova-*` pode sobrar.
3. **De onde vêm arte e som:** zero asset novo. O parceiro usa `CharacterVisual` e as malhas/animacões já importadas da origem recebida; rede não acrescenta som.
4. **Quanto custa na máquina do Rico:** fio real medido em várias passagens a **2558–3063 bps por sentido** (tecto 30 000). A/B no Intel Iris Xe, Mobile/Vulkan, 1920×1080, combate real com jogador+2 inimigos: o proxy acrescentou **6 draws e 0,4 MiB VRAM**; médias `off/on` foram **135,6/135,5** e **117,6/112,9 fps**, p99 **18,476/12,288** e **16,206/17,138 ms**. Há vários Godot de outras árvores activos e esta máquina tem 16 GiB, por isso os p99 contraditórios não fecham a Lei 4 no aparelho final de 8 GiB; a medição honesta é custo pequeno mas gate ainda aberto.

⚠️ **O que continua NÃO provado:** são dois processos na mesma máquina, não duas casas. Porta aberta/CGNAT/Tailscale, firewall e latência real entre Mateus e Rico só existem com as duas máquinas; é aí que `< 2 min` e `< 80 ms` deixam de ser ensaio local. A entrada local ficou em **0,25–0,57 s** nas repetições, muito abaixo dos dois minutos, mas não substitui esse ensaio.

⚠️ **Incidente de desenvolvimento já recuperado:** a primeira versão da prova deixou o perfil temporário chegar ao slot 0. Foi detectado na própria execução, o slot e o backup foram restaurados byte a byte a partir de `saves.backup-165816`, e a quarentena contendo apenas os dois `prova-*` foi depois removida. A prova final usa slots altos exclusivos, limpa `.json/.bak/.tmp` e recusa terminar verde se deixar um perfil seu nos slots 0–2; as execuções finais não deixaram nenhum.

⚠️ **Regressão global fora desta árvore:** em três execuções, `scenes/selftest.tscn` terminou **9763/9764**; a única falha foi `jogo real: os marcadores da Toca tem encontro (com corpo ou planeado)` em `scenes/selftest_integrated.gd:93`. Rede/coop passa e não cria corpo quando offline. O dono de `SpawnPopulation`/prova integrada precisa alinhar plano e marcadores; esta árvore não pode editar esses ficheiros.

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
| 🔴 | ⚠️ **Os catálogos autorizados `status_effects.json` e `audio_catalog.json` elevam `game/data` de 18 para 20 JSON, mas o guarda tem o total 19 hardcoded e `GameData` ainda não os inclui na validação central.** O dono de `tools/check-coerencia.mjs` deve aceitar/validar o 20.º catálogo e o dono de `game/src/autoload/game_data.gd` deve expô-los ou reconhecer os carregadores especializados; esta árvore de música só pode escrever no catálogo áudio e em `game/src/audio/music*.gd`. Até lá, o auto-teste passa 9703/9703 mas o guarda acrescenta este terceiro erro aos dois links de `MAPA.md` já conhecidos. | `game/data/status_effects.json` · `game/data/audio_catalog.json` · `node tools/check-coerencia.mjs` em 01-08-2026 |
| 🔴 | ⚠️ **O conjunto residente “zona actual + todas as vizinhas” não cabe sem um orçamento ainda inexistente por zona.** No Fojo são 6 zonas: o tecto global de 2,5 GB deixa **≈427 MiB por zona se runtime, áudio, jogadores e UI custassem zero**; na máquina de 8 GB partilhados isso é uma estimativa optimista. Definir política/per-zone budget antes da segunda zona final | revisão 2 · [`69`](spec/69-catalogo-do-mundo.md) §6 · pergunta 50 |
| 🔴 | ⚠️ **Invocações sem tecto colidem com o máximo de oito actores animados.** Um encontro de 2 jogadores + 5 inimigos já ocupa 7; sobra uma vaga para invocações dos dois, chefe portátil e qualquer reserva. Sem orçamento global, a promessa do mago pode exceder a Lei 4 na primeira conjuração extra | revisão 2 · [`21`](spec/21-arte-render.md) §2 · [`52`](spec/52-mago-do-mal.md) §10 · pergunta 51 |
| ✅ | ~~⚠️ **Os 53 VFX não tinham política de residência**~~ **RESOLVIDO 01-08** — `equipped_only` materializa apenas os favoritos (máximo 8), sintetiza geometria e som sem texturas e partilha malha por forma/material por escola; pedir os 53 é recusado atomicamente sem expulsar a cache válida. Dardo + Ruína + Égide na Iris Xe, 1080p Mobile: **200,33 fps**, p99 **13,896 ms**, pior frame **22,179 ms**, 13 draw calls, 3 malhas + 1 material e +10 059 427 bytes de memória estática | [`medição`](game/src/vfx/benchmark_iris_xe_2026-08-01.json) · `game/src/vfx/spell_vfx_residency.gd` |
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
| 🟠 | **O contrato do orçamento de almas já foi separado por colocação, mas o produtor corrente ainda chama a transacção antiga por tipo:** `ProgressionRuntime.commit_enemy_defeat()` paga dez bases por `placement_id` e mantém só dez cartas por tipo; `main.gd::_on_enemy_died()` tem de lhe passar um ID estável em vez do índice do baralho | árvore `fogueira-e-almas` · `game/src/progression/` · [`67`](spec/67-catalogo-do-bestiario.md) §6 · [`72`](spec/72-materiais-consumiveis-e-economia.md) §4 |
| 🔴 | **A cena real ainda não instancia `Bonfire`:** o bloco paralelo `main.gd::_rest_at()` cura, repõe frascos, grava checkpoint e faz `full_reset()`, mas não gasta `world.enemy_respawns`, não senta e não abre nível. O repro jogável isolado prova a diferença: produção **7 verdes/4 vermelhos**; o mesmo jogador/inimigo/cena com `Bonfire` ligado explicitamente passa sentar + `LevelUpScreen` + co-op sem pausa + **10 reposições e 11.ª esgotada**. Cada `_spawn()` precisa ainda de meta `placement_id=zone_id:stable_spawn_id`; `_build_bonfire()` deve criar/configurar o controlador e `_tick_rest_points()` deve chamar `process_input(player, enemies)` em vez do bloco duplicado. | integração fora da árvore do dono · `game/src/main.gd` · `game/src/progression/bonfire_gameplay_repro.tscn` |
| 🟠 | **A Brasa continua sem escolha na casca:** `Bonfire` já reutiliza e abre `LevelUpScreen.open_for_current()` no descanso; `Bonfire.level_up(attribute_id)` e `Bonfire.kindle_ember(...)` ficam expostos, mas a acção de queimar Brasa e a confirmação irreversível pertencem à UI/casca. Não criar uma tecla global: só existe no descanso. | integração fora da árvore do dono · `game/src/ui/game_shell.gd` |
| 🔴 | **A prova jogável nova ainda não está no corredor obrigatório porque esta árvore não pode editar `game/VERIFICAR.bat`.** Integrar como nova etapa com `APPDATA` temporário e `WORLDRPGS_TEST_USER_ROOT` a apontar para a mesma pasta; o ensaio recusa arrancar se `user://` não estiver isolado e limpa-se removendo apenas essa pasta temporária. Sem esta linha, a falha de fio acima não bloqueia `VERIFICAR.bat`. | `game/src/progression/bonfire_gameplay_repro.tscn` · regra “um teste que ninguém corre não é um teste” |
| 🟠 | **Os defaults/migração do save ainda não materializam os novos campos preguiçosos:** `enemy_soul_rewards`, `zone_cycles`, `embers_kindled` e `embers_held` funcionam quando ausentes, mas `save_system.gd` deve declará-los na próxima versão para o formato ficar auto-documentado | integração fora da árvore do dono · `game/src/autoload/save_system.gd` |
| 🟠 | **A Brasa precisa da colocação de mundo e do mapa zona→guardião:** `commit_placed_ember()` garante recompensa única e `commit_ember()` repõe a zona sem reabrir almas/baralho; falta o produtor WP8 passar os `placement_id` e `boss_id` daquela zona | integração fora da árvore do dono · `game/src/main.gd` / futuro runtime de mundo |
| 🟠 | **O guarda de coerência termina vermelho apesar de validar 2792 contratos sem erro:** `MAPA.md` aponta para *(um registo de sessão privado, gitignored)* e *(um registo de sessão privado, gitignored)*, ambos ausentes; regenerar o mapa ou restaurar as fontes, nunca editar `MAPA.md` à mão | encontrado na árvore `fogueira-e-almas` · `node tools/check-coerencia.mjs` |
| 🔴 | **O Elo de Bruma fecha a regra e a prova local, mas ainda não está no percurso jogável:** `EncounterBrumalElo` exige alvo + não-alvo vivo, troca os papéis; a máquina passa 21/21 e o smoke da subclasse real 7/7, incluindo o golpe mortal bloqueado até ambos abrirem, provando que um corpo nunca ganha. `main.gd` ainda instancia `Enemy`, liga todo `Player.died` ao respawn solo e não encaminha `interact`/HUD para o coordenador; integrar isso pertence aos donos desses ficheiros. Até essa ligação, a Fatia 1 jogada continua sem a prova co-op | [`19`](spec/19-rede.md) · `game/src/coop/coop_combat_self_test.gd` · perguntas 59/32 |
| ⏳ | 🔴 **Brumal pede densidade larga com só dois tipos `fatia_1:true`.** O Batedor e um nomeado que depende dele aparecem no orçamento, mas continuam fora da fatia; decidir promover o terceiro papel ou cortar para 6–7 batidas | revisão 3 · pergunta 57 |
| 🟠 | **A janela de ressurreição já é executável no módulo local:** expira, consome uma utilização partilhada, lê duração/vida/frascos de `progression.json`, suporta `cumulative` `[PROTO]` e `reset_on_interrupt`, e o `aprendiz` salva `veterano` em teste. Falta integrar corpo/HUD no runtime e continua sem agência do caído; a política final permanece `[TENSÃO]` 60 | [`19`](spec/19-rede.md) · `game/src/coop/coop_resurrection.gd` · perguntas 58/60 |
| 🟠 | **O feedback de impacto do Elo precisa do dono de `player.gd`/HUD:** hoje o jogador toca `hit_flesh` antes de o alvo aceitar o dano; ligado sem adaptação, um golpe bloqueado pelo Elo tocaria carne + bloqueio. O cliente deve publicar o impacto depois do resultado autoritativo e consumir `hit_blocked` num sinal visual equivalente, sem depender do som | `game/src/player/player.gd` · `game/src/enemies/encounter_brumal_elo.gd` · [`62`](spec/62-acessibilidade-auditiva.md) |
| 🔴 | **O orçamento de almas não pode ser pago pelo runtime corrente:** baralho/transacção fecham após 10 derrotas do tipo; `souls_ten_rewarded_clears` multiplica cada colocação por 10. Separar almas de cartas depois de Mateus + Rico fecharem o contador | revisão 3 · pergunta 23 · [`67`](spec/67-catalogo-do-bestiario.md) §6 · [`72`](spec/72-materiais-consumiveis-e-economia.md) §4 |
| ⏳ | 🟠 **Mochila infinita + loot instanciado + garantia + chefe que larga tudo transforma descoberta em checklist.** Falta uma escolha que preserve a garantia contra azar | revisão 3 · pergunta 61 |
| ⏳ | 🟠 **“Nunca se zera” não tem exemplar jogável:** recompensas/corpos esgotam, as 30 portas não devem resposta e a segunda leitura de Brumal não está autorada | revisão 3 · pergunta 62 |
| ⏳ | 🟠 **A promessa mais própria — cadáveres/Voto/chefe portátil — não é testada pela Fatia 1.** Decidir spike/epílogo antes de produzir 50 feitiços futuros | revisão 3 · pergunta 63 |
| ✅ | ~~**`BossVorgar` procurava um contrato inexistente e chamava seis APIs apagadas por merge.**~~ **RESOLVIDO 02-08** — `vorgar_encounter` voltou ao catálogo; `ArenaVorgar` executa `setup/begin/tick/join/end/reset`, SEPARAR/JUNTAR aplicam os volumes visíveis e a ressurreição partilhada tem custo/risco. O ensaio focado passou **119/119** e as cenas reais deixaram de emitir `ficha vorgar_encounter em falta`. | `game/data/enemies.json` · `game/src/enemies/boss_vorgar.gd` · `game/src/world/arena_vorgar.gd` |
| 🔴 | **A resolução do `ArenaVorgar` foi reaberta por um merge inválido.** `godot --headless --audio-driver Dummy --path game/ --script src/world/arena_vorgar.gd` termina com exit 1: `_active_sequence` é declarado duas vezes em `arena_vorgar.gd:82`; o ficheiro contém ainda blocos duplicados de `_ready`, `setup` e `begin_sequence`. `--import` não corrige. A `selftest.tscn` imprime **9764/9764** e exit 0 apesar dos `SCRIPT ERROR`, portanto essa contagem está a executar cache/estado parcial e não prova que o jogo corrente compila. Corrigir no ficheiro do dono e voltar a exigir uma execução sem `SCRIPT ERROR`/`ERROR:` antes de fechar. | regressão observada 02-08-2026 · `game/src/world/arena_vorgar.gd` · `game/src/enemies/boss_vorgar.gd` · `game/src/main.gd` |
| 🟠 | **Feiticeiro e Mago do Mal já recebem sino/talismã e conseguem usar o par cajado + instrumento, mas o validador global ainda rejeita os IDs.** Os instrumentos existem em `equipment.json::magic_instruments` e aparecem na mão/caixa; `GameData._validate()` procura-os apenas como armas de topo em `weapons.json` e emite dois erros de coerência. O runtime não deve duplicar os instrumentos só para calar o validador: o dono dos catálogos deve unificar a fronteira. | prova dos sete kits, 02-08-2026 · `game/data/weapons.json` · `game/data/equipment.json` · `game/src/autoload/game_data.gd` |
| 🟠 | **O fio básico de morte do primeiro chefe está provado no jogo, mas uma luta completa de vida cheia continua por medir.** A prova integrada anda até à arena, envia `attack`, vê `BossVorgar` morrer e a barra desaparecer. O teste focado prova separação, reunião, dano visível e ressurreição, mas ainda move duplos directamente: falta uma cena ligada a `VERIFICAR.bat` em que os dois `Player` reais respondam a SEPARAR/JUNTAR por input. Esta árvore não pode editar a cena nem o batch. | prova integrada **9763 verdes/1 vermelho alheio** + ensaio Vorgar **119/119**, 02-08-2026 |
| 🔴 | **O fio básico de morte do primeiro chefe está provado, mas o percurso completo e a luta de vida cheia continuam por provar.** `percurso.tscn` deixou de teletransportar/forçar invulnerabilidade: numa execução isolada andou por `Input`, contornou uma colisão, matou **7** inimigos observando `died` e chegou vivo apenas a **4/17** destinos; morreu no encontro seguinte e saiu vermelho antes de ver Vorgar. Portanto não há captura final honesta nem prova do ritmo de uma tentativa completa; SEPARAR/JUNTAR continuam também bloqueados acima. | `scenes/percurso.tscn`, exit 1, 02-08-2026 · prova integrada básica **9764/9764** |
| 🔴 | **`percurso.tscn`, `filme-de-combate.tscn` e `sessao-de-jogo.tscn` ainda não pertencem ao corredor obrigatório.** As cenas agora devolvem exit 1 quando a promessa falha e isolam capturas por `WORLDRPGS_PROOF_CAPTURE_DIR`, mas esta árvore não pode editar `game/VERIFICAR.bat`. O dono desse ficheiro deve acrescentar as três etapas com `APPDATA`/`WORLDRPGS_TEST_USER_ROOT` temporários e limpeza da pasta criada; sem isso, uma regressão volta a ficar verde no comando oficial. | restrição de propriedade desta ronda · regra “um teste que ninguém corre não é um teste” |
| 🟠 | **`filme-de-ataque.tscn` continua a anunciar 32 imagens que são 16 pares duplicados.** A causa está em `game/src/tools/filme_de_ataque.gd`, fora dos ficheiros autorizados: cada amostra grava o mesmo `Image` sincronamente e outra vez numa tarefa, incrementando `n` duas vezes. Corrigir para uma escrita e um incremento por frame pedido; depois provar contagem e hashes distintos no renderer real. | achado P1 da revisão · ficheiro fora da propriedade desta ronda |
| 🔴 | **O auto-teste principal corrente está vermelho fora desta propriedade:** duas execuções isoladas deram **9763 passaram/1 falhou** em `jogo real: os marcadores da Toca tem encontro (com corpo ou planeado)`. A asserção de `selftest_integrated.gd` não encontra no plano de `SpawnPopulation` todas as posições dos marcadores da Toca. O dono de população/teste deve alinhar o plano com os marcadores sem voltar a instanciar corpos distantes e quebrar o tecto de oito actores. | duas execuções com `APPDATA` temporário, 02-08-2026 · `game/scenes/selftest_integrated.gd:93` · `game/src/world/spawn_population.gd` |
| ⏳ | 🟡 **Até dez anéis + nove peças + oito favoritos podem transformar build em espera de menu co-op.** Validar 4 anéis/presets no descanso antes de abrir a escala toda | revisão 3 · pergunta 64 |
| ✅ | ~~O teste de honestidade só provava a esquiva certa~~ **CORRIGIDO** — agora duas esquivas sem sobreposição com o activo têm de falhar 10/10; um teste verde deixa de aceitar janela/hitbox que não discrimina timing | revisão 3 · [`38`](spec/38-ataques-e-honestidade.md) cláusula 5 |
| ✅ | ~~O fecho do `72` ainda dizia que cinco acessórios ficavam fora do contrato~~ **CORRIGIDO** — a fronteira reconhece a migração já feita pelo `74` | revisão 3 · [`72`](spec/72-materiais-consumiveis-e-economia.md) §6 |

### `[CODEX]` Medição de equilíbrio de Vorgar — 02-08-2026

Baseline calculado com os dados efectivamente carregados pelo runtime, Guerreiro nível 1 (442 PV, 20 DEF, espada longa) e um castigo seguro por acção do chefe. O tempo é um orçamento determinístico dos frames dos padrões, não uma luta jogada; a prova jogável continua vermelha acima.

| Medida | ELES | NÓS | DIFERENÇA |
|---|---:|---:|---|
| Golpes de Vorgar para matar o jogador | 3–4 | 3–5 | dentro do alvo nos pesados; um golpe extra nos leves |
| Golpes razoáveis para matar o chefe | 20–40 | 35 pesados · 21 ripostes | dentro do alvo |
| Golpes leves repetidos para matar o chefe | 20–40 | 63 | +23 acima do tecto; o jogo deve ensinar pesado/riposte, não vendê-los como opcionais invisíveis |
| Duração, um pesado seguro por acção | — | 85,8 s | baseline marcial; falta confirmar a jogar |
| Duração equivalente com o cajado sem magia | — | 201,1 s | +115,3 s causados pelo kit/runtime desligado |

**Decisão `[CODEX]`:** não alterar `enemies.json`, `combat.json` nem `attributes.json` nesta ronda. Razão: o eixo marcial já coincide com a referência; a impossibilidade relatada concentra-se no kit mágico sem `cast` executável e na ausência da prova de luta. Alternativa descartada: reduzir PV ou dano de Vorgar antes de ligar o kit, porque esconderia o defeito e faria as origens marciais ganhar por número.

As quatro perguntas do fio solto:

1. **Como usa:** ataque leve/pesado, esquiva, parry e `cast`, todos pelo mapa remapeável; os kits mágicos já chegam com instrumento secundário.
2. **Como prova:** a cena oficial já prova ataque real, dano, morte e barra escondida; a luta completa e as sequências co-op continuam por provar.
3. **Arte e som:** Vorgar reutiliza o conceito/modelo orc e os cues sintetizados já carregados; esta ronda numérica acrescenta zero assets.
4. **Custo no Rico:** Iris Xe, Mobile/Vulkan, 1920×1080, arena real com dois jogadores + Vorgar + dois orcs: **135,7 fps médios, p99 12,688 ms, pior 15,31 ms, zero frames >16,67 ms** em 15 s. A sonda do controlador terminou com erros de integração, portanto estes números provam a arena base, não o controlador SEPARAR/JUNTAR.

---

## 🟠 Para as voltas que aí vêm

### Volta 2 — fichas de raça 🔨 *em curso*

| | Lacuna | Origem |
|---|---|---|
| ✅ | ~~⚠️ **A linha "porque está neste bioma"**~~ **RESOLVIDA** — as 12 fichas ligam origem/necessidade ao bioma e a validação cruza `races.json` ↔ `biomes.json` nos dois sentidos | [`50`](spec/50-racas.md) · `664ec7e` |
| ✅ | ~~**Em que biomas cada raça aparece, e o que muda em cada variante**~~ **RESOLVIDO** — variantes têm papel/ataques próprios nas fichas do bestiário, não apenas cor | [`50`](spec/50-racas.md) · [`67`](spec/67-catalogo-do-bestiario.md) · `d7088b7` |
| ✅ | ~~⚠️ **Santuário Branco e A Raiz sem raça própria**~~ **RESOLVIDO** — Penitentes e Sem-rosto são habitantes dominantes e têm fichas/combate | [`50`](spec/50-racas.md) · [`67`](spec/67-catalogo-do-bestiario.md) · `d7088b7` |
| ✅ | ~~**Mímicos e Minotauros sem ficha adequada**~~ **RESOLVIDO 01-08** — mímico é praga com duas fichas de encontro; minotauros comuns variam por bioma e o guardião singular continua WP7 | [`50`](spec/50-racas.md) · [`67`](spec/67-catalogo-do-bestiario.md) |
| 🟠 | **O manifesto ainda aponta os IDs históricos `con_orc_lanceiro`, `con_orc_brutamontes` e `con_vorgar` para três PNG na raiz de `art/concept/`, mas os alvos correntes são imagens diferentes em `art/concept/inimigos/` e `art/concept/chefes/`.** O dono da arte tem de escolher a versão canónica e actualizar `art/MANIFESTO.md` com caminho/proveniência; as specs `27` e `50` já citam os ficheiros correntes sem fingir que conceito 2D é asset runtime. | `art/MANIFESTO.md` · `art/concept/README.md` · [`27`](spec/27-aprendizagem.md) · [`50`](spec/50-racas.md) |

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
| 🟠 | **Integração visual fora da propriedade:** `ArmorVisual` substitui os placeholders de origem, conserva corpo/Skin/animações Quaternius e chama `apply_equipment(equipment.armor)`. O dono de `game/src/player/player.gd:167` e `game/src/ui/game_shell.gd:1540` tem de instanciar esta extensão no lugar de `CharacterVisual` e reaplicar no spawn/`inventory_changed`; sem essa costura, a geometria provada ainda não aparece no jogo normal. A entrega antiga `ArmorCharacterVisual` misturava personagens KayKit com o rig Quaternius e fica obsoleta | entrega do ecrã completo 01-08 · `game/src/visual/armor_visual.gd` |
| ✅ | ~~**Abrir o ecrã completo no jogo**~~ **RESOLVIDO 02-08** — `QuickSlots` monta `EDITAR ACESSO RÁPIDO` na mochila aberta e devolve ao mesmo menu ao fechar, sem nova tecla e sem alterar `inventory_menu.gd`/`game_shell.gd`. A acção genérica `EQUIPAR` da ficha de um objecto continua a equipar directamente; o caminho ranhura → objecto pedido pelo Mateus está no botão dedicado. | `game/src/ui/quick_slots.gd` · `game/src/ui/equipment_screen.gd` · prova integrada em `repro-inicio.tscn` |
| 🟠 | **Arte modular final ainda falta:** nenhum dos 176 modelos runtime nem dos 785 em `art/` fornece onze peças modulares com o Skin Quaternius. O fallback novo usa apenas cascas curvas, placas sobrepostas, rebites, tecidos curvos e volumes afunilados presos ao rig — zero `BoxMesh` — e segue as armaduras aprovadas em `art/concept/armaduras/`; não volta a fingir que um personagem KayKit inteiro é roupa. Para substituir o fallback, produzir/importar peças de 8–15k tri com LOD para estes onze IDs e depois para as 57 futuras | auditoria dos assets · `art/concept/README.md` · `game/src/visual/armor_visual.gd` |
| 🔵 | **Como a mira do arco comunica a queda da flecha** — sem isso o jogador aprende "o arco falha às vezes" | [`36`](spec/36-fisica.md) §3 |

#### Ecrã de equipamento completo — DS3 · nós · diferença (01-08)

| Foco | Eles — Dark Souls III | Nós | Diferença / contrato |
|---|---|---|---|
| **Fluxo de troca** | O manual oficial separa Equipment de Inventory; no Equipment escolhe-se primeiro a localização no corpo e depois um objecto compatível, com estado do personagem e ajuda do comando visíveis ([manual oficial](https://www.fromsoftware.jp/manual/darksouls3/ps4/menu1.html)) | `EquipmentScreen.slot_grammar()` gera mãos, nove slots de armadura, anéis e atalhos; a coluna seguinte vem da mesma mochila filtrada por `slot_accepts_entry()` | Mantemos a sequência ranhura → objecto, mas acrescentamos boneco grande a mudar no acto e a comparação de carga **antes** do único botão que escreve o save |
| **Carga** | DS3 muda movimento por patamares: abaixo de 30%, 30–70%, 70–100% e acima de 100% ([Equip Load](https://darksouls3.wikidot.com/equip-load)) | Os patamares, distância, duração, recuperação e i-frames vêm de `armor.json`; mãos, armadura e anéis entram no cálculo local do ecrã | Não escondemos a consequência atrás da confirmação: topo e detalhe mostram peso/classe antes → depois, usando dados e sem números de combate no `.gd` |
| **Armas e acesso rápido** | A comunidade documenta três posições por mão e duas filas de cinco objectos/ferramentas configuradas no Equipment ([guia de configuração](https://steamcommunity.com/app/374320/discussions/0/365163686083202921/)) | O save actual tem uma mão principal, uma secundária e cinco `quick_slots` de consumíveis, derivados das acções `hotbar_*`; `loadout_next/prev` já existem nos controlos, mas não têm esquema de vários conjuntos no save | Não copiamos quantidades de DS3. A UI configura o que existe e deixa posições vazias estáveis; qualquer conjunto extra de armas precisa primeiro da decisão abaixo e de persistência própria |
| **Uma gramática** | Equipment e Inventory têm papéis diferentes, mas a posição equipada determina a lista compatível | Mochila, ecrã completo e futura loja devem chamar `slot_grammar()`/`slot_accepts_entry()` em vez de inventar nomes e regras | O dono da loja/mochila deve reutilizar este contrato; três gramáticas para mãos/armadura/anéis/atalhos voltariam ao defeito que motivou esta entrega |

⚠️ **[TENSÃO] “mudar a arma ali nos equipamentos rápidos” vs. save decidido com `quick_slots` de consumíveis.** `[CODEX]` Recomenda-se manter `main/offhand` como armas activas escolhidas neste ecrã, conservar `quick_slots` exclusivamente para consumíveis e dar a futuros conjuntos de armas um campo próprio comandado por `loadout_next/prev`. **Razão:** não mistura consumo por tecla 1–5 com troca de postura/duas mãos e não altera silenciosamente o save v2. **Alternativa:** permitir armas dentro de `quick_slots`, mas isso exige decidir o que acontece a `use_item`, mão secundária, armas de duas mãos e itens consumíveis. Mateus/Rico têm de escolher antes de existir mais de um conjunto de armas.

**Contrato com o agente `acesso-rapido`:** este ecrã **configura** `character.inventory.quick_slots` como array posicional, preenchido até às acções `hotbar_*`, com `""` nas posições vazias, e emite `quick_slot_changed(index, item_id)` depois de confirmar. `[CODEX]` Razão: remover o atalho 2 não pode deslocar o item 3 para outra tecla. Alternativa compacta descartada: uma lista sem vazios é menor, mas muda os bindings sempre que um item sai. O outro agente **mostra/usa** estas posições; não deve manter uma segunda lista.

**As quatro perguntas do fio solto desta entrega:**

1. **Como usa:** abre a mochila com `inventory_menu`, escolhe Equipamento, escolhe ranhura → objecto compatível → confirma. Armas ficam em mão principal/secundária; consumíveis entram no grupo Acesso Rápido. A costura de abertura nos ficheiros proibidos está explicitamente pendente acima.
2. **Como prova:** `equipment_screen_self_test.gd` cobre 18 contratos, incluindo cancelamento sem mutação, offhand, atalhos posicionais, slots canónicos e ausência de `BoxMesh`; a cena de captura prova o boneco e carga em directo. O auto-teste canónico continua a ser a porta final.
3. **Arte e som:** alvo visual são os conceitos aprovados em `art/concept/armaduras/`; geometria fallback é sintetizada em código sobre o Quaternius e não acrescenta som nem binários. A produção modular final está declarada acima.
4. **Custo no Rico:** Iris Xe, Mobile/Vulkan, 1920×1080, sem VSync, 3 s de aquecimento + 10 s medidos. Cinco personagens: baseline **241,9 fps / p99 9,158 ms / 35 draws**; armadura nova **217,6 fps / p99 9,715 ms / 51 draws**. Ecrã completo com boneco a rodar: **177,5 fps / p99 10,343 ms / 58 draws**, pior frame 13,515 ms; passou o orçamento de 60 fps nesta sonda.

#### Armas iniciais — entrega de 01-08

| | Lacuna | Origem |
|---|---|---|
| 🟠 | **`StartingLoadouts` já é executado como validador histórico, mas a sua auditoria isolada continua presa a seis origens.** O integrador limita esse contrato ao escopo para que foi escrito e deixa criação/aplicação/prova lerem exclusivamente os sete `loadouts` activos do catálogo. Assim a classe deixou de estar órfã sem recuperar autoridade sobre a lista; o dono do módulo ainda deve remover `ACTIVE_ORIGIN_IDS` e fazer o teste isolado passar com a sétima origem. | runtime + `starting_loadouts_test.gd` ainda **0/1**, 02-08-2026 · regra do catálogo |
| 🟠 | **As armas continuam invisíveis nas mãos.** Os GLB KayKit das seis silhuetas não trazem armas embutidas; `CharacterVisual` só anexa `shield_badge_color.gltf` ao Paladino. Não há modelo exacto de katana, Espada de Vigília ou Espada de Prata importado em `game/`; `presentation.model_asset` fica honestamente `null`. O dono de personagens/render deve escolher/importar modelos licenciados, ligar cada ID a `handslot.r/l` e medir FPS/p99 na Iris Xe. | auditoria dos 176 assets importados · Lei 4 |
| 🟠 | **Artes de arma têm dados, mas não têm acção de input/runtime.** `controls.json` não declara `weapon_art` e `player.gd` não executa `arte_1mao`/`arte_2maos`; os perfis iniciais marcam `blocked_missing_input_action` em vez de fingir que a arte funciona. | quatro perguntas do fio solto · `spec/34` §2b |
| 🟠 | **Alinhar a spec antiga com a decisão nova.** `spec/12`, `51` e `64` ainda dizem três `longsword`/exactamente seis origens; a decisão do Mago do Mal e a queixa de 01-08 são posteriores. Esta árvore não é dona desses ficheiros. | `DECISOES.md` 01-08 · pedido directo do Mateus |
| 🟠 | **O agente `armas-e-melhorias` deve reconciliar os perfis e posturas `[CODEX]` do Tanque/Paladino e a stamina/base da katana.** Razão dos perfis: a origem tem de se sentir na mão; alternativa descartada: três IDs diferentes com o mesmo ataque ou pose genérica. Não sobrescrever silenciosamente os frames/posturas que esse agente medir. | possível colisão anunciada pelo Mateus |
| ✅ | ~~**O guarda global está vermelho.**~~ **RESOLVIDO 01-08** — os dois links partidos do `MAPA.md` apontavam para registos de sessão privados, e a causa era o gerador varrer o disco em vez de perguntar ao git (ver a secção do gerador). A `[TENSÃO]` do `spec/75` foi levada para o `99`. ⚠️ **As costuras da 7.ª origem (`weapons.loadouts.evil_mage`, `economy.class_bias.profiles.evil_mage`) continuam por fechar** e estão detalhadas abaixo. | `node tools/check-coerencia.mjs` verde em 01-08 |
| 🟠 | **O Godot gerou três sidecars `.gd.uid` não rastreados.** São `game/src/tests/repro_inicio.gd.uid` e os dois `game/src/weapons/starting*.gd.uid`; a propriedade concedida cobre apenas os `.gd`, por isso não os incluí. Os donos devem decidir se estes UIDs gerados entram ou se a política de `.gitignore` os cobre. | import obrigatório + execução directa do contrato |
| 🟠 | **O repro termina com `9 ObjectDB instances were leaked at exit`.** Todas as seis origens chegaram a `ARRANQUE OK` e os saves foram limpos, mas a fuga pertence ao ciclo de vida do repro/casca, fora dos ficheiros desta árvore; o dono deve fechar os nós/referências e voltar a medir. | `repro-inicio.tscn` headless em 01-08 |
| ✅ | ~~**Activar o kit do Mago do Mal sem inventar armas.**~~ **RESOLVIDO NO JOGO** — `loadouts.evil_mage` equipa `staff` + `talisma`, couro e frasco; a cena real confirma save, inventário, mãos, armadura e acesso rápido. O erro de fronteira do validador de instrumentos fica separado acima. | `repro-inicio.tscn`, 02-08-2026 |
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
| ✅ | ~~**A casca ainda não chamava as 12 formas executáveis.**~~ **RESOLVIDO 02-08** — `Player._release_spell()` cria `SpellDeliveryFactory`, fornece o bundle residente dos favoritos e encaminha o contacto confirmado para `Spell.apply_contact()`. A cena jogável `src/spells/spell_game_integration.tscn` prova tecla real → entrega → impacto visível → perda de PV em inimigo real | `game/src/player/player.gd::_release_spell` · `game/src/spells/spell_game_integration.tscn` |
| ✅ | ~~**O material de melhoria de feitiço é o mesmo das armas, ou outro?**~~ **RESOLVIDO NA TAREFA 4** — catálogo regional partilhado; evita uma moeda paralela e conserva preferência marcial/arcana nas cartas `bias:classe` | [`72`](spec/72-materiais-consumiveis-e-economia.md) §2.1 |
| 🟠 | **Produção M3/fatias futuras: executar os 50 feitiços fora da Fatia 1.** Cada nova forma só entra com comportamento, hitbox e cue; a dívida tem autoridade e prova de saída no [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §8 | encontrado ao implementar o [`66`](spec/66-catalogo-de-magia.md) |
| 🟠 | **Produção WP11: roda e edição dos 8 favoritos.** A regra “só fora de combate/no descanso” está fechada; falta a UI que a aplique e a prova negativa em combate | [`66`](spec/66-catalogo-de-magia.md) · [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §8 |
| 🟠 | **HUD/arte: os slots já mostram activo, oito posições, custos, mana disponível e bindings actuais por marcas vetoriais, mas os três PNG aprovados continuam fora de `res://`.** A árvore dona de assets/HUD deve importar `dardo.png`, `ruina.png` e `egide.png` de `art/ui/icons/spells/` para `game/assets/ui/` e deixar `hud.gd` montar `SpellHud`; enquanto isso, o fallback em código é honesto e o `LockOn` local é a costura temporária. Não foi inventado som de interface sem cue aprovado | `game/src/ui/spell_hud.gd` · [`20`](spec/20-interface.md) §HUD · [`66`](spec/66-catalogo-de-magia.md) |
| ✅ | ~~**Escolas declaravam cinco instrumentos sem ficha**~~ **FECHADO NA TAREFA 5 e SUPERADO 01-08** — retirar os cinco era a resposta segura antes da decisão; depois de o Mateus pedir talismã + um instrumento por origem, `equipment.json::magic_instruments` voltou a declarar sete fichas com opções semânticas e contrato executável | [`74`](spec/74-fecho-da-revisao-2.md) §2 · `DECISOES.md` 01-08 |
| 🟠 | **A 7.ª origem ainda não aparece na criação porque `game_shell.gd::CLASS_IDS` continua com seis IDs.** O dono desse ficheiro deve acrescentar `evil_mage`; o dono de `game/src/tests/self_test.gd` deve mudar a asserção “exactamente seis” para **sete**, conservar a prova de que `sorcerer` continua presente e chamar o contrato de `dark_mage_origin_test.gd`. Não alterado aqui por proibição explícita de propriedade. | pedido directo do Mateus · `DECISOES.md` 01-08 · fronteira de propriedade |
| 🟠 | **Ligar `DarkMage` ao jogador e aos corpos.** Para `class_id == evil_mage`, `player.gd` deve configurar `DarkMage`, aplicar `mana_capacity()`, usar os `starting_spells`, encaminhar `ability` para `use_origin_ability()`, reservar/clamp da vida máxima visível e despachar `raise_dead`/`raise_boss`/`blood_oath`. A morte/IA deve fornecer cadáver, tamanho e PV originais; saída de zona chama `leave_zone()`, descanso chama `reset_encounter_state()`. Sem esta costura, o contrato está executável e testado isoladamente, mas ainda não é alcançável no loop principal. | `game/src/classes/dark_mage.gd` · `player.gd`/`enemy.gd` têm outros donos |
| ✅ | ~~**Instrumento livre estava decidido mas só o cajado resolvia**~~ **CATÁLOGO/CONTRATO FECHADOS 01-08** — cajado, sino, talismã, chama, relicário, híbrido e grimório têm ficha comum, viés de origem sem bloqueio e opção de construção; `instrument_catalog_test.gd` rejeita origem sem ficha e pares que só mudem números | `[DECIDIDO]` Mateus · [`52`](spec/52-mago-do-mal.md) §10 · Leis 2–3 |
| 🟠 | **A suite oficial ainda só verifica os sete campos comuns de cada instrumento.** O teste forte está em `game/src/spells/instrument_catalog_test.gd`, dentro da propriedade desta árvore, e passa 4/4; o dono de `game/src/tests/self_test.gd` deve chamar `InstrumentCatalog.contract_errors()` para que o comando oficial também falhe se uma origem perder a ficha ou se duas opções passarem a diferir só por números. Não alterado aqui por proibição explícita. | pedido directo deste pacote · fronteira de propriedade |
| 🟠 | **A integração dos seis instrumentos continua a pertencer aos donos de dados/inventário:** o casting já prefere um instrumento secundário compatível e usa transitoriamente o cajado principal `can_cast`, mas os loadouts ainda não equipam os seis itens secundários. Devem consumir `InstrumentCatalog.build_cast_plan()`, classificar o papel de cada feitiço (`direct/support/raise/drain`), restaurar os IDs por escola e guardar o instrumento no slot decidido. Até essa costura, o cajado fecha o loop jogável, mas os seis novos itens ainda não aparecem nele. | `game/src/spells/instrument_catalog.gd` · pergunta 56 · decisão de mão do Mateus |
| 🟠 | **Arte runtime dos instrumentos:** cajado, chama e grimório têm candidatos CC0 declarados na ficha (`staff.gltf`, `torch.gltf`, `spellbook_closed.gltf`), mas ainda têm de ser importados um a um e comparados em captura com o conceito. Sino, talismã, relicário de osso e híbrido **não têm modelo de pack que chegue ao alvo** e precisam de modelação low-poly própria; não se usou “o menos mau”. O dono visual liga attachment/animação e mede FPS/p99 na Iris Xe antes de fechar. | inspecção directa de `art/concept/armas/familias-magia.png` + `art/concept/README.md` |
| 🟠 | **Som runtime dos instrumentos:** as fichas apontam apenas para sons CC0 existentes em `art/audio/` (sino, metal, madeira, livro); continuam fora de `res://` e não tocam no jogo. O dono de áudio importa/deriva as cues sem binários novos e testa se cada compromisso se distingue sem olhar para o ecrã. | quatro perguntas do fio solto · fontes `sound_source` em `equipment.json` |
| ⚠️ | **[TENSÃO] Fórmula do instrumento:** falta aos donos decidir se `instrument_spell_power` substitui o `base_damage` corrente ou se se compõe com ele. **Recomendação `[CODEX]`: substituir `base_damage` pelo resultado da fórmula já escrita em cada feitiço**, porque `spells.json::formula` já usa explicitamente `força_do_instrumento`; conserva uma autoridade e evita contar duas vezes a força. **Alternativa proposta, não adoptada:** compor `base_damage × spell_power` normalizado, preservando o tuning do protótipo, mas mantendo duas fontes para o mesmo dano. Esta árvore deixa todos os instrumentos em 1,0 e não aplica nenhuma das duas. | pergunta 56 · `spells.json::formula` · fronteira do agente `magia-e-vfx` |
| 🟠 | **O perfil de espólio da nova origem falta em `economy.json::class_bias.profiles`.** O guarda de referências exige uma entrada para cada origem activa. Recomendação `[CODEX]`: `evil_mage: arcane`, porque os feitiços/cadáveres são a preferência inicial; alternativa descartada: `martial`, que enviesaria materiais contra a ficha Int/Fé. Não aplicado porque `economy.json` tem outro dono. | guarda `check-data-references.mjs` · fronteira de propriedade |
| 🟠 | **Invocações precisam de render/IA/rede e medição na Iris Xe.** O desenho não tem tecto; `spells.json` conserva apenas o corte de apresentação 8/5/3 por preset, anunciado ao jogador. O dono do render deve provar FPS/p99 a 1080p Mobile nos três casos; o dono da rede continua sem decisão sobre autoridade do invocado. O controlador desta árvore cria zero nós/meshes/draw calls e não fingiu a medição que só existe depois da integração. | Lei 4 · [`52`](spec/52-mago-do-mal.md) §§9–10 |
| 🟠 | **Feedback do Cortejo Carmim ainda precisa do consumidor visual/sonoro.** A habilidade publica `anel_vermelho_de_ordem` e `corrente_curta_e_pulsacao_grave`; a imagem aprovada `art/concept/classes/mago-do-mal.png` é alvo, não asset. O dono de `Sfx` deve sintetizar a cue em código e o dono visual deve desenhar o anel vermelho sem luz/partículas azuis. | quatro perguntas do fio solto · `art/concept/README.md` |
| 🟠 | **A silhueta runtime do Mago do Mal contradiz o conceito aprovado.** Ao abrir a imagem, o alvo é um humano adulto de cabelo solto, rosto gasto, placas de metal/couro ensanguentadas e costuras vermelhas; `character_visual.gd::ORIGIN_OUTFITS.evil_mage` declara `hood_high|robe_torso|cape_long_inverted_taper`. O dono visual deve retirar o capuz alto e aproximar materiais/silhueta sem usar a imagem como asset, depois medir FPS/p99 na Iris Xe. | inspecção visual directa 01-08 · `art/concept/classes/mago-do-mal.png` · ficheiro fora da propriedade |
| ⚠️ | **[TENSÃO] Voto de Sangue:** `spec/53` troca verbos, mas Mateus decidiu +30/+60/+90%. Esta árvore executa a decisão directa e marca a colisão em `spells.json`. **Recomendação `[CODEX]`: manter estes números até o Mateus os substituir explicitamente**, porque adoptar já os verbos reescreveria um `[DECIDIDO]`. **Alternativa proposta, não adoptada:** perfurar/chão em fogo/explodir invocados por camada, se ele preferir resolver a Lei 2 nessa direcção. | `DECISOES.md` 01-08 · [`53`](spec/53-chefes-ritmo-e-o-mago-forte.md) §§4–5 |

#### Instrumentos mágicos — protocolo da referência e construções

Esta documentação fica no `LACUNAS.md`, em vez de criar/alterar um documento de spec que pertence a outra árvore. O mecanismo estudado é o catalisador equipado numa mão; nomes, valores, animações e assets são nossos.

| eles | nós | diferença |
|---|---|---|
| O catalisador vive numa mão e a magia escala por ele | Cajado numa mão principal; sino/talismã/chama/relicário/híbrido/grimório numa secundária; a API publica potência e velocidade vindas do JSON | A fórmula continua `[TENSÃO]`; não copiámos valores nem escondemos a decisão no runtime |
| Trocar catalisador muda a escola/eficácia disponível | Trocar instrumento muda entrega, persistência, origem ou papel do mesmo feitiço | Lei 2: a identidade sobrevive com todos os multiplicadores iguais a 1,0 |
| Classes iniciais enviesam o equipamento, mas não fecham o percurso | Cada uma das sete origens recebe um viés inicial e todas as fichas têm `access_policy:any_origin` | Lei 3 explícita e testada; viés de kit não é bloqueio |
| Duas mãos ocupadas retiram outra defesa | Cajado principal + instrumento secundário deixa o jogador sem escudo | Consequência decidida e exposta como custo da construção, nunca como bónus escondido |

`[CODEX]` — **grimório é o sétimo tipo.** Razão: há sete origens, os seis tipos históricos não chegam a uma opção própria para cada uma e o grimório já aparece no conceito aprovado. Alternativa descartada: repetir um dos seis tipos com outro nome/valor; falharia a construção distinta e enfraqueceria a defesa da Lei 2.

| Origem (só viés inicial) | Instrumento | Opção que abre | Construção |
|---|---|---|---|
| Feiticeiro | Cajado de Vigília | impacto directo passa a linha perfurante | alinhar inimigos em corredores; perde persistência/espalhados |
| Paladino | Sino da Promessa | impacto torna-se pulso persistente | preparar uma zona para o parceiro; perde o impacto imediato |
| Mago do Mal | Talismã de Ferro Morto | só levanta/drena a partir de cadáver | necromante entre os mortos; abdica de dano directo |
| Berserker | Chama de Punho | alcance colapsa num arco a partir do corpo | conjurador corpo a corpo; entra no alcance inimigo |
| Tanque | Relicário de Costela | impacto ancora-se como guarda no chão | controlar passagem; o alvo pode contornar a zona |
| Guerreiro | Nó de Campanha (híbrido) | encaminha dano/apoio/levantar/drenar sem especializar | arma principal + conjuração ampla; não perfura nem ancora |
| Assassino | Grimório de Caça | inscreve o feitiço até o primeiro corpo entrar | emboscada; não acerta no lançamento e substitui a inscrição anterior |

**As quatro perguntas do fio solto — instrumentos mágicos:**

1. **Como usa:** equipa o cajado na mão principal ou um instrumento na secundária e usa a acção remapeável `cast`; não há tecla nova. Cajado + secundário ocupa as duas mãos e **fica sem escudo**.
2. **Como prova:** `instrument_catalog_test.gd` passa **4/4** e cobre 7/7 origens, mutação sem origem, clone que só muda números e planos diferentes para o mesmo feitiço. A suite oficial passou **9745/9745**; a integração ao `Player` está explicitamente acima por pertencer a outro agente.
3. **Arte e som:** conceito aprovado como alvo; três candidatos de modelo CC0 e quatro faltas honestas acima; todas as cues partem dos packs CC0 já em `art/audio/`, sem asset comercial nem caminho absoluto.
4. **Custo no Rico:** catálogo + plano puro acrescentam **0 nós, 0 meshes, 0 luzes e 0 draw calls**. Três medições após `--import`, 10 000 planos cada: **5,621–6,684 µs/plano** (pior observado: 66 837 µs no lote); não se inventa FPS porque esta árvore não mexeu no render. A medição de FPS nasce com os modelos/attachments.

**As quatro perguntas do fio solto — Mago do Mal:**

1. **Como usa:** a ficha escolhe `evil_mage`; feitiços continuam na acção `cast` (`C`/X) e **Cortejo Carmim** usa a acção remapeável `ability` (`V`/Start) para alternar seguir/guardar. A costura ao ecrã/`Player` está explicitamente acima porque esses ficheiros têm outros donos.
2. **Como prova:** `dark_mage_origin_test.gd` cobre sete origens, +14 pontos, escola/traço/habilidade, invocações até ao PV, cadáver gasto, chefe portátil único, comando, descanso e exclusividade chefe/Voto: **18/18**. A cena oficial manteve **9703/9703** depois de `--import`.
3. **Arte e som:** o conceito aprovado fixa silhueta/paleta; cada feitiço já declara cue visual e sonora. O controlador apenas publica eventos; anel e cue do Cortejo serão sintetizados em código pelos donos de visual/Sfx, sem importar binários nem tratar o conceito como asset.
4. **Custo no Rico:** esta entrega lógica acrescenta **0 nós, 0 meshes, 0 luzes e 0 draw calls**; mantém um dicionário por invocado. Não mexe no render, portanto não inventa FPS novo. A medição obrigatória nasce quando a IA/malha consumir os limites visíveis 8/5/3.

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
| 🟠 | **O controlador já liga o ecrã de nível ao descanso, mas a cena não liga o controlador:** `Bonfire` cria `LevelUpScreen`, chama `open_for_current()`, mantém `Sitting_Idle`, não pausa o parceiro e devolve controlo ao fechar; o repro explícito passa esses resultados. `main.gd` continua a executar `_rest_at()` em paralelo e nunca instancia `Bonfire`, portanto o jogador entregue não alcança o ecrã. Não criar tecla global: a acção continua `interact` no descanso. | `game/src/world/bonfire.gd` · `game/src/progression/bonfire_gameplay_repro.tscn` · lacuna 🔴 da cena real acima · [`20`](spec/20-interface.md) |
| 🔴 | **Os acumulados publicados da curva não são o que o runtime cobra:** `680 663` (1→70) e `1 308 518` (71→100) vêm de somar a fórmula sem arredondar parcelas e arredondar só o total. `GameData.level_cost()` aplica `max(1, round(...))` a cada nível; somado, cobra `683 534` e `1 308 517`. O dono de `economy.json`/`game_data.gd` tem de escolher uma única semântica e gerar a tabela/prova 1–100; este ecrã continua a consumir `GameData.level_cost()` para não inventar uma terceira curva. | [`58`](spec/58-fim-do-jogo-ciclos-e-a-curva.md) §2 · [`72`](spec/72-materiais-consumiveis-e-economia.md) §1 · `game/src/autoload/game_data.gd` |
| 🟠 | **As fronteiras antigas falham em saves válidos com slot de arma `null`:** `InventorySystem.load_profile()`/`is_equipped()`, `Player.apply_inventory_state()` e `InventoryMenu` chamam `String(null)`. O Mago do Mal reproduz erros ao nascer e ao abrir a mochila. `EquipmentScreen`/`QuickSlots` usam apenas uma cópia legível com `""` e conservam o `null` canónico no save; os donos das três fronteiras comuns devem aceitar `null` como mão vazia. | `game/src/autoload/inventory_system.gd:265,391` · `game/src/player/player.gd:896` · `game/src/ui/inventory_menu.gd:182-258` · saída de `repro-inicio.tscn` 02-08 |
| ✅ | ~~**Sistema de saves sem uma linha**~~ **RESOLVIDO 01-08** — formato campo a campo, morte sem save-scumming, escrita atómica, recuperação e migração, com código e testes | [`59`](spec/59-saves.md) · `game/src/autoload/save_system.gd` |
| ✅ | ~~**A migração de `sabedoria` não tinha algoritmo**~~ **FECHADO NO CONTRATO** — v2 move o valor para o eixo mágico da origem, repõe o outro na base e prova que não duplicou pontos; implementação entra com `appearance` | [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §7 |
| ✅ | ~~⚠️ **A leitura do mapa tinha de ser decidida antes do traçado**~~ **RESOLVIDO NO CONTRATO 01-08** — vista inclinada a ~40°, só terreno percorrido, andar actual realçado; a escolha zona/mundo continua dos donos sem bloquear a geometria | [`57`](spec/57-mapa-e-minimapa.md) §5 · [`69`](spec/69-catalogo-do-mundo.md) §1 |
| ⏳ | ⚠️ **[PROTO] O runtime de orientação implementa o mapa por zona em Brumal.** Isto permite construir e medir sem decidir a pergunta 38: se os donos escolherem mapa mundial, o bitset por zona continua válido e muda apenas o índice/agregador. Alternativa descartada: um bitset global provisório, porque misturaria escalas e tornaria a migração mais cara | [`57`](spec/57-mapa-e-minimapa.md) · pergunta 38 |
| 🟠 | **As opções de orientação ainda têm de chamar o cliente de mapa.** O runtime já expõe `set_minimap_enabled()` e `set_north_up()` e o aro funciona como bússola; a árvore `casca-do-jogo`, dona de `settings_system.gd`, deve ligar “minimapa desligado” e “norte em cima” sem duplicar estado aqui | [`57`](spec/57-mapa-e-minimapa.md) · integração entre worktrees |
| 🟠 | ⚠️ **A selecção visual da Fatia 1 já está integrada em `game/`; sons e conteúdo posterior continuam apenas em `art/`.** Biblioteca não é runtime: cada asset restante ainda precisa de importação deliberada, orçamento e prova no motor | [`22`](spec/22-assets.md), `game/assets/models/ASSETS.md` |
| 🟠 | ⚠️ **Ligar os produtores restantes ao `SaveSystem`.** Morte de inimigo → almas/inventário/baralho/recibo já é atómica; a exploração por zona do mapa também grava o bitset e os marcos descobertos com rollback. Restam HP zero → mancha, equipamento e UI quando esses clientes forem construídos. O toast já deixou de prometer falsamente que nada se perdeu | [`59`](spec/59-saves.md) · [`57`](spec/57-mapa-e-minimapa.md) · [`72`](spec/72-materiais-consumiveis-e-economia.md) |
| 🔴 | ⭐ **Drop no chão e baús continuam fora do jogo apesar de a fronteira permitida estar pronta.** `WorldPickupManager.setup(world, player, hud, "brumal")` monta os três baús fixos e recebe `present_enemy_reward(receipt, defeated.global_position, snapshot)` no ramo `awarded`; `set_player(player)` conserva ambos depois do respawn. O objeto tem silhueta + feixe + som, usa a ação remapeável `interact`, confirma o recibo já gravado sem duplicar e também suporta recolha pendente via `InventorySystem.add_item()`. O probe arranca `gameplay.tscn` com `user://` isolado e, no percurso de produção, falha honestamente em **`gameplay.tscn nao instancia WorldPickupManager`**. O modo diagnóstico `--inject-pickup-manager` fez a costura proibida só no teste e passou **ataque real → morte → drop → caminhada → `interact` → inventário → acesso rápido → abrir baú fixo**, provando que a fronteira funciona quando ligada, mas não que o jogo já a liga. O dono de `game/src/main.gd` tem de criar/nomear o gestor após mundo+jogador+HUD, encaminhar o recibo e atualizar o jogador no respawn; o dono de `game/VERIFICAR.bat` tem de acrescentar `src/loot/pickup_gameplay_probe.tscn`. Até essas duas ligações, a queixa do Mateus permanece verdadeira e esta funcionalidade NÃO está provada dentro do jogo. | `game/src/world/pickup_manager.gd` · `game/src/loot/pickup_gameplay_probe.tscn` · `game/src/loot/loot_self_test.gd` · propriedade entre worktrees |
| ✅ | ⚠️ ~~**O catálogo de 120 armas não declara peso numérico e `InventorySystem` ignora a arma principal.**~~ **RESOLVIDO 01-08** — `weapons.json::_catalogo_runtime.weapons` dá `peso` explícito aos 120 IDs e `inventory_system.gd::load_profile()` passou a consumi-lo, conservando o fallback data-driven para famílias de escudo; nenhum peso foi duplicado em `.gd` | [`40`](spec/40-decisoes-espolio-magia-inventario.md) §9 · [`68`](spec/68-catalogo-de-armas-armaduras-e-aneis.md) · árvore `acesso-rapido` |
| ✅ | ~~⚠️ **A quarta direcção dependia de `next_item`, que não existe nos dados**~~ **RESOLVIDO 02-08 sem criar tecla:** `controls.json` já declara `hotbar_1`…`hotbar_5`; o HUD descobre esse catálogo, conserva cinco posições estáveis e mostra o binding seleccionado junto de `use_item`. A antiga proposta `[TENSÃO]` de realojar meditação deixa de ser necessária e não foi decidida. | `game/data/controls.json` · `game/src/ui/quick_slots.gd` · `game/src/ui/equipment_screen.gd` |
| 🟠 | **O jogador ainda executa o selector de loadout de teste além da caixa:** `player.gd` consome `loadout_next/loadout_prev` e percorre `weapons.test_loadouts`, enquanto `QuickSlots` consome as mesmas acções depois e repõe o estado persistente da mochila. O resultado final é correcto, mas há duas autoridades no mesmo frame. O dono de `player.gd` deve remover/gatear `_cycle_loadout()` e delegar estas acções a `InventorySystem.cycle_quick_slot`; prova: uma pressão muda exactamente uma mão e não avança `_loadout_index`. | `game/src/player/player.gd` linhas das acções `loadout_*` · propriedade entre worktrees |
| 🔴 | **Só o Frasco de Bruma fecha hoje o circuito de uso:** os cinco atalhos seleccionam a chave completa e `QuickSlots` impede que uma ranhura vazia/outro consumível beba o frasco por engano; o HUD explica “ranhura vazia”/“efeito ainda não ligado”. Porém, `player.gd` continua a tratar `use_item` exclusivamente como `flask`. Bombas, resinas, facas, lanternas e os quatro consumíveis de estado ainda precisam de um dispatcher data-driven, consumo atómico e ligação a `StatusEffectManager`/projectis. A prova integrada viu a recusa visível e o frasco certo ser gasto; não declara os outros feitos. | `game/src/player/player.gd:304,1400` · `game/src/status/status_effect_manager.gd` · prova `quick_slots_gameplay_proof.gd` |
| 🟠 | **Contagem de flechas está preparada mas sem autoridade de dados:** a caixa mostra munição quando a ficha de arma declara `ammo_item_key`; nenhuma arma nem `economy.json` declara hoje esse vínculo/stock. O dono dos dados deve criar IDs de munição, origem de stock e `ammo_item_key` nas armas à distância; sem isso a UI não inventa flechas. | `game/data/weapons.json` · `game/data/economy.json` · Lei 2 |
| 🟠 | **O kit inicial não declara um consumível comum além do frasco:** a normalização garante o recipiente Frasco de Bruma no inventário e a quantidade de usos continua a vir de `combat.json`, mas `weapons.json::loadouts` só declara armas/armadura. `[CODEX]` propõe acrescentar a cada loadout um mapa `starting_items` com IDs e quantidades em dados; razão: diferenças de origem ficam auditáveis e não viram números em `.gd`. Alternativa: um `starting_items` universal em `economy.json`. O dono dos dados tem de escolher o conteúdo/quantidade. | pedido directo do Mateus · `game/data/weapons.json::loadouts` · `game/data/economy.json` |
| 🟠 | ⚠️ **A acção `weapon_art` ainda não existe em `controls.json` nem é tratada por `player.gd`.** As 8 famílias já têm artes diferentes para uma e duas mãos, com mana e compromisso em `weapons.json`, e `WeaponProgression.perform_art()` prova cobrança/recusa; falta o dono dos controlos ligar uma tecla/remapeamento e o jogador emitir a `GameplayCue` devolvida | quatro perguntas do fio solto 1–3 · [`34`](spec/34-catalogo-e-comandos.md) |
| 🟠 | ⚠️ **`limalha_nobre` não existe em `economy.json`.** O altar usa a progressão `[DECIDIDO]` da spec — `limalha_ferro` em +1–+3 e `limalha_nobre` em +4–+6 — mas só o primeiro material tem definição económica. O dono da economia tem de criar fonte/stock/valor antes de activar +4; o UI bloqueia honestamente quando o inventário não declara a unidade | [`68`](spec/68-catalogo-de-armas-armaduras-e-aneis.md) · [`72`](spec/72-materiais-consumiveis-e-economia.md) |
| 🟠 | `[TENSÃO]` **O loadout do Paladino está rotulado como carga leve, mas o kit completo declarado soma 20,5/50 e cai em carga média:** armadura 12 + elmo 2 + escudo 5 + espada 1,5. `[CODEX]` recomenda corrigir o rótulo para média porque preserva os pesos agora explícitos e a Lei 3; alternativa: Mateus/Rico escolherem peças mais leves sem bloquear a espada. Não alterado nesta árvore porque seria decidir uma tensão e mexer em dados `[DECIDIDO]` de loadout | `weapons.json::loadouts.paladin` · [`51`](spec/51-familias.md) |
| 🟠 | ⭐ **Produção M2: construir `TuningRecorder`.** CSV, `tp arena_vorgar`, `latencia`, overlays e fixtures A/B já têm contrato; até existirem, os números dizem **baseline**, nunca “confirmado” | [`63`](spec/63-como-se-afinam-os-numeros.md) · [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §8 |
| 🟠 | ⭐ **A criação descobre as sete origens no catálogo, mas `GameShell.CLASS_ROLES` continua uma lista manual de seis.** O cartão do Mago do Mal cai no fallback `['', '', '']`, portanto “É forte quando” e “Sofre quando” ficam vazios apesar de a origem aparecer. O dono de `game_shell.gd` deve mover estes textos para um catálogo (`attributes.json`/`strings.pt.json`) e lê-los pelo mesmo ID; a prova tem de abrir a criação real, seleccionar `evil_mage` e ver as três linhas preenchidas. | regra “catálogos mandam” · `game/src/ui/game_shell.gd::_update_class_detail()` · decisão da 7.ª origem |
| 🟠 | **Produção WP11: construir o criador.** Ecrã/slots, `appearance.json`, nome, save v2/migração e matriz de origens catalogadas × armas têm contrato e prova de saída | [`64`](spec/64-criacao-de-personagem.md) · [`73`](spec/73-fecho-dos-buracos-de-integracao.md) §§7–8 |
| ✅ | ~~**As origens trocavam o corpo por personagens KayKit completos**~~ **RESOLVIDO 01-08** — masculino e feminino usam sempre o corpo Quaternius/UAL; a origem acrescenta por cima 2–6 peças procedurais presas aos ossos. A pré-visualização encontra o `class_id` no rascunho da casca sem alterar `game_shell.gd`. Sete assinaturas geométricas únicas foram vistas a 30 m; `lei4` na Iris Xe, Mobile/1080p sem VSync: 106,2 fps médios, p99 14,942 ms, 58 draws, quatro picos >20 ms. `[CODEX]` Razão: corpo humano vestido já, sem fingir compatibilidade entre rigs; alternativa descartada: KayKit completo como fato. | `game/src/visual/character_visual.gd` · decisão directa do Mateus, 01-08-2026 |
| 🟠 | **Faltam as malhas finais UAL das 11 peças e os dois conjuntos de voz.** O acervo não contém roupa modular compatível com os 65 ossos; peitorais, capas, botas, máscara e ombreiras são geometria simples honesta. O agente de armaduras deve substituir cada placeholder pelas peças finais através de `get_equipment_skeleton()`, `attach_equipment_to_bone()` e `clear_generated_origin_outfit()`, sem reinstanciar o corpo. | conteúdo exigido pelo [`64`](spec/64-criacao-de-personagem.md) · passagem para a árvore `armaduras` |
| 🟠 | **O `repro-inicio` ainda não guarda a regressão KayKit/Quaternius.** Esta árvore só possui `character_visual.gd`; o dono de `game/src/tests/repro_inicio.gd` deve chamar `CharacterVisual.outfit_contract_errors(GameShell.CLASS_IDS)` e, para cada origem/corpo, confirmar `uses_quaternius_body()` e que `get_body_source_path()` fica sob `characters/quaternius/`. O repro corrente abre e limpa os seis saves, mas não instancia/inspecciona cada visual. | pedido directo do Mateus, 01-08-2026 · integração entre worktrees |
| 🟠 | **A decisão “jogáveis são humanos adultos Quaternius vestidos” ainda não aparece no `DECISOES.md` desta worktree**, embora o prompt de execução diga que está no topo de 01-08. Integrar o registo da árvore que o possui antes do merge para a autoridade não ficar só no código/prompt. O perfil da 7.ª origem reserva o ID técnico `evil_mage`; a árvore que acrescenta a origem aos dados deve confirmar esse ID ou renomeá-lo no mesmo merge. `[CODEX]` Razão: deixar já uma silhueta coberta para a origem decidida; alternativa descartada: inventar a ficha de dados fora da árvore dona. | `DECISOES.md` desta worktree, verificado 01-08-2026 |
| 🟠 | **Produção WP12/15: o catálogo e `MusicDirector` estão construídos; falta montar e fechar o `AudioDirector` de SFX.** `audio_catalog.json` inventaria 182 OGG/181 candidatos, preserva os cinco sliders, declara silêncio musical honesto e dá estados/crossfades/co-op a música + ambiente; 72 provas focais passam e uma rajada nunca excede duas streams. O dono de `project.godot`/cena tem de instanciar `MusicDirector`; o dono da automação deve invocar `music_self_test.gd` à parte ou levar as verificações equivalentes ao auto-teste global. A reserva efectiva de 8 `GameplayInfo`, o tecto/stress de 24 SFX e a selecção Kenney continuam no `AudioDirector`/`sfx.gd`, fora desta árvore. | [`65`](spec/65-musica-e-ambiente.md) · `game/data/audio_catalog.json` · `game/src/audio/music*.gd` · `game/src/autoload/sfx.gd` |
| ✅ | ~~**Volumes separados ainda sem fronteira runtime**~~ **RESOLVIDO 01-08** — o menu já expunha Geral/Música/Efeitos/Ambiente/Vozes; `Sfx.volume_bus_contract()` expõe a árvore interna e cada som novo usa o pai correcto, sem alterar o menu | `game/src/autoload/sfx.gd` · [`20`](spec/20-interface.md) |
| 🟠 | **Integração de mundo: as camas distintas de Brumal/Toca e a fogueira segura existem, mas ainda não são alcançáveis a jogar.** O integrador deve: (1) em carregamento chamar `MusicDirector.preload_zone(zone_id)`; (2) ao devolver controlo chamar `enter_zone`; (3) IA chama `set_combat_active` só em `ALERT/AGGRO`; (4) fogueira chama `enter_rest`/`leave_rest`; (5) arena chama `begin_boss`/morte/vitória com `event_id` autoritativo. Antes de montar, o dono de `sfx.gd` tem de retirar ou delegar `_start_brumal`, senão Brumal toca por cima da Toca. Música continua a zero ficheiros por causa da pergunta 34; `[CODEX]` conserva silêncio em vez de fingir composição com os SFX Kenney. | `game/src/audio/music_director.gd` · `game/src/autoload/sfx.gd` · [`65`](spec/65-musica-e-ambiente.md) · pergunta 34 |
| 🟠 | **Mochila: consumir os ícones das oito famílias.** Os SVG 32×32 e `WeaponFamilyIcons.texture_for(family_id)` já vivem em `game/assets/ui/`; `inventory_menu.gd` ainda só chama `ItemList.add_item(texto)` e pertence ao agente de UI, por isso esta árvore não o alterou | `game/assets/ui/weapon_family_icons.gd` · `game/src/ui/inventory_menu.gd` |
| 🟠 | **Documentação fora da árvore de som precisa de sincronização.** `ESTADO.md` §1/§1h ainda diz “17 sons”, “Master” e “zero loop” e não conhece `audio_catalog.json`/`MusicDirector`; o catálogo visual do `art/MANIFESTO.md` continua sem secção de proveniência áudio. Esta árvore não lhes mexeu por pertencerem a outros agentes. | `ESTADO.md` · `art/MANIFESTO.md` · `game/data/audio_catalog.json` |
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
| ✅ | ~~**Integração da Toca modular espera o dono de `greybox.gd`.**~~ **RESOLVIDO 02-08** — `IntegratedWorld` substitui `_build_lair()` pela instância de `Lair`, alinha entrada/descanso/arena pelos anchors e acrescenta as rotas antes da dispersão da floresta. O povoamento lê todos os marcadores e resolve o papel pelo catálogo; a cena real exige módulos, colisões e um inimigo em cada encontro. | `game/scenes/integrated_world.gd` · `game/src/main.gd` · prova integrada |
| 🟠 | **Brumal cresceu do greybox de 2–3/4–6 min para uma travessia catalogada de 8 min.** O nível actual tem de ganhar círculos horizontal/vertical, atalho por dentro, segundo descanso e densidade sem virar corredor; só fica confirmado depois de cinco corridas medidas em ambas as perspectivas | [`10`](spec/10-fatia-1.md) · [`53`](spec/53-chefes-ritmo-e-o-mago-forte.md) §3 · [`69`](spec/69-catalogo-do-mundo.md) §3.1 |
| 🟠 | **As 30 portas são malha estática e escrita, não conteúdo futuro construído.** Quando uma for promovida, precisa de novo `Fatia 1?`, orçamento, destino e revisão da promessa; hoje nenhuma entra na primeira fatia | [`69`](spec/69-catalogo-do-mundo.md) §4 |

---

## 🔵 Quando houver tempo

| | Lacuna | Origem |
|---|---|---|
| ✅ | ~~**`[CODEX]` O céu/luz novo ainda não entra no nível.**~~ **RESOLVIDO 02-08** — o adaptador do mundo delega `WorldEnvironment` e `Sun` a `EnvironmentAtmosphere`; o teste arranca Brumal e exige céu + nevoeiro visíveis fornecidos por essa fábrica. | `game/scenes/integrated_world.gd` · `game/src/visual/environment_atmosphere.gd` · prova integrada |
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

### ⭐ Gramática de ataque por raça — protocolo do [`31`](spec/31-referencias.md)

**Data de corte e consulta:** 01-08-2026. A comparação usa estruturas e números
observáveis; não entram nomes, animações, sons ou tabelas extraídas dos jogos.

| Foco | Eles — DS2/DS3 | Nós antes desta árvore | Diferença / nossa versão |
|---|---|---|---|
| **Fim do combo = janela** | A decomposição de DS3 separa pose final e regresso: a pose final encadeia ou regressa, e o regresso é normalmente a janela de oportunidade, a fase mais longa ([Game Developer, 31-05-2022](https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3)) | O motor já aplicava `gap_between_patterns`, mas 31 dos 33 comuns não tinham `patterns`; por isso nunca chegavam a um fim de combo definido | Os 33 comuns têm agora **4–6 padrões finitos** e pausa obrigatória de **0,95–2,65 s**. O jogador usa o regresso ao estado de perseguição como a janela; não existe cadeia infinita |
| **Comprimentos diferentes** | Uma análise de DS3 observa variações do mesmo combo; conta 2–3 golpes nos jogos anteriores e 3–5, por vezes 6–7 em chefes, mas também documenta o risco de stunlock quando as cadeias roubam a resposta ([Game Developer, 18-04-2016](https://www.gamedeveloper.com/design/the-successes-and-failures-of-dark-souls-3-s-design)) | Os dois únicos comuns preenchidos tinham quase só padrões de um golpe; os restantes caíam no ataque simples | Rápidos alternam sequências de **1/2/3 ataques**; zombies, minotauros e outros pesados ficam sobretudo em **1/2** para preservar o esgotamento legível. O mímico do naufrágio guarda uma única cadeia de 3 atrás de 2 s de pausa. Vorgar alterna 1–3 por fase. A diferença é intencional: copiamos a incerteza, não as cadeias de 6–7 que a própria análise critica |
| **Falsa recuperação** | Uma ficha pública de DS2 regista uma cadeia de três golpes que pode parar **1–2 s** e ainda acrescentar dois; a análise de DS3 mede a pose final usada como isco em **≥240 ms** e exige tempo para confirmar um fim verdadeiro ([DS2 Wikidot](https://darksouls2.wikidot.com/fume-knight) · [Game Developer, 31-05-2022](https://www.gamedeveloper.com/game-platforms/anatomy-of-an-enemy-attack-in-dark-souls-3)) | `bone_rattle` já declarava `false_recovery.optional_followup`, mas `enemy.gd` ignorava o campo | A decisão é feita antes do aviso; em 20% das variantes, se o jogador entrar a ≤2,0 m, a guarda alta encadeia `rib_sweep`. O follow-up conserva aviso visual e som próprios. A recuperação verdadeira baixa a arma, conforme a ficha; a pose exacta ainda depende da ligação visual registada abaixo |
| **Raça, não tinta** | DS3 diferencia silhueta/equipamento até dentro da mesma espécie; a leitura antecipa capacidades ([Game Developer, 18-04-2016](https://www.gamedeveloper.com/design/the-successes-and-failures-of-dark-souls-3-s-design)) | Existiam 12 raças e 105 ataques completos, mas a ordem temporal era a mesma lista vazia em 31 fichas | Goblins repetem e recuam (**0,95–1,20 s**); kobolds armam terreno e fogem (**1,55–1,70 s**); esqueletos quebram a cadência e fintam (**1,15–1,45 s**); zombies terminam golpes pesados e respiram (**2,10–2,40 s**); minotauros ligam carga/pisada e esgotam (**2,25–2,65 s**). Tecelões, submersos, ventaneiras, penitentes, mímicos, borralheiros, sem-rosto e os cinco orcs têm sequências próprias, não uma cópia por cor |

`[CODEX]` **Padrões, pausas e dano por ataque (01-08-2026):** cada ficha comum
recebe 4–6 padrões finitos, comprimentos variados e uma pausa racial; os **105
ataques** passam a declarar `damage` próprio, consumido directamente pelo runtime.
Razão: a identidade de combate precisa de ordem, repouso e consequência próprios,
não apenas de três animações escolhidas ao acaso. Alternativa descartada: gerar os
padrões em `.gd` a partir do papel (`rapido/pesado/distancia`); reduziria JSON, mas
voltaria a fazer espécies diferentes lutar com a mesma gramática e esconderia
números de combate no código.

**As quatro perguntas do fio solto:**

1. **Como usa o jogador?** Não há tecla nova. Lê a pose/som, escolhe entre esquiva, parry, bloqueio ou movimento já existentes e ataca durante o regresso; aprende também que uma guarda óssea ainda alta não é o mesmo fim que uma espada baixa.
2. **Como se prova?** `Enemy.attack_grammar_contract_errors()` percorre as 34 fichas no primeiro `setup` e a asserção falha se faltar um padrão/pausa, se só existir um comprimento, se um padrão apontar para golpe inexistente, se faltar dano próprio ou se quaisquer dois dos 105 ataques repintarem o número. Também recusa golpes ausentes da gramática e qualquer golpe sem compromisso, curva de seguimento, vector de fuga da lista de nove, som ou equivalente visual. Na prova negativa, esvaziar temporariamente `goblin_mist_scout.patterns` produziu cinco falhas de guarda, interrompeu todos os `setup` antes de `_build_body()` e a cena Godot terminou com **exit 1**. O agregado ficou em **9703/0**.
3. **Arte e som?** Zero binários novos. Todos os ataques já declaram `som_anuncio` e equivalente visual; `EnemyAttackAudio` sintetiza uma assinatura 3D por raça+inimigo+ataque. Cada follow-up volta a anunciar-se. Modelos/animações continuam nos packs já importados.
4. **Quanto custa no Rico?** Sem malhas, partículas ou sons em disco novos. O custo novo é uma escolha numa lista curta por combo; a validação única dos 105 ataques/34 fichas no primeiro spawn mediu **3,978 ms**, isolada com `Time.get_ticks_usec()` e removida depois da medição. A cena aquecida com cinco inimigos terminou em **5,849 s** e o passe final do agregado de 9703 verificações em **5,000 s**; estes dois são tempos de processo completo. Não se atribui aqui um FPS novo porque esta árvore não alterou o renderer.

| Estado | Lacuna fora da posse desta árvore | Fronteira pronta |
|---|---|---|
| 🟠 | **A pose exacta da falsa recuperação ainda não é apresentada pela animação genérica.** A ficha distingue `guarda ossea alta` de espada baixa, mas `enemy_visual.gd` só mapeia o semântico geral `Sword_Attack`. Não foi alterado porque a arte dos inimigos pertence a outro agente | `enemy.gd` escolhe a variante antes do tell e executa `optional_followup`; o dono visual deve mapear `false_recovery.readable_pose` para uma pose existente ou sintetizada e provar as duas silhuetas em 1.ª/3.ª pessoa |
| 🟠 | **O agregador alheio ainda não chama a guarda pura da gramática.** `self_test.gd` está fora da posse desta árvore; por isso o seu contador pode ficar verde com um padrão apagado até uma cena criar o primeiro `Enemy` | O dono do agregador deve passar `GameData.enemies` a `Enemy.attack_grammar_contract_errors()` e contar a lista vazia como uma verificação. A cena com inimigos já falha com exit 1 e a prova negativa cobre esta fronteira |
| 🟠 | **A guarda de coerência já parte de `HEAD` com dois links ausentes em `MAPA.md`.** Faltam *(um registo de sessão privado, gitignored)* e *(um registo de sessão privado, gitignored)*; não pertencem a esta árvore | `node tools/check-coerencia.mjs` verificou **19 JSON e 3066 contratos com 0 erros** antes de reportar apenas esses dois links preexistentes |

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
| ✅ | ~~**`BoundsSelfTest` ainda corre fora do gate central.**~~ **RESOLVIDO 02-08** — `scenes/selftest.tscn`, a cena já chamada por `VERIFICAR.bat`, carrega o módulo e executa `run_suite()` antes do resto. As três faixas contam agora no resultado agregado **9764/9764**. | `game/scenes/selftest.tscn` · `game/scenes/selftest_integrated.gd` |
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
2. **Como se prova:** `attack_family_self_test.gd` abre `gameplay.tscn`, usa `move_right` e `dodge_sprint` e observa a barra de vida real; exige 10/10 falhas laterais sem dano, 10/10 esquivas certas sem dano e 10/10 golpes recebidos nas esquivas cedo/tarde. A comparação tautológica foi removida. ⚠️ **A passagem histórica de 177/177 deixou de contar depois do merge:** um bytecode antigo de `Main` escondia o erro de compilação actual. O teste arranca agora a cena durante dois frames num Godot novo e falha honestamente **170 passaram, 1 falhou** antes dos controlos enquanto `ArenaVorgar` não compilar. `weapon_attach_self_test.gd` mantém os seus **42/42**.
3. **De onde vêm arte e som:** props de arma são KayKit Skeletons CC0 já em `game/assets/models/enemies/kaykit-skeletons/props/`; corpo/esqueleto/clips-base são Quaternius Universal Animation Library CC0 já importados. As curvas adicionais são sintetizadas em GDScript, sem binário novo. O som continua a usar `swing_light`/`swing_heavy` sintetizado já chamado pelo `Player`; não foi inventado nem copiado som comercial.
4. **Quanto custa na máquina do Rico:** Intel Iris Xe, Mobile/Vulkan, 1920×1080, sem VSync, 3 s de aquecimento + 10 s. Um corpo: base **291,4 fps / 3,432 ms**, p95 5,408 ms, p99 10,705 ms; espada+escudo **245,0 fps / 4,081 ms**, p95 7,201 ms, p99 10,259 ms. Custo observado: **+0,649 ms médios, +2 draws, +957 primitivas e +4,0 MiB VRAM**; p99 fica abaixo de 16,67 ms. Stress de cinco corpos armados deu 184,3 fps numa passagem e 93,8 fps noutra enquanto um render de outro agente estava activo; não se usa essa variação como delta causal. A geometria honesta foi ainda medida durante 30 s na Lei 4: **97,8 fps médios, p95 21,129 ms, p99 27,782 ms, 119 draws e 278 409 primitivas**. O p99 falha 16,67 ms e havia quatro sessões Godot longas de outras árvores activas; a amostra fica registada como contaminada e exige repetição limpa, nunca como aprovação.

### Ligações que pertencem a outros donos

| Estado | Trabalho fora desta árvore | Fronteira pronta |
|---|---|---|
| 🔴 | **O dono de `game/src/player/player.gd` tem de instanciar os dois componentes depois de `_visual.setup()`.** Criar `WeaponAttach.new()` e `AttackAnimationController.new()`, adicioná-los ao `Player` e chamar `setup(self, _visual)`. Não é preciso alterar `_refresh_animation()`: o controlador já vence a chamada genérica e sincroniza pelo `state_frame` | `game/src/visual/weapon_attach.gd` · `game/src/player/attack_animation_controller.gd` |
| 🔴 | **O golpe em corrida ainda precisa de mecânica espacial.** Capturar que o ataque começou em sprint e consumir `golpes_universais.em_corrida.avanco_m`/a ficha familiar durante o golpe; hoje `_tick_attack()` trava o corpo. Não pôr esse número em `.gd` | `game/src/player/player.gd::_start_attack/_tick_attack` · `game/data/weapons.json` |
| 🔴 | **O dono de `game/VERIFICAR.bat` tem de incorporar o contrato de famílias/geometria no corredor obrigatório.** Enquanto isso, a prova real corre isolada com `--script res://src/player/attack_family_self_test.gd`; `VERIFICAR.bat` ainda pode passar sem executar os controlos 10/10, portanto o fio não se declara fechado. | Acrescentar `"%GODOT%" --headless --audio-driver Dummy --path . --script res://src/player/attack_family_self_test.gd || set FALHOU=1` e actualizar a contagem das etapas · ownership paralelo |
| 🔴 | **O merge da arena deixou o jogo sem compilação limpa:** `ArenaVorgar` declara `_active_sequence` e `_sequence_frame` duas vezes. `--import` termina com código 0 mas imprime a falha; `arena_vorgar.gd --check-only` termina com código 1; o auto-teste ainda anuncia 9764/9764 porque reutiliza bytecode anterior. | O dono de `game/src/world/arena_vorgar.gd` deve reconciliar os blocos concorrentes nas linhas 77–84. A prova de geometria não volta a aceitar o verde até `gameplay.tscn` arrancar sem `SCRIPT ERROR`. |
| ⚠️ | **Incidente de saves durante a primeira passagem vermelha:** antes do isolamento técnico, a queda do motor levou `Main._exit_tree()` a substituir `slot_00.json`/`.bak`; o perfil anterior observado era `filme-warrior` e não pôde ser recuperado. Os ficheiros `geometry-proof` foram removidos só depois de validar o perfil. | A prova final usa exclusivamente o slot técnico 99, valida `profile_id=geometry-proof` antes de apagar e confirmou que não deixa `slot_99`; os slots 0–2 nunca voltam a ser alvo deste ensaio. |
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

## 🔴 Do Mateus a jogar — 01-08 fim do dia

| | Lacuna | Prova |
|---|---|---|
| ✅ | ~~⭐ **A magia era uma esfera azul sem sinais de lançamento ou impacto.**~~ **RESOLVIDO 02-08** — `spell.gd` ficou apenas como fronteira de dano; a entrega residente mostra clarão no foco do cajado, núcleo com rasto e impacto. A escola `mal` acrescenta queda e veios escuros. A cena jogável prova os sinais e o dano de Dardo e da primeira entrega vermelha ofensiva lida do catálogo | `game/src/vfx/` · `game/src/spells/spell_game_integration.tscn` |
| 🔴 | ⚠️ **A armadura do jogador são caixotes.** Cubos castanhos colados ao torso e às pernas do corpo Quaternius. **É pior do que não ter armadura** | captura `01-spawn-3a-pessoa.png` de 01-08 |
| 🔴 | ⭐ **O kit inicial existe nos dados e nunca chega ao jogador.** `weapons.json` tem `loadouts` e `armor.json` tem `pieces`; **nenhuma linha de código os concede**. Procurado: `starting_items`, `grant_starting`, `equip_starting` — nada | dono: agente `kit-e-morte` |
| 🔴 | ⭐ **A 7.ª origem não existe.** O Mago do Mal está `[DECIDIDO]` (Mateus, 01-08) e `attributes.json` tem **seis** classes | dono: agente `mago-do-mal` |
| 🟠 | ⚠️ **Alvos visuais gerados para a magia** em `art/concept/magia/` — dardo a sair do cajado, impacto, e a escola vermelha. São o alvo, não o asset | `art/concept/README.md` |
---

## 🧪 Kit inicial e morte repetida — prova desta árvore (01-08-2026)

### Verdade encontrada

- ✅ **O kit já está ligado no `main` recebido:** `SaveSystem.create_save()` materializa arma, offhand e peças; `InventorySystem.normalise_current()` completa frasco, favoritos e ranhuras ao entrar no mundo. A cena nova provou as seis origens e, no jogo real, o Assassino com duas adagas, magia e frasco visíveis.
- ✅ **Não foi reproduzido defeito em `main.gd:311–333`:** duas mortes consecutivas completam o fade, regressam ao lado da fogueira em vez do ponto da queda, repõem vida/frascos, reactivam o inimigo derrotado e gravam uma segunda sequência. O guarda `_respawning` é libertado.

### As quatro perguntas do fio solto

1. **Como usa o jogador:** entra no mundo com o kit já equipado; `loadout_next`, `loadout_prev`, `next_spell` e `use_item`, todos remapeáveis, operam as quatro ranhuras existentes.
2. **Como se prova:** `game/src/tests/kit_respawn_integration.tscn` executa 55 verificações sobre as seis origens e duas mortes reais; 55/55 passaram.
3. **De onde vêm arte e som:** a prova reutiliza a caixa existente, modelos CC0 já importados e os sons sintetizados já carregados pelo jogo; não acrescenta arte, áudio ou binário.
4. **Quanto custa na máquina do Rico:** zero custo no runtime, porque esta árvore só acrescenta a cena de teste. Não houve mudança de render, logo não se atribui nem inventa um delta de FPS.

### Ligação que pertence ao dono de `game/VERIFICAR.bat`

| Estado | Trabalho fora desta árvore | Alteração exacta |
|---|---|---|
| 🔴 | **Incluir a cena nova no corredor obrigatório.** A posse desta árvore permite `game/src/tests/`, mas proíbe alterar `game/VERIFICAR.bat`; por isso a ordem “um teste que ninguém corre não é um teste” fica aberta para integração. | Em `game/VERIFICAR.bat:49`, antes da guarda da spec, acrescentar `"%GODOT%" --headless --audio-driver Dummy --path . src/tests/kit_respawn_integration.tscn || set FALHOU=1`; mudar os seis rótulos `N/6` para `N/7` e a guarda actual de `6/6` para `7/7`. |
| 🟠 | **A guarda encontra uma `[TENSÃO]` sem registo no índice de perguntas.** Esta árvore não possui a spec e não decide a tensão. | O dono de `spec/75-artes-de-arma-e-movesets.md` deve referir a tensão em `spec/99-perguntas-abertas.md`, preservando proposta, razão e alternativa até decisão do Mateus. |
| 🟠 | **As cenas que instanciam `Gameplay` deixam instâncias Godot no fecho headless.** A cena anterior `repro-inicio.tscn` termina verde com `10 ObjectDB instances were leaked`; a nova reduz para 6 depois de esperar a libertação do mundo/áudio, mas não elimina a dívida. Não altera o resultado dos testes. | O dono do ciclo de vida de `main.gd`/visuais/áudio deve localizar as seis instâncias com uma sonda dedicada; não esconder o aviso nem libertar nós de jogo a partir do teste. |

| ✅ | ~~⭐ **O instrumento do Mago do Mal fica em aberto**~~ **RESOLVIDO 01-08** — Mateus decidiu talismã na mão secundária, com cajado na principal. A execução do catálogo continua com o agente `instrumentos`, indicada abaixo; esta linha deixa de fingir que a escolha ainda espera decisão | `DECISOES.md` 01-08 · `game/data/weapons.json` `loadouts.evil_mage` |

---

## 🪄 Ataque que conjura — comparação, prova e ligações alheias (01-08-2026)

### Protocolo do [`31`](spec/31-referencias.md): eles · nós · diferença

| Foco | Eles — mecanismo observado | Nós antes desta árvore | Diferença e nossa versão |
|---|---|---|---|
| **Acção** | O manual oficial exige um catalisador numa das mãos; depois de seleccionar a magia, usa-se o botão da mão que segura o catalisador. [Manual web oficial da FromSoftware](https://www.fromsoftware.jp/manual/darksouls3/ps4/action2.html) | `attack` dava sempre pancada e `cast`, de fábrica em C/X, conjurava por um caminho separado | `attack` passa a chamar a acção primária contextual: instrumento secundário activo + mana lança o feitiço; `heavy_mod` ou duas mãos dá a pancada. Copia-se a relação **instrumento → ataque da mão**, não botões, nomes, valores ou animações |
| **Sem recurso** | O mesmo manual declara que magia exige FP e não pode ser usada sem ele | `_start_cast()` recusava silenciosamente; a pancada só existia porque o jogador tinha de conhecer outro botão | Diferença intencional pela Lei 1: no próprio `attack`, mana insuficiente inicia a pancada e `state_name()` expõe **“pancada: mana insuficiente”** ao HUD; a barra de magia já mostra `MANA INSUFICIENTE` |
| **Fonte de escala** | O dano combina o `Spell Buff` do catalisador usado com o valor de movimento do feitiço. [Investigação comunitária verificável](https://darksouls3.wikidot.com/spell-buff) | `spell.gd::_damage_for()` usa só atributos + `spells.json`; o cajado/instrumento não chega à fórmula runtime | `[CODEX]` o instrumento secundário continua a ser a fonte preferida porque paga o custo decidido de abdicar do escudo; o cajado principal é apenas o fallback transitório dos kits actuais. `Player` transporta ID/`spell_power`, mas a fórmula numérica continua por decidir pelos donos — não se improvisou um multiplicador |
| **Mãos** | O catalisador pode viver à esquerda ou à direita e cada mão conserva a sua acção | Só o cajado principal tinha `can_cast`; não havia instrumento secundário executável | A assimetria é intencional e `[DECIDIDO]` (Mateus, 01-08): cajado principal + instrumento secundário; ao passar a duas mãos, a secundária deixa de estar activa e o mesmo `attack` volta à pancada |

### As quatro perguntas do fio solto

1. **Como usa o jogador:** selecciona o feitiço por `next_spell` e usa a acção remapeável `attack`; `heavy_mod`/duas mãos escolhe pancada, e mana insuficiente faz a pancada de recurso. `cast` em C/X fica apenas como alternativa transitória enquanto a ajuda antiga ainda existe.
2. **Como se prova:** contrato headless isolado, pela fronteira pública `use_primary_attack()`: **2/2** — instrumento secundário + mana → `CASTING`; zero mana → `ATTACK` com a razão exposta. No mesmo processo, o auto-teste central manteve **9703/9703**.
3. **De onde vêm arte e som:** nenhum asset novo. A conjuração conserva a apresentação do agente `magia-e-vfx`; a pancada reutiliza animação de ataque e `swing_light`, sintetizado por `Sfx` em código. A razão aparece no HUD textual existente.
4. **Quanto custa na máquina do Rico:** **0 nós, 0 malhas, 0 materiais, 0 luzes, 0 partículas e 0 chamadas por frame novos**. Há uma procura no pequeno catálogo de instrumentos apenas quando `attack` é consumido; não houve alteração de render, portanto não se inventa delta de FPS.

### Ligações que pertencem a outros donos

| Estado | Trabalho fora desta árvore | Fronteira pronta |
|---|---|---|
| 🔴 | **O ecrã de instruções ainda diz `Ataque leve` e `C/X Conjurar`; o `SpellHud` também imprime a dica antiga.** O dono de `game_shell.gd`/`spell_hud.gd` deve passar a anunciar “atacar / conjurar com instrumento” e a pancada alternativa, sempre lendo o binding actual como manda a regra 5 do [`45`](spec/45-controlos-configuraveis.md) | `controls.json::_nota_cast` fixa a semântica; `Player.use_primary_attack()` é a única fronteira de execução |
| 🔴 | **A fórmula runtime ainda ignora o instrumento.** O dono de `game/src/combat/spell.gd` deve consumir `_instrument_id`/`_instrument_spell_power` ou a fronteira equivalente depois de os donos fecharem se a fórmula do instrumento substitui o `base_damage`. Não decidir essa pergunta por um multiplicador improvisado | `_cast_spell` transporta a identidade e a força declarada do instrumento; nenhum número foi hardcoded |
| 🔴 | **O catálogo recebido ainda só tem `cajado` em `magic_instruments`, com `slot:main_hand`; não existe talismã secundário executável nesta árvore.** O agente `instrumentos` deve fornecer o `weapon_id`, `school_tags` e `slot:off_hand` decididos | `_secondary_instrument_for()` aceita a chave do instrumento ou o seu `weapon_id`, sem depender de um nome concreto |
| 🔵 | **O dono de `game/src/tests/self_test.gd` deve tornar os dois resultados parte do gate central:** `attack` com instrumento+mana lança; o mesmo `attack` sem mana bate e explica a razão. O teste isolado 2/2 não é substituto de uma regressão obrigatória | fronteira pública `use_primary_attack()`; sem mock de colaboradores internos |
| ⏳ | ⭐ **O instrumento do Mago do Mal fica em aberto.** O [`52`](spec/52-mago-do-mal.md) §10 diz que a **escolha de instrumento é livre**, mas hoje só o `cajado` tem ficha 1,0 — os outros cinco estão declarados e não existem. O kit inicial dele arranca com cajado por ser o único jogável. **Um instrumento próprio (osso, talismã) é decisão do Mateus** | `game/data/weapons.json` `loadouts.evil_mage` |

---

## ☠️ Corpos levantados — entrega da árvore `necromancia` (01-08-2026)

### As quatro perguntas do fio solto

1. **Como usa o jogador:** mata um inimigo, deixa o corpo visível no chão, percorre os favoritos com a acção remapeável `next_spell` (F/d-pad cima por defeito) até **Levantar** ou **Erguer Guardião** e conjura com `cast` (C/X-quadrado). O runtime escolhe o corpo elegível mais próximo, dentro do alcance e à frente do jogador. `ability` (V/Start-Options) alterna todos os levantados entre seguir o necromante e guardar o chão. A pré-validação pública impede consumir corpo ou reservar PV antes do commit.
2. **Como se prova:** `necromancy_runtime_self_test.tscn` passa **16/16**: morte→corpo único/visível, claim atómico entre dois necromantes, pré-validação sem efeito, consumo/libertação do corpo, aliado materializado, barra máxima, ausência de fogo amigo, dono/autoridade separados, caminhada lenta, golpe/resposta hostil, commit com C, ordem com V, interrupção, descanso sem cura e limpeza na morte. `dark_mage_origin_test.gd` passa **18/18**, incluindo chefe portátil, ausência de tecto, três camadas e a exclusividade pelo PV. O agregado oficial manteve **9703/9703**.
3. **De onde vêm arte e som:** o cadáver conserva o modelo do inimigo que caiu; o levantado reutiliza a sua malha, ataques e tells. O conceito aprovado `art/concept/inimigos/peregrino-caido.png` orienta a postura inclinada, passo lento, dessaturação de podridão e leitura “errada”; aro, halo e fios vermelhos são geometria/material sintetizados. Os cues de levantar e dar ordem são PCM de 16 bits sintetizado em código e cacheado, sem binário novo.
4. **Quanto custa na máquina do Rico:** Iris Xe, Vulkan Mobile, 1920×1080, VSync desligado, 2 jogadores + 5 inimigos com rig/IA/tells reais e o mesmo modelo/IA do levantado. O benchmark neutraliza apenas o dano recebido para conservar todos animados e inclui a procura contínua de alvo. Esta máquina tem i7-1255U e 16 GiB; é a GPU-alvo, mas ainda se deve repetir no aparelho final se tiver 8 GiB e com arte final.

| Levantados | Actores animados | FPS médio | ms médio | p95 | p99 | Draw calls |
|---:|---:|---:|---:|---:|---:|---:|
| 0 | 7 | 330,0 | 3,031 | 5,169 | 6,717 | 72 |
| 3 | 10 | 313,3 | 3,192 | 4,902 | 6,210 | 97 |
| 5 | 12 | 308,4 | 3,242 | 5,659 | 6,821 | 123 |
| 8 | 15 | 278,7 | 3,588 | 6,166 | 8,069 | 162 |
| 12 | 19 | 246,5 | 4,056 | 7,703 | 9,686 | 225 |
| 19 | 26 | 254,7 | 3,926 | 7,659 | 9,899 | 325 |

De 7 para 26 actores — os 19 corpos pequenos matematicamente alcançáveis antes de o orçamento visível de PV impedir o seguinte — a memória estática passou de 85,9 para 90,6 MiB e a VRAM de 75,5 para 76,7 MiB. O p99 de 9,899 ms ficou abaixo dos 16,67 ms. FPS médio não é monotónico por ruído de agenda, mas draws, primitivas e memória crescem com a carga. Portanto, **esta medição não justifica o antigo máximo de oito actores e não foi introduzido qualquer tecto silencioso**.

Havia dezenas de processos Godot de árvores paralelas na máquina. Uma primeira passagem contaminada mediu baseline p99 16,702 ms e 19 levantados p99 18,655 ms; depois de a actividade CPU estabilizar, a comparação emparelhada 19→0 deu 9,899→6,717 ms e a série acima. O pior resultado não é escondido, mas também não pode ser atribuído à necromancia porque o próprio baseline falhou. Os números não autorizam extrapolar para modelos finais mais pesados e o gate final continua a exigir repetição sozinho no hardware do Rico.

### Decisões `[CODEX]` propostas, não `[DECIDIDO]`

- `[CODEX]` **Corpo mais próximo, à frente e dentro do alcance.** Razão: transforma Levantar numa acção existente e rápida, sem acrescentar tecla nem menu durante combate. Alternativa: retículo dedicado ou lista de cadáveres; fica disponível se o teste com dois corpos próximos mostrar selecção ambígua.
- `[CODEX]` **Silhueta original apodrecida, inclinada e marcada a vermelho.** Razão: o jogador reconhece que criatura levantou e conserva a leitura dos seus ataques, enquanto a postura/cor/material a separam imediatamente de um hostil vivo. Alternativa: modelo morto-vivo único para todas as espécies; não adoptada porque apaga essa identidade e pede arte nova.
- `[CODEX]` **Som curto sintetizado para levantamento e ordem.** Razão: dá confirmação mesmo fora da câmara e cumpre a proveniência sem bloquear em assets finais. Alternativa: silêncio até gravação/pack final; rejeitada nesta fatia porque tornaria a acção menos legível.

### Ligações e decisões que pertencem a outros donos

| Estado | Trabalho fora desta árvore | Fronteira pronta |
|---|---|---|
| 🔴 | **O dono de `game/src/main.gd`/`game/src/player/player.gd` tem de instanciar `NecromancyRuntime` para `class_id == evil_mage`.** Configurar com jogador, raiz do mundo, IDs de dono/autoridade e catálogos; chamar `watch_enemy(enemy, stable_spawn_id)` em cada `_spawn` (o segundo argumento é necessário entre peers; a omissão só é estável no processo local); chamar `rest()` antes da cura da fogueira e `leave_zone(new_root)` na transição. A morte do caster já limpa automaticamente; descanso também descarta os registos de corpos antes de os inimigos ressuscitarem. Sem estas chamadas, a necromancia continua sem consumidor no jogo principal, apesar de o fluxo isolado estar completo | `res://src/summons/necromancy_runtime.gd::setup/watch_enemy/rest/leave_zone` |
| 🔴 | **O dono de `player.gd` deve chamar `validate_raise_target(selected_spell)` antes de gastar mana/iniciar Levantar ou Erguer.** Hoje `_start_cast()` cobra primeiro e não conhece cadáver/PV; o runtime só observa o commit. A API devolve `no_eligible_corpse`, `missing_body_size_data`, `insufficient_health_budget` ou aceitação sem mutar estado | `NecromancyRuntime.validate_raise_target(spell_id)` |
| 🔴 | **O dono de `game/data/enemies.json` tem de declarar `necromancy_body_size` em cada inimigo comum**, usando uma chave de `spells.json::levantar.effect.health_cost_fraction_by_size`. É um número/classificação de combate e esta árvore não o inferiu pelo modelo. Sem a declaração, o corpo aparece mas Levantar rejeita `missing_body_size_data`; chefes continuam pela ficha própria | `RaisedCorpse.body_size`; escolher pequeno/médio/grande nos dados, não em `.gd` |
| ⚠️ | **[TENSÃO] Quem simula/comanda invocados em co-op continua por decidir.** A implementação não fechou a questão: o claim do corpo e o levantado guardam `caster_owner_id` e `simulation_authority_id` separadamente, pelo que o adaptador de rede pode usar “quem levantou” ou “host” sem reescrever IA/posse. O ID estável e claim atómico já impedem duplicação local; a validação remota fica para a política escolhida. Não há fogo amigo em nenhuma das opções | Mateus/Rico escolhem política; `RaisedCorpse.try_claim(...)` e `RaisedEnemy.setup_raised(...)` aceitam os dois IDs |
| 🔵 | Incluir a cena focal no corredor obrigatório para esta regressão passar a contar no total central; a posse desta árvore proíbe alterar o agregador | `res://src/summons/necromancy_runtime_self_test.tscn` · 16/16 isolados |
| 🔵 | Repetir o benchmark no hardware físico final e com modelos/efeitos finais. Não transformar variação de FPS em limite de desenho; se a Lei 4 falhar, degradar apresentação pelos presets declarados e publicar o número medido | `res://src/summons/necromancy_benchmark.tscn -- --summons=N` |

O orçamento continua puramente data-driven: chefe erguido (50%) + Voto de Sangue ×3 (60%) já excedem 100%, e qualquer invocação comum aumenta ainda mais. `_fits_budget()` exige que o necromante permaneça vivo, logo as combinações incompatíveis são rejeitadas pela mesma matemática, independentemente da ordem, sem travão adicional nem máximo de criaturas.

## 🔧 Defeito de processo — 02-08

⚠️ **Eu proibi os agentes de tocar em `game/src/main.gd` para evitar colisões, e `main.gd` é exactamente onde o fio se liga.** Resultado: três agentes seguidos entregaram o motor perfeito e pararam à porta — necromancia, fogueira, recolha. Cada um foi honesto e escreveu aqui que faltava a ligação; nenhum podia fazê-la.

⭐ **A correcção:** `main.gd` passa a ter um **integrador** — um agente por lote, que corre depois dos outros e só liga fios. É o papel que fez a necromancia chegar ao jogo.

⚠️ **A regra que fica:** um sistema novo nomeia no seu commit **qual é a linha de `main.gd` que falta**, para o integrador não ter de a descobrir.
---

## 🗡️ Geometria de arma e armadura — prova real fechada (02-08-2026)

**Estado actualizado: FEITO NO JOGO INTEGRADO.** `main.gd` troca apenas o renderer-base por `ArmorVisual`, prende `WeaponAttach` e `AttackAnimationController` ao mesmo esqueleto e reaplica as peças do inventário. A captura canónica `game/captures/01-spawn-3a-pessoa.png` mostra o Guerreiro de frente, com peitoral, botas, espada na mão direita e escudo na esquerda; a tábua escura desapareceu.

### As quatro perguntas do fio solto

1. **Como usa o jogador:** entra no mundo ou confirma equipamento pela UI existente; `refresh_inventory_state()` aplica arma, mão secundária, duas mãos e IDs de armadura ao corpo visível.
2. **Como se prova:** `scenes/selftest.tscn` arranca `gameplay.tscn` com um save só em memória e exige `couro_peitoral` + malha e `longsword` + prop visível no Guerreiro real. O modo fotografia pedido gravou depois a captura canónica e foi inspeccionado visualmente.
3. **De onde vêm arte e som:** seis props foram escolhidos individualmente de KayKit Adventurers CC0 — espada, adaga, machado de duas mãos, arco, besta de duas mãos e escudo redondo — e descobertos pelo nome de família do catálogo. O cajado KayKit foi rejeitado depois de captura porque a argola verde era desproporcionada; cajado, katana e haste usam geometria procedural sólida temporária. Não entrou som novo; o combate conserva os cues existentes.
4. **Quanto custa na máquina do Rico:** GPU-alvo Intel Iris Xe, Mobile/Vulkan, 1920×1080, VSync desligado, 3 s de aquecimento + 10 s. Corpo de comparação: **357,9 fps / 2,794 ms**, p99 5,305 ms, 8 draws, 39 488 primitivas, 57,3 MiB VRAM. Corpo com espada + peitoral: **350,3 fps / 2,855 ms**, p99 4,998 ms, 7 draws, 39 784 primitivas, 61,3 MiB VRAM. Delta observado: **+0,061 ms médio, -1 draw, +296 primitivas e +4,0 MiB VRAM**; havia vários Godot de outras árvores abertos, pelo que estes valores são uma medição local emparelhada, não certificação do aparelho final de 8 GiB.

`[CODEX]` **Modelo por família descoberto no catálogo, com fallback geométrico explícito.** Razão: uma família nova deixa de depender de uma lista manual em `.gd`, e ausência de asset nunca volta a produzir um plano. Alternativa descartada: proxies por dicionário fechado, porque escondem famílias novas e já causaram conteúdo invisível.

`[CODEX]` **Peitoral temporário como casca afunilada e curva, não caixa.** Razão: acompanha cintura, peito e decote do corpo UAL com duas superfícies agrupadas. Alternativa final preferível: malha modular própria, pesada e ajustada ao rig, quando existir no acervo; não foi fingida compatibilidade com outro esqueleto.

### Ligações e arte final que pertencem a outros donos

| Estado | Trabalho fora desta árvore | Alteração exacta / prova necessária |
|---|---|---|
| ✅ | ~~**Ligar arma e armadura ao jogador real.**~~ **RESOLVIDO 02-08** — `main.gd` monta os três componentes no esqueleto real e a prova integrada/captura fecha peitoral + espada visíveis. | `game/src/main.gd` · `game/scenes/selftest_integrated.gd` · `game/captures/01-spawn-3a-pessoa.png` |
| 🔴 | **O estado de equipamento chega com forma incompatível.** O photo tour falhou em `inventory_system.gd:391` ao construir `String(dagger)` e o repro falhou com `String(staff)`; `player.gd:896` repete a conversão. O valor de `main`/`offhand` é agora uma ficha/dicionário onde estes consumidores esperam ID textual. | O dono do inventário/jogador deve normalizar a fronteira uma vez, preservando o ID catalogado, e provar trocar/guardar/reabrir arma e armadura sem `SCRIPT ERROR`. Não inferir ID pelo nome apresentado. |
| 🔴 | **`repro-inicio` suja o save apesar de anunciar limpeza.** A execução de 02-08 imprimiu `slots de teste apagados: 6`, mas deixou `saves/slot_00.json` e `.bak` às 02:22 com o perfil de teste `evil_mage/Mateus`. Esta árvore restaurou ambos byte a byte do backup pré-existente `saves.backup-165816` e confirmou hashes iguais; não removeu outras pastas. | O dono do repro deve redireccionar os sete perfis para um namespace/directório de teste ou preservar/restaurar atomicamente todos os alvos, incluindo o perfil escolhido para entrar no mundo. O corredor deve falhar se restar qualquer artefacto criado por ele. |
| 🟠 | **A prova focal da arma ainda fecha com um diagnóstico do renderer.** As 42 asserções passam e o processo sai com código 0, mas, depois de percorrer e libertar várias malhas no mesmo teste, Godot 4.7 imprime `Parameter "material" is null` durante a limpeza do renderer Dummy/Mobile. O benchmark de uma arma não o reproduz e o auto-teste central fecha limpo. | Localizar qual recurso/troca conserva a referência de material antes de promover o componente ao jogador; não silenciar o erro nem tratar código 0 como prova limpa. |
| 🟠 | **Faltam modelos finais compatíveis para cajado, katana, haste e as peças de armadura.** O acervo não contém roupa modular comprovadamente compatível com os 65 ossos UAL; o cajado KayKit testado não cumpre o alvo visual. | Substituir os fallbacks um a um, mantendo `License.txt`/proveniência e repetindo captura + orçamento. Não importar packs inteiros nem voltar a planos/caixas. |
| ✅ | ~~**Faltava uma árvore dona da integração e da captura real.**~~ **RESOLVIDO 02-08** — esta árvore recebeu posse de `main.gd`, `character_visual.gd` e `game/scenes/`; a captura do photo tour foi produzida pelo comando canónico com saves isolados. | integração `fe88f1d` · captura canónica |
---

## Acesso rápido editável — prova desta árvore (02-08-2026)

### As quatro perguntas do fio solto

1. **Como usa o jogador:** abre a mochila com a acção remapeável `inventory_menu`, carrega em **EDITAR ACESSO RÁPIDO**, escolhe uma das ranhuras `hotbar_*`, escolhe um consumível e confirma. No mundo, a acção `hotbar_N` selecciona sem abrir menu/parar tempo e `use_item` usa o seleccionado. O mesmo ecrã troca mão principal/secundária; a confirmação aplica o estado ao `Player`, portanto o ataque lê a arma nova.
2. **Como se prova:** a prova carregada pelo `QuickSlots` apenas dentro da cena oficial `repro-inicio.tscn` abriu a `InventoryMenu` e o editor reais, colocou o Frasco no atalho 2, confirmou que o atalho 1 vazio não bebia nada, carregou no binding actual do atalho 2, usou o binding actual de `use_item` e viu a contagem do Frasco baixar. Depois descobriu no catálogo uma arma principal diferente, equipou-a, confirmou `Player.main_weapon`, atacou o boss real e viu a barra do boss encolher. A cena terminou verde; como `Main._exit_tree()` voltava a gravar o slot 0 depois da limpeza do repro, o nó da prova remove no seu próprio fecho apenas ficheiros cujo `profile_id` começa por `repro-`. O agregado manteve **9750/9750**.
3. **De onde vêm arte e som:** não entrou asset. A caixa conserva as silhuetas vectoriais baratas, o Frasco reutiliza o desenho e `Sfx` já existentes, e o editor reutiliza `WeaponVisual`/`ArmorVisual` no boneco de pré-visualização. A arma no modelo do jogador real continua na lacuna de integração de `WeaponVisual`; a prova do mundo viu ataque + barra, não inventa uma malha que ainda não está montada.
4. **Quanto custa na máquina do Rico:** Intel Iris Xe, Vulkan Mobile, 1920×1080, VSync desligado. O editor aberto mediu **234,0 fps médios, p95 6,734 ms, p99 9,108 ms, pior 12,514 ms, 58 draws**. A zona completa com a caixa mediu 121,4/115,9 fps médios em duas passagens, mas p99 **17,537/21,525 ms** (1,2%/1,8% acima de 16,67 ms); processos concorrentes e o mundo actual impedem atribuir esses picos à caixa sem corrida A/B limpa. O scan recursivo inicialmente suspeito foi removido: em repouso ficam só quatro descritores redesenhados a cada 0,1 s; montagem da mochila ocorre pelo evento de entrada.

### Fora dos ficheiros desta árvore

| Estado | Trabalho | Prova/razão |
|---|---|---|
| ✅ | ~~**Mão esquerda do Mago do Mal vazia.**~~ **RESOLVIDO** — o catálogo equipa `talisma`; `Player`, `WeaponAttach` e a caixa mostram-no como instrumento secundário sem lista de IDs no HUD. | prova dos sete kits em `repro-inicio.tscn` |
| 🟠 | **A conversão nula do Berserker foi corrigida no limite possuído, mas `InventoryMenu._show_detail()` ainda emite `Invalid call 'String' constructor: adaga`.** A prova funcional prossegue e termina verde; a consola não está limpa até o dono de `inventory_menu.gd` corrigir a descrição. | backtrace real de `repro-inicio.tscn`, 02-08-2026 |
| 🟠 | **Lei 4 da zona completa ainda não fecha em p99.** O editor isolado passa com folga e a média do mundo excede 60, mas as duas amostras curtas da zona tiveram p99 acima de 16,67 ms. Repetir A/B sozinho no hardware final de 8 GB antes de atribuir regressão ou declarar 60 estáveis. | medições acima; sem alterar números/render alheios |
---

## Magia ligada ao jogo — dano, sinais visuais e prova jogável (02-08-2026)

### As quatro perguntas do fio solto

1. **Como usa o jogador:** entra no mundo com um cajado cujo catálogo declara `can_cast`, selecciona um favorito e carrega na acção remapeável `cast`. O instrumento secundário continua a ter prioridade; enquanto o talismã decidido ainda não está no loadout, o cajado principal compatível fecha o fio em vez de a tecla não fazer nada.
2. **Como se prova:** `src/spells/spell_game_integration.tscn` monta `scenes/gameplay.tscn`, o `Player`, o mundo e inimigos reais; arranca como Mago do Mal, carrega em `cast`, confirma o cajado e o clarão no foco, observa o rasto durante o voo, comprova hitbox = núcleo visível, vê o impacto no mesmo frame e mede a perda de PV do inimigo. Faz depois o mesmo com a primeira entrega vermelha ofensiva lida do catálogo: **13/13**. A prova focal das 12 formas manteve **171/171** e o agregado oficial **9750/9750**.
3. **De onde vêm arte e som:** `art/concept/magia/dardo-azul.png`, `impacto.png` e `magia-vermelha.png` são alvo visual, nunca assets copiados para runtime. Clarão, núcleo, rasto, estilhaços e veios são malhas/material emissivo sintetizados e partilhados; o vermelho usa queda, assimetria e interior escuro. O som lê `spells.json::_vfx.audio_profiles` e passa pelo `Sfx` sintetizado já existente.
4. **Quanto custa na máquina do Rico:** Iris Xe, Mobile/Vulkan, 1920×1080, sem VSync, 6 s de aquecimento + 12 s medidos, Dardo + Ruína + Égide visíveis: **412,8 fps médios**, **2,423 ms médios**, p95 **3,987 ms**, p99 **5,224 ms**, pior frame **11,17 ms**, **14 draws**, 188 objectos e +10 218 597 bytes de memória estática. Só os três favoritos residiam: 3 malhas + 1 material. Havia 32 Godot concorrentes; a passagem cumpre 60/p99, mas não se atribui a melhoria face a 01-08 como ganho causal. Ver [`medição`](game/src/vfx/benchmark_iris_xe_2026-08-02.json).

### O fio que estava solto e o que ficou executável

- O kit real traz `staff` na mão principal e `null` na secundária; `_start_cast()` só aceitava `_secondary_instrument_for()`, portanto recusava antes de gastar mana. Agora procura o instrumento compatível no catálogo, prefere a secundária e usa o cajado principal apenas quando a arma equipada declara `can_cast`.
- `Player._release_spell()` deixou de despachar a esfera legada: cria `SpellDeliveryFactory`, passa apenas o bundle residente dos favoritos e liga `contacted` a `Spell.apply_contact()`. O inimigo real recebe `DamageInfo` mágico e perde vida.
- O contacto móvel mira o centro catalogável do corpo e faz varrimento entre posições. Ao tocar, o volume e o núcleo visível fecham no mesmo relógio; o estilhaço de impacto é confirmação de dano já aplicado, explicitamente sem nova hitbox.
- O clarão acompanha `WeaponAttach.main_weapon_tip_position()`. O rasto usa uma única camada `MultiMesh`; a escola `mal` acrescenta veios escuros e queda assimétrica, orientados pelo conceito doente em vez de brilho heróico.
- `SpellVfxResidency` continua `equipped_only`; nenhuma lista de 53 feitiços foi escrita no código ou pré-carregada.

### Ligações e problemas fora dos ficheiros desta árvore

| Estado | Trabalho fora desta árvore | Saída exacta |
|---|---|---|
| 🔴 | ⭐ **A prova jogável ainda não pertence ao corredor obrigatório.** Esta árvore pode criar `game/src/spells/spell_game_integration.tscn`, mas não possui `game/VERIFICAR.bat`. Pela regra nova, a entrega só fica gate-completa quando o dono a ligar. | Acrescentar ao `VERIFICAR.bat`, antes da guarda final: `"%GODOT%" --headless --audio-driver Dummy --path . src/spells/spell_game_integration.tscn || set FALHOU=1`, e actualizar a contagem de 7 para 8. A cena limpa o seu slot temporário mesmo quando falha normalmente. |
| 🔴 | **Os 13/13 provam dano directo azul/vermelho e a Égide conserva a barreira já existente; não provam os efeitos sem dano dos restantes feitiços.** `SpellDelivery` publica esses contactos, mas no runtime de produção nenhum alvo implementa `receive_spell_contact`; esse método só existe no duplo do teste focal. Portanto, os 171/171 das formas são contrato do motor, não prova de que cegueira, isco, suporte ou outras semânticas já aconteçam no jogo. | Cada família sem dano precisa de um consumidor de produção e de uma prova pela cena/jogador/resultante visível. Não escrever uma lista manual: iterar as famílias declaradas no catálogo e ligar cada efeito ao sistema que possui o estado correspondente. |
| 🔴 | **Mão secundária `null` gera dois `SCRIPT ERROR` no arranque real:** `InventorySystem.load_profile():391` e `Player.apply_inventory_state():903` fazem `String(null)`. O `setup()` anterior deixa o cajado utilizável, mas favoritos/carga podem não aplicar. Não foi corrigido porque `inventory_system.gd` e essa parte de `player.gd` não pertencem a esta tarefa. | Normalizar `null` para mão livre antes de converter para `String`, tanto no perfil de carga como na aplicação ao jogador; acrescentar caso de loadout sem offhand ao gate. O repro de magia normaliza apenas a sua cópia temporária para não mascarar a lacuna no código de produção. |
| ⚠️ | **Incidente de isolamento durante a primeira versão da prova:** `Main` persistiu a normalização que se julgava só em memória no slot activo. A auditoria encontrou `slot_00.json` e `.bak` ambos com o perfil `prova-magia-em-memoria`; foram removidos depois de validar o perfil e a pasta ficou com zero ficheiros. Não é possível provar retrospectivamente se o slot 0 estava vazio antes da primeira passagem. | A cena agora reserva apenas um slot inexistente entre 9000–9999, guarda/restaura `SaveSystem.active_slot`, valida `profile_id` antes de apagar e a auditoria pós-teste confirmou **0 ficheiros restantes**. |
| 🟠 | **A cena integrada termina com 9–15 instâncias ObjectDB vivas**, variando entre headless e captura gráfica. O resultado 13/13 não muda, mas o fecho não está limpo. | O dono do ciclo de vida de `main.gd`/áudio/visuais deve localizar as instâncias; não esconder o aviso nem libertar colaboradores de produção a partir da prova. |
| ⚠️ | **[TENSÃO] “toda magia vermelha paga PV” não tem número executável no catálogo.** `Lança Negra` declara 38 mana e nenhum custo de vida; o orçamento decidido de `spells.json::_rules.dark_mage_health_budget` é partilhado apenas por levantar morto, levantar chefe e Voto de Sangue. Esta árvore não inventou uma percentagem de PV para o projéctil. | `[CODEX]` Conservar o contrato actual: projécteis vermelhos pagam mana; necromancia/Voto pagam PV pelos campos já declarados. Alternativa, se Mateus quis PV em **cada** feitiço vermelho: o dono de `spells.json` deve declarar `health_cost_fraction` por ficha e o runtime deve mostrar/recusar o custo antes do commit. |
| ⚠️ | **[TENSÃO] A fórmula de dano continua sem consumir `spell_power`.** O casting transporta o instrumento, mas `Spell.apply_contact()` conserva a fórmula anterior para não decidir se o instrumento substitui ou compõe `base_damage`. | Fechar a decisão no catálogo/spec e só depois alterar a fronteira de dano; não improvisar um multiplicador em `.gd`. |

---

## 🔌 Integração dos oito órfãos — resultado jogável (02-08-2026)

O scan inicial encontrou **8 órfãos / 1744 linhas**. Depois da segunda volta encontra **zero órfãos**. `BossVorgar` é a instância real da arena e recebe input/dano/morte; `StartingLoadouts` executa a parte compatível do contrato histórico, enquanto a lista de origens e a aplicação dos sete kits continuam catalog-driven. As incompatibilidades internas dos dois módulos não são escondidas: ficam abaixo e continuam a emitir/falhar onde indicado.

| Módulo | Estado no jogo | Prova |
|---|---|---|
| `Lair` | ✅ substitui a Toca provisória; anchors, rotas, colisões, arena e todos os marcadores são consumidos | cena real exige módulos/colisões e ocupação dos seis encontros |
| `MonsterVisual` | ✅ substitui apenas o renderer provisório de cada inimigo com perfil | cena real exige malha + assinatura visual em todos os inimigos povoados |
| `EnvironmentAtmosphere` | ✅ fornece `WorldEnvironment` e `Sun` de Brumal | cena real exige céu e nevoeiro activos pela fábrica integrada |
| `NetMenu` | ✅ botão **JOGAR A DOIS** abre Hospedar/Entrar e **Fechar** devolve controlo | foco real + `ui_accept`, resultado visível e `Player.input_enabled` suspenso/restaurado |
| `NetHud` | ✅ montado sob os menus e invisível offline | sinal real `NetSession.link_warning` torna a mensagem visível e o sinal vazio limpa-a |
| `BoundsSelfTest` | ✅ executado pela cena que `VERIFICAR.bat` já chama | faixas segura/intermédia/mortal contam no agregado **9764/9764** |
| `BossVorgar` | ✅ ligado no combate básico | instância real recebe `attack`, perde a barra, morre e sai do HUD; controlador SEPARAR/JUNTAR continua bloqueado pelos dados/API |
| `StartingLoadouts` | ✅ ligado sem autoridade sobre a lista | contrato histórico executado; os sete IDs exactos vêm do catálogo e cada kit é provado no save, jogador, mãos, armadura e caixa |

### As quatro perguntas do fio

1. **Como usa o jogador:** equipamento aparece ao entrar e acompanha o inventário; anda pela entrada e salas da Toca até ao chefe; combate os monstros/chefe pelos controlos normais; escolhe **JOGAR A DOIS** no HUD para abrir Hospedar/Entrar. O aviso de linha é passivo.
2. **Como se prova:** `scenes/selftest.tscn` continua em **9764/9764**. Além disso, `repro-inicio.tscn` atravessa criação e abertura, entra no mundo, percorre exactamente as sete origens catalogadas, observa o kit em save/jogador/mãos/armadura/caixa, troca a arma pela UI, envia `attack` e vê `BossVorgar` perder vida, morrer e sair do HUD. Os seis ficheiros temporários são apagados no fim.
3. **De onde vêm arte e som:** nenhum asset foi criado. Corpo/armadura/armas usam os recursos já escolhidos por `ArmorVisual`/`WeaponAttach`; Toca usa os módulos KayKit já carregados por `Lair`; monstros usam os modelos e perfis já declarados; atmosfera é procedural; rede usa Controls/Labels existentes. Sons continuam nos sistemas já ligados, sem ficheiro novo.
4. **Quanto custa no Rico:** Intel Iris Xe, Mobile/Vulkan, preset `medio`, 1920×1080, VSync desligado e 8 s de aquecimento. Arena final já com `BossVorgar`, dois jogadores e dois orcs: a amostra de 30 s deu **97,2 fps**, p95 **24,899 ms**, p99 **31,899 ms** e 9,9% acima de 16,67 ms; a repetição de 15 s deu **82,2 fps**, p95 **25,335 ms**, p99 **32,982 ms** e 28,4% tardios. A média excede 60, mas a estabilidade falhou duas vezes nesta sessão; não se declara a Lei 4 satisfeita nem se atribui a regressão a esta ligação sem A/B.

### O que continua por provar/corrigir

| Estado | Lacuna | Próxima fronteira honesta |
|---|---|---|
| ✅ | ~~`BossVorgar` combatia, mas não instalava SEPARAR/JUNTAR~~ | **RESOLVIDO 02-08** — a ficha e a API única foram recompostas sem tocar em `main.gd`; o controlador nasce em modo lógico sobre a Toca existente, sem duplicar a sala/render/colliders. |
| ✅ | ~~`StartingLoadouts` usava uma lista de seis origens como autoridade~~ | **RESOLVIDO 02-08** — o contrato descobre as origens activas em `loadouts`, exclui `_...`, cruza-as com `attributes.json` e valida requisitos nas duas mãos. `ACTIVE_ORIGIN_IDS` fica apenas como compatibilidade de API para o teste/integração antigos. Ensaio isolado: **22/22**. |
| ✅ | ~~`GameData` rejeitava `sino` e `talisma` como armas inexistentes~~ | **RESOLVIDO 02-08** — `weapons.json` publica apenas aliases runtime de slot/família/requisito; descrição, tipo e arte continuam definidos uma vez em `equipment.magic_instruments`. O carregamento real deixou de emitir os dois erros e o `WeaponAttach` resolve o catálogo referido sem lista de IDs. |
| 🟠 | O Berserker não tem um item secundário distinto | O catálogo declara `greataxe` de duas mãos e `offhand:null`; o jogo prova a arma/pose a duas mãos e mostra a ranhura esquerda livre. Se “cada origem tem offhand” exigir um segundo item, o dono de `weapons.json` tem de o escolher; o integrador não inventa conteúdo. |
| 🟠 | `InventoryMenu` converte a descrição `adaga` com um construtor inválido | O dono de `game/src/ui/inventory_menu.gd` deve corrigir `_show_detail()` e repetir o mesmo percurso real da mochila. |
| 🟠 | Menu/HUD de rede só foram provados numa máquina | Abrir anfitrião + convidado reais, confirmar entrada em menos de dois minutos, corpo remoto e aviso de latência. O menu existe e é utilizável; a sessão entre duas máquinas não é declarada provada. |
| 🔴 | A arena final continua acima do p99 de 16,67 ms | Repetição desta consolidação na Iris Xe, Mobile/Vulkan, 1080p, 15 s: controlador desligado **105,7 fps/p99 19,123 ms**; ligado e sem duplicar geometria **98,6 fps/p99 22,207 ms**. Ambos falham; com agentes concorrentes, a diferença não isola causalidade, mas o custo observado do controlador foi **+404 primitivas, +8,5 MiB estáticos e +32,8 MiB de VRAM**. Repetir em host limpo antes de atribuir os 3,084 ms ao controlador ou declarar a Lei 4 satisfeita. |
| 🟠 | `repro-inicio.tscn` não fecha nesta árvore, embora limpe os seis saves temporários | O erro do controlador Vorgar desapareceu. A execução pára agora na conversão inválida de `adaga` e depois não encontra três inimigos comuns vivos por causa da população virtualizada já registada abaixo. |
| 🟠 | O harness legado `arena_vorgar_perf.gd` cai no Godot 4.7.1 com `0xC0000005` | Reproduzido em headless/Dummy e em Mobile/Vulkan antes de qualquer resultado. Não o contar como prova; localizar a queda no dono desse ficheiro ou substituir por uma cena jogável ligada a `VERIFICAR.bat`. |
| 🟠 | Rede foi provada com anfitrião + convidado em dois processos da mesma máquina; duas máquinas/casas continuam abertas | A prova nova confirma F3, menu, erro visível, entrada em 0,25–0,57 s, origens diferentes, corpo remoto e movimento nos dois sentidos. Falta repetir entre Mateus/Rico com porta/VPN, firewall e latência reais; não se declara isso provado. |
| 🔴 | A arena final mediu p99 31,899/32,982 ms e 9,9%/28,4% de frames tardios em duas passagens | Fazer A/B e localizar a regressão antes de cortar qualidade/conteúdo. Médias de 97,2/82,2 fps não contam como 60 estáveis. |
| 🟠 | `repro-inicio.tscn` passa, mas a consola não está limpa | A prova funcional termina `ARRANQUE + NECROMANCIA OK` e apaga seis ficheiros; continuam os dois erros de instrumentos, o erro do controlador Vorgar, a conversão de `adaga` e o aviso de modelo de talismã no preview. |

## 🔴 Sessão jogada por mim — 02-08

| | Achado | Prova |
|---|---|---|
| 🔴 | ⭐ **A única animação de ataque do jogo chama-se `Punch_Cross` — um murro.** Não é o encaixe da espada que está mal: o jogo toca uma animação de soco porque é a única que a Quaternius Universal Animation Library `[Standard]` traz. As palavras do Mateus, *"ele bate com a mão e a espada fica na mão"*, descrevem exactamente o que o código manda fazer | `grep '"Punch_Cross"' game/src/` |
| 🔴 | ⭐ **Brumal tem 3 tipos de inimigo de 34 no catálogo, e 1 chefe de 36 nomeados.** Nascem 10 lanceiros, 5 brutamontes e o Vorgar. O resto do bestiário existe em ficha e nunca no mundo | `_spawn()` em `main.gd` |
| 🔴 | **O inimigo morto continua a deslocar-se** | sessão-de-jogo, passo 8 |
| 🔴 | **O `WorldPickupManager` não está na cena** — sem ele não há baús nem nada no chão | sessão-de-jogo, passo 13 |
| 🟠 | **52 fps, não 60** | sessão-de-jogo, passo 14 |
| ✅ | ~~**Faltava biblioteca de animação**~~ **RESOLVIDO 02-08 sem gastar nada nem sair do repositório** — a `UAL1_Standard.glb` que já temos tem **43 animações**, incluindo `Sword_Attack`, `Sword_Idle`, `Spell_Simple_Shoot`, `Roll`, `Death01`, `Sitting_Enter/Idle/Exit` e `PickUp_Table`. O jogo usava **seis** e tocava `Punch_Cross` ao atacar com espada. ⭐ Mixamo deixa de ser preciso: isto é **CC0 e já está no repositório**, portanto o Rico tem tudo com um `git clone` — sem download manual, sem licença por explicar | listado com `AnimationPlayer.get_animation_list()` |
| 🟠 | `repro-inicio.tscn` ainda não fecha e a consola não está limpa | O erro de contrato do Vorgar desapareceu. Continuam fora desta tarefa a conversão de `adaga` em `InventoryMenu._show_detail()`, a falta dos três inimigos da população virtualizada e o preview separado de `weapon_visual.gd`, que ainda avisa não ter modelo de talismã. |

## Golpe filmado e equipamento coerente — prova de 02-08-2026

- **Golpe:** `Player` deixou de impor `Sword_Attack` por cima do controlador UAL. O controlador é chamado no início do estado e continua a procurar a pose por `state_frame`; duração e janela visível permanecem exactamente `startup + active + recovery` de `weapons.json`. Contrato focal: **186/186**.
- **Filme:** a compressão PNG bloqueava 50–65 ms no fio principal e fazia o índice da imagem saltar vários ticks. A prova grava em segundo plano e amostra `physics_frame`. No comando canónico, `ataque-04` registou frame autoritativo **12** e mostra o aviso; `ataque-08` registou **24** e mostra a recuperação. As duas poses foram abertas e inspeccionadas, não inferidas pelo log.
- **Kit do Mago do Mal:** um save novo arranca com `staff + talisma`, ambos sem requisitos em falta. A passagem isolada imprimiu `hand_l -> Offhand_talisma` e `hand_r -> Main_staff`; o HUD mostrou `Cajado + talisma`, a caixa deixou de mostrar X e o estado nunca apresentou o multiplicador ×0,6.
- **Uma verdade:** save/inventário guarda IDs; `Player.equipment_weapon_id()` normaliza `null`, texto ou carta na fronteira; `WeaponAttach` lê os IDs do `Player`; a caixa integrada pelo `integrador2` lê o mesmo equipamento persistente e actualiza o jogador por `apply_inventory_state()`.
- **Empunhadura:** transformação de punho vem de `weapons.json`; sino e talismã usam silhuetas compactas próprias. A adaga importada deixou de receber a compressão transversal da espada, conserva os 38 cm catalogados e roda pelo punho, em vez de parecer uma haste.

## 🔴 Combate filmado e comparado com o DS3 — 02-08

> Filmado com `scenes/filme-de-combate.tscn`. **A `sessao-de-jogo` verifica se as coisas existem; isto filma o que o jogador vê.** Foi o Mateus que apontou a diferença: *"tu tá a ver poucos erros, eu tô a ver muita coisa"*.

### Tabela ELES / NÓS / DIFERENÇA — repetida no jogo antes desta intervenção

| Mecanismo | ELES | NÓS, visto no jogo a 02-08 | DIFERENÇA a fechar nesta árvore |
|---|---|---|---|
| Silhueta a 20–30 m e em contraluz | Corpo, arma e papel continuam identificáveis contra um fundo escuro | `combate-00.png` mostra uma massa quase rectangular, com dois olhos emissivos soltos e a lança parcialmente confundida com a árvore; no percurso, o corpo desaparece no verde/cinzento até o HUD o denunciar | Separar pele, armadura e arma por valor; dar frente anatómica (focinho/testa/mandíbula), ombros e pernas com espaço negativo; manter preenchimento barato em contraluz |
| Preparação antes do golpe | A postura inteira muda: peso recua, tronco fecha e arma arma o golpe antes da hitbox | A barra escreve `PREPARA` e a lança roda, mas `combate-00`, `08` e `16` conservam quase o mesmo bloco corporal; sem ler o texto, o instante de compromisso não é claro | Fazer o corpo antecipar por família, com recuo/lateralização e arma afastada da silhueta; golpe avança e recupera de forma distinta, conduzido pelo sinal real de fase |
| Vida do inimigo engatado | A barra aparece para o alvo relevante e permite decidir se se arrisca outro golpe | A barra superior existe, traz nome/PV e acompanha 135 → 98 → 60 → 14 no filme | Mecanismo já ligado; conservar e provar que a melhoria visual não o parte |
| Impacto ao levar dano | Ecrã e corpo reagem no mesmo acontecimento; a direção e a interrupção lêem-se | `combate-04.png` e `12` mostram vinheta vermelha, número e pose de hit-stun do jogador; o inimigo clareia por um instante, mas o recuo visual dele é pequeno dentro da massa | Mecanismo do jogador já ligado; ampliar no inimigo a torção/recuo visível que consome `health_changed`, sem alterar dano ou hit-stun |

**Diferença nomeada:** a base atual já comunica o combate por HUD, mas o adversário ainda não o comunica suficientemente pelo próprio corpo. Não é intencional: obriga a ler texto durante a luta e enfraquece a Lei 1. A nossa versão usa os modelos CC0 já importados, geometria procedural de baixo custo e os sinais reais de `Enemy`; não copia nomes, assets ou animações comerciais.

### Resultado visto dentro do jogo nesta árvore

| Pergunta do fio | Resposta provada |
|---|---|
| Como é que o jogador usa isto? | Não ganhou uma tecla artificial: engata com `TAB`, aproxima-se, ataca e esquiva como antes. `filme-de-combate.tscn` repetiu essas ações no jogo real; os sinais reais de fase, vida e estado conduziram o corpo. |
| Como se prova? | `combate-00..04.png` mostra preparação → golpe → recuperação com corpo e arma em poses diferentes; `combate-09.png` mostra flash e recuo do inimigo; `combate-26..29.png` mostra o corpo inteiro cair. `percurso-25.png` e `30.png` mostram o goblin já ligado pelo catálogo durante combate real. A auditoria abriu `enemy-art-20m.png` e mediu as quatro famílias entre 62,7 e 132,4 px a 20 m, com os pés no chão. |
| De onde vêm arte e som? | Corpo e animações são os assets CC0 Quaternius/UAL já creditados no projeto; rosto, armadura e armas são geometria simples composta pelo catálogo JSON. Não foi copiado asset, nome ou animação comercial. O som continua a vir dos efeitos existentes; esta intervenção não acrescentou sons. |
| Quanto custa na máquina do Rico? | A/B Mobile/Vulkan, Iris Xe, 1920×1080, cinco atores, duas repetições em ordem inversa: proposta 383,7 fps médios e p99 6,011 ms; anterior 454,2 fps e p99 4,209 ms. Custo p99 +1,802 ms, 17 draw calls a mais, 3 224 primitivas e 6,9 MB VRAM a menos. A máquina medida tem 15,7 GB, não os 8 GB-alvo; resultado completo em `game/assets/models/enemies/monster_visual_benchmark_2026-08-02.json`. |

| Estado | Lacuna que continua fora dos ficheiros desta árvore | Prova |
|---|---|---|
| 🔴 | A prova visual e o percurso **não estão ligados a `game/VERIFICAR.bat`**. Não alterei o batch nem as cenas porque não pertencem à lista de ficheiros autorizada; portanto, há prova jogada e inspecionada, mas ainda não há gate automático desta funcionalidade no comando canónico. | `VERIFICAR.bat` só chama `scenes/selftest.tscn` e selftests por script; não contém `filme-de-combate`, `percurso` nem `monster_visual_audit`. |
| 🟠 | O auto-teste canónico desta árvore terminou com **9 763 a passar e 1 a falhar**. Não caiu abaixo dos 9 750 verdes e os testes reais de `MonsterVisual`, arena e combate passaram, mas a suite não ficou toda verde. A única falha é a regressão já registada dos marcadores da Toca, em ficheiros proibidos nesta tarefa. | `FALHA jogo real: os marcadores da Toca tem encontro (com corpo ou planeado)`; causa documentada abaixo em `_populate_zone()`/`spawn_population.gd`. |
| 🟠 | A câmara de `percurso.tscn` ainda atravessa terreno/objetos e acaba com Vorgar fora do enquadramento, embora as duas barras e o log provem que o chefe foi encontrado. | `percurso-35.png`, `percurso-chefe.png`; avisos `Target and up vectors are colinear` em `src/tools/percurso.gd`. |
| 🟠 | A legibilidade e os mecanismos de apresentação ficaram comparáveis à referência, mas **o acabamento artístico ainda não é AAA**: o corpo humanoide é reutilizado e rosto, roupa e armas continuam low-poly/procedurais. Não se deve confundir “já não é uma mancha e já avisa o golpe” com “tem a qualidade final de um inimigo Dark Souls”. | `combate-00.png`, `percurso-25.png` e `enemy-art-20m.png`; falta modelação/textura/animação autoral ou CC0 dedicada a cada família. |
| 🟠 | As cenas de prova podem tocar em `user://` se forem corridas normalmente. Todas as execuções desta árvore usaram `GODOT_USER_HOME` temporário, validado e removido no fim; o isolamento deve passar para a própria ferramenta antes de entrar no gate comum. | Diretório temporário removido após cada execução; nenhum slot de save desta intervenção ficou no perfil partilhado. |

| | O que se vê | O que o DS3 faz | Porque dói |
|---|---|---|---|
| ✅ | ~~**O inimigo era uma mancha preta sem forma.**~~ Agora pele, roupa, cabeça, membros e arma têm valores separados; as quatro silhuetas medem pelo menos 62,7 px a 20 m | cada inimigo lê-se pela silhueta e pela cor, mesmo em contraluz | fechado visualmente em `enemy-art-20m.png`, `combate-00.png` e no percurso |
| ✅ | ~~**O inimigo não tinha estado legível.**~~ Preparação recua o corpo e arma, golpe avança e recuperação abre a postura, tudo alimentado por `attack_phase_changed` | cada ataque tem preparação visível, golpe e recuperação — três fases que se leem | fechado no filme `combate-00..04.png`, sem depender apenas do texto do HUD |
| ✅ | **A barra de vida já existia e foi preservada.** Nome, PV e fase acompanham o alvo engatado durante o filme e o percurso | barra por cima do alvo engatado | fechado em `combate-00..29.png`, `percurso-15.png`, `25.png` e `30.png` |
| ✅ | ~~**Levar dano não se via suficientemente no corpo inimigo.**~~ O jogador conserva vinheta/recuo; o adversário agora dá flash claro e recua na direção do impacto | ecrã pisca, o corpo recua, o som muda | fechado em `combate-03.png` (jogador) e `combate-09.png` (inimigo) |
| 🟠 | ⚠️ **A dica de tutorial tapa o meio do ecrã durante o combate:** uma caixa preta com *"Left Mouse Button — ataque leve"* por cima da luta | | |
| 🟠 | ⭐ **A luta está fácil demais.** Medido: o inimigo tira 32 PV de 442 — **13 golpes até morrer**. E morre em 4 | um inimigo comum mata em 4–6 e morre em 3–5 | 13 golpes de margem transforma um souls-like num jogo de acção |

## 🔴 Percurso jogado de ponta a ponta — 02-08

> `scenes/percurso.tscn`: anda os 7 pontos do caminho, ataca o que encontra, e vai à arena. **É a única ferramenta que responde a *"tem como ir até ao chefe?"***.

| | Achado | Prova |
|---|---|---|
| ✅ | ⭐ **O chefe existe e chega-se lá.** *"Vorgar, o Guarda-Portão — fase 1"*, com barra nomeada e fases | `percurso-chefe.png` |
| ✅ | ~~⭐ **Zero inimigos mortos em 40 rondas de ataque.**~~ **DIAGNOSTICADO NA REVISÃO DE CÓDIGO 02-08:** os inimigos morrem; `percurso-20.png` mostra cadáver + recompensa e `percurso-25.png` mostra `0/135 PV · DERROTADO`. O contador só aceita `not is_instance_valid(inimigo)`, mas a morte conserva deliberadamente o nó em `DEAD` para necromancia. A lacuna real é a prova: observar `is_alive()`/`died`, nunca libertar o cadáver para fazer o contador passar | `game/src/tools/percurso.gd:88-95` · `game/src/enemies/enemy.gd:760-776,792-793` |
| 🟠 | ~~**Só dois tipos de inimigo no caminho inteiro.**~~ O percurso desta árvore encontrou e combateu três tipos regulares, incluindo o batedor goblin que a primeira passagem revelou ainda estar no visual antigo. A pouca variedade global continua a ser conteúdo fora deste trabalho visual. | `tipos encontrados: 3 -> { "orc_spearman": 13, "orc_brute": 6, "goblin_mist_scout": 6 }`; `percurso-25.png` e `30.png` |
| 🟠 | **O caminho tem 7 pontos** para uma travessia que a spec quer de 8–12 minutos | `[percurso] caminho com 7 pontos` |

## 🔎 Revisão de código jogada — 02-08-2026

Relatório completo: [`docs/REVISAO-CODIGO.md`](docs/REVISAO-CODIGO.md). Nenhuma linha de código ou ficheiro de jogo foi alterado nesta revisão.

| Estado | Lacuna | Prova exacta |
|---|---|---|
| 🟠 | ~~**Vorgar estava ligado apenas como inimigo básico.**~~ **MOTOR LIGADO 02-08:** a ficha existe, as seis APIs executam e o auto-teste dedicado passa **119/119**. **Prova ainda fora do fio oficial:** o teste dedicado continua sem entrada em `VERIFICAR.bat` e a cena integrada só prova ataque/morte do chefe, não os dois jogadores a responder por input a SEPARAR/JUNTAR. | `game/data/enemies.json` · `game/src/enemies/boss_vorgar.gd` · `game/src/world/arena_vorgar.gd` · `game/VERIFICAR.bat` |
| 🔴 | ⭐ **O motor da geometria visível é autoridade única, mas a prova integrada está vermelha e fora do gate.** `GameplayCue` entrega o mesmo polígono ao mesh e a `covers_world_point()`; `Enemy` deixou de somar `body_radius` ou reconstruir cone/raio e, sem cue, não causa dano. O teste dedicado rejeita agora bytecode antigo: abre `gameplay.tscn` num Godot novo antes de usar input/HUD. Resultado actual: **170 passaram, 1 falhou**, porque `ArenaVorgar` não compila; por isso os controlos 10/10 não foram aceites nesta árvore. Mesmo depois dessa correcção, o dono de `VERIFICAR.bat` ainda tem de ligar o teste ao corredor obrigatório. | `game/src/enemies/enemy.gd` · `game/src/combat/gameplay_cue.gd` · `game/src/player/attack_family_self_test.gd` · `game/src/world/arena_vorgar.gd:77-84` · `game/VERIFICAR.bat` |
| 🔴 | **O auto-teste central dá verde falso ao arrancar uma cena sem `Main` compilável.** A execução observada declarou **9764 passaram, 0 falharam** e código 0, mas no mesmo log aparecem `ArenaVorgar` inválido e `Failed to load script res://src/main.gd`. O total cumpre a quantidade, não a regra “jogo a sério”. | O dono do agregador deve tornar qualquer `SCRIPT ERROR` de dependência numa falha, e o dono da arena deve remover as declarações duplicadas; esta árvore só endureceu o teste que possui. |
| 🔴 | **Vorgar está ligado apenas como inimigo básico.** A ficha não contém `vorgar_encounter`; `BossVorgar` exige-o e chama APIs que `ArenaVorgar` não tem. O auto-teste dedicado falha e não pertence a `VERIFICAR.bat`. | `game/data/enemies.json:620-639` · `game/src/enemies/boss_vorgar.gd:24-40` · `game/src/world/arena_vorgar.gd:60-128` · `game/VERIFICAR.bat:29-78` |
| 🔴 | ⭐ **Lei 2 codificada como número e integração incompleta:** Voto de Sangue calcula +30/+60/+90% e o teste exige o multiplicador. O runtime de produção reserva os PV, mas o caminho de dano do jogador nunca consome o resultado; pode pagar a vida sem ganhar o benefício prometido. | `game/data/spells.json:3072-3108` · `game/src/classes/dark_mage.gd:102-121` · `game/src/summons/necromancy_runtime.gd:268-292` · `game/src/player/player.gd:823-833` |
| 🔴 | **Os bancos de jogo dão verdes falsos.** A sessão aprova “estado de ataque” quando o estado observado é `livre`, mata por dano letal injectado, lê FPS uma vez e termina sempre com código 0. O filme de combate não reconhece `DEAD`; o filme de ataque grava pares duplicados. | `game/src/tools/sessao_de_jogo.gd:149-165,180-193,304-314` · `game/src/tools/filme_de_combate.gd:75-77` · `game/src/tools/filme_de_ataque.gd:77-96` |
| 🔴 | **Lei 4 ainda vermelha.** Mobile está correcto, mas a medição de apresentação regista p99 18,323 ms e `fail_p99`; a prova quente integrada 2+5 continua por fazer. | `medicoes/animacao-esqueleto-2026-08-01.json:57-65,99-118` |
| 🟠 | ⭐ **A regra de ouro voltou a falhar.** Há números de combate em `Player`/`Enemy`, famílias+clips no controlador de ataque, seis `CLASS_ROLES` para sete origens e uma lista “só de compatibilidade” que `main.gd` ainda usa para filtrar validação. | `game/src/player/player.gd:698-804` · `game/src/enemies/enemy.gd:613-712` · `game/src/player/attack_animation_controller.gd:9-58` · `game/src/ui/game_shell.gd:28-35` · `game/src/main.gd:541-555` |
| 🟠 | **Dois renderers fazem o mesmo trabalho.** `Enemy.setup()` cria `EnemyVisualRenderer`; `_spawn()` remove-o imediatamente e instala `MonsterVisual`. Jogo, galeria e testes podem observar caminhos diferentes. | `game/src/enemies/enemy.gd:299-320` · `game/src/main.gd:379-410` |
| 🟠 | **Lei 1 continua sem prova jogada:** as fórmulas contam 45–70 golpes, mas o percurso não combate Vorgar e o teste integrado prepara a vida para uma morte injectada. | `game/src/autoload/game_data.gd:699-706` · `game/src/tools/percurso.gd:104-115` · `game/scenes/selftest_integrated.gd:109-151` |
| 🟠 | **Testes sem chão no jogo:** rede já liga dois processos do jogo real e move os dois corpos, mas ainda não liga duas máquinas/casas; efeitos de magia sem dano só têm `receive_spell_contact` no duplo do teste. | `game/src/coop/coop_online_gameplay_proof.tscn` · `game/src/net/net_selftest.gd` · `game/src/spells/spell_delivery.gd:371-384` · `game/src/spells/spell_delivery_self_test.gd:16-23` |

## 🔴 Regressão apanhada por um teste que se recusou a ficar verde — 02-08

⚠️ **`_populate_zone()` está definida em `game/src/main.gd:470` e nunca é chamada.** Foi substituída pelo produtor de população virtualizada — e levou com ela duas coisas que estavam lá dentro:

- ⭐ **os inimigos dos marcadores da Toca** (`lair.get_enemy_markers()` → `_spawn`)
- ⭐ **o registo do chefe** (`_register_boss`, que liga a barra de vida do Vorgar ao HUD)

⚠️ **Como isto se apanhou, e porque interessa:** dois testes começaram a falhar depois do merge. A tentação era relaxá-los — *"agora a população é virtualizada, os corpos não existem ao frame zero"*. **Relaxei um** (o do chefe passou a **andar até à arena** em vez de o exigir carregado, e isso é mais honesto). **O segundo recusou-se a passar mesmo depois de aceitar as duas formas legítimas** — corpo no mundo *ou* colocação no plano.

⭐ **Era o teste a ter razão.** O orçamento de Brumal declara `orc_spearman: 4 · orc_brute: 2 · goblin_mist_scout: 2` e **nenhum guardião**; os marcadores da Toca não entram no plano, e o Vorgar deixou de ser registado. **O caminho antigo morreu e o novo não assumiu o que ele fazia.**

⛔ **Não fechar isto baixando o teste.** O que falta é o produtor de população passar a cobrir os marcadores da Toca e o guardião, ou `_populate_zone` voltar a ser chamada para essa parte.
## 🔴 Arena de chefe do Vorgar — prova integrada bloqueada (02-08-2026)

O contrato da arena passou a existir em `world.json` e `ArenaVorgar`: tem identidade, prontidão explícita, nevoeiro que espera o grupo e fecha atrás dele, teto catalogado de empurrão e espaço/guia para SEPARAR/JUNTAR. `node tools/cobertura-spec.mjs` já retira a spec 61 de **SEM CHÃO**; a auditoria isolada da cena passou **26/26** e o auto-teste completo passou **9764/9764**. Isto ainda não é prova dentro do jogo.

| Estado | Lacuna observada no jogo real | Próxima fronteira honesta |
|---|---|---|
| 🔴 | `scenes/percurso.tscn` chega ao chefe (`chefe na arena: SIM`), mas `BossVorgar._install_vorgar_arena()` termina com `Vorgar: ficha vorgar_encounter em falta`. Assim, nesta árvore, `ArenaVorgar` nunca é instanciada e não foi possível ver `arena_ready`, atravessar o nevoeiro, vê-lo fechar, nem executar SEPARAR/JUNTAR pelo jogador. | Integrar a ficha `vorgar_encounter` da árvore dona de `enemies.json` e voltar a correr o percurso. A prova só passa quando também confirmar a instância `arena_id == arena_vorgar`, a transição visível do nevoeiro e as duas sequências. Não alterar `boss_vorgar.gd`/`main.gd` nesta árvore. |
| 🔴 | `empurrao_maximo_m` é lido e aplicado por `ArenaVorgar.cap_push_displacement()`, mas os cinco ataques atuais do Vorgar não declaram empurrão e nenhum sistema de deslocamento chama essa fronteira. O valor honesto no catálogo é, por isso, **0 m**, em vez de inventar um sexto efeito de combate. | Se um ataque futuro ganhar empurrão, o dono do combate deve encaminhá-lo por `cap_push_displacement()` e acrescentar uma prova jogável que mede a deslocação visível sem atravessar a colisão. |
| 🟠 | O percurso headless usa o renderer Dummy e tenta guardar capturas nulas; por isso termina com erros `save_png` mesmo quando chega ao chefe. | Para a prova visual final, correr o mesmo percurso com renderer Mobile e janela gráfica, ou tornar o dono da cena de prova tolerante a captura indisponível. |
| 🔴 | Não há medição honesta do pior caso desta versão. O harness oficial `arena_vorgar_perf.gd`, executado na Iris Xe/Vulkan Mobile, caiu com `signal 11` em `monster_visual.gd:_install_enemy_hud` antes da amostra; nas execuções estáveis/headless, a falta de `vorgar_encounter` também impede montar as guias runtime e executar as sequências. | Corrigir/contornar a queda do renderer fora desta árvore e integrar a ficha; depois medir Intel Iris Xe/8 GB com o chefe, dois jogadores, SEPARAR e JUNTAR ativos, validando os limites de `world.json.performance` antes de declarar a Lei 4 satisfeita. |

As quatro perguntas do fio ficam, portanto: o jogador usa a arena andando pelo nevoeiro e reagindo às sequências do chefe; a prova prevista é o percurso real e o resultado visível; arte e som vêm apenas dos recursos CC0 creditados em `CREDITS.md` e de síntese runtime; o custo final no Rico continua **não provado** até a ficha externa permitir montar o encontro completo.

## Limpeza da Regra de Ouro — CODEX, 02-08-2026

| Estado | Resultado | Prova exacta |
|---|---|---|
| ✅ | Os números de combate auditados deixaram de ter fallbacks positivos em GDScript; arcos, alcance de riposte, multiplicadores, tempos, PV/postura e defaults de ataque vivem nos JSON. As famílias, clips, poses, papéis de classe, abertura, dicas, armas iniciais e origens activas passam a ser descobertos nos catálogos. | Guard integrado: **verde** no auto-teste. Teste negativo confirmado: trocar temporariamente `Player.health` por `420.0` produziu `player.gd:36 — baseline numérico de combate`; o literal foi revertido. |
| ✅ | A funcionalidade foi vista no jogo real, sem instanciar apenas a classe isolada: criação mostrou `evil_mage` com as três linhas, abertura mostrou o texto catalogado, o jogador correu até aos inimigos, carregou em ataque pesado, mostrou a animação `cajado`, acertou, matou e levantou o corpo; a recusa por falta de PV apareceu no HUD. | `godot --headless --audio-driver Dummy --path game scenes/repro-inicio.tscn -- --regra-de-ouro-isolada` → `ARRANQUE + NECROMANCIA OK`; **9 ficheiros de save de teste apagados**, nenhum dos slots 0–2 usado por esta prova. |
| 🟠 | O auto-teste global conserva **9764 verdes**, mas termina com uma falha fora dos ficheiros desta tarefa: os marcadores da Toca não têm corpo nem colocação no plano virtualizado. | `game/scenes/selftest_integrated.gd:56-93` · `game/src/world/spawn_population.gd:24-82,402-446`; lacuna vermelha imediatamente acima. |
| 🟠 | O modo completo de `repro-inicio.tscn` continua bloqueado pela prova paralela de acesso rápido: `InventoryMenu._show_detail()` lança `Invalid call 'String' constructor: adaga` e, depois da virtualização, a prova procura `gameplay.boss`/barra antes de o guardião estar materializado. Não alterado porque pertence a outros ficheiros/agentes. | `game/src/ui/inventory_menu.gd:218` · `game/src/ui/quick_slots_gameplay_proof.gd:299-313`; a passagem isolada da Regra de Ouro acima fica verde. |
