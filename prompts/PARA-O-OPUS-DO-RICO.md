# Para o Opus do Rico — a camada visual do combate

> **Actualizado 01-08-2026 (2.ª versão).** A primeira versão pedia a camada de rede. **Mudou por decisão do Mateus:** *"faz o Rico nos ajudar a apanhar a camada visual e a mecânica"*. A rede fica como alternativa **B** no fim.
>
> ⚠️ **Há 10 agentes Codex a trabalhar em paralelo neste momento**, cada um na sua árvore git. Este documento existe para o teu trabalho **não colidir com nenhum deles**. A tabela do §4 é a parte mais importante — lê-a antes de abrires um ficheiro.

---

## 1. Contexto da sessão pai

| | |
|---|---|
| **Projecto** | WorldRPGs — RPG 3D souls-like, co-op para dois. Hobby do Mateus e do Rico |
| **Repositório** | `MateusJuni0/worldrpgs` — **público**. ⚠️ Nunca commitar segredos nem caminhos `C:\Users\...` |
| **Motor** | Godot 4.7.1-stable, renderer **Mobile**, GDScript |
| **Máquina alvo** | **Intel Iris Xe integrados, 8 GB RAM, 1080p @ 60 fps** — a do Rico, a mais fraca. É a **Lei 4** |
| **Ler primeiro** | [`CLAUDE.md`](../CLAUDE.md) · [`ESTADO.md`](../ESTADO.md) · [`LACUNAS.md`](../LACUNAS.md) §*Do Mateus a jogar* · [`art/concept/README.md`](../art/concept/README.md) |

**Preferências:** documentação e comunicação em **português**; código, commits e nomes de ficheiro em **inglês**; **sem falhas silenciosas**.

---

## 2. ⭐ O problema, na frase do Mateus

> *"A magia funciona; é a bola azul que a envergonha."*

O jogo tem **muita mecânica** e **pouca imagem**. Os sistemas foram construídos e a camada visual não os acompanhou. É isso que vais fechar.

### O que ele viu a jogar, com a prova

| | O que está mal | Prova |
|---|---|---|
| 🔴 | **A magia é uma esfera azul.** `_build_visual(raio, cor)` cria uma `SphereMesh` e mais nada. Sem partículas, sem rasto, **sem clarão na ponta do cajado**, sem impacto | `game/src/combat/spell.gd:55` |
| 🔴 | **Bater não se sente.** *"Nem parece que tô a dar dano no inimigo"* | — |
| 🔴 | **A arma não se vê na mão** | — |
| 🔴 | **Os inimigos são sapos cartoon** — olhos redondos, boca a sorrir | captura `arena-rasante.png` |
| 🔴 | **Escala descontrolada:** um inimigo minúsculo e outro gigante na mesma arena, e o grande parece enterrado | idem |

---

## 3. ⭐ O que construir, por ordem de impacto

### 3.1 Os efeitos visuais do combate — **começa aqui**

⚠️ **Espera pelo agente `magia-e-vfx` acabar antes de tocar em `game/src/vfx/`** (ver §4). Enquanto esperas, faz o 3.2.

- **Impacto do golpe:** faísca/sangue **no ponto de contacto**, nunca no centro do inimigo
- **Paragem curta no toque** (*hit stop*) — poucos frames, e **mede-os**
- **O inimigo reage:** recuo, animação de dor, interrupção do que estava a fazer
- **Som próprio** conforme o que se atinge: carne, metal, madeira
- ⚠️ **Quando LEVAS dano** tem de ser óbvio de quem e de onde — em 1.ª pessoa não vês quem te bate por trás

### 3.2 A arma na mão, e a escala dos inimigos

- ⭐ **A arma tem de se ver**, e mudar quando se troca. Há um `BoneAttachment3D` no `character_visual.gd` e o Mateus continua sem ver espada nenhuma. **Descobre porquê** — osso errado? escala? modelo em falta?
- ⭐ **Escala em metros por família**, escrita em JSON, e todos os modelos normalizados a ela. Um inimigo grande é grande **por desenho**, nunca por acidente de importação
- ⭐ **Os pés no chão.** Corrige o pivot: nada enterrado nem a flutuar

### 3.3 A regra que evita repetir o erro dos sapos

Está escrita em [`art/concept/README.md`](../art/concept/README.md) e é o passo que falhou da última vez:

1. **Antes de escolher um modelo de um pack**, abre o conceito da mesma coisa em `art/concept/`
2. Pergunta: *este modelo pode chegar aqui só com materiais, cor e escala?*
3. ⚠️ Se **não** puder — **não uses o menos mau**. Escreve no `LACUNAS.md` que peça falta e porquê aquela não serve
4. **Nunca se aceita:** caras a sorrir, olhos grandes e redondos, cores saturadas, proporções de desenho animado

⭐ **Os conceitos em `art/concept/` foram aprovados pelo Mateus** (*"o tom tá certo, esse estilo"*). São o **alvo**, não o asset — dizem que materiais e que silhueta perseguir, e **não entram no jogo**.

---

## 4. ⛔ Ficheiros com dono — não tocar

**10 agentes a trabalhar agora.** Isto muda ao longo do dia; **confirma com o Mateus antes de começar**.

| Não tocar | Quem lá está |
|---|---|
| `game/src/vfx/` · `game/src/spells/` · `game/data/spells.json` | `magia-e-vfx` |
| `game/src/ui/equipment_screen*.gd` · `game/src/visual/armor_visual*.gd` | `equipar-e-ver` |
| `game/data/enemies.json` | `gramatica-de-ataque` |
| `game/src/coop/` · `game/src/enemies/encounter*.gd` | `coop` |
| `game/src/enemies/boss*.gd` · `game/src/world/arena*.gd` | `vorgar` |
| `game/src/world/bonfire*.gd` · `game/src/progression/` | `fogueira-e-almas` |
| `game/src/autoload/inventory_system.gd` | `kit-e-morte` |
| `game/data/attributes.json` · `abilities.json` | `mago-do-mal` |
| `game/src/audio/music*.gd` | `musica-e-ambiente` |
| `game/src/ui/levelup*.gd` · `game/data/attributes.json` | `subir-de-nivel` |
| `game/src/ui/game_shell.gd` · `hud.gd` · `inventory_menu.gd` | vários |

**Livres e teus:** `game/src/combat/impact*.gd` · `game/src/visual/weapon_attach*.gd` · `game/src/visual/monster_visual.gd` · `game/assets/models/enemies/`

⭐ **Precisas de algo que tem dono?** Escreve no [`LACUNAS.md`](../LACUNAS.md) **exactamente o que precisas e de quem**. ⛔ **Não mexas.**

---

## 5. ⚠️ Como entregar — e é aqui que se evita partir o jogo

**Instrução do Mateus:** *"vai aprovando aos poucos os commits, ele deve fazer assim que terminar"*.

1. ⭐ **Commits pequenos e frequentes**, um por peça que funciona. Não guardes tudo para o fim
2. ⛔ **NUNCA push para `main`.** Abre PR, ou commita no teu ramo e avisa
3. ⭐ **Antes de cada commit** — e isto não é opcional:
   ```bash
   cd game && ./VERIFICAR.bat
   ```
   São **6 verificações**, incluindo o **arranque real do jogo** (criar personagem, saltar entre ecrãs, entrar no mundo). **9703 têm de continuar a passar, nunca menos.**
4. **Commits em português**, a explicar **o porquê**, não o quê
5. No fim de cada peça: **os números que mediste**, e uma captura

**O Claude revê e funde.** Se algo partir, é apanhado antes de chegar ao Mateus.

### Dois avisos que este projecto aprendeu hoje da maneira difícil

⚠️ **Um teste em ficheiro próprio que ninguém corre não é um teste, é um ficheiro.** Já aconteceu aqui: 92 verificações a existir e a não correr. **Criaste um script de teste? Acrescenta-o ao `game/VERIFICAR.bat` no mesmo acto.**

⚠️ **Não sujes a pasta de saves.** Todas as árvores partilham o mesmo `user://` porque têm o mesmo nome de projecto. Um teste que escreveu nos três slots deixou o Mateus **sem conseguir começar jogo nenhum**. **Limpa o que escreveres.**

⚠️ **Se der `Identifier X not declared`**, corre primeiro com `--import`. É a cache de classes do Godot, não é o teu código.

---

## 6. As regras do repositório

### As quatro leis
1. **Ganha-se com habilidade, não com nível.** Nada de gating, nada de grind
2. **As melhorias dão opções, não números**
3. **Qualquer classe pega em qualquer arma**
4. **A máquina alvo manda.** Queda de fotogramas num souls-like não é feio, **é injusto**

### As etiquetas
`[DECIDIDO]` **não se mexe** · `[TENSÃO]` **não se decide**, propõe-se · o que decidires é `[FABLE]` **com razão e alternativa descartada**

### ⭐ As quatro perguntas do fio solto — nada entra sem as quatro
1. Como é que o jogador usa isto? *(uma acção sem tecla não existe no jogo)*
2. Como é que se prova que funciona? *(um teste, ou um número medido)*
3. De onde vem a arte e o som?
4. Quanto custa na máquina do Rico?

### ⚠️ O contrato de honestidade ([`spec/38`](../spec/38-ataques-e-honestidade.md)) aplica-se ao visual
**A hitbox vive exactamente enquanto o efeito se vê.** Se a espada ainda está a descer e já não magoa, **o jogo mentiu**. O feedback nunca se pode desalinhar do que magoa de verdade — é a diferença entre um souls-like justo e um jogo que parece injusto.

---

## 7. Alternativas, se preferirem

| | O quê | Porquê importa |
|---|---|---|
| **B** | **A camada de rede** — `game/src/net/` está **vazia** | O jogo é co-op por desenho e só se joga sozinho. [`spec/19-rede.md`](../spec/19-rede.md) está fechado |
| **C** | **O mundo para além de Brumal** — os 12 biomas | O jogo tem **uma** zona |
| **D** | **NG+ e o fim do jogo** — [`spec/58`](../spec/58-fim-do-jogo-ciclos-e-a-curva.md) | Escrito com a curva calculada, zero código |
