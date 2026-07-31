# 20 — Interface e configurações

> **WP11 · Fable** (31-07-2026). O ecrã inteiro, a 1920×1080 (a resolução das duas máquinas — pergunta 0). Herda: hotbar em baixo `[DECIDIDO]` (04:37), mochila limitada `[DECIDIDO]` (04:34), a dúvida das magias no ecrã (04:55/04:59), o HUD mínimo do [`08-ui.md`](08-ui.md), os comandos do WP1 e o feedback visual do WP12. Regra do documento: **o HUD diz o que o corpo não consegue dizer — e mais nada.** Tudo `[FABLE]` salvo indicação.

## HUD — o que está no ecrã durante o jogo

Posições em coordenadas de 1920×1080; tudo escala com a opção "tamanho do HUD".

| Elemento | Onde | Tamanho | Comportamento |
|---|---|---|---|
| **Vida** | canto sup. esquerdo (32, 28) | 340×20 px | barra; dano mostra "fantasma" vermelho que encolhe em 0,6 s (lê-se quanto doeu) |
| **Stamina** | sob a vida (32, 54) | 300×14 px | âmbar; some 1,5 s depois de cheia — só existe quando interessa; pisca 2× ao esgotar (WP12) |
| **Cargas de magia** | sob a stamina | pips de 14 px | 1 pip por carga total (Sab 14 → 7 pips); vazios ficam ocos |
| **Magias equipadas** | canto inf. esquerdo (32, 940) | 3 quadrados de 72 px | a activa à frente e maior; **F** roda (WP1); o custo em cargas no canto do ícone — responde ao 04:55: **3 visíveis, sempre** |
| **Hotbar** | fundo ao centro (760–1160, 1000) | **5 espaços** de 72 px | teclas 1–5 (WP1); o item activo (R) com moldura; quantidade no canto |
| **Habilidade de classe** | à direita da hotbar | 72 px | ícone + recarga em varrimento circular; tecla **G** (WP3, regra dos comandos do 34) |
| **Arte de arma** | à esquerda da hotbar | 72 px | ícone da arte da arma equipada; tecla **V** (WP5) |
| **Skills activas** | junto à arte de arma | 2×56 px | slots `X`/`Z` (WP3); só aparecem se a skill equipada for activa |
| **Vida do chefe** | fundo (480–1440, 944) | 960×22 px + nome | só em arena; a barra de postura dele por baixo, fina (960×6) |
| **Parceiro** | sob a tua vida (32, 84) | 200×12 px + nome | vida e estado (a beber, caído, longe →seta); **quem o chefe persegue** tem um olho âmbar junto ao nome (WP7/WP10) |
| **Aviso de latência** | canto sup. direito | ícone 28 px | só quando > 150 ms (WP10); nunca número, só o ícone |
| **Pistas de interacção** | centro-baixo, sobre o objecto | texto 20 px | "E — apanhar" a ≤ 2 m e a olhar; nunca setas para longe |

**Contador de almas** (realinhado ao [`33-morte-e-almas.md`](33-morte-e-almas.md)): canto inferior direito, número simples. Com as almas a caírem na morte, o que trazes por gastar é **informação de risco** — tem de estar à vista para a ganância ser uma decisão. Substitui o "sem contador de XP permanente" da primeira versão deste documento, pela razão exacta que o 33 dá: um jogador com 5.000 almas joga diferente de um com 200, e para isso tem de as ver.

**Ressurreição em co-op** (33 §4 + WP10): o morto vê o **contador do minuto** no centro-baixo do seu ecrã; o parceiro vê um **feixe âmbar** no corpo e, a ≤ 8 m, o tempo restante; durante a canalização de 5–7 s, barra de progresso sobre o corpo, visível aos dois.

**O que o HUD não tem, de propósito:** minimapa (WP8), números de dano a saltar dos inimigos (*alternativa descartada:* damage numbers — transformam leitura de animação em leitura de contabilidade; a barra do inimigo em lock-on chega), missões/objectivos (não há — WP8B).

**Barra do inimigo comum:** só com lock-on — sobre a cabeça, 120×8 px, com a postura por baixo (120×4). Some 2 s depois de soltar o lock.

## Mochila e itens

`[DECIDIDO]` capacidade limitada (04:34). Os números:

- **24 espaços** em grelha 6×4; equipamento vestido não ocupa espaço.
- **Cheia:** não se apanha — o item fica no chão com aviso ("mochila cheia"). *Alternativa descartada:* apanhar e destruir o mais antigo — decidir pelo jogador é pior do que dizer não.
- **Abre em tempo real, sempre** — solo e co-op. O mundo não pára (em co-op não pode; em solo seria treinar um hábito que o co-op pune). Beber, trocar e equipar em combate é possível e perigoso — como o frasco (WP5), decisão com corpo. *Alternativa descartada:* pausa em solo — dois comportamentos para o mesmo botão é o tipo de inconsistência que gera "o jogo comeu-me".
- **Baú no ponto de descanso** ⬜ (fatia 2, com a economia): capacidade ilimitada, acesso em qualquer descanso. A fatia não enche 24 espaços.
- Trocar hotbar ↔ mochila: arrastar, ou seleccionar + tecla 1–5.

## Ecrã de personagem e subir de nível

- **Ficha** (Tab): atributos, equipamento, skills equipadas (2+2 — WP3), resistências. Cada atributo mostra **o que dá agora e o que daria +1** ("Vida 14 → 15: PV 508 → 530") — a decisão informada é meio caminho para a Lei 1 ser sentida como justa.
- **Subir de nível: só no ponto de descanso** (WP2). O ecrã mostra XP actual, custo do próximo nível, e simulação ao vivo do ponto antes de confirmar. Sem redistribuição (WP3 — "quando doer").

## Menus

| Menu | Conteúdo |
|---|---|
| **Principal** | Continuar (último save) · Jogar a dois (hospedar / juntar por código — o fluxo < 2 min do WP10) · Novo personagem · Opções · Sair |
| **Criação** | classe (as 6 fichas do WP3 com "como se joga" numa frase) · voz grave/agudo (WP12) · nome |
| **Pausa** (Esc) | Retomar · Opções · Sair para o menu — **o mundo nunca pára** (coerência com a mochila e com o co-op); "pausar" é encostar num sítio seguro, como no género |
| **Gravação** | automática: no descanso, ao apanhar item, ao morrer, ao sair — sem botão de gravar (WP14 detalha); o menu mostra "última gravação há Xs" |

## Configurações — a lista completa

**Gráficos:** ecrã inteiro/janela · resolução (nativa por omissão) · escala dinâmica on/off (on) · limite de fps (60) · brilho · **perspectiva: 1.ª ou 3.ª pessoa** ([`29-perspectiva.md`](29-perspectiva.md) — troca fora de combate; em 1.ª: FOV 75–90°, balanço de passo on/off) · **sem presets de qualidade** — o jogo tem um alvo único (Lei 4); *alternativa descartada:* low/medium/high — três combinações a equilibrar e testar para duas máquinas conhecidas é trabalho sem cliente.

**Áudio:** 5 canais separados (geral, música, efeitos, ambiente, vozes — WP12) · o aviso sonoro de telegrafia **não tem slider próprio**: vive em "efeitos", que nunca deve ir a zero (aviso ao tentar).

**Comandos:** remapeamento total de teclado e rato (o mapa do WP1 é a omissão, **+ `G` habilidade de classe, `V` arte de arma, `X`/`Z` skills activas** — este documento valida as teclas da regra dos comandos do 34: todas ✅ livres no mapa) · sensibilidade do rato · inverter Y · o esquema de comando (WP1) aparece se um comando for ligado.

**Jogo:** tamanho do HUD (×1,0 / ×1,25 / ×1,5) · mostrar pistas de interacção (on) · legendas das pistas sonoras (off — escreve "passos atrás", "grito de alerta"; a acessibilidade que faz falta a eles é bem-vinda, conformidade formal não é objectivo) · idioma: **português, único** (briefing: jogam os dois em português).

**Rede:** nome de anfitrião · porta (omissão 27890) · código de sessão para juntar (WP10).

## Regras transversais de UI

1. **Nada de tutorial em janela** — o ensino é do mundo (WP11B/27-aprendizagem); a UI no máximo mostra a tecla contextual uma vez.
2. **Tempo real em tudo** — nenhum menu pára o mundo. O único ecrã seguro é o descanso.
3. **Toda a informação de combate vive no corpo primeiro** (telegrafia, WP12) **e no HUD segundo** — o HUD confirma, não substitui.
4. Navegação completa por teclado; rato opcional nos menus.
5. Fonte: uma família só, ≥ 18 px em 1080p em qualquer texto; números tabulares nas quantidades.

## O que este documento entrega aos outros

| Para | O quê |
|---|---|
| **WP12/WP13** | a lista de ícones com tamanhos (3 magias 72 px, hotbar 72 px, pips 14 px, retratos de classe da criação) — entra no manifesto |
| **WP10** | o fluxo hospedar/juntar por código, e o olho âmbar de alvo do chefe |
| **WP14** | gravação automática nos 4 momentos; settings num ficheiro legível |
| **WP15B** | o "fantasma" da barra de vida e a simulação de ponto são instrumentos de leitura nos testes |

## O que continua aberto

- Ícone e retrato finais por classe → WP13 gera, eles escolhem
- Baú e ecrãs de vendedor ⬜ — esperam pela economia (WP9/WP8B)
- O nome do jogo no menu principal — pergunta 21 (WP8B); até lá, "WorldRPGs" como nome de trabalho

## Ligações

[`08-ui.md`](08-ui.md) (sessão 1) · [`01-combate.md`](01-combate.md) (comandos) · [`13-magia.md`](13-magia.md) (3 slots) · [`21-arte-render.md`](21-arte-render.md) (feedback visual) · [`19-rede.md`](19-rede.md) · [`27-aprendizagem.md`](27-aprendizagem.md)
