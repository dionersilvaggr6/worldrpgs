# Revisão de código — 02-08-2026

**Papel:** revisor. Não foi alterado nenhum ficheiro de código, cena, dados ou jogo.  
**Veredicto:** **NOT READY**. Há combate funcional, mas as provas dão verdes falsos, Vorgar está integrado só pela metade, a Lei 2 está codificada como multiplicador num fio incompleto, a Lei 4 continua vermelha e a geometria de dano não coincide com o que se vê.

## O que executei antes de ler

| Prova | Resultado observado |
|---|---|
| `game/scenes/percurso.tscn` | chegou à arena; encontrou 37 lanceiros e 3 brutamontes; declarou **0 mortos**; emitiu `Vorgar: ficha vorgar_encounter em falta` |
| `game/scenes/sessao-de-jogo.tscn` | declarou **0 falhas em 27 passos**; emitiu o mesmo erro de Vorgar |
| `game/scenes/filme-de-combate.tscn` | 30 imagens; PV inimigo `135 → 89 → 52 → 14 → 0`; continuou a atacar o cadáver |
| `game/scenes/filme-de-ataque.tscn` | declarou 32 imagens; são 16 pares duplicados |
| `node tools/orfaos.mjs` | zero `class_name` órfãos segundo a heurística |
| `node tools/cobertura-spec.mjs` | 6 documentos sem chão; `50-racas.md` com 1/4 âncoras; a própria ferramenta avisa que mede existência, não qualidade |
| `boss_vorgar_self_test.gd` | **falhou**: 5 passaram, 1 falhou; depois lançou erros de script e chamou uma API `setup()` que a arena não tem |

Foram abertas as **103 imagens** em `game/captures/`, não apenas os logs. Em particular:

- `percurso-20.png` mostra um brutamontes morto e a recompensa `+80 almas · material:couro_javali`;
- `percurso-25.png` mostra `ORC LANCEIRO 0/135 PV · DERROTADO`;
- `percurso-chefe.png` mostra o jogador a `0/442 PV`, `[morto]`, junto da arena;
- `combate-26.png` a `combate-29.png` mostram o inimigo morto e o jogador a continuar o combo;
- o filme de ataque está parcialmente tapado pela fogueira e pelo escudo, portanto não prova a forma do golpe nem da hitbox.

## Diagnóstico pedido: por que razão o percurso conta zero mortos

**Causa encontrada. Não é alcance, cura nem dano. É o contador.**

- `game/src/tools/percurso.gd:88-95` só soma uma morte quando `is_instance_valid(inimigo)` passa a falso.
- `game/src/enemies/enemy.gd:760-776` transforma a morte em estado `DEAD`, retira o inimigo do grupo e pára a física, mas conserva deliberadamente o nó como cadáver para necromancia.
- `game/src/enemies/enemy.gd:792-793` já expõe a pergunta correcta: `is_alive()`.
- `game/src/tools/filme_de_combate.gd:75-77` repete o mesmo erro e, por isso, filma ataques contra o morto.

As capturas provam que o percurso matou. **Não se deve corrigir isto com `queue_free()` no inimigo:** isso destruiria a identidade do cadáver e a necromancia. O contador tem de observar `is_alive()`, o sinal `died` ou a saída do grupo `enemies`.

O percurso também não prova aquilo que o nome promete:

- `game/src/tools/percurso.gd:67-70` tenta activar uma propriedade `invulnerable` que o `Player` não possui; a captura final mostra o jogador morto;
- `game/src/tools/percurso.gd:73-77` teleporta entre sete pontos, portanto não prova caminhada, colisões, navegação ou atalhos;
- `game/src/tools/percurso.gd:104-115` apenas verifica que há um nó de chefe e tira uma fotografia; nunca luta com Vorgar.

## Achados — gravidade alta

### P1 — A geometria de dano mente ao jogador

**Ficheiros:** `game/src/enemies/enemy.gd:695-715`; `game/src/combat/gameplay_cue.gd:71-86`; `game/src/visual/monster_visual.gd:472-481`; `spec/38-ataques-e-honestidade.md:45,76-82`.

Para ataques comuns, o dano é decidido por um cone invisível: distância até `range + body_radius` e ângulo até `arc_degrees / 2`. O aviso visual, porém, é sempre uma caixa com apenas `0,12 m` ou `0,34 m` de largura. A animação dá uma pose própria só ao lanceiro; todos os outros inimigos partilham a mesma pose genérica, apesar de as fichas declararem arcos muito diferentes.

Logo, a forma que acerta não é a forma que se vê. O acréscimo de `body_radius` torna ainda possível acertar para lá do alcance declarado. Isto viola directamente o contrato de honestidade: a hitbox nunca pode ser maior ou mais comprida do que a forma visível.

O teste existente não protege esta cláusula. `game/src/player/attack_family_self_test.gd:71-82` calcula `hitbox_active` com a mesma expressão que `visible_strike_active()` usa e compara uma com a outra. Prova que duas expressões iguais são iguais; não observa arma, efeito, colisão, falha lateral nem os controlos negativos 10/10 de `spec/38`.

### P1 — Vorgar existe como boneco, mas o encontro especial não existe no jogo

**Ficheiros:** `game/data/enemies.json:620-639`; `game/src/enemies/boss_vorgar.gd:24-40`; `game/src/world/arena_vorgar.gd:60-128`; `game/src/enemies/boss_vorgar_self_test.gd:83-112,176-198`; `game/VERIFICAR.bat:29-78`.

`BossVorgar` exige `vorgar_encounter`, mas a ficha termina sem esse campo. Depois tenta chamar na arena `setup`, `begin_sequence`, `tick_sequence`, `join_safe_center_global`, `end_sequence` e `reset_attempt`; `ArenaVorgar` não expõe essas APIs. Todas as quatro cenas jogadas imprimiram o erro.

O auto-teste dedicado confirma a quebra: falha a existência de SEPARAR/JUNTAR e depois rebenta ao chamar `setup()`. Pior: `VERIFICAR.bat` afirma correr todas as verificações, mas não inclui este teste. É assim que um chefe partido coexiste com “tudo passou”.

### P1 — A Lei 2 está codificada como multiplicador e a integração nem entrega o benefício

**Ficheiros:** `game/data/spells.json:3-4,3072-3108`; `game/src/classes/dark_mage.gd:102-121,247-250`; `game/src/classes/dark_mage_origin_test.gd:103-116,184-197`; `game/src/summons/necromancy_runtime.gd:268-292`; `game/src/player/player.gd:823-833`.

O Voto de Sangue não oferece três verbos: cada camada reserva vida máxima e calcula **+30%, +60% ou +90% de dano**. O catálogo admite que isto está em tensão com a Lei 2; `DarkMage` devolve o multiplicador e o teste exige que chegue à última camada. Marcar a contradição com `[TENSÃO]` não deixa de a codificar como a resposta.

A integração de produção agrava a falha: `NecromancyRuntime` aplica o Voto e reserva os PV, mas `_deal_damage_to()` nunca consulta o multiplicador. Portanto, no jogo actual o jogador pode pagar a vida e não receber o aumento que a ficha promete. É simultaneamente uma Lei 2 quebrada no contrato implementado e um fio de gameplay incompleto.

As melhorias normais de feitiço +1…+5 estão honestamente bloqueadas em `game/data/spells.json:180-185`; não são o problema actual. O problema é o Voto base já executável.

### P1 — A Lei 4 continua vermelha; o passo da sessão não a mede

**Ficheiros:** `game/project.godot:45-63`; `JOGAR-WORLDRPGS.bat:84-86`; `medicoes/animacao-esqueleto-2026-08-01.json:57-65,99-118`; `game/src/tools/sessao_de_jogo.gd:304-305`.

O renderer Mobile está correctamente configurado e o lançador força-o. Isso deve ser conservado. Contudo, a medição de apresentação com cinco actores dá p99 real de **18,323 ms** contra o tecto de **16,67 ms** e marca `fail_p99`; a própria conclusão diz `not_ready` e que falta a prova quente integrada 2+5.

A sessão lê `Engine.get_frames_per_second()` uma única vez e aprova se vir 55. Isso não mede aquecimento, p95, p99, pior frame, memória, resolução ou máquina. O “60 fps” verde da sessão não pode sobrepor-se ao gate medido que falhou. Os FPS mostrados durante gravação PNG também não servem para aprovar ou reprovar o jogo normal, porque a própria captura acrescenta carga.

### P1 — As provas principais aceitam estados que contradizem os próprios títulos

**Ficheiros:** `game/src/tools/sessao_de_jogo.gd:149-165,180-193,304-314`; `game/src/tools/filme_de_combate.gd:60-77`; `game/src/tools/filme_de_ataque.gd:77-96`.

- “atacar entra em estado de ataque” passa desde que `state_name()` exista. Na execução, o detalhe foi `estado=livre` e mesmo assim ficou verde;
- “o dano real mata” injecta exactamente os PV restantes por `DamageInfo.make()`; prova o handler de morte, não que um ataque normal acerta e mata;
- qualquer quantidade de falhas termina com `quit(0)`, portanto automação externa recebe sucesso;
- o filme de combate só reconhece morte quando o nó deixa de ser válido e continua a atacar o cadáver;
- o filme de ataque guarda a mesma `Image` duas vezes, uma síncrona e outra em worker. As 32 imagens são 16 pares duplicados.

Um banco de ensaio que não falha o processo e não testa a frase que imprime é mais perigoso do que não ter banco: produz confiança falsa.

## Achados — gravidade média

### P2 — A regra de ouro volta a ser violada por números de combate em GDScript

**Ficheiros:** `game/src/player/player.gd:698-717,736-742,797-804`; `game/src/enemies/enemy.gd:39-45,613-617,643-651,695-712`.

Há baselines de arranque/activo/recuperação, stamina, carga, MV, hiper-armadura, alcance e um arco fixo de **110°** no jogador. No inimigo há PV/postura/raio, tempos, raio, alcance e arco como fallbacks. Mesmo que os JSON normalmente os substituam, continuam a ser números de combate escritos à mão e tornam dados incompletos silenciosamente jogáveis.

O arco fixo de 110° é especialmente grave: famílias e animações diferentes acertam pela mesma forma invisível. Viola simultaneamente a regra de ouro e a honestidade.

### P2 — A regra de ouro volta a ser violada por listas de conteúdo em GDScript

**Ficheiros:** `game/src/player/attack_animation_controller.gd:9-58,97-106`; `game/src/ui/game_shell.gd:14-35,72-79,574-583`; `game/src/ui/intro_sequence.gd:11-36`; `game/src/weapons/starting_loadouts.gd:6-12,89-97`; `game/src/main.gd:541-555`.

Exemplos reais:

- `FAMILY_ANIMATIONS` volta a escrever no código todas as famílias, movimentos e clips, incluindo `Punch_Jab`, `Punch_Cross` e `Sword_Attack` — exactamente a classe de defeito que já aconteceu;
- `CLASS_IDS` agora é dinâmico, mas `CLASS_ROLES` continua com seis origens. `evil_mage` recebe três textos vazios na criação;
- dicas, armas iniciais, strings obrigatórias e abertura existem em listas duplicadas entre `GameShell` e `IntroSequence`;
- `ACTIVE_ORIGIN_IDS` diz ser só compatibilidade, mas `main.gd` ainda o usa para retirar origens do catálogo que valida. A oitava origem voltará a desaparecer desse contrato até alguém editar a constante.

O resultado não é teórico: corrigiu-se uma lista de seis e ficou outra lista de seis no mesmo ecrã.

### P2 — Há dois renderers de inimigo em sequência para a mesma responsabilidade

**Ficheiros:** `game/src/enemies/enemy.gd:21-23,299-320`; `game/src/main.gd:379-410`.

`Enemy.setup()` cria e configura `EnemyVisualRenderer`. Logo a seguir, cada `_spawn()` chama `_attach_monster_visual()`, remove esse renderer, agenda-o para libertação e instala `MonsterVisual`. São dois caminhos de corpo, animação, assets e sinais para o mesmo inimigo.

Além da duplicação, isto carrega/configura trabalho para o deitar fora e permite que galeria, testes e jogo vejam renderers diferentes. As cenas terminaram com 6–10 objectos vivos; não há prova de que esta duplicação seja a causa das fugas, mas é o primeiro caminho paralelo a eliminar antes de esconder os avisos.

### P2 — A Lei 1 tem fórmulas, não a prova jogada decisiva

**Ficheiros:** `game/src/autoload/game_data.gd:541-571,699-706`; `game/src/tools/percurso.gd:104-115`; `game/scenes/selftest_integrated.gd:109-151`.

Não encontrei uma porta de nível nem um bloqueio de arma. O cálculo abaixo do requisito aplica ×0,6 e continua, o que cumpre a Lei 3. Porém, a alegada prova de Lei 1 apenas calcula quantos golpes a vida do chefe deve aguentar. O teste integrado reduz os PV de Vorgar ao dano previsto e observa a morte. O percurso não o combate.

Continua por provar dentro do jogo: personagem nível 1, zero pontos, encontro completo, esquivas/parries normais, até matar Vorgar sem injecção de PV ou dano.

### P2 — Sistemas com prova focal continuam sem prova no jogo

**Ficheiros:** `game/src/net/net_selftest.gd:8-13`; `game/src/spells/spell_delivery.gd:371-384`; `game/src/spells/spell_delivery_self_test.gd:16-23`; `tools/cobertura-spec.mjs:17-22,76-92`.

- a rede testa protocolo e autoridade, mas declara explicitamente que não liga duas máquinas;
- `SpellDelivery` só entrega efeitos não numéricos se o alvo implementar `receive_spell_contact`; esse método existe no duplo do teste, não em nenhum alvo de produção;
- o analisador de cobertura encontrou sem chão `23-tecnico.md`, `24-plano.md`, `27-aprendizagem.md`, `28-testes.md`, `48-arcos-bestas-escudos.md` e `61-arenas-de-chefe.md`, e apenas 25% em `50-racas.md`. Isto é um sinal para inspecção, não prova automática de ausência, porque a própria ferramenta só procura âncoras textuais.

`orfaos.mjs` passar também não contradiz estes achados: `tools/orfaos.mjs:14-15,69-78` só exige uma menção externa ao `class_name`. Uma chamada incompatível, um consumidor que não produz efeito e dois renderers concorrentes contam todos como “ligados”.

## Achados — gravidade baixa

### P3 — As capturas ainda não são uma prova visual fiável do combate

**Ficheiros:** `game/src/tools/percurso.gd:154-157`; `game/src/tools/filme_de_ataque.gd:77-96`.

A câmara fixa fica frequentemente atrás de árvores, arcos, do escudo e da fogueira. Marcadores verticais amarelos tapam personagens no percurso. O filme de ataque duplica frames e não desenha a hitbox. Serve para descobrir defeitos grosseiros, mas não para aprovar contacto, alcance ou timing.

## As quatro leis — conclusão

| Lei | Estado | Julgamento |
|---|---|---|
| 1. Habilidade acima de nível | **não provada** | não encontrei gating de nível; i-frames e penalidade de requisito estão correctos, mas ninguém vence Vorgar a nível 1 dentro do encontro real |
| 2. Melhorias dão opções | **falha** | armas cumprem; o controlador do Voto codifica +30/+60/+90%, e o caminho de dano nem consome esse resultado |
| 3. Qualquer classe, qualquer arma | **cumpre no runtime actual** | não há rejeição de equipamento; abaixo do requisito continua a funcionar a ×0,6; as listas manuais deixam risco real de regressão |
| 4. A máquina alvo manda | **falha o gate actual** | Mobile está certo, mas p99 de apresentação e arena final permanecem acima do orçamento e falta prova quente 2+5 |

## Se só pudesse fazer uma coisa

**Faria a geometria visível ser a única autoridade do dano.** Removeria o cone matemático independente e faria a colisão varrer exactamente a arma/efeito mostrado, alimentada pela mesma ficha. Depois exigiria, para cada ataque, contacto visual positivo e falhas laterais/cedo/tarde 10/10 dentro da cena real. Enquanto um golpe pode acertar fora do que se vê, afinar dano, conteúdo ou dificuldade só melhora um combate injusto.

## O que está bem e não se deve mexer

- **Cadáver persistente:** `game/src/enemies/enemy.gd:760-776` é necessário à necromancia. Corrija-se o observador, não o cadáver.
- **Lei 3 no cálculo:** `game/src/autoload/game_data.gd:541-571` reduz rendimento abaixo do requisito sem proibir a arma.
- **Melhorias de armas:** `game/src/weapons/weapon_progression.gd:41-52,114-145` rejeita aumento de dano base e oferece escolhas por nível. Não reintroduzir `+% dano` para “simplificar”.
- **Gate honesto das melhorias de feitiço:** `game/data/spells.json:180-185` não finge que +1…+5 estão decididos.
- **Renderer do alvo:** `game/project.godot:45-63` e `JOGAR-WORLDRPGS.bat:84-86` escolhem Mobile de forma explícita. O problema é pacing/prova, não essa escolha.
- **Lista dinâmica de origens:** `game/src/ui/game_shell.gd:14-20` passou a ler o catálogo. Deve ser o padrão para remover as listas paralelas restantes.
- **Uma fonte temporal para o golpe do jogador:** `game/src/player/attack_animation_controller.gd:213-219` lê `startup/active` da ficha. Conservar esta fonte única; falta tornar única também a geometria.

## Frase honesta

**Ainda não é um souls-like; é um protótipo de acção com vocabulário de souls-like.** Tem stamina, esquiva, fogueira, morte persistente, padrões e chefe, mas ainda não prova os três contratos que transformam esses verbos no género: golpe visualmente verdadeiro, chefe completo vencível por leitura e frame pacing estável na máquina alvo.
