# 21 — Arte, render, animação, efeitos e som

> **WP12 · Fable** (31-07-2026). O maior custo real do projeto, nunca falado na sessão 1 — tudo aqui é `[FABLE]` debaixo da **Lei 4** (Iris Xe, 8 GB partilhados, 1080p @ 60 Hz, medido quente) e de uma regra que atravessa o documento inteiro: **a legibilidade vence a beleza** — um efeito bonito que esconde uma telegrafia é um efeito errado.
>
> O que este documento **não** repete: fontes e licenças de modelos/animações/áudio vivem no [`22-assets.md`](22-assets.md) (WP13, entregue); prompts de imagem em [`art/prompts/`](../art/prompts/); hit-stop, tremor e latência no [`25-controlo.md`](25-controlo.md) (WP1B, entregue). Este documento fecha o que faltava: direcção de arte, orçamentos, a lista fina de animações com durações, as fichas de efeitos, e o som fecho-a-fecho.

## 1 · Direcção de arte

### O estilo

A frase de estilo canónica já existe e é uma só — [`art/prompts/00-estilo.md`](../art/prompts/00-estilo.md) (`[CLAUDE]` provisório, pergunta 15 continua deles):

> *Stylized dark fantasy game art, hand-painted look, muted earthy colors with cold mist accents, simple readable shapes, low-poly-friendly design, no photorealism, subtle grim humor.*

O que este documento acrescenta é a **tradução dessa frase para 3D**:

- **Formas:** silhuetas fortes e exageradas — os ombros do brutamontes 1,5× o realista, o machadão maior do que devia. Num souls-like lê-se a silhueta, não o detalhe: **a animação é a informação; o modelo é o portador.**
- **Superfícies:** o look é pintado-à-mão (frase de estilo), com o orçamento do [`30-qualidade-visual.md`](30-qualidade-visual.md): personagens com **albedo + normal + ORM a 2048²** — o normal dá volume às formas grandes, nunca poro de pele; cenário em trim sheets e atlas de 1024². PBR simplificado, sem texturas 4K. **A barra é a do 30: orçamento consciente, não PS1.**
- **Proporções de personagem: 1:6,5** (heróicas, não *chibi*). *Porquê:* o parry lê-se no braço e na anca; proporções cartoon encurtam membros e escondem telegrafias. *Alternativa descartada:* voxel/blocos — barato, mas mata a leitura de animação que é o jogo.
- **Referências** (régua, não cópia): **Ashen** (souls-like low-poly a sério), **Absolver** (combate legível estilizado), **Tunic** (cor e leitura à distância), **Valheim** (bruma e luz a esconder polígonos). O *grim humor* da frase vive nos adereços e nas descrições — **nunca** na telegrafia.

### Cor

Regra dura do jogo inteiro `[FABLE]`: **vermelho saturado é reservado a avisos de inimigo** (agarrões, marcas de área de chefe). Áreas perigosas criadas **pelo jogador** (a Ruína) marcam a âmbar. Nenhum cenário ou cosmético usa o vermelho de aviso puro. *Porquê:* é a versão em cor da regra do WP1 ("brilho vermelho = só esquiva") — uma língua, sem dialectos.

Paleta de **Brumal** (fatia 1) — coerente com os prompts do WP13:

| Papel | Cor | Uso |
|---|---|---|
| Base | verdes dessaturados (#4a5d43 ±) | vegetação, musgo |
| Profundidade | azul-cinza da bruma (#7c8a96) | névoa, longes |
| Acento | âmbar (#d9a441) | tochas, olhos de orc, pontos de interesse, marcas do jogador |
| Perigo | vermelho (#c8322b) | **só** avisos de inimigo |

A Toca escurece a mesma paleta e sobe o âmbar. Cada bioma futuro = paleta própria com **uma cor de assinatura** (WP8), para se saber onde se está numa captura sem HUD.

## 2 · Orçamento técnico — os números da Lei 4

A medição da pergunta 0b ([`09-tecnico.md`](09-tecnico.md)) validou o greybox: 60 fps cravados no cenário da fatia, com ~6× de folga média. **Essa folga é este orçamento** — e a ressalva escrita lá ("sem animação de esqueleto — a incógnita cara") é exactamente o que a secção 3 abaixo orça. Medido no alvo (máquina do Rico), quente, em combate 2+3; **estourar uma linha = parar conteúdo e optimizar** (marco 1/WP15).

**Revisto ao [`30-qualidade-visual.md`](30-qualidade-visual.md)** (31-07 — "não é PS1"): as faixas de malha e textura são as do 30; o que este documento acrescenta são os tectos de cena que o Iris Xe impõe por cima delas.

| Recurso | Orçamento | Nota |
|---|---|---|
| Triângulos em cena | ≤ **1,5 M** visíveis | a névoa aos 60 m corta o resto; **valida-se no marco 2 — se o Iris Xe disser menos, corta-se cenário, não personagens** |
| Jogador | **10 000–15 000 tris** (30) | por classe, vestes incluídas |
| Inimigo comum | **6 000–10 000 tris** (30) | lanceiro/brutamontes partilham base |
| Vorgar | **20 000–30 000 tris** (30) | está sozinho em cena quando importa |
| Adereço | 200–2 000 tris (30) | por tamanho |
| Chamadas de desenho | ≤ **500** | atlas + batching; é o limite que o Iris Xe sente primeiro |
| Esqueletos | jogador 45 ossos · inimigo 30 · Vorgar 60 · **2 influências/vértice** | animação é CPU+largura de banda — é aqui que a folga dos 6× se gasta |
| Personagens animados em cena | ≤ **8** (2 jogadores + 5 inimigos + 1 reserva) | tecto de desenho de encontros para o WP6/WP8 |
| Texturas | personagem **2048²** (albedo+normal+ORM — 30) · cenário/trim sheets 1024² · adereços 512² | tudo em atlas; 2K **só** em personagens |
| Memória de texturas residente | ≤ **800 MB** | subiu com os 2048² dos personagens (30); RAM partilhada — cada MB de textura é RAM que o jogo perde; o working set de 2,5 GB não mexe |
| Working set total | ≤ **2,5 GB** | o tecto real são 3–4 GB (pergunta 0); 2,5 deixa o SO respirar — e a medição 0b já viu a memória a crescer: vigiar é regra |
| Partículas vivas | ≤ 300 · ≤ 4 emissores/personagem | §5 |
| Alvo / mínimo | **60 fps / 50 fps** com escala dinâmica | critério 5 do WP0 |

## 3 · Personagens e animação

### Construção

- **Um corpo base + um esqueleto para as 6 classes**, com **4 pontos de encaixe de armadura** (elmo, peito, mãos, pernas — a armadura por peças do [`33-morte-e-almas.md`](33-morte-e-almas.md) §3 obriga a modular, e vê-se no corpo porque "o que se vê pode cair") + arma na mão e escudo no antebraço. **Realinhado:** a primeira versão desta regra descartava o modular — a decisão da armadura inverteu-a; o custo controla-se com peças desenhadas **sobre o mesmo corpo base** (sem re-rigging por peça) e testadas contra as animações uma vez por *slot*, não uma vez por peça.
- **Lanceiro e brutamontes partilham a malha base de orc** (brutamontes a 1,3× com ombros próprios) — 1 esqueleto, 2 variações. Vorgar é malha própria (1,6×, adereços de armadura — lista de compras do WP13).

### O viewmodel de primeira pessoa — a conta nova ([`29-perspectiva.md`](29-perspectiva.md))

A perspectiva dupla acrescenta um **conjunto de braços-e-arma de 1.ª pessoa** separado do corpo. A conta `[FABLE]`, por cima da lista abaixo: 5 famílias × ~5 clips (leve×combo, pesado, idle, bloqueio/parry onde a família apara) + 3 conjurações + frasco + rolamento (mãos) ≈ **+32 clips**. Duas notas que controlam o custo:

- **Adopto a recomendação `[CLAUDE]` do 29: a fatia 1 afina-se em 3.ª pessoa primeiro** — o viewmodel entra logo a seguir (fatia 1.5), quando os números do combate estiverem fechados; animar duas vistas de números ainda vivos é pagar tudo duas vezes.
- Em co-op o parceiro vê-te **sempre** em 3.ª pessoa — o conjunto de corpo completo abaixo é obrigatório de qualquer forma; o viewmodel é sempre um acrescento, nunca um substituto.

### A lista fina de animações — durações-contrato

O WP13 estimou "~55 animações" por alto e delegou aqui o detalhe. O inventário fino dá **~95 clips** — a diferença importa para o plano (WP15), por isso fica escrita. **As durações são as do frame data do WP1: a animação é o contrato** — se o rolamento diz 0,60 s, são 36 frames, sem "quase".

**Jogador — 57 clips**, partilhados pelas 6 classes (1 esqueleto):

| Grupo | Clips | Duração | Origem (regras no WP13) |
|---|---|---|---|
| Locomoção: idle, andar ×4, correr, sprint, strafe ×4, exausto | 11 | loops 0,8–1,2 s | packs CC0 / Mixamo |
| Rolamento ×4 direcções | 4 | 0,60 s | Mixamo + corte à mão (i-frames 5–23 têm de bater) |
| Espada reta: leve ×3, pesado, idle de combate | 5 | 0,67 / 1,03 s | packs + mão |
| Adaga: leve ×4, pesado, idle | 6 | 0,50 / 0,75 s | packs + mão |
| Machadão: leve ×2, pesado carregável (segura +20 f), idle | 4 | 0,97 / 1,37 s+ | mão (o carregado é identidade) |
| Cajado: pancada ×2, pesado, idle | 4 | 0,72 / 1,08 s | packs |
| Escudo: erguer (0,1 s), loop, impacto, **Guarda Quebrada**, bash | 5 | 1,5 s a quebra | packs |
| **Parry ×2** (escudo, adaga) + **riposte** + **backstab** | 4 | 0,9 s riposte | **mão — são o jogo** |
| Conjuração ×3 (Dardo 0,8 s · Ruína 1,6 s · Égide 0,5 s) | 3 | WP4 | mão (telegrafia para o parceiro) |
| Reacções: HitStun ×2 (0,4 / 0,7 s), morte, renascer | 4 | WP1 | Mixamo |
| Frasco (1,2 s), interagir, descansar, subir de nível | 4 | WP5 | Mixamo |
| Habilidades ×6: Ímpeto, Eco, Provocação, Passo Sombra, Fúria, Julgamento | 6 | 0,4–0,8 s | mão |
| Skill com corpo próprio: Chute | 1 | 0,4 s | mão |

**Inimigos — 36 clips:**

| Inimigo | Clips | Notas |
|---|---|---|
| Orc lanceiro | 12 — idle, patrulha, alerta, perseguição, **fecho** (o anti-kite dos 4 s do WP1), estocada (aviso 0,5 s), combo ×2, ataque de corrida, **Cambaleio** (1,2 s), morte ×2 | o professor da esquiva |
| Orc brutamontes | 10 — idle, andar, **pancada vertical** (arma acima da cabeça, aviso 0,9 s — todos os golpes dele aparáveis, WP1), varrido (0,6 s), investida, HitStun, Cambaleio, grito, morte ×2 | o professor do parry |
| Vorgar | 14 — intro, 5 ataques fase 1, 3 novos fase 2, transição (grito 2,5 s, invulnerável), Cambaleio, **Postura Quebrada** (2,0 s — o estado pós-parry, ripostável), morte, idle ×2 | **tudo à mão — o chefe é onde o tempo se gasta** |

**Regra de telegrafia animada** (contrato com WP6): todo o ataque inimigo tem **antecipação ≥ 0,5 s legível na silhueta** — não no rosto, não só na cor. E uma língua visual fixa para a marca `só esquiva` do WP1: **ataques que não se aparam (agarrões, áreas, projécteis grandes) levam brilho vermelho curto** no inimigo ou marca vermelha no chão; ataques aparáveis telegrafam só com a silhueta, sem vermelho. Uma língua, jogo inteiro.

## 4 · Render — o pipeline que o Iris Xe aguenta

A medição 0b já escolheu com dados: **renderer Mobile (forward) no protótipo Godot — 412 fps em greybox, melhor 1% low, −33% de VRAM**. A escolha formal de engine é do WP14; o que fica aqui é a exigência que qualquer pipeline tem de cumprir:

- **Forward, um passe. Render diferido proibido** — largura de banda é o que o integrado não tem.
- **Iluminação:** 1 direccional em tempo real **sem sombras dinâmicas de cena** + assado (lightmaps 32 px/m em interiores, vertex-baked no exterior). Tochas: luz assada + tremulação por material. Máx. **4 luzes dinâmicas pequenas** em cena (o Dardo em voo é uma delas — raio 4 m, sem sombra).
- **Sombras de personagem: blob estilizado** (disco suave nos pés). *Porquê:* shadow maps decentes custam 3–5 ms no Iris Xe — meio orçamento de frame; o blob dá a leitura de posição (a que a esquiva precisa) por ~0,1 ms. *Reavalia-se com medição:* 1 cascata só do sol, se o marco 2 mostrar folga.
- **Névoa exponencial + distância de visão 60 m** em Brumal (30 m na Toca). A bruma é arte, é render e é o nome da zona — esconde o corte do mundo e corta o que se desenha.
- **Céu: skybox pintado** — prompt já pronto em `art/prompts/06-ui-ceu.md` (WP13).
- **Pós:** tonemapping + vinheta leve + AA barato (FXAA, ou MSAA 2× se a medição do marco 2 o der de graça no forward). **Proibidos:** TAA e motion blur (borram a leitura de animação — atacam a Lei 1), SSAO, profundidade de campo, bloom de ecrã inteiro.
- **Escala dinâmica de resolução:** 100% → 75% por degraus quando o frame passa de 15 ms; HUD sempre nativo.

| Técnica | Ganha | Custa (estim.; marco 2 mede) | Veredicto |
|---|---|---|---|
| Forward + assado | tudo | ~8–10 ms de cena | ✅ validado em greybox (0b) |
| Blob shadows | posição legível | ~0,1 ms | ✅ |
| 1 cascata de sombra do sol | profundidade | 3–5 ms | ⏸️ só com medição a sobrar |
| FXAA / MSAA 2× | arestas calmas | ~0,4 ms / ~1 ms | ✅ um deles |
| Bloom meia-res (interiores) | magia com brilho | ~0,8 ms | ⏸️ medir |
| TAA · motion blur · SSAO · DoF | — | 2–6 ms cada | ❌ custo **e** legibilidade |

## 5 · Efeitos visuais

Regras: **legibilidade vence beleza**; efeitos do jogador ficam **finos e baixos** (o espaço acima da cintura do inimigo pertence às telegrafias dele); vermelho é dos inimigos, âmbar é do jogador; sprites grandes (bruma, fumo) em **meia resolução** — o overdraw de partículas é o assassino silencioso do integrado. Orçamento: ≤ 300 partículas vivas, ≤ 4 emissores por personagem.

### Fichas de combate (fatia 1)

| Efeito | Especificação | Dispara |
|---|---|---|
| Rasto de arma | fita 0,2 s na lâmina, cor por família (aço frio; âmbar no pesado) | frames activos |
| Impacto em carne | 6–10 partículas escuras + risco branco 4 f | acerto |
| Impacto em madeira/pedra/metal | lascas / pó / faíscas, 8 partículas | escudo/cenário |
| **Faísca de parry** | estrela dourada **12 f**, 1,5× o punho, no ponto de contacto — cola no hit-stop do WP1B | frame exacto do parry |
| Guarda Quebrada | arco de fragmentos + onda 0,3 s no escudo | stamina a 0 a bloquear |
| **Cambaleio** (postura a 0) | anel âmbar no chão (r 1 m) + o inimigo pisca âmbar 2× | tem de se ler do outro lado da arena: é o sinal de crítico |
| Postura Quebrada (pós-parry) | idem + partículas a cair do inimigo ajoelhado, 2,0 s | parry acertado |
| Crítico (riposte/backstab) | 1 frame branco no alvo + sangue estilizado (puffs escuros, sem gore) | animação de crítico |
| Morte de inimigo | dissolve 1,5 s de baixo para cima + 8–12 motas de XP a voar ao jogador | vida a 0 |
| Telegrafia de `só esquiva` (agarrões, áreas) | **brilho vermelho** pulsante no torso, 0,25 s | a língua fixa desta secção, marcada ataque a ataque no WP6 |
| Marca de área de chefe | anel **vermelho**, contorno 8 px, preenche do centro no tempo do aviso | áreas do Vorgar |
| Marca da Ruína (jogador) | anel **âmbar** 4 m, 0,5 s antes do impacto — o parceiro lê-a como lê o chefe | WP4 |

### Magias da fatia

| Magia | Lançamento (a telegrafia do Feiticeiro, visível ao parceiro e ao inimigo) | Voo / área | Impacto |
|---|---|---|---|
| **Dardo** | glifo azul-branco a crescer na ponta do cajado, 0,8 s | traçado fino 20 m/s, luz dinâmica r 4 m | estrela branca 8 f |
| **Ruína** | o cajado ergue-se, runas no chão, 1,6 s | esfera em arco + marca âmbar 0,5 s | implosão + anel 4 m, 20 f |
| **Égide** | anel que sobe dos pés, 0,5 s | 3 placas orbitais translúcidas (2,5 s ou 120 de dano) | a placa que absorve estilhaça |

Quando o **mal** entrar (pergunta 8): o preço em PV **tem de se ver** — motas vermelho-escuras a sair do corpo do lançador no frame do custo. Fica como regra à espera do catálogo.

### Estados e ambiente

- **Choque** (Julgamento do Paladino): arcos branco-azuis 4 f a cada 0,5 s. Fogo/veneno ⬜ ganham ficha quando entrarem (WP5/WP6).
- **Brumal:** bruma em cartões meia-res (máx. 12), folhas a cair (1 emissor global, 20 partículas), feixes de sol assados no lightmap. **Toca:** gotejar, poeira nos feixes das tochas.
- **Interface (contrato com WP11):** dano = vinheta vermelha 0,3 s (nunca ecrã opaco); stamina a zero = barra pisca âmbar 2×; vida < 25% = pulso lento na barra, sem som de coração em loop.

## 6 · Som

Regra que manda: **um chefe lê-se de ouvido.** Cada ataque tem som de antecipação **distinto**; de olhos fechados distingue-se o aparável do não aparável — o não aparável **arrasta grave** (a pancada vertical do brutamontes), o agarrão **assobia agudo**. É o par áudio das duas línguas visuais fixas, e é pista extra para a Lei 1.

### Música — 6 peças + 3 stingers (~14 min compostos)

| Peça | Duração | Comportamento |
|---|---|---|
| Menu (reusa no descanso, mais baixa) | 2 min loop | — |
| Brumal — camada calma | 3 min loop | base de exploração |
| Brumal — camada de tensão | mesma grelha | crossfade 2 s ao entrar em combate; sai 4 s depois do último inimigo desistir |
| A Toca | 2,5 min loop | mais esparsa, mais grave |
| Vorgar fase 1 / fase 2 | 2,5 min loop cada | a fase 2 entra no grito de transição, cosida por stinger de 2 s no compasso |
| Stingers: morte · vitória · descoberta | 5 / 8 / 3 s | na morte, a música **corta no golpe fatal** — 0,5 s de silêncio antes do stinger é o efeito |

(O WP13 estimou "4–5 faixas"; a conta fina dá 6 + stingers — a camada dupla de Brumal é o que cresce, e é a que faz o combate *sentir-se* diferente de explorar.)

### Ambiente, por camadas

- **Brumal:** vento na copa (base, −18 dB) + folhagem intermitente + corvos distantes (aleatório 20–60 s) + one-shots raros de criatura na bruma, lado aleatório — a bruma tem de parecer habitada.
- **Toca:** gotas com eco longo + rumble < 60 Hz no limiar + correntes ao longe.

### Efeitos — o catálogo da fatia

- **Matriz arma × material:** 5 famílias × 4 materiais (carne, madeira, pedra, metal) × 2 variações = **40 impactos**. Whoosh por peso: leve/médio/pesado ×3 variações.
- **Parry: UM som icónico** (sino metálico + estalo), 3 variações mínimas. É o som mais importante do jogo — escolhe-se à mão e testa-se com os dois. Bloqueio madeira/ferro, Guarda Quebrada (racha + queda), Cambaleio (craque grave + guizo âmbar), crítico (perfuração curta, estilizada).
- **Passos:** 4 pisos (terra, folhas, pedra, madeira) × andar/correr × 4 variações = 32. Rolamento (pano + baque), exaustão (respiração em loop até aos 15 de histerese), frasco (gole + vidro), apanhar item, XP (cintilar), subir de nível (acorde curto).
- **Magias:** por magia, lançamento (o glifo **carrega** — é a telegrafia audível), voo (loop curto) e impacto. A Égide a absorver = vidro grosso a rachar.
- **Inimigos:** orc — 4 grunhidos idle, **alerta** (a chamada que avisa o jogador que foi visto: é mecânica, não decoração), esforço distinto por golpe, dor ×3, morte ×2; brutamontes uma oitava abaixo + o arrasto grave; Vorgar — respiração de arena em loop, rugido de intro, grito de fase 2, esforços por ataque, morte.
- **Jogador:** esforço leve/pesado, dano ×3, morte, respiração de sprint; **2 conjuntos de voz** (grave/agudo, escolha na criação — WP11). Gravar os grunhidos em casa é opção séria (WP13) — e uma noite divertida.

### Mistura

- **Prioridades (de cima para baixo):** telegrafias de ataque > golpes no jogador > parry/Cambaleio > vozes do jogador > impactos gerais > música > ambiente. Tecto de 24 vozes simultâneas; corta-se de baixo.
- **Ducking:** telegrafia de chefe baixa a música −4 dB por 0,5 s; pausa baixa tudo −8 dB menos UI. Canais separados nas opções (WP11): geral, música, efeitos, ambiente, vozes.
- Música em streaming; SFX residentes ≤ **150 MB** (dentro do working set do §2). Licença por ficheiro no manifesto — regras do WP13, sem excepções.

## O que este documento não fecha

- **Estilo visual = pergunta 15, deles** — isto é a proposta concreta; o caminho barato para o sim é gerar 3–4 conceitos com os prompts do WP13 e pôr os dois a escolher
- **Engine e medições reais** → WP14 / marcos 1–2 do WP15 — as estimativas de custo daqui viram medições lá
- **Animação de esqueleto medida** — a incógnita declarada na 0b; o teto de 8 personagens animados do §2 é a aposta a validar
- **Quem compõe a música** — ferramenta e fluxo a decidir com o Mateus (as imagens já têm dono; o som ainda não)

## Ligações

[`09-tecnico.md`](09-tecnico.md) (restrição-mãe + medição 0b) · [`01-combate.md`](01-combate.md) (durações-contrato) · [`13-magia.md`](13-magia.md) · [`22-assets.md`](22-assets.md) (fontes/licenças) · [`25-controlo.md`](25-controlo.md) (hit-stop) · [`10-fatia-1.md`](10-fatia-1.md)
