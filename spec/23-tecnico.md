# 23 — Arquitectura técnica

> **WP14 · Fable** (31-07-2026). Engine, sistemas, dados, gravação e ferramentas — tudo decidido pela **Lei 4 primeiro** ([`09-tecnico.md`](09-tecnico.md)) e pelos contratos que os outros pacotes já assinaram: frames-como-contrato (WP1/WP12), autoridade dividida e dois sacos de estado (WP10), dados afináveis para o protótipo (WP15B). **Este documento não escreve código** — descreve o que o código tem de ser, para o Opus 5 construir sem perguntar. Tudo `[FABLE]` salvo indicação.

## Engine — a escolha, com os dados que já existem

O critério do briefing: *o que é que cada engine entrega mesmo sem GPU dedicada.* E há uma medição real na mesa: **o protótipo da pergunta 0b correu em Godot 4.7.1, renderer Mobile, na máquina do Rico — 60 fps cravados no cenário da fatia, 416 fps em greybox, 20 min quente sem degradação** ([`09-tecnico.md`](09-tecnico.md)).

| | **Godot 4.x** | Unity | Unreal 5 | Motor próprio |
|---|---|---|---|---|
| No Iris Xe | ✅ **medido**: renderer Mobile forward, leve por defeito | possível com URP, mas o editor e o overhead pesam nas máquinas deles | assume deferred/Lumen/Nanite — tudo o que a Lei 4 proíbe; desligar tudo é remar contra o motor | teoricamente óptimo |
| Custo / licença | grátis, MIT, sem contas | grátis até tecto de receita; políticas de licença com histórico instável | 5% royalties (irrelevante) mas pesado | tempo infinito |
| Rede para 2 | multiplayer de alto nível embutido (autoridade por nó — encaixa no modelo WP10) | terceiros | embutida, pesada | do zero |
| Iteração de dados | recursos + hot-reload simples | boa | boa | do zero |
| Risco | maturidade 3D menor que os grandes — mitigado: o protótipo já provou o que a fatia precisa | política de licença | desempenho no alvo | é outro projeto |

**Escolha: Godot 4.7.1-stable**, dentro da família 4.x. A versão ficou congelada quando o protótipo entrou neste repositório; mudá-la exige migração e nova medição. *Justificação:* é a única com **medição real nas máquinas reais** a favor; renderer Mobile já escolhido com dados (−33% VRAM, melhor 1% low); grátis e sem contas para duas pessoas; a rede de alto nível mapeia directamente na autoridade dividida do WP10. *Alternativa descartada:* Unreal — a mais forte no papel e a mais errada para gráficos integrados: o caminho feliz dela é o que a Lei 4 proíbe. Unity ficaria em segundo; perdeu no peso do editor nas máquinas U-series e no risco de licença.

**Linguagem: GDScript** para jogo e ferramentas (iteração rápida; a simulação da fatia — 8 personagens, WP12 — não precisa de mais). Se um sistema medir caro no perfil (a IA a 60 Hz, p. ex.), migra-se **esse sistema** para C#/GDExtension com a medição na mão — nunca por gosto. 

## Arquitectura por sistemas

Regra de ouro, herdada dos contratos: **a simulação manda, a apresentação obedece.** O combate corre em números (frames, hitboxes, estados) e a animação/VFX/som apenas mostram — nunca ao contrário: uma animação nunca decide um acerto.

| Sistema | Responsabilidade | Contrato que cumpre |
|---|---|---|
| **Entrada** | buffer, prioridades, janela de guarda | WP1B (números do Claude) |
| **FSM do personagem** | os estados do WP1, transições e cancelamentos exactos | WP1 (máquina de estados) |
| **Combate** | hitbox/hurtbox por frame, i-frames, postura, dano | WP1/WP2 — lê tudo dos dados, nada em código |
| **IA** | a máquina de estados única do WP6, parametrizada por ficha | WP6 (círculo de agressão, fecho aos 4 s) |
| **Chefes** | fases, sequências, alternância em co-op | WP7 |
| **Rede** | dois sacos, autoridade dividida, 20 Hz, transporte agnóstico | WP10 |
| **Mundo** | streaming por gargantas (zona + vizinha), pontos de descanso, renascimento | WP8/WP1 |
| **Gravação** | os dois sacos em disco, escrita atómica | WP10/WP11 |
| **UI** | HUD e menus do WP11, tempo real | WP11 |
| **Áudio** | catálogo, buses, prioridades, ducking, 24 vozes e streaming | [`65`](65-musica-e-ambiente.md) |
| **VFX** | orçamento de partículas, fichas | WP12 |
| **Ferramentas** | consola, overlays, registo de combate | WP15B (abaixo) |

Cada sistema comunica por eventos (sinais), não por acesso directo — é o que permite ao registo de combate (WP15B) ouvir tudo sem tocar em nada.

## Dados afináveis sem recompilar — a regra que o equilíbrio exige

**Todos os números da spec vivem em ficheiros de dados, não em código.** O marco 2 (WP15) é afinar a jogar; recompilar para mudar um custo de stamina mataria o método.

```
data/
  combat.json            frames, esquiva, parry, stamina e contacto     (WP1)
  weapons.json           armas, golpes, custos, requisitos e escala     (WP1/WP2/WP5)
  enemies.json           comuns, chefe, ataques e população por zona    (WP6/WP7)
  spells.json            mana, tempos, formas, alcances e efeitos       (WP4)
  attributes.json        atributos, bases e curvas                      (WP2/WP3)
  progression.json       nível, morte, ciclos e tectos                   (WP2/WP9)
  world.json             topologia, curva e posições de encontros       (WP6/WP8)
  named_encounters.json  os 36 encontros nomeados                       (WP6/WP8)
  controls.json          acções e bindings de fábrica                    (WP1/WP11)
```

- Formato: JSON (legível em qualquer editor; o Mateus e o Rico podem afinar sem abrir a engine).
- **Recarga a quente em modo dev:** tecla dedicada relê os dados sem reiniciar — muda-se um número com o Vorgar à frente e sente-se já.
- Os **tectos da Lei 1** (WP2) validam-se ao carregar: um `enemies.json` com um golpe acima de 40% da vida base da zona **recusa-se a carregar com erro claro**. A lei é código de validação, não boa intenção.

## Gravação de progresso

✅ **Detalhado e implementado no [`59-saves.md`](59-saves.md).** Os dois sacos do WP10 continuam literais, mas vivem juntos em cada `slot_NN.json`: `character` viaja; `world` só muda quando o perfil hospeda. O singleton escreve `.tmp`, valida checksum, roda o activo para `.bak` e publica por rename; versões antigas passam por migrações sequenciais.

Sem cloud nem encriptação — são dois amigos; editar à mão não é ameaça. ⚠️ A única divergência que não se fecha por construção é dos donos: matar um chefe no mundo alheio dá recompensa apenas, ou também muda o mundo próprio? [`99`](99-perguntas-abertas.md), pergunta 32.

## Plataformas, build e distribuição

- **Windows 11 64-bit, e mais nada** (as duas máquinas — pergunta 0; o briefing corta consolas/telemóvel).
- Build: export do editor, um clique; `-- dev` liga consola e overlays; a build de jogo normal **mantém o registo de combate** (WP15B precisa dele nas sessões reais).
- Distribuição entre os dois: pasta partilhada / link directo — são dois; **itch.io privado** fica como opção se quiserem histórico de versões com zero infra-estrutura. `[DECIDIDO]` (Mateus, 31-07-2026): o código vive em `game/` **neste** repositório, ao lado da spec; só builds geradas ficam de fora. Isto substitui a proposta histórica de um `worldrpgs-game` separado, porque spec + dados + código têm de mudar no mesmo PR.

## Ferramentas de afinação — obrigatórias, não opcionais

O WP15B declara-as pré-requisito dos testes; ficam especificadas aqui, construídas no marco 0:

| Ferramenta | Tecla (dev) | O que faz |
|---|---|---|
| **Consola** | F1 | `dar <item>` · `tp <zona>` · `matar_chefe` · `deus` · `camera_lenta 0,25` · `spawn <inimigo>` · `nivel <n>` · `latencia <ms>` (a rede artificial do WP15B) |
| **Overlay de hitboxes** | F2 | hurtbox verde, hitbox activa vermelha, i-frames do jogador a piscar azul, contador de frames do estado actual |
| **Overlay de desempenho** | F3 | fps, frame time actual/p99, 1% low, draw calls, tris, memória, entidades, vozes de áudio |
| **Registo de combate** | sempre ligado | CSV por sessão: cada morte (causa, ataque, stamina restante, posição), cada tentativa de parry (acertou/falhou), cada gole de frasco, tentativas por chefe — o alimento do WP15B |
| **Salto ao chefe** | consola | `tp arena_vorgar` com equipamento à escolha — o teste da Lei 1 não pode custar 5 min de caminhada por tentativa |

## Medição de desempenho — os números vigiados

Protocolo completo no WP15B; os limiares que disparam alarme vivem aqui:

| Número | Alvo | Pára-se tudo se |
|---|---|---|
| Frame time p99, quente (20 min) | ≤ 16,7 ms | > 20 ms (= abaixo de 50 fps efectivos, o mínimo do WP0) |
| Memória (working set) | ≤ 2,5 GB | > 3,0 GB |
| Draw calls em combate | ≤ 500 | > 650 |
| Crescimento de memória por hora | ~0 | > 100 MB/h (a fuga que a medição 0b mandou vigiar) |

"Pára-se tudo" quer dizer o que diz: conteúdo novo congela até a medição voltar ao verde (regra do WP12, agora com números de alarme).

## O que este documento entrega aos outros

| Para | O quê |
|---|---|
| **WP15** | engine escolhida, sistemas nomeados na ordem de dependência, ferramentas no marco 0 |
| **WP15B** | consola com latência artificial, registo CSV, overlays — o protocolo assume-os existentes |
| **Opus 5** | a regra simulação-manda, os dados fora do código, e a validação dos tectos ao carregar — as três coisas que não pode "optimizar" para fora |

## O que continua aberto

- **O carimbo dos dois na engine** — a escolha está feita com dados, mas a pergunta 17 é deles; assinar por baixo de números, como a 0b pediu
- ✅ O repositório existe como `worldrpgs` e contém `game/`; já não é uma decisão por tomar.
- ✅ O protótipo e os testes correntes congelam **Godot 4.7.1-stable**; mudar de versão exige migração medida, não preencher esta lista.

## Ligações

[`09-tecnico.md`](09-tecnico.md) (medição 0b) · [`19-rede.md`](19-rede.md) (dois sacos, autoridade) · [`21-arte-render.md`](21-arte-render.md) (orçamentos) · [`28-testes.md`](28-testes.md) (quem usa as ferramentas) · [`24-plano.md`](24-plano.md) (quando se constrói o quê)
