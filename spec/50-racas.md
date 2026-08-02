# 50 — As 12 fichas de raça

> **Volta 2 · Fable** (31-07-2026). A segunda metade do motor de produção do [`46`](46-coerencia-bioma-raca-item.md) §5: **12 raças, 8 linhas cada**, mais `descrição visual` e `Fatia 1?`. Herda: **10 a 15 raças** `[DECIDIDO]` · as **7 aprovadas a 31-07** com as notas do Rico ([`04`](04-inimigos-chefes.md)) · as casas semeadas na volta 1 ([`49`](49-biomas.md)). As **6 novas são `[FABLE]`** — a liberdade criativa pedida no briefing, com as quatro pontas atadas.
>
> ⭐ **Vivem também em [`game/data/races.json`](../game/data/races.json), no mesmo PR** — e o motor passa a **verificar o laço bioma ↔ raça nos dois sentidos**: toda a raça que um bioma aloja existe, e todo o bioma que uma raça habita existe. A regra anti-mistura do [`46`](46-coerencia-bioma-raca-item.md) §4 deixa de ser prosa e passa a ser um teste.

---

## 0. A conta, e o mímico

**12 raças = as 6 esboçadas** (goblin, kobold, esqueleto, zumbi, orc, minotauro) **+ 6 novas** (Tecelões, Ventaneiras, Borralheiros, Submersos, Penitentes, Sem-Rosto). Dentro do tecto `[DECIDIDO]` de 10–15.

⚠️ **O mímico não é uma raça — é uma praga.** Não tem sociedade, não veste o bioma, não trata os mortos: imita baús onde há espólio. Fica em `races.json` como `tipo: "praga"` (os biomas referem-no, o laço tem de fechar), e a ficha de **encontro** dele é do WP6 — com a regra que já tem: **respira**, e isso é a telegrafia.

**A linha "como luta" usa os papéis do [`38`](38-ataques-e-honestidade.md) §6** — rápido · pesado · distância · grupo · armadilha — porque é o papel que garante ≥ 3 perguntas diferentes por bioma.

---

## 1. Orcs — a raça da fatia · **Fatia 1 ✅**

| | |
|---|---|
| **De onde vem** | da Fornalha: descem da gente da forja, de quando a forja precisava de mãos |
| **O que quer** | provar valor em duelo — um clã mede-se pelo ferro que carrega |
| **Porque está neste bioma** | **Brumal**: a bruma é terreno de caça e rito de passagem · **Costa**: os expulsos, viraram saqueadores de naufrágios · **Fornalha**: os que nunca deixaram a forja-mãe |
| **Como trata as outras raças** | goblins como batedores tolerados na orla; minotauros respeitam-se de longe (não se caçam); kobolds desprezam-se |
| **O que faz com os mortos** | ergue-os em pilhas com o ferro em cima — o ferro do morto é de quem provar que o merece. *(É por isso que orcs largam armas: o espólio é um rito deles, não uma mecânica nossa)* |
| **Como se veste** | a lei do bioma: ferro rude e couro de javali (Brumal) · bronze verde (Costa) · obsidiana (Fornalha) |
| **Como luta** | **rápido** (lanceiro) e **pesado** (brutamontes) — os dois professores da fatia ([`15`](15-inimigos.md)) |
| **Uma coisa que ninguém sabe** | nenhum orc entra na Toca por vontade. Vorgar não guarda a dungeon **dos** orcs — guarda-a **contra** eles |
| **Descrição visual** | guerreiro tribal maciço, pele cinzenta-esverdeada, ferro rude e couro de javali *(✅ conceitos reais: [`orc-lanceiro.png`](../art/concept/inimigos/orc-lanceiro.png), [`orc-brutamontes.png`](../art/concept/inimigos/orc-brutamontes.png) e [`vorgar.png`](../art/concept/chefes/vorgar.png); fichas do jogo `orc_spearman`, `orc_brute` e `vorgar` em [`enemies.json`](../game/data/enemies.json))* |
| **Fatia 1?** | ✅ — lanceiro, brutamontes e Vorgar |

## 2. Goblins

| | |
|---|---|
| **De onde vem** | da Selva Funda — expulsos do chão para as copas por aquilo de quem o chão é |
| **O que quer** | comida, e coisas que brilham; sobreviver em número |
| **Porque está neste bioma** | **Selva**: a casa nas copas · **Brumal**: a orla é onde se rouba aos orcs · **Raizama**: um bando desceu atrás dos esporos que brilham, e voltou diferente |
| **Como trata as outras raças** | serve os orcs por medo; troca seda com os Tecelões (são os únicos sem nojo deles); foge do resto |
| **O que faz com os mortos** | abandona-os — e volta de noite para levar o que ficou. *(Um corpo de goblin nunca está onde caiu)* |
| **Como se veste** | vime e retalhos; na Raizama, quitina |
| **Como luta** | **grupo** — 3 a 5, nunca menos de 3; moral de bando, fogem a 20% ([`15`](15-inimigos.md)) |
| **Uma coisa que ninguém sabe** | há um goblin que os outros alimentam e que nunca luta — e não é o mais fraco |
| **Descrição visual** | pequeno e curvado, pele verde-acinzentada, olhos grandes, armadura de retalhos de vime, faca curta *(nota do Rico: "pequeno, verde ou cinza, ataca em grupos")* |
| **Fatia 1?** | ⬜ |

## 3. Kobolds

| | |
|---|---|
| **De onde vem** | das minas do Fojo — mudaram-se para o que encontraram aberto |
| **O que quer** | que ninguém entre; colecciona mecanismos |
| **Porque está neste bioma** | **Fojo**: a casa · **Selva**: os barrancos armam-se bem · **Fulgor**: têm pavor ao raio, mas a fulgurite vale o risco — a ganância vence o medo |
| **Como trata as outras raças** | evita todas; deixa tributo à entrada do labirinto do Minotauro, sem nunca o ver |
| **O que faz com os mortos** | enterra cada um com uma armadilha desarmada — a ferramenta morre com o dono |
| **Como se veste** | couro, corda, e **um sino de aviso ao pescoço** — ouve-se um kobold antes de o ver *(telegrafia de raça: a honestidade do [`38`](38-ataques-e-honestidade.md) vestida)* |
| **Como luta** | **armadilha** — não procura combate: foge para o terreno que armou e espera ([`15`](15-inimigos.md)) |
| **Uma coisa que ninguém sabe** | as armadilhas mais antigas do Fojo não são deles — são cópias do que lá estava |
| **Descrição visual** | réptil pequeno de escamas cor de ferrugem, corcunda, sino ao pescoço, olhos de mina grandes e escuros *(nota do Rico: "pequeno réptil covarde que gosta de armadilhas")* |
| **Fatia 1?** | ⬜ |

## 4. Esqueletos

| | |
|---|---|
| **De onde vem** | da guerra das Campas — os que nunca foram enterrados |
| **O que quer** | cumprir a última ordem que recebeu. Só isso |
| **Porque está neste bioma** | **Campas**: o campo de batalha · **Santuário**: a guarda dourada, que rezou e ficou · **Raiz**: os antigos, de antes da guerra |
| **Como trata as outras raças** | ignora tudo o que não atravessa o seu posto |
| **O que faz com os mortos** | recolhe ossos caídos e tenta montá-los — mal. *(Os esqueletos errados que se vêem pelas Campas não são inimigos: são tentativas)* |
| **Como se veste** | o que morreu a vestir: ferro ferrugento nas Campas, ouro baço no Santuário |
| **Como luta** | **rápido** — golpes curtos de espada, e **reergue-se uma vez** a menos que o golpe final seja contundente ([`15`](15-inimigos.md)) |
| **Uma coisa que ninguém sabe** | ainda obedecem a alguém que dá ordens — e não é o Ceifador |
| **Descrição visual** | osso seco e quebradiço, armadura da guerra a cair aos pedaços, postura de sentinela *(✅ retrato de raça já gerado no bestiário)* |
| **Fatia 1?** | ⬜ |

## 5. Zumbis

| | |
|---|---|
| **De onde vem** | dos mesmos mortos da guerra — os que a água encharcada não deixou secar |
| **O que quer** | nada. Anda para onde o corpo se lembra de ir |
| **Porque está neste bioma** | **Campas**: a água parada · **Cidade Afogada**: os que a água levou no dia em que subiu |
| **Como trata as outras raças** | nem as vê; os esqueletos empurram-nos para fora das formações |
| **O que faz com os mortos** | quando um zumbi cai de vez, o corpo fica **apontado para onde ia** — a rota dele lê-se no chão. *(→WP8: apontá-los a segredos é cenário grátis)* |
| **Como se veste** | restos inchados de camponês; na Cidade, algas e a prata que afundou com eles |
| **Como luta** | **pesado** — lento, e **resiste a dano físico comum**: obriga a trocar de ferramenta (nota do Rico; a Lei 2 do lado do inimigo) |
| **Uma coisa que ninguém sabe** | quando ninguém os vê, os zumbis das Campas andam todos na mesma direcção. Para baixo |
| **Descrição visual** | cadáver inchado e lento, pele cinzenta esticada, roupa de camponês encharcada *(✅ retrato de raça já gerado no bestiário)* |
| **Fatia 1?** | ⬜ |

## 6. Minotauros

| | |
|---|---|
| **De onde vem** | do Fulgor — manadas em migração eterna debaixo da tempestade |
| **O que quer** | caminhar o caminho. Parar é sagrado ou é castigo — um minotauro parado guarda alguma coisa |
| **Porque está neste bioma** | **Fulgor**: a casa; o raio cai-lhes nos chifres e eles seguem (estão ligados ao chão — é o elemento terra do bioma) · **Cimeira**: os postos de neve · **Fojo**: **um** parou, e ganhou um labirinto (o guardião do WP8) |
| **Como trata as outras raças** | aceita o tributo dos kobolds sem o entender; os orcs respeitam-no; ignora o resto |
| **O que faz com os mortos** | carrega-lhes os ossos até ao fim da migração — os velhos carregam dezenas |
| **Como se veste** | quase nada: pele de cabra na Cimeira, couro seco no Fulgor. O corpo é a armadura |
| **Como luta** | **pesado** puro — hiper-armadura, massa alta, empurrão ([`36-fisica.md`](36-fisica.md)) |
| **Uma coisa que ninguém sabe** | o labirinto do Fojo não foi construído para manter ninguém fora |
| **Descrição visual** | homem com cabeça de touro, 2,6 m, chifres lascados, ossos de outros minotauros pendurados no peito *(✅ retrato de raça já gerado no bestiário; nota do Rico: "vive em labirintos")* |
| **Fatia 1?** | ⬜ |

## 7. Tecelões `[FABLE]` — nova

| | |
|---|---|
| **De onde vem** | da Raizama — nasceram dentro da carcaça do grande morto |
| **O que quer** | seda e silêncio. **Tecem tudo o que sabem: a teia é escrita** — um ninho de Tecelões é um arquivo |
| **Porque está neste bioma** | **Raizama**: a casa · **Selva**: subiram atrás das aves gigantes (é deles o espinho que a colheita da Selva menciona) |
| **Como trata as outras raças** | troca seda com os goblins; embrulha o resto |
| **O que faz com os mortos** | embrulha-os e pendura-os — e a teia à volta **diz quem era**, para quem souber ler |
| **Como se veste** | a própria seda, endurecida em placas |
| **Como luta** | **armadilha** — mas orgânica: teia no terreno que prende e **vê-se** (contra a mecânica escondida dos kobolds, a deles está à vista e é pegajosa — dois "armadilha" que se jogam de maneiras diferentes, [`46`](46-coerencia-bioma-raca-item.md) §7) |
| **Uma coisa que ninguém sabe** | há uma teia no fundo da Raizama que nenhum Tecelão teceu — e nenhum se aproxima dela |
| **Descrição visual** | torso humanoide de quitina azul-escura sobre quatro patas, quatro olhos ciano, dedos longos de fiar, placas de seda endurecida |
| **Fatia 1?** | ⬜ |

## 8. Ventaneiras `[FABLE]` — nova

| | |
|---|---|
| **De onde vem** | da Cimeira — dizem que eram as sentinelas que subiram a vigiar, e o vento ficou com elas |
| **O que quer** | **ver primeiro.** Coleccionam primeiras-vistas, e gritam o que vêem — quer se queira ouvir, quer não |
| **Porque está neste bioma** | **Cimeira**: o posto de vigia · **Costa**: ninhos nas falésias, pesca nos destroços |
| **Como trata as outras raças** | grita avisos que ninguém pediu; odeia os Submersos, que lhe levam os ovos |
| **O que faz com os mortos** | deixa-os ao vento no pico mais alto — o vento leva quem era delas |
| **Como se veste** | as próprias penas, e bronze dos naufrágios (a lei do bioma da Costa) |
| **Como luta** | **distância** — mergulhos picados, **sempre anunciados pelo grito** antes de entrar no campo de visão (é a regra da 1.ª pessoa do [`29`](29-perspectiva.md) nascida na raça, não remendada depois) |
| **Uma coisa que ninguém sabe** | o que a primeira vigia viu ao longe ainda lá está — e há um quadrante do horizonte para onde nenhuma Ventaneira olha |
| **Descrição visual** | mulher-ave de penas cinza-azuis, envergadura de 4 m, garras com ponteiras de bronze, olhos amarelos de falcão |
| **Fatia 1?** | ⬜ |

## 9. Borralheiros `[FABLE]` — nova

| | |
|---|---|
| **De onde vem** | do borralho da Fornalha — o povo que restou quando a forja deixou de precisar de mãos |
| **O que quer** | servir a forja: alimentá-la, vigiá-la, morrer perto dela |
| **Porque está neste bioma** | **Fornalha**: nasceram do borralho dela; não há Borralheiros noutro sítio — a única raça que não viaja *(a excepção que confirma a lei do §7 do [`46`](46-coerencia-bioma-raca-item.md): quem vive DE um sítio não aparece vestido por outro)* |
| **Como trata as outras raças** | vende lâminas de obsidiana aos orcs do fogo; foge de tudo o que traga água ou gelo |
| **O que faz com os mortos** | devolve-os à forja — todo o Borralheiro volta ao lume de onde saiu |
| **Como se veste** | avental de couro curtido e placas de obsidiana; a pele, cinza-brasa, já é meio armadura |
| **Como luta** | **pesado** com elemento — martelos-lâmina de obsidiana ainda quentes; onde bate, fica brasa uns segundos *(área pequena, honesta: vê-se no chão)* |
| **Uma coisa que ninguém sabe** | a forja arde sozinha há cem anos. Não precisa deles — e eles alimentam-na na mesma, porque precisam de acreditar que servem |
| **Descrição visual** | humanoide atarracado de pele cinza com fendas incandescentes, avental de couro, martelo-lâmina de obsidiana ao ombro |
| **Fatia 1?** | ⬜ |

## 10. Submersos `[FABLE]` — nova

| | |
|---|---|
| **De onde vem** | da Cidade Afogada — os habitantes que a água guardou quando subiu |
| **O que quer** | levar para baixo tudo o que faz barulho. Os sinos ensinaram-lhes que o som é a coisa mais valiosa que há |
| **Porque está neste bioma** | **Cidade**: a casa · **Costa**: a maré traz alguns, e devolve-os |
| **Como trata as outras raças** | não distingue vivos de coisas: o que soa, leva-se; rouba ovos às Ventaneiras — dentro há um bater, e um bater é um som |
| **O que faz com os mortos** | senta-os nas casas de onde eram. **A Cidade continua habitada** — é isso que se vê pelas janelas debaixo de água |
| **Como se veste** | prata escurecida e algas; a prata afogada é deles por direito de morada |
| **Como luta** | **rápido dentro de água, lento fora** — a mesma criatura é duas lutas, conforme o terreno *(a variante de bioma do [`46`](46-coerencia-bioma-raca-item.md) §7 dentro de uma raça só)* |
| **Uma coisa que ninguém sabe** | ainda pagam impostos: todos os ciclos deixam prata à porta de uma casa vazia. Ninguém sabe de quem era a casa |
| **Descrição visual** | humanoide magro cinza-esverdeado de olhos brancos sem pupila, coberto de algas, jóias de prata escurecida ao pescoço |
| **Fatia 1?** | ⬜ |

## 11. Penitentes `[FABLE]` — nova

| | |
|---|---|
| **De onde vem** | peregrinos que vieram rezar ao Santuário e nunca mais saíram |
| **O que quer** | que a luz olhe outra vez para eles — deram os olhos por isso, dizem |
| **Porque está neste bioma** | **Santuário**: a casa; não saem — lá fora a luz não responde |
| **Como trata as outras raças** | **fala primeiro**: tenta converter quem entra, e o ataque só vem depois da recusa *(o único primeiro-contacto não-hostil do bestiário — e o aviso é a própria conversa)* |
| **O que faz com os mortos** | cobre-os de cera e acende-os. **As milhares de velas do Santuário são os mortos dele** |
| **Como se veste** | hábito branco com ouro baço, venda dourada sobre os olhos |
| **Como luta** | **grupo com cantor** — o círculo ataca enquanto um entoa (reforça os outros; primeiro alvo certo é o cantor), e a luz do bioma cega nas zonas marcadas |
| **Uma coisa que ninguém sabe** | debaixo das vendas não há cicatrizes. Nasceram assim — todos |
| **Descrição visual** | figura em hábito branco e ouro, venda dourada, pele com brilho de cera, círio erguido |
| **Fatia 1?** | ⬜ |

## 12. Sem-Rosto `[FABLE]` — nova

| | |
|---|---|
| **De onde vem** | ninguém sabe — já lá estavam quando a Raiz foi aberta |
| **O que quer** | empilhar pedra contra a porta de onde a bruma sai. Há cem anos, sem parar — **e a pilha nunca cresce** |
| **Porque está neste bioma** | **Raiz**: a casa, se é que "casa" é a palavra; talvez sejam a razão de tudo o resto |
| **Como trata as outras raças** | não reage a nada que não se aproxime da porta; os élites que descem à Raiz desaparecem |
| **O que faz com os mortos** | não se encontram Sem-Rosto mortos. Nunca *(→WP6: não largam nada do corpo — o espólio da Raiz vem do que os outros lá deixaram)* |
| **Como se veste** | placas de pedra negra amarradas com raiz — não se sabe onde acaba a roupa |
| **Como luta** | **pesado** de longo alcance, e **em silêncio**: no bioma do escuro absoluto, o único som que fazem é o do ataque a começar. A telegrafia dos 0,50 s ([`38`](38-ataques-e-honestidade.md)) mantém som **e** sinal visual equivalente ([`62`](62-acessibilidade-auditiva.md)); silêncio atmosférico nunca esconde o golpe |
| **Uma coisa que ninguém sabe** | têm rosto, debaixo das placas. É igual ao teu |
| **Descrição visual** | silhueta alta de placas de pedra negra sem cabeça visível, bruma pálida a escapar das juntas |
| **Fatia 1?** | ⬜ |

---

## 13. O quadro-resumo, e o laço fechado

| Raça | Papel ([`38`](38-ataques-e-honestidade.md) §6) | Biomas | Fatia 1? |
|---|---|---|---|
| Orcs | rápido + pesado | Brumal · Costa · Fornalha | ✅ |
| Goblins | grupo | Brumal · Selva · Raizama | ⬜ |
| Kobolds | armadilha (mecânica, escondida — o sino avisa) | Fojo · Selva · Fulgor | ⬜ |
| Esqueletos | rápido | Campas · Santuário · Raiz | ⬜ |
| Zumbis | pesado (resiste a físico) | Campas · Cidade | ⬜ |
| Minotauros | pesado | Fulgor · Cimeira · Fojo | ⬜ |
| Tecelões | armadilha (orgânica, à vista — prende) | Raizama · Selva | ⬜ |
| Ventaneiras | distância (o grito anuncia) | Cimeira · Costa | ⬜ |
| Borralheiros | pesado (deixa brasa) | Fornalha | ⬜ |
| Submersos | rápido na água, lento fora | Cidade · Costa | ⬜ |
| Penitentes | grupo com cantor | Santuário | ⬜ |
| Sem-Rosto | pesado (silêncio) | Raiz | ⬜ |
| *(mímico — praga, não raça)* | armadilha (respira) | Fojo · Costa | ⬜ |

**Cada bioma fica com ≥ 3 papéis diferentes** entre dominante, secundárias e o chefe âncora — verificado ficha a ficha contra o [`49`](49-biomas.md) §4. E nenhuma raça vive em mais de 3 biomas (o travão do [`46`](46-coerencia-bioma-raca-item.md) §7, agora testado no motor).

**Os dois "armadilha" e os três "pesado" não se repetem:** kobold esconde e o sino avisa; Tecelão mostra e prende. Zumbi resiste, Minotauro empurra, Borralheiro deixa brasa, Sem-Rosto cala — **a variante tem de mudar como se luta, não a cor** ([`46`](46-coerencia-bioma-raca-item.md) §7), e é aqui que isso se cumpre ou se apanha.

---

## 14. O que fecha, o que abre, o que entrega

**Fecha:** as 24 fichas do [`46`](46-coerencia-bioma-raca-item.md) §9 — **o motor de produção está completo.** A partir daqui, cada descrição de item é uma intersecção de duas fichas que existem.

**Abre:**

| Pergunta | Para |
|---|---|
| ~~As fichas de inimigo (raça × bioma × camada, ~30–36) com ataques e baralhos~~ | ✅ [`67`](67-catalogo-do-bestiario.md): 33 tipos, 100 ataques comuns e 33 baralhos |
| Que peças de armadura cada raça larga (a decisão da armadura por peças) | volta 5, com a volta 3 |
| O goblin que não luta, a teia que ninguém teceu, a casa dos impostos — viram segredos de zona | volta 9 (WP8) |
| O Ceifador: senhor dos esqueletos das Campas — a ficha de subchefe dele | volta 7 (WP7) |

**Entrega já:**

| Para | O quê |
|---|---|
| **volta 3 (armas/armaduras)** | quem faz e quem usa cada material: orcs trabalham ferro e obsidiana, Tecelões dão seda, Submersos guardam prata — nenhum item nasce órfão |
| **volta 5 (bestiário)** | 13 entradas em `races.json` prontas a virar fichas de combate |
| **volta 6 (descrições)** | as 12 × 8 linhas que fazem as descrições escreverem-se "sozinhas" |
| **Claude (imagens)** | 6 `descrição visual` de raças novas → [`art/MANIFESTO.md`](../art/MANIFESTO.md) |

## Ligações

[`46-coerencia-bioma-raca-item.md`](46-coerencia-bioma-raca-item.md) · [`49-biomas.md`](49-biomas.md) · [`04-inimigos-chefes.md`](04-inimigos-chefes.md) · [`15-inimigos.md`](15-inimigos.md) · [`38-ataques-e-honestidade.md`](38-ataques-e-honestidade.md) · [`29-perspectiva.md`](29-perspectiva.md) · [`game/data/races.json`](../game/data/races.json)
