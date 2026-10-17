# Masmorra Relógio — Guia de arte e animação

Este guia vale para **todo personagem novo** (herói, lendário, monstro, guardião ou classe). Ele junta o que as referências fazem bem com as regras técnicas do nosso gerador de sprites (`tools/`).

## 1. O que cada referência ensina

| Referência | O que pegamos |
|---|---|
| **Risk of Rain** (Hopoo) | Sprites pequenos e simples, que dão escala: chefes grandes parecem enormes ao lado dos personagens. Cada personagem tem silhueta e jeito de jogar únicos, então dá para reconhecer cada um a 1×, só pela forma. |
| **Noitu Love 2 / Iconoclasts** (Konjak) | Ataques cheios de energia: antecipação curta, **smear** (o rastro do golpe desenhado como uma meia-lua colorida), quadro de impacto segurado, contorno escuro e cores vivas. |
| **Starbound** | Personagem montado em **camadas** (corpo, braço de trás, braço da frente com a arma, cabeça). Assim a mesma animação serve para várias roupas e armas. O ciclo de andar tem 8 quadros. |
| **Moon Hunters** | Paleta limitada com identidade de cor por classe, iluminação quente de tochas contra o fundo frio, leitura clara de quem é quem. |
| **Grand Chase** (classes) | Cada classe muda **arma, combo e jeito de se mover**. Exemplos: Elesis vai de espada para lança e depois espadão; Lire vai de arco para bestas automáticas; Arme vai de magia para invocação. A classe precisa ser reconhecida pela arma e pela pose. |

## 2. Regras de silhueta e cor

- A silhueta precisa ser legível a 1× (16 a 24 px). Arma e cabeça sempre saem do contorno do corpo.
- Uma cor dominante e um acento por personagem. Heróis usam acentos frios ou metálicos; guardiões e monstros, quentes ou sombrios.
- Contorno escuro de 1 px em tudo. Luz vem de cima e da esquerda, e o pipeline (`cel()`) faz isso sozinho.
- Classes do mesmo guardião mudam **paleta e arma**, mas mantêm a forma do corpo. Assim o jogador sabe que continua sendo o mesmo guardião.

## 3. Conjunto de animações por tipo

| Tipo | Quadros |
|---|---|
| Herói no mapa (17×19) | andar 4 (contato, descida, passagem, subida) e atacar 2 (preparo, golpe com smear) |
| Monstro no mapa | 1 ou 2 quadros e pulo feito em código; golpe com faísca de efeito |
| Guardião na arena | parado 4, correr 6, pular 1, cair 1, ataque 4 (antecipação, smear, impacto, recuperação), conjurar 1, dano 1 |
| Lendário na arena | parado 2, correr 4, preparo (aviso) 1, ataque 3 (smear, impacto, recuperação), dano 1 |

## 4. Ataque: os quatro tempos

1. **Antecipação:** recua a arma no sentido contrário. É curta no guardião (≈60 ms, para resposta rápida) e longa no lendário, porque serve de **aviso** para o jogador.
2. **Smear:** 1 quadro com o arco inteiro do golpe desenhado como meia-lua. A cor do rastro é a identidade do ataque.
3. **Impacto:** a arma estendida, 1 px "dentro" do alvo. É **segurado** mais tempo (120 a 300 ms, maior em arma pesada).
4. **Recuperação:** volta para a pose parada. Em arma pesada demora mais.

Tempos de referência (ms):
- Leve (garras, adaga): 60 / 50 / 120 / 60
- Médio (espada, lança): 100 / 50 / 150 / 60
- Pesado (machado, martelo): 220 / 60 / 300 / 120

A sensação de peso vem do motor, além do desenho:
- **hit stop** de 40 a 80 ms ao acertar;
- tremida de tela proporcional ao peso;
- clarão branco no alvo;
- faíscas ou poeira como efeitos separados.

## 5. Andar e correr

- Os quadros avançam pela **distância andada**, não pelo tempo. Assim os pés não deslizam.
- Ciclo: contato (pernas abertas), descida (corpo 1 px abaixo), passagem (pernas juntas), subida (corpo 1 px acima).
- Capa, cabelo e cauda chegam **1 quadro atrasados**: é o *follow-through*.
- Squash e stretch de 1 a 3 px ao pular e aterrissar.

## 6. Ataques normais: guardião contra herói

Os dois lados precisam ser diferentes à primeira vista.

- **Guardiões (monstros):**
  - rastros quentes e "orgânicos": laranja, vermelho, verde-veneno, roxo-necro;
  - formas pesadas, com meia-lua grossa e garras em três riscos;
  - efeito de poeira no impacto.
- **Heróis e lendários:**
  - rastros frios ou de luz: branco-azulado, dourado-sagrado;
  - formas finas e precisas, como corte em linha e estocada reta;
  - faíscas em cruz no impacto.

## 7. Como isso está no jogo

- **Guardião:** o ataque básico segue os quatro tempos no código (`arena.gd → start_basic/basic_step`). Cada classe define `anti`, `t` (golpe ativo) e `rec` em `data.gd → CLASSES`. Quadros: `atk0` antecipação, `atk1` smear, `atk2` impacto, `atk3` recuperação. O rastro é um efeito separado (`fx/slash_axe|claw|necro|spear`).
- **Hit stop:** 40 a 80 ms ao acertar (mais em arma pesada); o guardião leva hit stop de 60 ms quando é atingido.
- **Faíscas:** `fx/spark_guard` (poeira quente) quando o guardião acerta; `fx/spark_hero` (cruz fria) quando o lendário acerta.
- **Lendários:** o aviso (`tele`) dura mais que a antecipação do guardião. Os golpes corpo a corpo deles usam `fx/slash_hero` ou `fx/slash_hero_heavy`.
- **Mapa:** heróis trocam `walk0-3` pela distância andada e `atk0/atk1` quando estão lutando. Golpe de herói = corte fino e frio; golpe de monstro = garra quente.

## 8. Classes (estilo Grand Chase)

Cada guardião tem 4 classes. A forma do corpo fica; mudam paleta, arma, pose de ataque, rastro, passiva e habilidades.

| Guardião | Classes |
|---|---|
| Minotauro | Guerreiro do Labirinto (machado) · Berserker (dois machados, rápido) · Guardião de Pedra (maça e escudo, tanque) · Senhor dos Touros (lança longa) |
| Lich | Lich (virotes de osso) · Necromante (caveiras, ergue esqueletos) · Feiticeiro do Gelo (deixa lento) · Arauto do Tempo (devolve tempo) |
| Dragão | Dragão Jovem (garras) · Dragão da Tempestade (pulo triplo, raios) · Serpe Venenosa (veneno) · Dragão Ancião (grande, cauda larga) |

Para criar uma classe nova:
1. Paleta e arma em `tools/rig.py` (`GPAL`).
2. Linha em `data.gd → CLASSES`: multiplicadores, ataque com os 4 tempos, passiva e 3 habilidades de `SKILLS`.
3. Ícones `ui/atk_<guardião>_<classe>` e `ui/sk_<habilidade>` em `tools/ui_icons.py`.

## 9. Lendários

São 13. Cada um tem silhueta, arma e cor de rastro próprias (`tools/rig.py → LEGENDS`), um poder no corredor (`power` em `data.gd → HEROES`) e golpes na arena (`moves`/`moves2` e sprites `fx` em `LEG_ARENA`). Regra de ouro: **todo golpe tem aviso legível** (marca no chão, coluna piscando ou pose `tele`) antes de causar dano.

## 10. Checklist para personagem novo

1. Silhueta a 1×: dá para reconhecer sem cor?
2. Cor dominante, acento e cor do rastro do ataque (seguir a seção 6).
3. Arma ou objeto que diz a função dele.
4. Todos os quadros da seção 3, com âncora nos pés.
5. Tempos do ataque (seção 4) e efeito de impacto.
6. Testar na prancha (`tools/showcase.py`) e no jogo, ao lado dos outros personagens.

## Fontes consultadas

- [Pixelblog 56: animação de ataque (SLYNYRD)](https://www.slynyrd.com/blog/2025/5/23/pixelblog-56-top-down-character-attack-animation)
- [12 princípios de animação para pixel art (Sprite-AI)](https://www.sprite-ai.art/guides/animation-principles)
- [Smear frame (Wikipedia)](https://en.wikipedia.org/wiki/Smear_frame)
- [Risk of Rain (Wikipedia)](https://en.wikipedia.org/wiki/Risk_of_Rain)
- [Starbound: quadros de animação (fórum oficial)](https://community.playstarbound.com/threads/adding-additional-animation-frames.135629/)
- [Grand Chase (Tropedia)](https://tropedia.fandom.com/wiki/Grand_Chase)
