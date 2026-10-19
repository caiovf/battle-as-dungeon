# Masmorra Relógio — versão Godot

Port completo do protótipo 3.6 (Phaser) para **Godot 4.3**.

## Como abrir e jogar

1. Baixe o Godot 4.3 (ou mais novo da série 4) em godotengine.org: a versão padrão, não a .NET.
2. Descompacte este zip numa pasta.
3. Abra o Godot e clique em **Importar**. Escolha o arquivo `project.godot` desta pasta.
4. Aperte **F5** (ou o botão ▶ no canto superior direito) para jogar.

Na primeira abertura, o Godot leva alguns segundos importando as fontes.

## Controles

**Masmorra**
- Clique ou toque num bloco do mapa para pôr a armadilha escolhida.
- Clique numa armadilha já colocada para vendê-la.
- Clique no coração para soar a badalada.
- `1`–`7` escolhem a armadilha. `Q W E R T Y U I O` soltam monstros.
- `B` badalada · `P` ou `Espaço` pausa · `G` melhorias da masmorra · `C` classes do guardião · `F` tela cheia.

**Luta do guardião**
- `A`/`D` ou setas: andar.
- `W`, `↑` ou `Espaço`: pular.
- `J`: atacar (segurar repete).
- `K`: dash.
- `U`, `I`, `O` (ou `1`, `2`, `3`): as 3 habilidades.
- `Y` (ou `4`): habilidade suprema, quando a barra dourada (embaixo das recargas) enche.
- `P`: pausa.
- **No celular (estilo MOBA):** encoste o polegar em qualquer lugar da metade esquerda da tela e aparece um analógico. Arraste para os lados para andar e empurre para cima para pular. Na direita fica o botão grande de ataque, com pular, dash e as 3 habilidades em arco em volta. A recarga aparece girando no botão, com os segundos no meio, e os pontinhos dourados mostram o nível da habilidade. Tudo é semitransparente por cima da arena e aceita vários dedos ao mesmo tempo. No computador, o mouse também funciona nesses controles.
- Para ajustar tamanho, transparência e posição dos botões, mexa no topo de `scripts/touch_pad.gd`.

## Guardião, classes e lendários

- **Bônus na masmorra:** cada guardião dá um bônus à masmorra enquanto ele é o seu guardião (Minotauro: monstros com +25% de vida; Lich: badalada recarrega 30% mais rápido; Dragão: cada herói derrotado dá +0,5s). Cada classe soma um bônus próprio, por exemplo o Necromante faz esqueletos custarem metade e solta um de graça a cada 12s.
- **Classes por missões:** cada guardião tem 4 classes no estilo Grand Chase. A primeira já vem liberada; as outras três saem de missões, em ordem: a missão da 3ª só conta depois de liberar a 2ª, e a da 4ª depois da 3ª. Exemplo: o Necromante libera soltando 40 esqueletos jogando com o Lich. O progresso e as classes liberadas ficam salvos para sempre, mesmo depois que a run acaba. Troque no botão **Guardião** da barra de cima (ou `C`), fora da luta. A tela mostra cada missão e quanto falta.
- **Upgrades básicos do guardião:** Força (dano), Resistência (menos tempo perdido), Poder das habilidades, Agilidade e Ímpeto (suprema começa mais carregada). Valem para as 4 classes do guardião, inclusive a base, e ficam para sempre. Cada lendário vencido dá 2 pontos de guardião. Abra em Guardião → Upgrades básicos. Ficam em `data.gd → BASIC_UPS`.
- **Talentos (estilo Grand Chase):** cada classe tem a sua árvore especializada, com três ramos ligados ao jeito de lutar dela (ex.: Berserker: Lâminas, Sede, Frenesi; Necromante: Caveiras, Servos, Almas) e o talento de Mestre. Cada lendário vencido com a classe dá 2 pontos para ela. Abra em Guardião → Talentos. Ficam em `data.gd → TALENT_TREES`.
- **Habilidades e suprema:** cada classe leva 3 habilidades e 1 suprema. Em Guardião → Habilidades, cada posição tem a habilidade da classe e duas alternativas exclusivas dela (nenhuma habilidade se repete entre classes) e só troca com a mesma posição: habilidade 1 com habilidade 1, suprema com suprema. Cada alternativa libera com 3 pontos da classe (a suprema com 4), e a habilidade equipada pode ser aprimorada para sempre (+1 nível por 2 pontos, +2 por mais 3). A suprema carrega acertando o lendário e levando golpes. As alternativas ficam em `data.gd` (`CLASS_ALTS`, `ALT_SKILLS`, `ALT_ULTS`), montadas com peças de efeito de `arena.gd → run_mechs`.
- **Poder das classes:** a 1ª é a base e cada uma das seguintes é mais forte. A 4ª dá +50% de dano e faz perder 24% menos tempo por golpe.
- **Antes de cada onda** há 5 segundos para arrumar a masmorra; o relógio fica parado. O botão "Começar agora" pula a contagem.
- **Lendários:** a dificuldade sobe a cada lendário que chega (mais dano e mais vida). O botão **Melhorias** (antigo grimório) gasta essência para fortalecer a masmorra e liberar armadilhas e monstros novos.
- Cada classe muda arma, ataque básico, velocidade, pulos, armadura, passiva, as 3 habilidades e o bônus da masmorra. O nível das habilidades fica guardado mesmo trocando de classe.
- São **13 lendários**. Cada um tem um poder no corredor e golpes próprios na arena.
- O painel de baixo separa **o que os heróis sabem da masmorra** de **o que os lendários sabem do guardião**.
- Missões, bônus e textos ficam em `data.gd` (`MISSIONS`, `GUARD_BONUS` e o campo `bonus` de cada classe em `CLASSES`).

## Onde mexer

| Arquivo | O que tem |
|---|---|
| `scripts/data.gd` | **Todos os números de balanceamento** e as tabelas: armadilhas, monstros, heróis, eventos, melhorias (`PERKS`), guardiões, classes (`CLASSES`), habilidades (`SKILLS`) e lendários (`LEG_ARENA`). Comece por aqui. |
| `scripts/main.gd` | A masmorra: caminho aleatório, ondas, adaptação dos heróis, contras escondidos, combate em grupo, fama, energia absorvida. |
| `scripts/arena.gd` | A luta de ação: ataque em 4 tempos com hit stop, classes, habilidades, passivas, golpes dos lendários e como eles aprendem o seu jeito de lutar. |
| `scripts/touch_pad.gd` | Controle virtual de toque da luta (analógico flutuante e botões em arco). |
| `scripts/ui.gd` | Interface: barra do topo, bandeja, painel "O que os heróis sabem", telas de escolha, Melhorias, botões de toque. |
| `scripts/art.gd` | Desenha os sprites de `art/` (âncoras, animação, escala ×2 sem borrar). |
| `art/` | Toda a pixel art em PNG: tiles, armadilhas, monstros, heróis, guardiões, lendários, cenário da arena e efeitos. |
| `tools/gen_art.py`, `tools/rig.py`, `tools/arena_art.py`, `tools/fx_art.py`, `tools/ui_icons.py` | O "código-fonte" da arte. `rig.py` monta guardiões e lendários em camadas (corpo, braços, arma, cabeça). Mude e rode `python3 tools/gen_art.py` (precisa de Python 3 e Pillow) para gerar os PNGs de novo. |
| `docs/GUIA-ANIMACAO.md` | Guia de arte e animação tirado das referências. Siga ao criar personagem novo. |
| `tools/showcase.py` | Gera a prancha de prévia com todos os sprites. |
| `tests/sim.gd` | Robô que joga uma run e uma luta para cada classe de guardião. |
| `tests/balance.gd` / `tests/skills_test.gd` | Teste de balanceamento dos lendários e teste que usa todas as habilidades e supremas. |

## Gerar o executável

O projeto já vem com as configurações de exportação para Windows e Linux (`export_presets.cfg`). No editor, vá em *Projeto → Exportar*, escolha **Windows** e clique em *Exportar projeto*. Na primeira vez, o Godot pede para baixar os modelos de exportação; é só aceitar. O resultado é um único `.exe` com tudo dentro.

## Testar no celular

- **Android:** em *Projeto → Exportar*, adicione Android. Siga o assistente para baixar os templates e configurar o SDK.
- **Navegador (Vercel, itch.io):** o projeto já tem a exportação *Web* configurada, sem threads, então roda em qualquer hospedagem estática. Em *Projeto → Exportar*, escolha **Web** e exporte para `build/web/`. Para publicar com GitHub + Vercel, suba o conteúdo de `build/web/` num repositório e importe na Vercel com *Framework Preset: Other* (o passo a passo está em `build/web/README.md`, que acompanha o `vercel.json`). Também dá para subir no itch.io como jogo HTML5.

O projeto já usa o renderizador *Compatibilidade*, que funciona na web e em celulares mais simples.

## Rodar o teste automático

No terminal, dentro da pasta do projeto:

```
godot --headless --fixed-fps 60 -s res://tests/sim.gd
```

Teste de balanceamento da arena (todos os lendários, relógio de 80s e 200s, 1º, 2º e 4º lendário). Troque o guardião com a variável `BAL_G` (minotauro, lich ou dragao):

```
BAL_G=lich godot --headless --fixed-fps 60 -s res://tests/balance.gd
```

O dano dos lendários acompanha o relógio com que você entra na sala: cada golpe tira uma fatia do seu tempo, então guardar muito tempo não deixa a luta fácil. Os números ficam em `data.gd → CFG` (`LEG_DMG_REF`, `LEG_DMG_GROWTH`, `LEG_ARENA_HP`).

## Arte

Estilo pixel art inspirado em Risk of Rain, Moon Hunters, Starbound e Noitu Love 2: contorno escuro grosso, cores vivas com brilho nas bordas, cenário sombrio com luz de tocha.

- Tiles de 20×20 e personagens de 16–48 px, sempre desenhados em ×2.
- Se quiser redesenhar à mão, abra os PNGs de `art/` no Aseprite ou no LibreSprite e salve por cima. Mantenha o mesmo tamanho, ou rode o gerador para atualizar `art/meta.json` (onde ficam os pés de cada sprite).

## Créditos

Fontes Press Start 2P, Pixelify Sans e Alegreya Sans, sob a licença SIL Open Font License (arquivos em `fonts/`).
