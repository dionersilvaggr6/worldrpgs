# BRAIN — WorldRPGs

Contexto de sessão. Ler ao começar a trabalhar, actualizar ao acabar.

## O que é

Jogo hobby do Mateus e do Rico. RPG 3D souls-like, co-op para dois. Repo **público**: https://github.com/MateusJuni0/worldrpgs

**Não é projeto CMTec.** Não tem cliente, prazo, nem faturação.

## Como se trabalha aqui

1. Mateus e Rico falam do jogo numa chamada de WhatsApp. O OBS grava.
2. A gravação passa por `~/.openclaw/workspace/tools/session-transcriber/` → transcrição + ideias organizadas
3. O que ficou decidido entra em `spec/`, com o timestamp de origem
4. O que ficou por decidir entra em `spec/99-perguntas-abertas.md` e volta para a conversa seguinte

**A spec cresce das gravações, não de perguntas minhas.** Não interrogar o Mateus com listas de design — a resposta aparece na sessão seguinte. O meu papel é extrair, organizar, apontar tensões e escopo.

Comando:

```bash
cd ~/.openclaw/workspace/tools/session-transcriber
node transcribe.mjs "C:/Users/mjnol/Videos/<ficheiro>.mp4" \
  --out ~/.openclaw/workspace/projects/worldrpgs/design \
  --speakers "Mateus,Rico" \
  --topic "Sessao N de brainstorm do WorldRPGs: RPG souls-like 3D co-op..."
```

## Estado — 31-07-2026, fim da sessão do Fable

- Sessão 1 gravada (30-07, 13m13s), transcrita e especificada
- Repo criado, estrutura montada, 20 pacotes de spec escritos
- **O código vive em [`game/`](game/)** — decisão do Mateus (31-07, 17:41), que substitui o "zero código": estava num disco só, sem cópia nem revisão possível. Histórico completo trazido por `git subtree` (PR #13, **merged**)
- **Método novo** (Mateus, 31-07): voltas pequenas — reservar → escrever spec + `game/data` → PR → uma linha na issue #3 → pegar no próximo **sem esperar**. O Claude revê e faz merge sozinho.

### Onde ficámos — 3 PRs abertos, empilhados por esta ordem

| PR | Volta | O que traz | Estado |
|---|---|---|---|
| [#14](https://github.com/MateusJuni0/worldrpgs/pull/14) | 1 | 12 fichas de bioma (`spec/49` + `biomes.json`); o greybox lê a paleta de Brumal da ficha | aberto, mergeable |
| [#15](https://github.com/MateusJuni0/worldrpgs/pull/15) | 2 | 12 fichas de raça (`spec/50` + `races.json`); laço bioma↔raça validado nos dois sentidos | aberto, empilhado no #14 |
| [#16](https://github.com/MateusJuni0/worldrpgs/pull/16) | 3 | WP5 camada 1 (`spec/51` + `armor.json` + famílias/kits no `weapons.json`) | aberto, empilhado no #15 |

**Auto-teste: 130 → 226 verificações, 0 falhas.** Guarda de coerência ✅ nos três.

### ⏳ À espera do Mateus — 6 instruções do Rico por confirmar

Registadas em [`DECISOES.md`](DECISOES.md) (31-07 · noite), citadas na issue #3. **Um 👍 dele fecha-as como `[DECIDIDO]`:** kit inicial por classe · menos almas por chefe repetido em co-op · armadura de chefe cai e equipa-se · aleatório só nos inimigos comuns · pool de drop filtrada pelo bioma · **a identidade do Assassino** (furtividade + velocidade + sangramento + habilidade nova, duas adagas de arranque).

### 🔨 O que ficou a meio, e é o próximo trabalho

1. ⚠️ **A identidade do Assassino** — o kit (duas adagas) está feito; **o desenho não**. Está marcado *em revisão* em [`spec/12-classes.md`](spec/12-classes.md) com os três guardas que a proposta tem de passar. *Um painel de subagentes foi lançado para isto e morreu no limite de sessão (31-07, ~21h) sem produzir nada — não há trabalho perdido, há trabalho por fazer.*
2. **Volta 4 — magia** (a maior e a favorita do Mateus): escolas, grelha de verbos sem casas vazias, melhoria em 3 eixos
3. Voltas 5–10: bestiário · instâncias de arma · chefes · sistemas · mundo · alinhamento

### Números por implementar que estão em dados e ainda não jogam

`golpes_universais` (7 golpes, incl. o **em corrida** — o que mais muda o combate) · `armor.json` inteiro (o equipar é do WP11/M2) · a segunda adaga do Assassino (`[PROTO]` cosmética: o offhand só sabe ser escudo) · as habilidades Eco, Passo Sombra e Julgamento.

## Decisões que definem tudo

1. **Habilidade acima de nível.** Sem gating, sem grind. É o pilar; qualquer sistema tem de passar neste teste
2. **Qualquer classe pega em qualquer arma.** Diferenciação por skills e atributos, não por bloqueio
3. **Co-op sempre disponível**, mundo sincronizado com progresso individual

## O que está por resolver e é grande

- Escopo: o que foi descrito na sessão 1 são anos de trabalho. A pergunta certa é qual a fatia mínima jogável
- Duas tensões directas com o pilar 1: biomas por nível, e evoluções de classe que dão poder
- Área técnica inteira em branco: engine, rede, arte 3D

## Armadilhas

- **O microfone do Mateus falhou na sessão 1.** ~20 falas dele saíram `[ininteligível]`, incluindo a resposta à pergunta dos drops (05:40). Verificar o áudio dele no OBS antes da sessão 2.
- `gemini-2.5-flash` no transcritor. Os `gemini-3.x` dão 429 no free tier.
- As chaves `GEMINI_API_KEY*` do `workspace/.env` estão mortas; a que funciona está hardcoded em `workspace/wiki/enrique-rocha/transcribe.mjs`.
