# Masmorra Relógio

Roguelike em que **você é a masmorra** e o coração é um relógio: o tempo é a sua vida e a sua moeda. Heróis invadem, aprendem o seu jeito de jogar naquela run e se adaptam. Quando um herói lendário chega ao coração, você controla o guardião numa luta de ação.

Feito em **Godot 4.3** (renderizador Compatibilidade), com pixel art gerada por código em `tools/`.

## Jogar no navegador

A pasta `web/` tem a exportação para navegador. A Vercel publica essa pasta direto (ver `vercel.json`), sem build.

**Atualizar a versão web:** abra o projeto no Godot 4.3, vá em *Projeto → Exportar*, escolha **Web** e exporte para `build/web/index.html`. Depois copie os arquivos `build/web/index.*` para `web/` e faça commit (o `manifest.json` e os ícones `icon-*.png` da pasta `web/` ficam; eles fazem o jogo abrir em tela cheia quando adicionado à tela inicial). A Vercel republica sozinha.

## Abrir o projeto

Importe o `project.godot` no Godot 4.3 (versão padrão, não a .NET) e aperte F5. Os detalhes de controles, onde mexer no balanceamento, testes e exportação para Windows estão no [LEIA-ME.md](LEIA-ME.md). O guia de arte e animação fica em [docs/GUIA-ANIMACAO.md](docs/GUIA-ANIMACAO.md).

## No celular

- O jogo é só na horizontal; com o celular em pé aparece um aviso para deitar.
- **Android (Chrome):** o primeiro toque já coloca em tela cheia e trava em paisagem.
- **iPhone (Safari):** o Safari não deixa sites em tela cheia. Toque em *Compartilhar → Adicionar à Tela de Início* e abra pelo ícone: assim o jogo ocupa a tela toda.
