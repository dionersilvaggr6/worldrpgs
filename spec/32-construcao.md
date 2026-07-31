# 32 — A fase de construção

`[DECIDIDO]` (Mateus, 31-07-2026) — **a spec está escrita; começa-se a construir.** O Fable escreve o código; o Mateus e o Claude encaminham e geram os assets.

Este documento é curto de propósito. **O plano de construção é o [`24-plano.md`](24-plano.md) (WP15)** — M0 a M7. Isto são só as regras de como se trabalha agora.

## A regra que manda em tudo

> **A spec manda. Se o código e a spec discordarem, muda-se a spec primeiro — no mesmo PR.**

Não é burocracia. É o que impede o projeto de voltar ao ponto de partida: um jogo que não corresponde ao que está escrito é um jogo sem spec, e passados dois meses ninguém sabe porque é que um número é aquele.

Na prática, ao construir vais descobrir que alguns números não funcionam. **Isso é esperado e é bom** — foi para isso que o WP1 escreveu *"o que o protótipo desmentir, volta aqui e muda-se neste documento primeiro"*. O que não pode acontecer é o código dizer 0,45 s e a spec continuar a dizer 0,60 s.

## O que muda no fluxo

| | Antes | Agora |
|---|---|---|
| Reservar em [`../COORDENACAO.md`](../COORDENACAO.md) | por pacote de spec | **por marco** (M0, M1, …) ou por sistema |
| Um PR contém | um documento | **código + a mudança de spec que ele obriga** |
| O guarda de coerência | valida links e etiquetas | o mesmo, mais o que se lhe acrescentar para código |

## Regras de código

Não há aqui um manual de estilo — a engine e a linguagem decidem-se no [`23-tecnico.md`](23-tecnico.md) (WP14). Cinco regras que valem seja qual for:

1. **Os números do jogo vivem em dados, não em código.** Frames, custos de stamina, vida, dano — em ficheiros que se editam sem recompilar. Está no WP14 e é o que torna o afinar do WP15B possível.
2. **Cada número tem um comentário com a sua origem na spec.** `// 25 stamina — 01-combate.md §Esquiva`. Quando alguém quiser mudar, sabe onde está a razão.
3. **O que se mede vem primeiro.** O marco 1 já provou o princípio: primeiro mede-se, depois constrói-se por cima. Ferramentas de afinação (consola, sobreposição de hitboxes, frametime no ecrã) entram cedo, não no fim.
4. **Nada de assets com licença incompatível**, nem em `_local/`. As regras do [`22-assets.md`](22-assets.md) valem inteiras, e o repositório continua **público**.
5. **Segredos nunca no repositório.** Se a rede vier a precisar de chaves, ficam fora e o `.gitignore` cobre-as.

## O que continua igual

- **As quatro leis.** Sobretudo a 1 e a 4 — habilidade acima de nível, e o desempenho na máquina do Rico como tecto. Código que quebre uma delas não entra, por muito elegante que seja.
- **As etiquetas.** `[DECIDIDO]` continua a ser dos donos. Uma constante de código não vira decisão só por estar escrita.
- **A reserva antes de começar**, e quem faz merge actualiza a tabela.
- **Inspira-te na estrutura, não copies o conteúdo** ([`31-referencias.md`](31-referencias.md)) — vale para código também: estudar como um sistema se organiza, sim; copiar código de outro jogo, não.

## Assets: quem faz o quê

- **O Mateus e o Claude geram as imagens** — 32 já feitas ([`../art/MANIFESTO.md`](../art/MANIFESTO.md)), pelo Gemini via Higgsfield. Se precisares de um asset que não existe, **acrescenta a linha ao manifesto** com ID e caminho canónico e pede — não esperes nem improvises.
- **Modelos 3D, animações e som** vêm das fontes do [`22-assets.md`](22-assets.md). A arte de conceito já gerada é o árbitro: um modelo que destoe dela não entra.

## O que ainda está por decidir e vai bater no código

Nenhuma trava o M0, mas todas chegam cedo:

| | Onde |
|---|---|
| ~~Morte · cura · armadura~~ | **fecharam no [`33-morte-e-almas.md`](33-morte-e-almas.md)** (perguntas 10, 7 e 14) — o M2 herda almas, frascos e peças |
| Drops em co-op · escala de chefe a dois | perguntas 5 e 6 — o M3 precisa |
| ~~6 zonas ou 10+~~ | **decidido 10+; o WP8 cresceu para 10** ([`17-mundo.md`](17-mundo.md)) |
| Lock-on em primeira pessoa | [`29-perspectiva.md`](29-perspectiva.md) — o M2 precisa |

**Quando bateres numa destas, não adivinhes:** escreve a pergunta na issue de coordenação e segue para outra coisa. São decisões dos donos, e são baratas de responder e caras de refazer.
