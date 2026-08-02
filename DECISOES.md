# Registo de decisões

Todas as decisões dos donos, por ordem, com o que cada uma substitui.

**Para que serve:** o Fable esteve a construir localmente enquanto isto era decidido. Quando os commits dele chegarem, é contra esta lista que se compara — linha a linha, para ver o que foi construído sobre premissas antigas.

Ordem inversa: **o mais recente primeiro.**

---

## 01-08-2026

### ⭐ O Mago do Mal lança por **talismã** · e cada origem ganha o seu instrumento
**[DECIDIDO] (Mateus, 01-08-2026)** — *"quero um talismã .. cria pras outras classes também"*

- ⭐ **O instrumento do Mago do Mal é o talismã.** Fecha a linha que o [`52`](spec/52-mago-do-mal.md) §3 deixou em aberto — *"o Mateus perguntou"* — e substitui a proposta `[CLAUDE]` de **cajado negro + relicário**, que fica registada como alternativa descartada, não apagada
- ⭐ **Cada origem passa a ter um instrumento próprio**, não só as que lançam magia. É a Lei 3 aplicada ao equipamento: o instrumento é uma **ficha de equipamento**, não um privilégio de classe — qualquer origem pode pegar em qualquer um
- ⚠️ **O que isto obriga a resolver, e é o difícil:** hoje **só o cajado existe** com ficha 1,0. Os outros cinco estão declarados no `spells.json` e **não têm instância, slot, mão, escala nem animação**. É a pergunta **56** do [`99`](spec/99-perguntas-abertas.md), e esta decisão resolve *quais existem*, não *como funcionam*
- ⭐ **Lei 2:** o instrumento tem de dar **opções, não números**. Se o talismã for só *"+X% de dano"* face ao cajado, não é um instrumento — é um upgrade. A pista está no próprio [`52`](spec/52-mago-do-mal.md) §3: *"pelo cajado tende a ser mais destrutiva; pelo sino tende a ser mais passiva"* — o instrumento muda **o que a magia faz**, não quanto dói
- ⭐ **O instrumento vai na MÃO SECUNDÁRIA** — *"pode ser a segunda mão, o cajado em uma e o talismã na outra"* (Mateus, 01-08). Fecha a metade da pergunta 56 que era dos donos: **o cajado ocupa a mão principal, o instrumento a secundária**, e levar os dois é uma escolha real — quem leva os dois **fica sem escudo**
- ⭐ **O esquema segue o do Dark Souls** — *"usa o mesmo modelo que o dark souls, ele é nossa referência"*. ⚠️ Isto é **o modelo de sistema**, não o conteúdo: lá, o catalisador vive numa mão e a magia escala por ele. Copia-se **o mecanismo**, nunca nomes, valores, animações ou assets ([`spec/31`](spec/31-referencias.md)) — e o protocolo obriga a escrever a tabela `eles · nós · diferença`
- ⏳ **Continua dos donos:** se a fórmula do instrumento substitui o `base_damage` corrente do feitiço

### 🔴 ⭐ Os jogáveis são **humanos com proporções reais**, nunca bonecos
**[DECIDIDO] (Mateus, 01-08-2026)** — *"cadê o personagem humano a sério? os personagens jogáveis são humanos sempre, não pequeninhos assim, igual o Dark Souls faz"*

- ⭐ **Proporções humanas adultas.** Cabeça normal, corpo normal. Nada de cabeças grandes, nada de estilo *chibi*
- ⚠️ **O que estava errado, e a culpa é do briefing que eu escrevi:** mandei *"vestir as classes"* e o agente usou o **KayKit Adventurers**, que é um pack **cartoon de propósito**. Trocámos um corpo com proporções certas por um bonequinho de chapéu. Os corpos **Quaternius Universal Base Characters** — os que já lá estavam, os do boneco nu — **são os certos**, e continuavam carregados sem serem usados
- ⭐ **A saída não é voltar ao boneco nu.** É **vestir o corpo realista**: a armadura vai por cima do corpo certo, não se troca o corpo por um fato inteiro
- ⚠️ **O KayKit continua a servir para o resto** — masmorra, cenário, adereços, e talvez inimigos não-humanos. **Só não serve para os jogáveis**, que são a coisa que o jogador olha 100% do tempo
- **Referência:** Dark Souls. E a linha do [`31`](spec/31-referencias.md) continua: estuda-se, não se copia

### ⭐ O Mago do Mal é uma **origem própria** — a 7.ª classe · fecha a pergunta 36
**[DECIDIDO] (Mateus, 01-08-2026)** — respondeu à pergunta 36 do [`99`](spec/99-perguntas-abertas.md) depois de lhe serem apresentadas as três saídas.

- ⭐ **O Mago do Mal entra no ecrã de criação ao lado das outras seis**, com ficha inicial, traço de mana e postura próprias. Passam a ser **sete origens**
- **Não é o Feiticeiro.** O Feiticeiro é o mago que fica atrás; este **anda entre os mortos**, porque precisa dos corpos para trabalhar. É o argumento do [`52`](spec/52-mago-do-mal.md) §5: *"uma classe com postura própria, não uma variante de números"*
- **Alternativa descartada:** a Escola vermelha aberta a qualquer origem. *Perdia* a identidade — o traço de +40% de mana e a ficha inicial deixavam de fazer sentido, e o mago do mal passava a ser um ramo de magia em vez de alguém que se é
- ⚠️ **O que isto obriga a mexer:** o ecrã de criação do [`64`](spec/64-criacao-de-personagem.md), o kit inicial em `weapons.json`, o traço em [`54`](spec/54-mana-meditacao-e-tracos-de-classe.md), e **todos os testes que verificam "exactamente seis origens"**
- ⚠️ **Continua `[TENSÃO]` e não é para os agentes:** o Voto de Sangue por trocas de verbo do [`53`](spec/53-chefes-ritmo-e-o-mago-forte.md) §§4–5 colide com o +30/+60/+90% que o Mateus decidiu. Essa fica aberta

### ⭐ Os vendedores vendem **tudo**, e a loja separa-se por slot como no Dark Souls
**[DECIDIDO] (Mateus, 01-08-2026)** — *"os vendedores vendem tudo do jogo nao so o que eu achei.. faz direitinho separa as coisas por slot igual é do darksouls"*

- ⭐ **Todo o catálogo está à venda desde o início:** todas as magias, todas as armaduras, poções e elixires. Sem desbloqueio, sem "descobre primeiro"
- ⭐ **Quem trava é o preço, nunca uma porta.** É a Lei 1 aplicada à economia: o que separa o jogador do item é habilidade (juntar almas) e escolha (gastar aqui ou subir de nível), não um cadeado
- ⚠️ **O que isto obriga:** se tudo está à venda no minuto um, a **curva de preços passa a ser a única coisa que decide a ordem de aquisição**. Deixa de ser um detalhe e passa a ser desenho de progressão — tem de ser justificada com números
- ⭐ **A loja separa-se por slot** — mão direita, mão esquerda, peças de armadura, anéis, consumíveis rápidos, feitiços — e **usa exactamente a mesma divisão que a mochila**. Duas gramáticas para a mesma coisa é o defeito nº 1 destes menus
- ⚠️ **SUBSTITUI** a regra que eu tinha escrito no briefing do agente dos vendedores — *"o vendedor só vende o que já descobriste"*. Essa era **minha, não dele**, e foi revogada pelo dono antes de chegar a código. O agente foi parado a meio e relançado com a regra certa
- **Continua em aberto e é dos donos:** *"os vendedores morrem?"* — `[TENSÃO]`, ninguém decide sozinho

### Os packs CC0 vivem no repositório → fase 1.2 do [`prompts/TERMINAR-A-SPEC.md`](prompts/TERMINAR-A-SPEC.md)
**Instrução directa do Rico (01-08-2026), ⏳ falta a confirmação do Mateus** — decidido depois de lhe ser apresentado o custo, e com ele à vista.

- ⭐ **Os packs CC0 entram em `art/models/`, `art/textures/` e `art/audio/`, e vão para o GitHub.** Quem clonar tem tudo à mão, sem passo extra
- ⚠️ **O custo, aceite de olhos abertos:** o git **nunca esquece**. Centenas de MB ficam no histórico para sempre, e cada `git clone` passa a puxá-los. Tirá-los depois obriga a reescrever a história do repositório
- ⚠️ **Isto contradiz o [`game/CLAUDE.md`](game/CLAUDE.md)**, que diz *"Binários: modelos, texturas, áudio, builds — `.gitignore` já os trava"*. Era **falso** mesmo antes desta decisão (o `game/.gitignore` só trava `*.zip`, `*.exe` e `*.pck`); agora fica também **desactualizado**. Corrige-se no PR da fase 1.2
- **Continua a valer:** o que é royalty-free **sem redistribuição** (Mixamo, Sonniss, lojas) **nunca** entra — vive em `_local/`, que continua gitignored. Esta decisão é só sobre **CC0** ([`spec/22-assets.md`](spec/22-assets.md))
- **Todo o pack que entra leva linha no [`CREDITS.md`](CREDITS.md) no mesmo PR** — CC0 também, que é decência e não obrigação
- **Alternativa descartada** (era a minha recomendação): packs crus em `art/models/_local/` e no repositório só o que o jogo carrega mesmo, optimizado. *Perdia:* o Mateus tinha de correr um passo de download para ver o jogo com arte. O Rico escolheu a conveniência dos dois donos acima do peso do clone — e é uma escolha defensável num projecto de duas pessoas

## 31-07-2026 · noite

### Cinco instruções do Rico sobre equipamento e espólio → volta 3 (WP5) e volta 5 (WP6)
**Instrução directa do Rico (31-07-2026), ⏳ falta a confirmação do Mateus.** As cinco, com as palavras dele e onde cada uma bate:

1. **Kit inicial por classe** — *"quando começar o jogo escolhemos uma classe tem que vim os items de inicio de acordo com a classe."* Cada uma das 6 classes nasce com o seu equipamento. → volta 3 escreve os kits; a fatia já dava a arma, agora dá o conjunto
2. **Menos almas por chefe repetido em co-op** — *"no modo coop se o player ja tiver matado o boss recebe menos almas."* ⭐ Confirma a direcção da proposta do WP9 ([`spec/18-progressao.md`](spec/18-progressao.md): ajudar no que já se matou paga 40% e só materiais) — o número exacto continua proposta, a direcção passa a ter palavra de dono
3. **Armadura de chefe cai e equipa-se** — *"as armaduras dos chefes que seram dropadas tem que adcionar uma [forma] de equipar as mesmas."* Chefes largam peças do que vestem, e o jogo precisa do sistema de equipar (slots por peça — casa com a decisão do Mateus de armadura por peças em [`spec/33-morte-e-almas.md`](spec/33-morte-e-almas.md)) → volta 3 (slots) + WP11 (ecrã)
4. **Aleatório só nos inimigos comuns; chefes e baús são fixos** — *"os itens podem dropar aleatoriamente dos inimigos nao dos chefes e baus."* O baralho de 10 ([`spec/43-estudo-espolio-inventario-mundo.md`](spec/43-estudo-espolio-inventario-mundo.md) §2) fica nos comuns; **chefe e baú têm espólio desenhado, sem sorte** → volta 5 (baralhos) e volta 7 (chefes)
5. **O aleatório filtra pelo bioma** — *"quando matar inimigos dropa equipamentos aleatórios com base nas disponíveis no qual o cenário esta correndo."* ⭐ É a lei da coerência ([`spec/46-coerencia-bioma-raca-item.md`](spec/46-coerencia-bioma-raca-item.md) §4) dita pelo dono: a pool de drop de uma zona é o que existe naquele bioma

- **Substitui:** nada — as 5 encaixam no que está; a 2 e a 5 dão palavra de dono a propostas que existiam
- **Registado por:** Fable, no próprio dia; citadas na issue #3 para o Mateus confirmar

### A identidade do Assassino → volta 3 (kit) + WP3 (habilidade)
**Instrução directa do Rico (31-07-2026), ⏳ falta a confirmação do Mateus** — *"o assassino tera furtividade velocidade e dano de sangramento, cria alguma habilidade especial, a arma de inicio do assassino pode ser duas adagas."*
- **Kit inicial: duas adagas** → entra já na volta 3 (`weapons.json`, loadout) — ⚠️ a segunda adaga é `[PROTO]` cosmética até o golpe alternado ser implementado (o offhand só tem mecânica de escudo hoje)
- **Furtividade + velocidade + sangramento** = a identidade da classe → [`spec/12-classes.md`](spec/12-classes.md) (WP3); o sangramento liga ao estado alterado da volta 3 §7 — o Assassino é a classe do sangramento
- **Habilidade especial nova** → a desenhar pelo Fable a seguir à volta 3 (o Passo Sombra existente está "por implementar" — ou evolui para isto, ou dá lugar)
- **Substitui:** nada; especifica a classe que o WP3 tinha genérica

## 31-07-2026 · tarde

### Do greybox ao visual → [`spec/47-do-greybox-ao-visual.md`](spec/47-do-greybox-ao-visual.md)
`[DECIDIDO]` (Mateus, 31-07-2026) — *"vê se não está estilo jogo de PS1, tem que ser estilo Dark Souls."*
- **Fui ver, não supor:** corri o modo fotografia do protótipo e olhei para as seis capturas
- **Não é "estilo PS1" — é "sem estilo nenhum".** É greybox: cones por árvores, cápsulas por personagens, cores por ESTADO e não por beleza (o próprio `graphics.json` diz isso). Correcto para um protótipo de combate
- ⚠️ **Mas o risco é real e é outro:** não há **nada no plano que converta** greybox em visual. Nenhum marco do WP15 diz *"aqui o jogo deixa de ser cinzento"* — e é assim que um protótipo se torna o jogo, sem ninguém decidir
- ⭐ **O que faz parecer a referência NÃO é geometria:** luz com contraste, névoa com cor por bioma e gradação de cor valem **mais** do que modelos e texturas, e custam **quase zero fotogramas**. Trocar 40 modelos custa dias e dá salto médio; afinar luz e névoa custa horas e dá o salto maior
- ⭐ **A cor vem da ficha de bioma** ([`46`](spec/46-coerencia-bioma-raca-item.md) §2) — os 3 valores de paleta deixam de ser decoração e passam a ser configuração de luz e névoa
- ⭐ **Capturas obrigatórias em todo o marco.** A ferramenta já existe (o modo fotografia do Fable). A pergunta por marco: *está mais perto da barra do que no anterior?* Duas vezes "não" = o visual parou
- ⚠️ **A animação de esqueleto continua a ser o único risco técnico por medir** — a folga de 6× é orçamento para ela, não garantia
- **Substitui:** nada — a barra do [`30-qualidade-visual.md`](spec/30-qualidade-visual.md) não muda

### Coerência do mundo, subchefes e escala → [`spec/46-coerencia-bioma-raca-item.md`](spec/46-coerencia-bioma-raca-item.md)
`[DECIDIDO]` (Mateus, 31-07-2026) — *"as descrições têm que ter a ver com o bioma... a armadura do orc tem que ser de fogo se ele estiver num bioma de fogo. **Cuidado pra não misturar nesse aspecto.**"*
- ⭐ **A lei de herança: `item = função × raça × bioma`.** Escolhe-se o bioma e a raça; material, resistência, fraqueza, onde cai, aspecto e descrição **deduzem-se**
- ⭐ **O motor de produção: 12 fichas de bioma + 12 de raça = 300 descrições coerentes.** 24 fichas de 8 linhas, meio dia de trabalho, e desbloqueia o catálogo todo
- ⚠️ **Um item fora do bioma é permitido — mas nunca por acidente.** Precisa de duas frases que expliquem a viagem, e aí passa a ser a coisa mais interessante da zona
- ⭐ **A camada que faltava: SUBCHEFE.** Não é um chefe pequeno — vive **no mundo, sem arena, sem porta, sem música**. Aparece sem avisar, **pode-se fugir dele**, e guarda uma coisa que se vê. ⚠️ Aparecer sem aviso ≠ atacar sem aviso: os 0,50 s de telegrafia continuam
- ⭐ **61 chefes DERIVADOS DO MAPA:** 1 Ultra + 12 subchefes + 12 guardiões + 36 de campo, com 12 biomas. Fecha a pergunta 13 **e** a 4 de uma vez — decidir biomas decide chefes
- **10–15 raças** (temos 6) · **mais inimigos** — a alavanca é a **mesma raça em vários biomas, vestida pelo bioma**: muda material, resistência e **um** ataque; não muda esqueleto nem animações
- **Todas as raças e chefes têm história** — 8 linhas por raça, +3 por chefe. Não é prosa: é a matéria-prima das descrições
- ⚠️ **Muda a ordem de escrita:** as 24 fichas vêm **antes** do catálogo. Ao contrário, cada descrição é inventada de novo e a lei é impossível de aplicar
- **Substitui:** nada — mas altera a ordem do [`ESTADO.md`](ESTADO.md) §3

### O código vem para este repositório → [`ESTADO.md`](ESTADO.md) §1
`[DECIDIDO]` (Mateus, 31-07-2026) — **o jogo passa a viver em `game/`, ao lado da spec.**
- ⚠️ **O jogo já existia e vivia num sítio só** — o disco do Rico. Sem cópia, sem revisão possível
- ⭐ **A regra do "mesmo PR" é impossível em dois repositórios** — se o código e a spec discordam, a spec muda primeiro **no mesmo PR**
- **Substitui:** o repositório separado `worldrpgs-game` planeado no [`spec/23-tecnico.md`](spec/23-tecnico.md) e [`spec/24-plano.md`](spec/24-plano.md) — foi escrito quando este repo era só de especificação

### Controlos configuráveis dentro do jogo → [`spec/45-controlos-configuraveis.md`](spec/45-controlos-configuraveis.md)
`[DECIDIDO]` (Mateus, 31-07-2026) — *"tem que dar pra gente escolher os controles no jogo mesmo."*
- ⭐ **Dissolve a pergunta 30**, que era a mais urgente: o parry fica em `Q` **e** no toque de `RMB`, e cada jogador escolhe
- ⭐ **E é a Lei 1:** um parry desconfortável faz o jogo parecer injusto, e depois baixa-se a dificuldade para compensar um problema que é de teclado. Com teclas configuráveis, o que sobra a medir é o jogo
- ⚠️ **Não apaga o mapa de teclas** — alguém decide os **valores de fábrica**, que é o que 100% dos jogadores experimenta primeiro
- ⚠️ **O jogo mostra a tecla do jogador, nunca a de fábrica** — senão o tutorial passa a mentir
- **Abre:** comando/`gamepad` fica `[EM ABERTO]`; o sistema nasce agnóstico da fonte

### Liberdade criativa do Fable — sem limites
`[DECIDIDO]` (Mateus, 31-07-2026) — o Fable inventa à vontade. **Os guardas são contra esquecimentos, não contra ideias:** as **quatro perguntas do fio solto** ([`ESTADO.md`](ESTADO.md) §5) — como se usa · como se prova · de onde vem a arte · quanto custa na máquina do Rico.
- ⚠️ O risco de escopo foi levantado e o Mateus **reafirmou avançar**. Fica registado, não trava nada

### Espólio garantido, magia, inventário e carregamento → [`spec/40-decisoes-espolio-magia-inventario.md`](spec/40-decisoes-espolio-magia-inventario.md)
**Regra de processo, e vale para todos:** nenhum sistema entra nesta spec por analogia ou de memória. **Estuda-se o mecanismo, escreve-se com números e com fonte, e só depois se decide o nosso.**
- **Descanso recarrega o mapa todo** (chefes não) · tecto de **10 reaparições** por inimigo — não se farma
- **Almas variam por inimigo** — e com o tecto, cada zona passa a ter um orçamento fixo de almas
- ⭐ **GARANTIA DE ESPÓLIO:** em 10 mortes o inimigo larga **todas as peças que se vêem nele + a arma + o feitiço**. Chefe larga tudo de uma vez. ⚠️ Aleatório dá **32%** de sair o conjunto — por isso o mecanismo é um **baralho de 10 sem reposição**, não um dado
- **Armadura pesada**: rolamento mais lento e curto — ⚠️ **nunca menos invencibilidade**
- **Atributos:** vida, stamina, magia, inteligência, slots de magia, carga
- ⭐ **O MAGO é a classe mais vasta** — cura, dano, buffs, elementos, **magia do mal**. ⚠️ `[TENSÃO]` registada: sem travões quebra a Lei 3
- **Espadachim = destreza**, capricho nas **katanas** e nas espadas
- ⭐ **Cada arma bate diferente — "nada é uma animação, tudo é calculado"**: se duas armas só diferem em números, uma não devia existir
- **Inventário SEM LIMITE** — só o equipado pesa (70%) · **baús** · **carregamento por área** · **mundo vasto**
- ⭐ **Feitiços NUNCA repetem** (armas podem) · ⭐ **melhoria de feitiços** em 3 eixos: força, **área**, **lançamentos**
- ⭐ **Espólio enviesado pela classe** — só nas cartas de enchimento; a promessa nunca muda
- **Abre as perguntas 26–29** no `99`
- **Substitui:** nada — os estudos que a sustentam são o [`41`](spec/41-estudo-armas-e-golpes.md), [`42`](spec/42-estudo-magia.md) e [`43`](spec/43-estudo-espolio-inventario-mundo.md)

⚠️ **Substituições posteriores (01-08):** a lista de atributos preserva a fala original, mas **slots deixaram de existir** e o bolo de cargas foi revogado pelo [`54`](spec/54-mana-meditacao-e-tracos-de-classe.md); a execução está no [`66`](spec/66-catalogo-de-magia.md). Carga equipada e curvas próprias por atributo foram fechadas no [`70`](spec/70-fecho-dos-sistemas-de-combate.md).

### Estudo profundo da referência → [`spec/39-estudo-profundo.md`](spec/39-estudo-profundo.md)
- ⭐ **PISO DE 30%** — nenhuma defesa reduz um golpe abaixo de 30%. É a **Lei 1 em equação**, e não a tínhamos
- ⭐ **Soft cap aos ~40** — sem ele o nível 100 ganha jogos. Lá, dos 40 aos 99 ganham-se **10 pontos de stamina**: é a curva que segura a Lei 1, não a boa vontade
- ⭐ **A carga muda distância e stamina, NUNCA a invencibilidade** (12 vs 13 frames = ruído) — confirma a cláusula 3 do 38 e dá a forma certa de a armadura pesada custar
- ⭐ **Interrupção + hiper-armadura** — sistema inteiro em falta; sem ele **armas lentas não existem**
- ⭐ **Um bolo de cargas repartido entre curar e usar** — resolve artes de arma, magia e a Lei 3 de uma vez
- ⭐ **Contador de mortes por sala** — acaba com o grind e amolece a zona sozinha, sem menu de dificuldade
- ⭐ **Toda a zona fecha um círculo**; o atalho abre-se **do lado de dentro** · **descanso à vista da porta do chefe** (a corrida de volta é fricção ×2 em co-op)
- ⭐ **Descrição em todo o objecto, colocado por relevância** — é daqui que vem o *"nunca zera"*
- Defesa por **curva sobre a razão** + absorção **multiplicativa** · dois eixos de melhoria (reforço/infusão) · parry com **três janelas** · **invencibilidade durante o crítico** (impede o parceiro de interromper) · a loja vende conveniência, **nunca poder**
- ⚠️ **NÃO copiar:** chefe de co-op só com mais vida (esponja, castiga quem já perde) · inimigos que encadeiam ataques na recuperação · estatística de interrupção que só funciona a atacar
- **Abre as perguntas 22–25** no `99`
- **Substitui:** nada — completa o [`spec/35-estudo-referencia.md`](spec/35-estudo-referencia.md)

⚠️ **Substituições posteriores (01-08):** soft cap universal → curvas próprias; distância variável de esquiva → recuperação/regen/sobrecarga; bolo de cargas → frasco + mana; descanso em cada porta → descanso por arco antes do guardião. Autoridades: [`53`](spec/53-chefes-ritmo-e-o-mago-forte.md), [`54`](spec/54-mana-meditacao-e-tracos-de-classe.md), [`66`](spec/66-catalogo-de-magia.md), [`70`](spec/70-fecho-dos-sistemas-de-combate.md).

### Ataques dos inimigos e o contrato de honestidade → [`spec/38-ataques-e-honestidade.md`](spec/38-ataques-e-honestidade.md)
- **5 fases por ataque**; aviso ≥ **0,50 s**; hitbox viva só **3–6 frames**
- ⚠️ **O CONTRATO, 5 cláusulas:** hitbox nunca >10% do visual · **o seguimento pára antes de a hitbox acender** (é a causa nº1 de "esquivei e levei") · invencibilidade não escala com nada · o que se vê é o que acontece · **teste do rolamento: 10 em 10, sem excepção**
- **3–5 ataques por inimigo**, e os três têm de ser **três perguntas diferentes** — um que se apara, um que só se esquiva, um que obriga a mexer o pé
- ⚠️ **A coluna "como se escapa" nunca pode dizer "não dá"** — ataque sem escapatória não é difícil, é injusto
- **Largam o que se vê no corpo deles**
- **Substitui:** nada — detalha o `arranque/activo/recuperação` do WP1

### Anéis, elementos e a correcção da queda → [`spec/37-aneis-e-elementos.md`](spec/37-aneis-e-elementos.md)
- **~70 anéis, até 10 equipados** (um por dedo), ~10 por classe mas usáveis por todas. Criativos, sem repetir; alguns somam-se
- **Elementos:** fogo, raio, veneno, escuridão, magia do mal — além de físico (corte/contundente/perfuração) e mágico. **Escudos diferem por elemento**
- ✏️ **CORRIGE o dano de queda:** era percentagem pura (nível não valia nada); passa a **fixo + proporcional**, com tecto absoluto aos 25 m. Eu tinha esticado a Lei 1 para onde ela não se aplica
  - ⚠️ **Histórico:** o contrato canónico posterior do [`70`](spec/70-fecho-dos-sistemas-de-combate.md) preserva fixo + proporcional abaixo do limiar e move a morte absoluta para **20 m**, para vida/equipamento não abrirem topologia.
- ⚠️ **Substitui:** a tabela de queda do [`spec/36-fisica.md`](spec/36-fisica.md) §2

### Física, artes de arma e armadura por peça → [`spec/36-fisica.md`](spec/36-fisica.md) e [`spec/34-catalogo-e-comandos.md`](spec/34-catalogo-e-comandos.md) §2b/§2c
- **Cada arma dá arte a 1 mão e outra a 2 mãos** — 8 famílias × 2 = **16 artes com UMA tecla**
- **Habilidade da armadura vive na PEÇA**, não no conjunto. Sem bónus de conjunto: misturar passa a ser construção
- **Física escrita de raiz** — era buraco total: gravidade −18 m/s², dano de queda por percentagem (Lei 1), **setas com balística** (a 30 m falha-se se apontar a direito), empurrão que escala com a massa, varrimento de arma obrigatório, **passo fixo a 60 Hz** para as janelas do WP1 não mudarem com engasgos
- **Substitui:** nada — preenche o que não existia

### Escala do catálogo e a regra dos comandos → [`spec/34-catalogo-e-comandos.md`](spec/34-catalogo-e-comandos.md)
- ~**30 armaduras**, cada uma com habilidade ou identidade própria. Nenhuma existe só para dar defesa
- ~**20 armas por classe** (≈120), em famílias que **partilham conjunto de movimentos**
- ⚠️ **Toda a habilidade diz como se activa, na mesma linha.** Armaduras → passivas ou condicionais; armas → uma tecla partilhada de arte de arma
- **Substitui:** nada. Acrescenta uma regra de processo que vale para trás — o WP3, WP4 e WP5 têm de ser revistos contra ela

### Os quatro casos das almas → [`spec/33-morte-e-almas.md`](spec/33-morte-e-almas.md) §4
- **Um ressuscitado a tempo:** não perde nada · **um morre e o minuto passa:** almas ficam onde caiu · **os dois morrem:** duas manchas separadas, uma por cada · **solo:** igual ao segundo caso
- Recuperar = voltar e apanhar. **Morrer outra vez antes de apanhar perde-as de vez**
- ⚠️ Se os dois morrerem na arena do chefe, as manchas ficam lá dentro com o chefe vivo. **É tensão de propósito — ninguém conserte isto**
- **Substitui:** a linha vaga de que as almas "ficam no corpo"

### Ressurreição afinada → [`spec/34-catalogo-e-comandos.md`](spec/34-catalogo-e-comandos.md) §3
- Canalização passa a **5–7 s** (era 5 fixo)
- **Quem morre larga itens**, não só almas
- **Substitui:** o valor fixo de 5 s no [`33-morte-e-almas.md`](spec/33-morte-e-almas.md)

### Morte, almas, cura e armadura → [`spec/33-morte-e-almas.md`](spec/33-morte-e-almas.md)
- **Almas** = moeda e experiência. Nível **1→100**. Caem no sítio da morte; morrer outra vez perde-as
- **Frascos** que recarregam nos **pontos de descanso**; descansar **faz voltar os inimigos**
- **Armadura existe, muitas, por peças**; inimigos largam o que usam
- **Co-op:** o morto fica no mundo do parceiro, **1 min** de janela, ressuscita-se ficando em cima do corpo
- **Substitui:** *"não se perde nada ao morrer"* (WP0) · *"o jogador morto fica morto até o combate acabar"* (WP1) · a pergunta 7 aberta · a pergunta 14 aberta

### A fase muda: spec → construção → [`spec/32-construcao.md`](spec/32-construcao.md)
- O Fable **passa a escrever código**
- **A spec manda:** código que diverja obriga a mudar a spec no mesmo PR
- Reserva passa a ser **por marco**, não por pacote
- **Substitui:** a regra *"não escreves código"* no briefing, no `CLAUDE.md` e no `README.md`

### Referências → [`spec/31-referencias.md`](spec/31-referencias.md)
- **Dark Souls** é a referência; **DS2 é o chão aceitável**
- **Protocolo:** recolher números → tabela *eles·nós·diferença* → nomear a diferença → escrever a nossa versão → citar fonte
- ⚠️ **A linha:** padrões sim, conteúdo não. Nada extraído de outro jogo entra no repositório
- **Substitui:** nada. ⏳ **Os 11 documentos do PR #11 não passaram por este protocolo** — falta uma revisão

### Qualidade visual → [`spec/30-qualidade-visual.md`](spec/30-qualidade-visual.md)
- **Não é PlayStation 1.** 8–15 mil tri por personagem, texturas 1–2K
- **Substitui:** a expressão *"baixo poligonal"* em cinco documentos

### Perspectiva → [`spec/29-perspectiva.md`](spec/29-perspectiva.md)
- **Primeira ou terceira pessoa, à escolha do jogador**
- ⚠️ Em 1.ª pessoa não há visão periférica → **todo o ataque anunciado antes de entrar no ecrã**. O [`62`](spec/62-acessibilidade-auditiva.md) corrige o canal exclusivo: o mesmo evento produz som direccional **e** sinal visual equivalente; ouvir nunca é requisito
- **Plataforma: PC**
- **Substitui:** *"terceira pessoa"* em 6 documentos. ⏳ O bestiário do PR #11 ainda não tem os sons por ataque

## 31-07-2026 · manhã

### Sete decisões aprovadas pelos dois
| | |
|---|---|
| Fatia 1 | aprovada como está |
| 6 classes na fatia | confirmadas |
| **Evoluções de classe** | **opção A** — opções, não números; por marco, não por nível |
| **Magia bem/mal** | aprovada; preço do mal é **PV à vista**. A fatia usa **as duas escolas** |
| 7 raças + Ceifador | aprovados |
| 3D | **caminho A** |
| **Soft gating** | mapa aberto, dificuldade sugerida e não exigida |
| **Mapa** | ~30 min a pé, **10+ biomas** |
| **Tom** | sombrio a sério · **Idioma:** português |

⚠️ **Divergência viva:** o WP8 desenhou **6 zonas**; foram aprovados **10+**.

## 30-07-2026 · sessão 1 (gravada)

As decisões originais, com timestamp, em [`spec/00-visao.md`](spec/00-visao.md) e nos documentos de cada área. As quatro leis saem daqui.

---

## Como usar isto quando os commits do Fable chegarem

1. **Ver a data do trabalho dele.** Tudo o que for anterior a 31-07 tarde não conhece as decisões de cima
2. **Percorrer esta lista de cima para baixo**, e para cada uma perguntar: *o código dele assume o contrário?*
3. **Os candidatos mais prováveis a divergir**, por ordem de risco:
   - **Morte** — se implementou "não se perde nada", está desactualizado
   - **Ressurreição em co-op** — se implementou "fica morto até o combate acabar", está desactualizado
   - **Perspectiva** — se assumiu só terceira pessoa, falta metade
   - **Habilidades sem tecla** — se criou habilidades sem dizer como se activam
   - **Cura** — se assumiu poções compráveis em vez de frascos
4. **A spec manda** ([`spec/32-construcao.md`](spec/32-construcao.md)): o código alinha-se com ela, não o contrário. Mas se ele descobriu a construir que um número não funciona, **isso muda a spec** — e é bom.
