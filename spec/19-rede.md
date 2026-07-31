# 19 — Multiplayer e rede

> **WP10 · Fable** (31-07-2026). O sistema mais complexo do jogo, descrito numa frase da gravação (12:34). Contexto que muda tudo: **são dois amigos concretos, em casas diferentes, sem intenção de publicar** — anti-cheat, matchmaking e escala estão fora por decisão do briefing. A rede serve duas pessoas que confiam uma na outra, e isso simplifica as escolhas certas. Tudo `[FABLE]` salvo indicação; os provisórios do WP0 formalizam-se aqui.

## Modelo de sessão

**Convite para o mundo de um deles** (formaliza o WP0): um hospeda, o outro entra; o **mundo mostrado é o do anfitrião**; cada um pode hospedar. Entrar numa sessão: < 2 min, sem editar ficheiros (critério 1 da fatia).

*Alternativa descartada:* mundo partilhado permanente (servidor sempre ligado) — pede máquina sempre acesa que nenhum dos dois tem, e o ganho ("entro quando quiser") já existe: quem quiser jogar, hospeda e convida. A pergunta "sempre disponível quer dizer o quê?" fecha-se assim: **sempre disponível = qualquer um hospeda a qualquer momento.**

**Dois jogadores exactamente.** O briefing já o fixa (fora: multijogador acima de dois); a arquitectura assume 2 e ganha simplicidade com isso.

## Progresso individual em mundo partilhado — o 12:34 resolvido

A frase: *"Os inimigos que te aparecem pra mim, aparecem pra tu, e vice-versa, mesmo se tu já matou ou não, tu me ajuda a matar, e aí tu ganha uma recompensa menor."*

O estado divide-se em dois sacos, e cada frase da gravação cai num deles:

| Saco | O que contém | Quem guarda |
|---|---|---|
| **Personagem** (viaja contigo) | nível, almas, atributos, inventário, skills, pergaminhos, ampliações, **flags de chefes que TU mataste**, verbos recebidos | cada jogador, no seu PC |
| **Mundo** (fica na casa) | atalhos abertos, estado da zona, inimigos comuns vivos/mortos desta sessão | o anfitrião |

As consequências, uma a uma:

1. **Inimigos comuns aparecem para os dois, sempre** — renascem ao descansar (WP1), portanto "já matei" nunca os apaga do mundo. É a primeira metade do 12:34, de borla.
2. **Chefe morto para o anfitrião, vivo para o convidado:** o mundo é o do anfitrião — a arena está vazia e o portão aberto. O convidado **não** mata o Vorgar dele no mundo alheio vazio; mata-o no mundo dele (com o amigo a ajudar, papéis trocados). *Porquê:* fazer aparecer um chefe num mundo onde ele já morreu partia a coerência do espaço para o anfitrião — e a sessão seguinte com papéis trocados é exactamente o loop de co-op que eles descreveram.
3. **Chefe vivo para os dois:** matam-no juntos → **conta para os dois**, recompensa completa para os dois (verbo + almas). É a segunda metade do 12:34.
4. **Chefe que o convidado já matou no mundo dele:** ajuda na mesma, com a **recompensa reduzida do WP9** (40% das almas, só materiais; verbos nunca duplicam).
5. **Atalhos são do mundo, não do personagem:** o convidado usa os atalhos do anfitrião, mas não os leva para casa. *Porquê:* o atalho é conhecimento do espaço — levar para casa um atalho que nunca se abriu é progresso fantasma.
6. **Itens colocados** (a adaga na árvore, ampliações): instanciados (WP9) — cada personagem apanha a sua cópia, no mundo de quem for. Apanhado uma vez por personagem, para sempre.

*Teste da Lei 1:* nada aqui cria caminho de poder que não seja jogar — o mundo alheio dá no máximo 40% das almas e materiais. ✅

## Transporte — como as duas casas se ligam

| Caminho | Custo | Configuração | Risco |
|---|---|---|---|
| **A — Ligação directa (ENet/UDP) + porta aberta no router do anfitrião** | 0 € | 10 min, uma vez, em cada casa que hospeda | routers CGNAT não deixam (operadora decide) |
| **B — Ligação directa sobre VPN de amigos (Tailscale/ZeroTier, plano grátis)** | 0 € | instalar app, aceitar convite — **funciona atrás de qualquer NAT** | dependência de um serviço externo grátis |
| C — Relay comercial (Steam/Epic/Photon) | 0–100 € + integração | SDK na engine | prende a plataforma; Steam pede registo pago; overkill para 2 pessoas |
| D — Servidor dedicado próprio | ~5 €/mês | administrar | trabalho permanente para resolver um problema que A/B já resolvem |

**Recomendação: A com B como plano B** — tentam a porta aberta; se a operadora tiver CGNAT, Tailscale resolve em 10 minutos e o jogo nem dá conta (vê um IP normal). *Alternativa descartada como padrão:* C/D — infra-estrutura de produto para um jogo de duas pessoas. O código de rede escreve-se **agnóstico ao transporte** (liga a um endereço; de onde ele vem não é problema do jogo), portanto migrar para relay mais tarde não parte nada. **Decidem: Mateus + Rico** (é a única decisão daqui que lhes pede acção no router).

## Autoridade — a decisão que ficava cara se fosse adiada

**Anfitrião autoritativo sobre o mundo; cada jogador autoritativo sobre o próprio corpo.**

| Quem decide | O quê |
|---|---|
| **Anfitrião** | IA e posição dos inimigos, dano que os inimigos **sofrem**, vida/postura/fases dos chefes, portas, loot do mundo |
| **Cada cliente (o próprio)** | a sua posição, os seus i-frames, o seu parry, a sua stamina, o seu frasco — **se um golpe me acertou, decido eu, com o meu relógio** |

- O convidado anuncia "esquivei aos 0,08–0,38" e o anfitrião **acredita** — entre amigos, a confiança é a compensação de latência mais barata que existe. O golpe do inimigo que no ecrã do convidado caiu dentro dos i-frames **não acerta**, mesmo que no anfitrião parecesse acertar.
- **Parry do convidado:** avaliado localmente contra a posição interpolada do inimigo; o anfitrião recebe "parry válido no ataque X" e aplica a Postura Quebrada. Janela de tolerância: aceita-se o relatório se chegar ≤ 150 ms depois do frame activo do ataque.
- *Porquê:* num souls-like, a esquiva avaliada do outro lado da linha **parece batota contra o jogador** — com 60–100 ms de ida-e-volta, i-frames de 300 ms viram 200 e o convidado morre "dentro" da esquiva. Isso é a Lei 1 quebrada pela infra-estrutura. *Alternativa descartada:* anfitrião decide tudo (autoridade clássica de servidor) — correcta contra batoteiros, injusta para o amigo; este jogo não tem batoteiros por definição de projeto.

**Números de rede:** simulação a 60 Hz local; instantâneos do anfitrião a **20 Hz** com interpolação de 100 ms nos ecrãs; eventos (golpes, parries, aggro) fiáveis e imediatos; alvo de largura de banda **< 30 kbps** por sentido (2 jogadores + ≤ 5 inimigos — o tecto de cena do WP12 também é tecto de rede). Latência alvo entre casas: < 80 ms; acima de 150 ms sustentados, aviso discreto no ecrã (WP11) — o jogo não esconde a linha má, porque esconder faria a injustiça parecer do jogo.

## Fogo amigo — pergunta 20, proposta fechada aqui

**Sem fogo amigo, em nada:** nem magia (provisório do WP4, agora formal), nem corpo a corpo. A Ruína marca o chão para o parceiro ler (WP4/WP12), mas não o fere.

*Porquê:* com o tecto de 2 atacantes do círculo de agressão (WP6) e arenas apertadas (a Toca), fogo amigo activo tornaria o machadão do Berserker um risco para o parceiro em cada varrido — fricção constante entre amigos, sem ganho de leitura. *Alternativa descartada:* fogo amigo "realista" — realismo não é pilar; e o griefing não é ameaça entre duas pessoas que partilham sofá espiritual. **Decisão de tom final: deles** (fica na pergunta 20 até o disserem).

## Quedas e saídas a meio

| Situação | O que acontece |
|---|---|
| Convidado desliga (crash, rage, jantar) | o mundo continua; inimigos em combate com ele largam o alvo; num chefe, a vida do chefe **reescala de ×1,8 para ×1,0 proporcionalmente ao que falta** (60% restantes a ×1,8 → 60% a ×1,0) — o anfitrião não herda uma luta de dois sozinho |
| Convidado volta | re-entra no ponto de descanso da zona do anfitrião, nunca dentro da arena |
| **Um jogador morre** (sem desligar) | **fica no mundo como corpo caído, 1 minuto** — regras em [`33-morte-e-almas.md`](33-morte-e-almas.md) §4; a ressurreição abaixo |
| Anfitrião desliga | a sessão acaba (o mundo era dele); o convidado volta ao seu mundo, no seu ponto de descanso, **com tudo o que ganhou** — XP, itens e flags viajam no personagem, nada se perde |
| Linha cai 5 s | pausa de sincronização até 10 s (inimigos congelam para o convidado); acima disso, trata-se como desligar |

*Teste de justiça:* nenhuma queda de rede mata um personagem — a morte é sempre de um golpe lido mal, nunca de um router. É a Lei 4 da rede: instabilidade não é feia, é injusta. ✅

## Ressurreição em co-op — os detalhes que o 33 delegou aqui

`[DECIDIDO]` (Mateus, 31-07): corpo no chão 1 min; o parceiro canaliza **5–7 s em cima do corpo**; ressuscitado a tempo não perde nada; itens largados ficam no chão. **Substitui** o provisório deste documento e do WP1 ("morto até o combate acabar"). Os três detalhes delegados, fechados `[FABLE]`:

| Detalhe | Decisão | Porquê |
|---|---|---|
| **Interrupção** | **dano cancela a canalização** (o progresso mantém-se: retomar continua de onde ia, não do zero) | sem interrupção, o risco desaparece e a jogada volta a ser botão — adopta a proposta `[CLAUDE]`; o progresso mantido evita que um golpe de área barato anule 6 s inteiros duas vezes seguidas |
| **Vida ao ressuscitar** | **50% dos PV; frascos como estavam** | segundo fôlego, não segunda vida — proposta `[CLAUDE]` adoptada |
| **Indicadores** | o morto vê o contador do minuto; o parceiro vê um feixe âmbar no corpo + o tempo restante ao aproximar-se (≤ 8 m) | a decisão de arriscar precisa do número à vista de quem arrisca (WP11 desenha) |

Na rede: o corpo e a canalização são do **anfitrião** (estado de mundo); a barra de progresso replica-se aos dois; os 5–7 s afinam-se no WP15B. O chefe durante a canalização é decisão do WP7 — está lá fechada.

## Voz e texto

**Nada dentro do jogo.** Eles já falam por fora (a sessão 1 **é** uma chamada gravada). Chat de voz embutido é semanas de trabalho para duplicar o Discord. *Registado como descartado, não como esquecido.*

## O que este documento entrega aos outros

| Para | O quê |
|---|---|
| **WP9** | o saco "personagem" transporta as flags que o 40% precisa |
| **WP11** | UI de convite (< 2 min), aviso de latência > 150 ms, indicador de alvo do chefe |
| **WP14** | transporte agnóstico; simulação separada da rede; os dois sacos de estado como formato de gravação |
| **WP15** | o marco de rede testa: entrar em < 2 min, esquiva do convidado justa a 100 ms simulados, queda a meio do Vorgar |
| **WP15B** | teste com latência artificial (80/150/250 ms) faz parte do protocolo |

## O que continua aberto

- **Pergunta 20** (fogo amigo) — proposta fechada acima, tom final deles
- **Transporte A vs B** — decisão prática deles (10 min de router ou 10 min de Tailscale)
- PvP/invasões: nunca mencionados, continuam fora até alguém os pedir

## Ligações

[`07-multiplayer.md`](07-multiplayer.md) (sessão 1) · [`18-progressao.md`](18-progressao.md) (o 40%) · [`01-combate.md`](01-combate.md) (i-frames que a rede tem de honrar) · [`16-chefes.md`](16-chefes.md) (×1,8 e alternância) · [`09-tecnico.md`](09-tecnico.md)
