# ESTADO — o que é verdade hoje

**Actualizado: 31-07-2026, fim do dia.** Este é o ficheiro que se lê primeiro. O [`SPEC.md`](SPEC.md) diz **onde** as coisas estão; este diz **em que pé** estão e **por que ordem** se pega nelas.

> **Porque existe:** a spec tem 46 documentos e ~35 decisões. Onze dos documentos de execução são **anteriores** a decisões que os mudam. Sem um sítio que diga o que vale hoje, qualquer agente constrói sobre o que já foi substituído.

---

## 1. ⚠️ O jogo existe, e até hoje vivia num sítio só

**O protótipo joga-se.** Combate fiel ao WP1 (i-frames 0,08→0,38, parry de 8 frames + contra-golpe, as 5 armas com frames exactos), lanceiro e brutamontes com telegrafia, 3 magias, o Vorgar com 2 fases, frasco de cura, habilidades de classe, 12 sons sintetizados. **130 auto-testes contra a spec.** Godot 4.7.1, renderer Mobile, **416 fps na máquina do Rico**. Detalhe em [`spec/44-prototipo.md`](spec/44-prototipo.md).

⚠️ **E até 31-07 vivia apenas no disco do Rico**, num repositório local `worldrpgs-game` que nunca chegou ao GitHub. Sem cópia. Sem revisão possível. Um disco avariado e perdia-se tudo.

### `[DECIDIDO]` (Mateus, 31-07-2026) — o código passa a viver aqui

**Neste repositório, ao lado da spec.**

O plano antigo ([`spec/23-tecnico.md`](spec/23-tecnico.md), [`spec/24-plano.md`](spec/24-plano.md)) previa um repositório separado. **Foi escrito quando este era só de especificação, e deixou de fazer sentido:**

| Razão | |
|---|---|
| ⭐ **A regra do "mesmo PR"** | o [`CLAUDE.md`](CLAUDE.md) manda que, se o código e a spec discordarem, **a spec muda primeiro, no mesmo PR**. Isso é **impossível** em dois repositórios |
| **Revisão** | o Claude revê o que está aqui. O que está fora não existe para a revisão |
| **Cópia de segurança** | um repositório é a cópia. Um disco não é |
| **Um sítio** | o Rico e o Fable já trabalham aqui |

**Estrutura:** o código vai para `game/`. A spec fica onde está.

---

### ✅ Feito — e verificado por mim, não pela palavra de ninguém

O código está em [`game/`](game/) desde 31-07 (PR #13), com os 8 commits originais preservados por `git subtree` — confirmei um a um que são ancestrais da `main`.

```
$ godot --headless --path game/ scenes/selftest.tscn
=== 130 passaram, 0 falharam ===
```

## 1b. ⭐ O que temos, em números

**Esta tabela é o retrato do projecto.** O que falta não é arquitectura — é **conteúdo**.

| | Temos | A spec promete | Falta |
|---|---|---|---|
| Documentos de spec | 47 · 6330 linhas | — | — |
| Código | 46 ficheiros · 4033 linhas · 717 de dados | — | — |
| Testes | **130, todos a passar** | — | — |
| Imagens | 32 (cenários, classes, 7 raças) | — | ⚠️ **zero ícones de objecto** |
| **Armas** | 5 instâncias · **8 famílias** ([`51`](spec/51-familias.md)) | ~120 | as instâncias (camada 2) |
| **Armaduras** | **11 peças** · 9 slots · 3 cargas ([`51`](spec/51-familias.md)) | ~30 | ~19 |
| **Anéis** | **0** | ~70 | **70** |
| **Feitiços** | **3** | catálogo largo | quase tudo |
| **Inimigos** | **3** | 12 raças + 61 chefes | quase tudo |
| Habilidades de classe | 6 | 6 | ✅ |
| **Biomas** | **12 fichas** ([`49`](spec/49-biomas.md) + `game/data/biomes.json`) | 12 | ✅ volta 1 |
| **Raças** | **12 fichas + mímico** ([`50`](spec/50-racas.md) + `game/data/races.json`) | 10–15 | ✅ volta 2 |

⭐ **E a instrução que daí sai:** o motor é data-driven — o `game_data.gd` recusa arrancar se os dados divergirem da spec. **Escrever o catálogo não é documentar o jogo: é construí-lo.** O catálogo escreve-se em `spec/` **e** em `game/data/*.json`, no mesmo PR.

## 2. O que está decidido e ainda não está na spec de execução

**~35 decisões, das quais estas são as que mais mudam trabalho já escrito.** A lista completa e por ordem está no [`DECISOES.md`](DECISOES.md).

| Decisão | Onde está | O que atinge |
|---|---|---|
| ⭐ **Piso de 30%** — nenhuma defesa reduz um golpe abaixo disso | [`39`](spec/39-estudo-profundo.md) §1 | WP2 |
| ⭐ **Soft cap aos ~40** — sem ele o nível 100 ganha jogos | [`39`](spec/39-estudo-profundo.md) §2 | WP2, WP9 |
| ⭐ **Interrupção e hiper-armadura** — sem isto armas lentas não existem | [`39`](spec/39-estudo-profundo.md) §4, [`41`](spec/41-estudo-armas-e-golpes.md) §4 | WP1, WP5 |
| ⭐ **Contra-ataque +30%** por bater enquanto o inimigo ataca | [`41`](spec/41-estudo-armas-e-golpes.md) §3 | WP1 |
| ⭐ **Um bolo de cargas repartido entre curar e usar** | [`39`](spec/39-estudo-profundo.md) §7 | WP4, WP5, WP9 |
| ⭐ **Espólio garantido — baralho de 10 sem reposição** | [`40`](spec/40-decisoes-espolio-magia-inventario.md) §3, [`43`](spec/43-estudo-espolio-inventario-mundo.md) §2 | WP6, WP7, WP9 |
| ⭐ **Descanso recarrega o mapa · 10 reaparições · não se farma** | [`40`](spec/40-decisoes-espolio-magia-inventario.md) §1 | WP6, WP9 |
| ⭐ **Feitiços únicos + melhoria de feitiços em 3 eixos** | [`40`](spec/40-decisoes-espolio-magia-inventario.md) §12–13, [`42`](spec/42-estudo-magia.md) §6 | WP4 |
| ⭐ **A magia é a área mais vasta do jogo** | [`40`](spec/40-decisoes-espolio-magia-inventario.md) §6, [`42`](spec/42-estudo-magia.md) | WP3, WP4 |
| ⭐ **Armas por família, não por classe** | [`35`](spec/35-estudo-referencia.md) §1, [`41`](spec/41-estudo-armas-e-golpes.md) §2 | WP5 |
| ⭐ **O contrato de honestidade** — 5 cláusulas, e o teste do rolamento | [`38`](spec/38-ataques-e-honestidade.md) | WP6, WP7, WP15B |
| ⭐ **Toda a zona fecha um círculo · descanso à vista do chefe** | [`39`](spec/39-estudo-profundo.md) §8 | WP8 |
| ⭐ **Carregamento por área · a porta de nevoeiro é a barreira** | [`43`](spec/43-estudo-espolio-inventario-mundo.md) §6 | WP14, WP8 |
| ⭐ **Mochila sem limite — só o equipado pesa** | [`40`](spec/40-decisoes-espolio-magia-inventario.md) §9 | WP11, WP5 |
| ⭐ **Controlos configuráveis no jogo** | [`45`](spec/45-controlos-configuraveis.md) | WP11 |
| **Descrição em todo o objecto, colocado por relevância** | [`39`](spec/39-estudo-profundo.md) §12 | WP9, WP13 |
| **10 anéis / ~70 anéis** | [`37`](spec/37-aneis-e-elementos.md) | WP5 |
| **Física: gravidade, queda, balística, empurrão** | [`36`](spec/36-fisica.md) | WP1, WP8 |

---

## 3. ⭐ A ordem, e por que é esta

⚠️ **Actualizada a 31-07 pelo [`46`](spec/46-coerencia-bioma-raca-item.md):** as **24 fichas** (12 de bioma + 12 de raça) vêm **antes** dos catálogos. São 8 linhas cada, meio dia de trabalho, e é delas que saem as descrições de tudo — com coerência de graça. Ao contrário, cada descrição é inventada de novo e a regra anti-mistura é impossível de aplicar porque não há biomas definidos para comparar.



**Não é uma lista de desejos — é uma cadeia de dependências.** Cada passo desbloqueia o seguinte.

```
0. ✅ O código veio para o repositório               (feito, PR #13)
        ▼
1. ✅ AS 24 FICHAS ── 12 de bioma (spec/49) + 12 de raça (spec/50)
        │           O MOTOR DE PRODUÇÃO ESTÁ COMPLETO — cada descrição
        │           é agora uma intersecção de duas fichas que existem
        ▼
2. Os CATÁLOGOS  (WP4 magia · WP5 armas e armaduras · WP6 bestiário)
        │           cada item = intersecção de uma ficha de bioma
        │           com uma de raça — a descrição sai quase sozinha
        │
        ├──► desbloqueia AS IMAGENS ──► não se desenham 120 armas
        │                               sem saber quais são
        │
        └──► desbloqueia O CONTEÚDO ──► o motor é data-driven:
                                        o catálogo É o jogo
        ▼
3. Os SISTEMAS que faltam  (interrupção · contra-ataque · baralho ·
        │                   soft caps · piso de 30% · carregamento por área)
        ▼
4. O MUNDO  (WP8: círculos, atalhos, 12 biomas, descanso à porta do chefe)
        ▼
5. O ALINHAMENTO dos documentos antigos contra o DECISOES.md
```

### Porque é que as fichas vêm antes do catálogo

⭐ **Porque são o motor de produção.** 12 fichas de bioma + 12 de raça = **24 fichas de 8 linhas**, e cada uma das ~300 descrições do jogo é **uma intersecção de duas delas**. Se a ficha do bioma diz *"obsidiana"* e a da raça diz *"usam os ossos dos inimigos"*, o machado escreve-se sozinho.

⚠️ **Ao contrário, cada descrição é inventada de novo, nenhuma combina com as outras, e a regra anti-mistura do [`46`](spec/46-coerencia-bioma-raca-item.md) §4 é impossível de aplicar** — não há biomas definidos contra os quais comparar.

### E porque é que o catálogo vem antes dos sistemas

As imagens estão paradas à espera dele: os 32 assets que existem cobrem cenários, classes e as 7 raças — **não há um único ícone de arma, de armadura ou de feitiço**, porque ninguém sabe ainda quais são. E o motor é data-driven por desenho ([`44`](spec/44-prototipo.md) §2): *"nenhum número de combate vive em código"*. **Escrever o catálogo é, literalmente, produzir conteúdo jogável.**

### E o alinhamento vem por último de propósito

É limpeza — necessária, mas **não produz nada novo**, e metade dele resolve-se sozinho à medida que os catálogos se reescrevem.

---

## 4. O que é dos donos, e só deles

Está tudo no [`99-perguntas-abertas.md`](spec/99-perguntas-abertas.md). **Nenhuma destas trava o trabalho** — todas têm proposta escrita, e o Fable avança com a proposta enquanto elas não fecham.

**As três que mais mudam o jogo se a resposta for diferente da proposta:**

| # | Pergunta | Proposta em cima da mesa |
|---|---|---|
| **28** | ⚠️ Se a magia faz tudo, como é que o mago não é a classe correcta? | cinco travões — o principal é **quem lança muito, cura pouco** |
| **24** | Chefe a dois: +40% de vida, ou zero? | **+40%, dano igual, e a escala desce quando um morre** |
| **22** | Se os inimigos param de reaparecer, de onde vêm as almas para o nível 100? | ou o mundo é maior, **ou o 100 não é para uma passagem** |

E as sete perguntas de narrativa ([`26-narrativa.md`](spec/26-narrativa.md) §3) continuam a precisar de uma gravação — **nome do jogo incluído**.

---

## 5. Os guardas

**Não são para travar ideias. São contra esquecimentos** — o modo de falha real deste projecto é escrever uma coisa boa e deixar-lhe uma ponta solta.

### ⭐ As quatro perguntas do fio solto

> **Nada entra na spec sem responder às quatro.** Uma resposta em branco é uma ponta solta, e pontas soltas descobrem-se seis meses depois, quando custam dez vezes mais.

| | Pergunta | Origem |
|---|---|---|
| **1** | **Como é que o jogador usa isto?** | a regra do Mateus, [`34`](spec/34-catalogo-e-comandos.md) §2 — apanhou 4 lacunas reais à primeira tentativa |
| **2** | **Como é que se prova que funciona?** | um teste, um critério, um número a medir |
| **3** | **De onde vem a arte e o som?** | pack, geração, ou à mão — [`22`](spec/22-assets.md) |
| **4** | **Quanto custa na máquina do Rico?** | Lei 4 — 8 GB e Iris Xe |

### E as regras de sempre

| | |
|---|---|
| **Se o código e a spec discordam** | muda-se a spec primeiro, **no mesmo PR** |
| **Nada por analogia nem de memória** | estuda-se o mecanismo, escreve-se com **números e fonte**, e só depois se decide o nosso |
| **Reservar antes de começar** | pacote **e** número de ficheiro, em [`COORDENACAO.md`](COORDENACAO.md) |
| **Não decidir uma `[TENSÃO]`** | propõe-se e recomenda-se. Decidem os donos |
| **Adjectivos não são spec** | *"combate responsivo"* não é nada. *"0,60 s, invencibilidade dos 0,08 aos 0,38"* é |
| **Coluna `Fatia 1?`** | em todo o catálogo. É o que trava o escopo |

---

## 6. O risco, dito uma vez

Mundo vasto + ~61 chefes + 10+ biomas + ~120 armas + 30 armaduras + ~70 anéis + catálogo de magia largo, **feito por duas pessoas e dois agentes**.

**Os donos sabem e decidiram avançar** — e a decisão é deles. Fica registado que a alavanca que dá vastidão sem custar produção são os **círculos e atalhos** ([`39`](spec/39-estudo-profundo.md) §8), e que a coluna `Fatia 1?` é o que impede o catálogo de virar um plano de dez anos.

---

## Onde continuar

| Quem | O quê |
|---|---|
| **Fable** | ⚠️ **a identidade do Assassino** (marcada *em revisão* no [`12-classes.md`](spec/12-classes.md)), depois a **volta 4 — magia** |
| **Mateus** | ⏳ **6 instruções do Rico à espera do 👍** — [`DECISOES.md`](DECISOES.md), 31-07 · noite. E os PRs #14, #15, #16 |
| **Donos** | as perguntas 22, 24 e 28 do [`99`](spec/99-perguntas-abertas.md), e uma gravação para a narrativa |
| **Claude** | rever o que chega · ⭐ **gerar os 11 ícones de armadura** (fatia 1, prioridade sobre biomas e raças) |

### As três voltas de 31-07, e onde estão

| PR | Volta | Auto-teste |
|---|---|---|
| [#14](https://github.com/MateusJuni0/worldrpgs/pull/14) | 12 fichas de bioma · fecha as perguntas 4 e 13 | 130 → **160** |
| [#15](https://github.com/MateusJuni0/worldrpgs/pull/15) | 12 fichas de raça · o motor das 24 fichas fica completo | → **194** |
| [#16](https://github.com/MateusJuni0/worldrpgs/pull/16) | famílias, armadura, kits · a tensão da armadura resolvida | → **226** |
