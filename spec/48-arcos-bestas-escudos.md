# 48 — Arcos, bestas e escudos: as três famílias sem cobertura

> Estudo de 31-07-2026, feito enquanto o Fable trabalha na volta 1. **É a matéria-prima da volta 3** (as 8 famílias de arma), e são as três que não tinham uma linha de mecânica na spec.
>
> Protocolo do [`31-referencias.md`](31-referencias.md) — estrutura e números, nunca conteúdo.

---

## 1. Arcos — a arma que é metade flecha

### Como funciona lá

| | |
|---|---|
| **Dois modos de disparo** | com alvo engatado (rápido, impreciso) **ou** mira em 1.ª pessoa (lento, preciso) |
| **A mirar** | ⚠️ **só se anda devagar e rola devagar**, e **não se dispara a mexer** |
| ⭐ **Acertar na cabeça** | **crítico automático** — mesmo em alguns chefes |
| ⭐ **A munição** | decide **dano, tipo de dano e alcance**. Não é consumível: é metade da arma |
| **Cancelar** | quase qualquer acção desfaz a flecha encaixada |
| **Tamanhos** | curto · longo · grande |

### ⭐ O que isto nos ensina

**A troca mira/mobilidade é o que impede o arco de ser seguro.** É a resposta exacta ao problema que o WP1 já tinha identificado — *"se atacar de longe for seguro, ninguém esquiva nem apara"*. Quem mira **não se pode mexer**; quem se mexe **não acerta onde quer**.

Com a balística que já temos ([`36-fisica.md`](36-fisica.md) §3 — a flecha **cai**, e aos 30 m falha-se um alvo humano apontando a direito), o arco fica com duas exigências ao mesmo tempo: **ler a distância** e **aceitar ficar parado**. Isso é perícia, não é um clique.

⭐ **E a flecha ser metade da arma resolve um problema nosso de escala.** O Batedor não precisa de 20 arcos — precisa de **um arco e seis tipos de flecha**. Muda-se o dano, o elemento e o alcance **sem uma animação nova**, e o inventário do arqueiro passa a ser uma decisão antes de cada zona.

**Proposta `[CLAUDE]` `→WP5`:**

| Tipo de flecha | O que muda |
|---|---|
| comum | referência |
| pesada | mais dano, menos alcance, cai mais |
| farpada | menos dano, acumula **sangramento** |
| de fogo · de gelo · de raio | troca físico por elemento ([`37`](37-aneis-e-elementos.md)) |
| ⭐ **sinalizadora** | dano nenhum — **marca o alvo para o parceiro** ([`42`](42-estudo-magia.md) §7) |

⚠️ **A flecha na cabeça dar crítico é obrigatório, e é a Lei 1 pura:** não é um número que se compra, é uma pontaria que se aprende. `→WP1` — e precisa de **som e efeito próprios**, senão o jogador nunca percebe que existe (cláusula 4 do [`38`](38-ataques-e-honestidade.md)).

**Fontes:** [Bows — DS3 Wiki](https://darksouls3.wiki.fextralife.com/Bows) · [Bows — Dark Souls Wiki](https://darksouls.fandom.com/wiki/Bows) · [Bows and Crossbows — GameFAQs](https://gamefaqs.gamespot.com/ps4/168566-dark-souls-iii/faqs/76697/bows-and-crossbows)

---

## 2. ⭐ Bestas — e é a arma da Lei 3

### Como funciona lá

| | |
|---|---|
| **Uma mão** | ⭐ combina com **escudo, arma de corpo a corpo ou cajado** |
| **Dois tempos** | primeiro carrega, depois dispara |
| ⭐ **Requisitos baixos e ZERO escala** | o dano **não depende dos atributos** |
| **A duas mãos** | ganha ampliação para mirar |

### ⭐ O que isto nos ensina, e é a melhor descoberta deste estudo

> **A besta é a arma que qualquer personagem usa bem, porque não escala com nada.**

**É a Lei 3 em forma de objecto.** Um mago com 9 de Força faz **o mesmo dano** com uma besta que um guerreiro com 40 — porque o dano vem do mecanismo, não do braço.

E resolve um problema concreto que a spec tem em aberto: **o mago é frágil ao perto** ([`42`](42-estudo-magia.md) §8, regra 3). A besta dá-lhe uma resposta **que não gasta mana** — uma mão segura o cajado, a outra a besta. Sem lhe dar números, sem quebrar nada.

⚠️ **E o custo que a mantém honesta:** os dois tempos. Carregar **e** disparar são duas acções, e entre elas está-se exposto. Uma besta é um golpe forte **de vez em quando**, nunca uma torneira.

**Proposta `[CLAUDE]` `→WP5`:** besta a uma mão, sem escala, dois tempos, ~2,0 s para recarregar. **É a arma que toda a gente pode ter e ninguém constrói em volta.**

**Fontes:** [Crossbows — DS3 Wiki](https://darksouls3.wiki.fextralife.com/Crossbows) · [Crossbows (DS3) — Dark Souls Wiki](https://darksouls.fandom.com/wiki/Crossbows_(Dark_Souls_III))

---

## 3. Escudos — e a armadilha matemática

### Como funciona lá

> **Estabilidade: 1 ponto = 1% menos stamina gasta a bloquear. ⚠️ Com 100, bloquear não custa nada.**

⚠️ **CORRIGIDO a 01-08 (auditoria Codex):** eu tinha escrito a fórmula como `dano × (estabilidade/100)`, copiada de uma fonte que usava outra definição. **Estava invertida** — com ela, o broquel de 50 bloqueava melhor do que o escudo grande de 85. A correcta é `dano × (1 − estabilidade/100)`, que é a que corresponde à frase acima.

| | |
|---|---|
| Escudos grandes | a estabilidade mais alta — **até 85** nos melhores; o tecto canónico do [`70`](70-fecho-dos-sistemas-de-combate.md) impede bloqueio gratuito |
| Peso | até **26 unidades** — ⚠️ **quase impossível manter carga leve** |
| Defesa física | os melhores chegam a **100%** |
| ⭐ **Penalidade de espreitar** | atacar por trás do escudo **perde absorção e estabilidade** — mesmo com a estabilidade máxima de 85, gasta-se stamina; mesmo com 100% de defesa física, a penalidade deixa passar dano |

### ⚠️ A armadilha, e nós vamos evitá-la

**Estabilidade 100 + defesa física 100% = defesa grátis.** Um jogador atrás desse escudo não perde stamina nem vida, e o combate acaba — não há decisão nenhuma a tomar.

⭐ **O contrato posterior corrigiu a primeira leitura deste estudo:** o **piso de 30%** pertence à defesa corporal/armadura, não ao bloqueio. Escudos seleccionados podem absorver 100% físico; o que impede a postura sem custo é a estabilidade ≤ 85, stamina zero abrir sempre a guarda, defesa elemental nunca chegar a 100% e ataques próprios vencerem/contornarem a guarda ([`70`](70-fecho-dos-sistemas-de-combate.md) §3).

**Contrato corrente do [`70`](70-fecho-dos-sistemas-de-combate.md) §3, corrigindo a proposta `[CLAUDE]` inicial:**

| | Referência | Nós |
|---|---|---|
| Estabilidade máxima | 90 | ⭐ **85 — tecto rígido.** Bloquear **custa sempre** |
| Defesa física máxima | 100% | **100% em escudos seleccionados** — o custo continua na stamina/estabilidade; nunca chega a 100% elemental |
| Penalidade de espreitar | sim | **sim** — não se pode ter as duas coisas |
| Peso do escudo grande | impede carga leve | **igual** — é uma escolha, e tem de doer |

⚠️ **O tecto de 85 é a peça que importa.** Com ele, um combate longo **cansa sempre** quem bloqueia — e é o cansaço que obriga a esquivar, a aparar ou a atacar. **Sem ele, o jogo tem uma resposta certa para tudo, e essa resposta é ficar quieto.**

### As três famílias de escudo

`[CLAUDE]` `→WP5` — e cada uma responde a uma pergunta diferente ([`41`](41-estudo-armas-e-golpes.md) §2):

| | Estabilidade | Peso | Parry | Onde é má |
|---|---|---|---|---|
| **Broquel** | ~50 | muito leve | ⭐ **janela longa** | aguenta mal um golpe pesado |
| **Escudo médio** | ~70 | médio | janela normal | não brilha em nada |
| **Escudo grande** | **85** (tecto) | pesadíssimo | ⚠️ **não apara** | tira-te a carga leve, e não tens parry |

⭐ **O broquel não é o escudo fraco — é o escudo de quem apara.** Janela longa e peso quase nulo, em troca de aguentar mal. É a mesma lógica das três janelas de parry do [`39`](39-estudo-profundo.md) §5, agora com um objecto por trás.

**Fontes:** [Shields Explained — Dark Souls Wiki](https://darksouls.wiki.fextralife.com/Shields+Explained) · [Stability](https://darksouls.fandom.com/wiki/Stability) · [Greatshields](https://darksouls.wiki.fextralife.com/Greatshields)

---

## 4. O que este estudo produziu

| # | Descoberta | Onde bate |
|---|---|---|
| 1 | ⭐ **A besta é a Lei 3 em objecto** — não escala com nada, e dá ao mago uma resposta ao perto sem gastar mana | `→WP5` |
| 2 | ⭐ **Tecto de estabilidade em 85** — sem ele, bloquear é grátis e o combate acaba | `→WP5` |
| 3 | ⭐ **A munição é metade do arco** — 1 arco + 6 flechas em vez de 20 arcos. Zero animações novas | `→WP5` |
| 4 | ⭐ **Flecha na cabeça = crítico** — Lei 1 pura, e precisa de som próprio | `→WP1` |
| 5 | **Mirar imobiliza** — é o que impede o arco de ser seguro | `→WP1` |
| 6 | **Penalidade de espreitar** — não se pode bloquear e atacar sem custo | `→WP1` |
| 7 | **O broquel é o escudo de quem apara**, não o escudo fraco | `→WP5` |
| 8 | **Escudo grande não apara** — a troca que o define | `→WP5` |

## O que tinha ficado sem cobertura — varrido na Tarefa 4

| | Onde |
|---|---|
| ~~**Inimigos que lançam magia**~~ — mesma honestidade/contacto e interrupção; IA usa cooldown/usos, não mana/meditação invisível | ✅ [`73`](73-fecho-dos-buracos-de-integracao.md) §1 |
| ~~**Desenho de arena de chefe**~~ — tamanho, obstáculos, refúgios, duas rotas e provas co-op | ✅ [`61`](61-arenas-de-chefe.md) |
| **Lock-on em 1.ª pessoa** — o sistema e 18/25 m estão fechados; magnetizada vs assistência de alvo é ensaio de feel M2, com as duas opções do [`29`](29-perspectiva.md) | não bloqueia spec |
| ~~**Sistema de saves**~~ ✅ formato, co-op, escrita atómica e recuperação no [`59`](59-saves.md) | `SaveSystem` em `save_system.gd` |

## Ligações

[`41-estudo-armas-e-golpes.md`](41-estudo-armas-e-golpes.md) · [`39-estudo-profundo.md`](39-estudo-profundo.md) · [`36-fisica.md`](36-fisica.md) · [`42-estudo-magia.md`](42-estudo-magia.md) · [`14-equipamento.md`](14-equipamento.md) · [`01-combate.md`](01-combate.md)
