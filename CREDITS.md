# Créditos de assets externos

Cada asset externo que entra no jogo tem uma linha aqui, **no mesmo PR em que entra**. Regra completa: [`spec/22-assets.md`](spec/22-assets.md).

| Asset / pack | Autor | Licença | Fonte | Usado em |
|---|---|---|---|---|
| **Universal Base Characters** (Standard) | Quaternius | CC0 1.0 | [quaternius.itch.io](https://quaternius.itch.io/universal-base-characters) | corpo base das 6 classes — esqueleto partilhado (Lei 3) |
| **Modular Character Outfits — Fantasy** (Standard) | Quaternius | CC0 1.0 | [quaternius.itch.io](https://quaternius.itch.io/modular-character-outfits-fantasy) | ⭐ roupa e armadura modular para o **mesmo esqueleto** dos corpos — Ranger (corpo, braços, pernas, botas, ombreiras, capuz) e Camponês, ♂ e ♀. ⚠️ A versão grátis traz **2 fatos**, não os 12 do cartaz; os outros são pagos. Texturas reduzidas de 4096² para 1024² por nós: 282 MB → 43 MB, e é a Lei 4 |
| **Modular Character Outfits — Fantasy** (Standard) | Quaternius | CC0 1.0 | [quaternius.com](https://quaternius.com) | componentes modulares Ranger e Camponês, masculinos e femininos; a roupa substitui o corpo e conserva apenas a cabeça base |
| **Universal Animation Library** | Quaternius | CC0 1.0 | [quaternius.itch.io](https://quaternius.itch.io/universal-animation-library) | ⭐ ciclos de animação — é o que permite medir o risco do M1 |
| **Ultimate Monsters** | Quaternius | CC0 1.0 | [quaternius.com](https://quaternius.com/packs/ultimatemonsters.html) | Orc, Orc Small e Orc Skull como corpos-base do lanceiro, brutamontes e Vorgar; máscaras sem rosto, armadura, lança, maça e cutelo são geometria sintetizada em `monster_visual.gd` |
| **KayKit — Adventurers** | Kay Lousberg | CC0 1.0 | [kaylousberg.itch.io](https://kaylousberg.itch.io/kaykit-adventurers) | seis silhuetas jogáveis; clips General + Movement Basic do rig Medium; seis props de arma escolhidos individualmente: espada, adaga, machado de duas mãos, arco, besta de duas mãos e escudo redondo |
| **KayKit — Dungeon Pack 1.1** | Kay Lousberg | CC0 1.0 | [kaylousberg.itch.io](https://kaylousberg.itch.io/kaykit-dungeon-pack) | 25 módulos seleccionados para a entrada, três salas, dois atalhos e arena da Toca |
| **KayKit — Skeletons** | Kay Lousberg | CC0 1.0 | [kaylousberg.itch.io](https://kaylousberg.itch.io/kaykit-skeletons) | raça esqueleto (Campas Cinzentas) |
| **Nature Kit** | Kenney | CC0 1.0 | [kenney.nl](https://kenney.nl/assets/nature-kit) | floresta de Brumal |
| **Graveyard Kit** | Kenney | CC0 1.0 | [kenney.nl](https://kenney.nl/assets/graveyard-kit) | Campas Cinzentas |
| **Castle Kit** | Kenney | CC0 1.0 | [kenney.nl](https://kenney.nl/assets/castle-kit) | estruturas de pedra, arenas |
| **Impact Sounds** | Kenney | CC0 1.0 | [kenney.nl](https://kenney.nl/assets/impact-sounds) | impactos de combate, passos |
| **RPG Audio** | Kenney | CC0 1.0 | [kenney.nl](https://kenney.nl/assets/rpg-audio) | sons de interface e objectos |

> CC0 também entra na tabela: é decência, não obrigação. O que for royalty-free sem redistribuição vive em `_local/` (gitignored) e é assinalado aqui na mesma, com a nota "não redistribuído".

## A licença foi lida no ficheiro, não na página

**Os doze packs trazem `License.txt` (ou `License_Standard.txt`) dentro da distribuição, com CC0 1.0 explícito.** Verifiquei um a um por leitura do ficheiro — uma página de download pode mudar; o ficheiro que veio com os assets é a prova, e fica junto deles.

Para **Modular Character Outfits — Fantasy**, entrou apenas o conteúdo que a edição Standard gratuita realmente contém: Ranger e Camponês, nos dois corpos. Foram copiados individualmente para `game/assets/models/outfits/` os 20 componentes `Body`, `Arms`, `Legs`, `Feet`/`Boots`, `Acc_Pauldron(s)` e `Head_Hood`, mais as 12 texturas 1024×1024 que esses GLTF referenciam. O cartaz mostra fatos da edição paga que não existem nesta distribuição; não foram procurados nem fingidos. O `Readme.txt` interno fixa ainda o contrato usado no runtime: com roupa, só a cabeça do corpo base fica visível; usar o corpo inteiro causa clipping e desperdiça geometria.

No caso de **Ultimate Monsters**, a distribuição oficial é a pasta Google Drive ligada pela página do pack. O `License.txt` interno foi lido e copiado para `game/assets/models/characters/quaternius-ultimate-monsters/License.txt`; declara literalmente **CC0 1.0 Universal / Public Domain Dedication**. Há uma gralha de empacotamento que não se esconde: o cabeçalho desse ficheiro diz “Ultimate Platformer Pack”, apesar de viver na pasta oficial Ultimate Monsters. A página oficial e os nomes dos modelos confirmam a origem; a concessão CC0 do próprio ficheiro é inequívoca.

`[CODEX]` (01-08-2026) — os três corpos acima deixaram de ser usados tal como vêm no pack: o catálogo [`monster_visual_profiles.json`](game/assets/models/enemies/monster_visual_profiles.json) normaliza cada família a uma altura deliberada e [`monster_visual.gd`](game/src/visual/monster_visual.gd) deriva o pivot dos pés do mesh, dessatura a pele e sintetiza elmo fechado, placas e arma numa só superfície adicional. **Razão:** os olhos redondos e a boca sorridente do atlas original contradizem o tom sombrio decidido. **Alternativa descartada:** escolher outro dos packs já arquivados; nenhum contém um orc humanoide ameaçador e redistribuível, e usar um esqueleto ou zombie com tinta verde trocaria uma incoerência por outra.

O subconjunto do **KayKit — Dungeon Pack 1.1** usado pela Toca vive em `game/assets/models/dungeon/`, junto de `License.txt` e da textura original do pack. A selecção deliberada traz e usa 25 dos 211 modelos disponíveis, sem importar o pack inteiro para o jogo.

Para **KayKit — Adventurers**, entraram deliberadamente apenas `Ranger.glb`, `Mage.glb`, `Knight.glb`, `Rogue_Hooded.glb`, `Barbarian.glb`, `Rogue.glb`, `Rig_Medium_General.glb`, `Rig_Medium_MovementBasic.glb` e o escudo paladino `shield_badge_color.gltf` com o seu `.bin`/`knight_texture.png`. Cada personagem é um GLB autocontido de um material; durante a importação o Godot extraiu os seis atlas embebidos com o prefixo do GLB (`Ranger_ranger_texture.png`, etc.) — não são cópias adicionais escolhidas do pack. O `License.txt` interno foi copiado com eles para `game/assets/models/characters/kaykit-adventurers/`.

Para a geometria de equipamento, a selecção foi igualmente unitária: `sword_1handed`, `dagger`, `axe_2handed`, `bow`, `crossbow_2handed` e `shield_round_barbarian`, com os `.bin` e atlas de que dependem, vivem sob `game/assets/models/weapons/` com nomes derivados das famílias do catálogo. O cajado do pack foi testado em captura e deliberadamente rejeitado: a argola verde desproporcionada contrariava o conceito aprovado. Cajado, katana e armas de haste usam geometria procedural temporária, sem asset externo novo. A cópia de `License.txt` junto desse subconjunto mantém a prova CC0 no runtime.

## Onde vivem, e o que o Godot vê

`[DECIDIDO]` (Rico, 01-08-2026, ⏳ falta o Mateus) — **os packs CC0 vivem no repositório**, em `art/models/` e `art/audio/`. Ver [`DECISOES.md`](DECISOES.md).

⚠️ **`art/` é a biblioteca; `game/` é o que o jogo carrega.** O projecto Godot tem a raiz em `game/`, por isso **não varre o `art/`** — nada aqui é importado por acidente nem pesa no arranque do editor. O que o jogo usa é copiado para `game/` deliberadamente, um de cada vez.
