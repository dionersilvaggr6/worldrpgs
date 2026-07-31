# 99 — Perguntas em aberto

Tudo o que falta decidir, por ordem de urgência. Serve de guião para a próxima gravação: passem por esta lista e a spec cresce sozinha.

**Regra:** tudo o que ainda estiver aqui quando a construção começar é uma decisão que vocês entregaram a quem constrói, sem saber.

> **Estado a 31-07-2026:** as perguntas **0, 0b, 1, 2, 3, 4, 8 e 9 fecharam** com a aprovação do Mateus e do Rico — ficam riscadas, com a decisão por baixo, porque o raciocínio continua a valer. **Nada bloqueia nenhum pacote.** O que resta são decisões de tom e de detalhe, e cada uma diz onde é que a spec joga com provisórios até lá.

---

## 🔴 Bloqueiam tudo o resto

### 0. ~~As máquinas~~ — RESPONDIDA (31-07-2026)

As duas estão medidas. **A do Rico é a mais fraca, e é a que manda** — orçamenta-se sempre para a pior das duas.

| | Rico ⚠️ *(o alvo)* | Mateus |
|---|---|---|
| Processador | Intel Core i5-1334U (13.ª ger.) | Intel Core i7-1255U (12.ª ger.), 10 núcleos / 12 threads |
| Gráficos | Intel Iris Xe integrados | Intel Iris Xe integrados |
| RAM | **8 GB** — 2×4 GB, canal duplo | 16 GB — 2×8 GB @ 3200 MT/s, canal duplo |
| Disco | SSD NVMe 256 GB | SSD NVMe 512 GB |
| Ecrã | 1920×1080 @ 60 Hz | 1920×1080 @ 60 Hz |
| Sistema | Windows 11 Home 64 bits | Windows 11 Home 64 bits |
| Comando | nenhum ligado — teclado e rato | nenhum ligado — teclado e rato |

⚠️ **O orçamento aponta aos 8 GB, não aos 16.** Descontando o sistema e a memória que os gráficos integrados tiram — partilham a RAM, não têm memória própria — sobram na ordem de **3 a 4 GB** para o jogo na máquina do Rico. É um tecto apertado, e é o real.

Do lado bom, três coisas: as duas têm **canal duplo**, que é o melhor cenário para gráficos integrados, porque a largura de banda da memória é o estrangulamento principal; as duas têm **SSD NVMe**, o que ajuda a carregar com memória curta; e as duas são **60 Hz**, o que fecha a taxa alvo em 60 fps e evita perseguir mais.

⚠️ Ambas são **chips de portátil da série U**, de baixo consumo. O problema não é o pico, é aguentar: o alvo mede-se **quente**, ao fim de vinte minutos, não ao primeiro. E não há comando ligado em nenhuma — o esquema de controlos parte de teclado e rato.

> Os relatórios `dxdiag` completos ficam **fora do repositório**: trazem nome de máquina e de utilizador, e isto é público. O que interessa está nesta tabela.

→ [`09-tecnico.md`](09-tecnico.md)

### 0b. ~~O 3D aguenta-se neste hardware?~~ ✅ DECIDIDA — caminho A
**Medido no protótipo local (31-07-2026), na máquina mais fraca:** 60 fps cravados no cenário da fatia com vsync; 416 fps médios em greybox ao fim de **20 minutos quentes, sem degradação térmica**; renderer Mobile escolhido. Ressalvas: sem animação de esqueleto ainda (a incógnita cara), e memória a vigiar. Os três caminhos (3D / 2.5D / 2D) ficam com dados à frente.

✅ **CARIMBADO** `[DECIDIDO]` (Mateus + Rico, 31-07-2026) — **caminho A: 3D estilizado, optimizado.** A tensão fecha-se.

⚠️ Uma ressalva que a aprovação não apaga, porque é matéria de facto e não de decisão: **a medição não está sustentada no repositório** — não há protótipo, log nem artefacto que a acompanhe, e o próprio relatório ressalva que falta a animação de esqueleto, que é a parte cara. O caminho está escolhido; a prova de que aguenta com esqueletos animados continua por fazer, e é o marco 1 do WP15 que a dá.
→ [`09-tecnico.md`](09-tecnico.md)

### 1. ~~Qual é a fatia mais pequena disto que já é divertida a dois?~~ ✅ APROVADA
A sessão 1 descreveu mundo aberto grande, 3D, ~61 chefes, 8 classes, dois sistemas de magia, montarias e co-op sincronizado. Isso é anos de trabalho para uma equipa.

A pergunta não é "cortamos o quê". É: **se só existisse uma zona, um chefe e duas classes, isso já era um jogo que vocês queriam jogar?** Se sim, é por aí que se começa e o resto cresce por cima.

**→ Proposta escrita (WP0):** [`10-fatia-1.md`](10-fatia-1.md) — 1 zona + 1 dungeon + 1 chefe, 6 classes (instrução directa do Rico), 5 armas, 3 magias, co-op desde o dia 1.

✅ **APROVADA** `[DECIDIDO]` (Mateus + Rico, 31-07-2026) — a fatia 1 é esta. É a linha que ordena todos os pacotes.
→ [`00-visao.md`](00-visao.md) · secção de risco

### 2. ~~Os biomas são patamares de dificuldade?~~ ✅ RESPONDIDA
`[DECIDIDO]` (Mateus + Rico, 31-07-2026) — **soft gating.** Mapa todo aberto; dificuldade sugerida, não exigida. Detalhe e o que obriga em [`05-mundo.md`](05-mundo.md).

O WP8 desenvolveu-o em [`17-mundo.md`](17-mundo.md): a dificuldade sobe pela curva do WP2 e pelos padrões dos inimigos, dentro dos tectos da Lei 1.
→ [`05-mundo.md`](05-mundo.md), [`00-visao.md`](00-visao.md)

### 3. ~~As evoluções de classe dão poder ou dão opções?~~ ✅ DECIDIDA — opção A
Se o mago nível 3 lança mais depressa que o nível 1, o nível está a dar vantagem — que é o que o pilar 1 recusa. O próprio Rico já apontou para o lado certo às 09:21 ("não aumentar o dano, uma magia diferente"). Falta confirmar como regra.

**→ Proposta escrita (WP3):** as duas opções lado a lado, com recomendação **A (opções)** e subida por marco em vez de nível — [`12-classes.md`](12-classes.md).

✅ **DECIDIDA** `[DECIDIDO]` (Mateus + Rico, 31-07-2026) — **opção A: as evoluções dão opções, não números**, e sobem por marco, não por nível. É a Lei 2 aplicada à progressão, e fecha a tensão com a Lei 1.
→ [`02-personagem.md`](02-personagem.md)

### 4. ~~"Mapa grande" é quanto?~~ ✅ RESPONDIDA
`[DECIDIDO]` (Mateus + Rico, 31-07-2026) — **~30 min a pé, 10+ biomas** (escala Elden Ring). A fatia 1 continua a ser Brumal sozinha; o resto cresce zona a zona. O WP8 herda três obrigações: densidade mínima por zona, estratégia de reutilização de peças, e viagem rápida. Ver [`05-mundo.md`](05-mundo.md).

✅ **Diferença acertada (realinhamento 31-07):** o WP8 **cresceu para 10 zonas + núcleo** ([`17-mundo.md`](17-mundo.md)) — 4 zonas novas com nome e gancho `[FABLE]`, ~30 min de travessia total, como decidido.
→ [`05-mundo.md`](05-mundo.md)

---

## 🟠 Decidem o que se sente a jogar

### 5. Como funcionam os drops em co-op?
O Rico levantou a pergunta às 05:36 e ficou sem resposta (o áudio do Mateus falhou). Três hipóteses: cópia para cada um, filtrado por classe, ou partilhado com negociação.

*Entretanto, a fatia 1 joga com loot instanciado provisório `[FABLE]` — [`10-fatia-1.md`](10-fatia-1.md).*

**→ Proposta escrita (WP9):** instanciado escolhido e justificado (é a leitura directa do 05:29; filtrar por classe contradiz a Lei 3; partilhado é atrito sem ganho), e o "recompensa menor" do 12:34 em números: quem ajuda no que já matou ganha 40% do XP e só materiais. Ver [`18-progressao.md`](18-progressao.md). **A resposta perdida do Mateus (05:40) tem precedência se for recuperada.**
→ [`06-itens-inventario.md`](06-itens-inventario.md)

### 6. Os chefes ficam mais duros com dois jogadores?
Nunca foi mencionado. Se não ficarem, a resposta a qualquer chefe difícil passa a ser "chamar o outro", e o pilar 1 morre.

*Entretanto, a fatia 1 joga com vida do chefe ×1,8 a dois, provisório `[FABLE]` — [`10-fatia-1.md`](10-fatia-1.md).*
→ [`07-multiplayer.md`](07-multiplayer.md)

### 7. ~~Como se recupera vida?~~ ✅ RESPONDIDA
`[DECIDIDO]` (Mateus, 31-07-2026) — **frascos, recarregados nos pontos de descanso.** Não se compram; o custo é o tempo de beber, não dinheiro. Detalhe em [`33-morte-e-almas.md`](33-morte-e-almas.md).

*(a pergunta original, para registo:)*
Frasco recarregável ao descansar, ou poções que se compram e acabam? Decide toda a tensão da exploração.

**→ Proposta escrita (WP5):** Frasco de Bruma — 3 cargas, 40% de vida por gole, 1,2 s a beber, recarrega ao descansar; ampliações escondidas no mundo em vez de stock comprável (poções finitas convidam ao farm, que a Lei 1 proíbe). Ver [`14-equipamento.md`](14-equipamento.md). Falta o sim dos dois.
→ [`06-itens-inventario.md`](06-itens-inventario.md), [`14-equipamento.md`](14-equipamento.md)

### 8. ~~O que é que "magia do bem e do mal" faz mecanicamente?~~ ✅ APROVADA
Hoje é só um nome. Pode ser o sistema mais interessante do jogo, ou decoração.

**→ Proposta escrita (WP4):** *bem = controlo sem preço; mal = ~1,5× mais forte por carga mas custa 8% dos PV por lançamento; qualquer um usa as duas; mortos-vivos temem o bem.* Detalhe e alternativa descartada em [`13-magia.md`](13-magia.md).

✅ **APROVADA** `[DECIDIDO]` (Mateus + Rico, 31-07-2026) — o preço da magia do mal é PV, à vista, sem medidor de corrupção. **A fatia 1 passa a poder usar as duas escolas.**
→ [`03-magia.md`](03-magia.md)

### 9. ~~Quantas classes no início?~~ ✅ CONFIRMADA — seis na fatia
Foram nomeadas 8. Como só jogam dois, a maior parte nunca vai ser jogada — mas todas custam trabalho.

**→ Respondida pelo Rico (30-07-2026, instrução directa): seis na fatia 1** — Guerreiro, Feiticeiro, Tanque, Assassino, Berserker, Paladino. O Batedor espera pelo arco; o Mago do mal, pela pergunta 8. Ver [`10-fatia-1.md`](10-fatia-1.md).

✅ **CONFIRMADA** `[DECIDIDO]` (Mateus + Rico, 31-07-2026) — seis classes na fatia, com o custo aceite de olhos abertos (6 habilidades + 5 conjuntos de animação).
→ [`02-personagem.md`](02-personagem.md)

### 10. ~~O que acontece quando se morre?~~ ✅ RESPONDIDA
`[DECIDIDO]` (Mateus, 31-07-2026) — **perdem-se as almas** (a moeda e a experiência ao mesmo tempo), que ficam no sítio onde se morreu; morrer outra vez antes de as apanhar perde-as de vez. Renasce-se no último ponto de descanso. **Em co-op**: ficas no mundo do parceiro e ele tem **1 minuto** para te ressuscitar, ficando **5 segundos** em cima do corpo. Detalhe em [`33-morte-e-almas.md`](33-morte-e-almas.md).

*(a pergunta original, para registo:)*
Nunca falado. É a decisão que define o tom de um souls-like: perde-se o quê, volta-se para onde, os inimigos voltam?

*Entretanto, a fatia 1 joga com renascimento na entrada, nada perdido, retry < 30 s — provisório `[FABLE]`, [`10-fatia-1.md`](10-fatia-1.md), formalizado no WP1 ([`01-combate.md`](01-combate.md), secção Morte, incluindo morte em co-op). O tom definitivo decide-se aqui.*
→ [`01-combate.md`](01-combate.md)

---

## 🟡 Precisam de resposta antes de construir

11. **Números do combate** — *ponto de partida completo escrito no WP1* `[FABLE]`: esquiva 0,60 s com 300 ms de invencibilidade, parry 133 ms, stamina 100 com custos por acção, frames das 5 armas. **Fecham-se a jogar o protótipo (marco 2)**, como sempre se disse. → [`01-combate.md`](01-combate.md)
12. **Vida e Constituição fazem o quê, cada um?** — *respondida no WP2* `[FABLE]`: Vida = PV (margem total), Constituição = defesa por golpe (dureza). E entraram Força/Destreza para os requisitos de arma que eles pediram (06:14). → [`11-formulas.md`](11-formulas.md)
13. **Hierarquia de chefes: 1+10+20+30 ou 1+30+20?** Os dois disseram versões diferentes e ficou por acertar (12:05). **→ Arrumada no WP7** ([`16-chefes.md`](16-chefes.md)): as 4 camadas ficam definidas pelo que as distingue (Ultra, subchefes, guardiões, chefes de campo); **o total fica em aberto de propósito** — conta-se quando houver mapa. A decisão continua deles. → [`04-inimigos-chefes.md`](04-inimigos-chefes.md)
14. **Existe armadura?** Não foi dita uma única vez. **→ Posta em formato de proposta no WP5** (A: sem sistema, vestes visuais + talismãs; B: 3 pesos que trocam i-frames por defesa; recomendação A pela Lei 4). Decisão dos dois. → [`14-equipamento.md`](14-equipamento.md)
15. **Estilo visual** — "realista não, mas tipo..." (10:24) ficou a meio da frase. **→ Proposta concreta no WP12** ([`21-arte-render.md`](21-arte-render.md): low-poly facetado, proporções 1:6,5, paleta de Brumal, referências Ashen/Absolver/Tunic), coerente com a frase de estilo do WP13. Caminho barato para o sim: gerar 3–4 conceitos com `art/prompts/` e escolherem. → [`05-mundo.md`](05-mundo.md)
21. **Tom, nome do jogo, idioma, e mais 4 perguntas de narrativa** — guião de gravação de ~15 min pronto em [`26-narrativa.md`](26-narrativa.md) §3.
16. **Lock-on em alvo?** — *respondida no WP1* `[FABLE]`: **sim** — engate a 18 m, quebra a 25 m, strafe, sem re-engate automático. A câmara do lock é do WP1B. → [`01-combate.md`](01-combate.md)
17. **Engine.** **→ Proposta escrita (WP14): Godot 4.x, renderer Mobile** — a única com medição real nas máquinas reais a favor (0b: 60 fps cravados); Unreal descartada pelo caminho feliz proibido pela Lei 4, Unity pelo peso do editor e risco de licença. Tabela completa em [`23-tecnico.md`](23-tecnico.md). Falta o carimbo dos dois — por baixo de números, não de palpite. → [`09-tecnico.md`](09-tecnico.md)
18. **Rede: P2P, relay ou servidor? E quem tem autoridade sobre o combate?** **→ Proposta escrita (WP10):** ligação directa com porta aberta (plano B: VPN de amigos tipo Tailscale), transporte agnóstico; **autoridade dividida** — anfitrião manda no mundo, cada jogador manda no próprio corpo (i-frames e parry avaliados localmente: entre amigos, a confiança é a compensação de latência). Ver [`19-rede.md`](19-rede.md). A escolha prática A/B é deles. → [`09-tecnico.md`](09-tecnico.md)
19. **Arte 3D: comprar, gerar ou fazer?** — *respondida em conjunto pelo WP13 + WP12*: modelos e ciclos base de packs CC0 (KayKit/Quaternius), Mixamo fora do repo, e **à mão o que é a alma** — telegrafias, parry, chefe. Fontes e licenças em [`22-assets.md`](22-assets.md); inventário de animações e orçamentos em [`21-arte-render.md`](21-arte-render.md). → [`09-tecnico.md`](09-tecnico.md)
20. **Fogo amigo em co-op?** **→ Proposta fechada no WP10: sem fogo amigo em nada** — com o círculo de agressão e arenas apertadas, feriria o co-op sem ganho de leitura; a Ruína continua a marcar o chão para o parceiro. Tom final é dos dois. → [`07-multiplayer.md`](07-multiplayer.md), [`19-rede.md`](19-rede.md)

---

## Perdido no áudio

Estas ficaram sem registo porque o microfone do Mateus falhou. Se se lembrarem, vale a pena recuperar:

| Momento | O que se perdeu |
|---|---|
| 05:40–05:41 | A resposta do Mateus sobre drops por classe — a pergunta 5 desta lista |
| 10:44–10:56 | Um bloco inteiro de fala, logo a seguir a "como será que a gente faz o mundo?" — provavelmente a resposta à pergunta 15 |
| 07:41–07:49 | Fala durante a enumeração das classes — podem ter ficado classes por registar |
| 06:17–06:18 | Reacção ao fecho da regra das armas |
