# Fogueira, morte e almas — prova das quatro perguntas

Medição de 01-08-2026 na máquina alvo: Intel Iris Xe, Mobile/Vulkan,
1920×1080, vsync desligado, cena `lei4` (2 jogadores + 3 inimigos), 4 s de
aquecimento e 10 s de amostra.

| Amostra | FPS médio | 1% low | p95 | p99 | pior | draw calls | primitivas | memória estática | VRAM |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| baseline | 111,5 | 48,0 | 12,473 ms | 15,270 ms | 54,64 ms | 47 | 272 830 | 82,5 MiB | 118,9 MiB |
| 2 manchas sempre visíveis | 135,8 | 86,5 | 9,242 ms | 9,928 ms | 25,75 ms | 48 | 273 598 | 82,9 MiB | 118,9 MiB |

A diferença de FPS entre corridas é variação do sistema, não uma melhoria
causada pelas manchas. O custo estrutural observado no pior caso é **+1 draw
call, +768 primitivas e +0,4 MiB de memória estática**, com p95 abaixo do
orçamento de 16,67 ms. Uma tentativa anterior em que a cena não chegou a
montar produziu `draw_calls: 0` e foi descartada.

Comandos reproduzíveis:

```text
<godot> --audio-driver Dummy --path game/ --rendering-method mobile -- --bench --seconds=10 --warmup=4 --vsync=off --label=almas-baseline --scene=lei4
<godot> --audio-driver Dummy --path game/ --rendering-method mobile --script res://src/progression/soul_stain_benchmark.gd -- --bench --seconds=10 --warmup=4 --vsync=off --label=almas-duas-manchas-visiveis --scene=lei4
```

## As quatro perguntas

1. O jogador usa `interact` junto da fogueira para descansar e abrir
   nível/Brasa; chega fisicamente à mancha para a recuperar.
2. `progression_test.gd` prova os contratos; o auto-teste global continua a ser
   a guarda de regressão. Esta medição prova o custo visual.
3. A fogueira existente, a mancha e as confirmações sonoras são sintetizadas em
   código a partir de `progression.json`; nenhum asset externo foi acrescentado.
4. O custo medido está na tabela acima. A integração final na cena continua
   registada no `LACUNAS.md`, porque `main.gd` pertence a outra árvore.

## Descanso e nível no ecrã — 02-08-2026

O repro `bonfire_gameplay_repro.tscn` arranca `gameplay.tscn`, fere o jogador,
mata um inimigo, percorre o último troço até ao descanso e carrega em
`interact`. Corre apenas com `user://` isolado e remove o slot que cria.

Na cena de produção actual passaram **7 observações** (jogador/fogueira/inimigo,
vida, frascos, inimigo reposto e checkpoint) e falharam **4 fios**: contador de
reposição, pose sentada, `LevelUpScreen` e instância de `Bonfire`. No mesmo jogo,
ligar explicitamente o controlador fez passar mais **8 observações**: transacção,
pose, ecrã existente, contador persistente, co-op sem pausa, levantar ao fechar,
dez reposições visíveis e a tentativa seguinte esgotada. Isto prova que o módulo
está pronto e prova também que o jogo entregue ainda não o chama; não é fecho.

A sonda existente `levelup_benchmark.gd` mediu o ecrã isolado a 1920×1080,
Mobile/Vulkan, VSync e limite de FPS desligados, na Intel Iris Xe:

| Amostra | FPS médio | p95 | p99 | pior | draw calls medianas | VRAM |
|---|---:|---:|---:|---:|---:|---:|
| menu oculto | 809,1 | 2,259 ms | 3,017 ms | 4,045 ms | 0 | 13,1 MiB |
| subir nível visível | 524,8 | 3,181 ms | 4,154 ms | 4,811 ms | 117 | 50,1 MiB |

A captura foi aberta e verificada: título, oito atributos, custo, pré-visualização
e botões cabem em 1920×1080 sem corte nem sobreposição. A sonda prova o custo do
menu, não o frame pacing do nível completo; essa prova depende do fio de
`main.gd` registado em `LACUNAS.md`.

As quatro perguntas ficam assim: o jogador usa `interact`; a cena real é a prova
e hoje termina vermelha nos quatro fios acima; fogo/som continuam sintetizados e
a pose reutiliza `Sitting_Idle` do corpo Quaternius já importado; o custo visual
medido fica na tabela, com margem para 16,67 ms mas ainda fora do nível completo.
