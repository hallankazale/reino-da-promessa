# Arquitetura — Reino da Promessa

## Objetivo

Construir um RPG 3D de fantasia bíblica com sensação de MMORPG clássico, começando offline e local para validar gameplay, performance e direção de arte antes de adicionar infraestrutura online.

## Princípios

1. **Gameplay antes de conteúdo em massa** — nenhum mapa gigante antes de combate, progressão e navegação estarem sólidos.
2. **Baixo custo de hardware** — GL Compatibility, geometrias simples no protótipo, LOD e assets otimizados na produção.
3. **Lógica desacoplada da arte** — player, combate, progressão e HUD não dependem de um modelo 3D específico.
4. **Dados antes de duplicação** — itens, inimigos, classes e quests migrarão para Resources/arquivos de dados conforme o volume crescer.
5. **Multiplayer só depois do vertical slice** — rede prematura aumenta drasticamente custo de depuração e segurança.

## Camadas

```text
scenes/
  player/        composição visual/física do jogador
  enemies/       entidades hostis
  world/         mapas e composição de regiões
  ui/            cenas de interface reutilizáveis (próxima etapa)

scripts/
  player/        movimento, seleção de alvo, combate e progressão inicial
  enemies/       comportamento de inimigos
  camera/        câmera estilo MMORPG
  ui/            apresentação e feedback ao jogador
  world/         spawners, portais e gerenciamento de região (próxima etapa)

data/            classes, itens, quests, drops (entra quando os sistemas forem criados)
assets/           somente conteúdo com licença compatível e origem registrada

tests/            smoke tests e testes de lógica
```

## Fluxo do vertical slice v1

```text
Jogador entra no mapa
        ↓
WASD movimenta
        ↓
TAB seleciona inimigo
        ↓
ESPAÇO ataca
        ↓
Inimigo perde HP e contra-ataca
        ↓
Inimigo morre → concede XP
        ↓
XP suficiente → level up
        ↓
Jogador ganha ataque/vida
        ↓
Inimigo reaparece para novo ciclo de teste
```

## Roadmap técnico

### Marco 1 — Combate base
- movimento e câmera
- target lock
- HP de player/inimigo
- ataque e cooldown
- morte/respawn
- XP e level
- HUD

### Marco 2 — Mundo jogável
- primeira vila
- estrada/campo
- 3 famílias de inimigos
- colisões e navegação
- NPC de missão
- portal para segunda área

### Marco 3 — RPG sistêmico
- inventário
- equipamentos
- drops
- atributos
- habilidades
- loja/ferreiro
- quests persistentes
- save local versionado

### Marco 4 — Conteúdo e identidade
- personagem definitivo
- animações
- VFX/SFX
- minimapa
- mapa geral
- primeira dungeon
- direção de arte consistente

### Marco 5 — Online
Somente após profiling e validação do loop offline:
- servidor autoritativo
- autenticação
- persistência remota
- sincronização de entidades
- chat
- grupo/guilda
- comércio
- PvE/PvP

## Segurança futura do online

Quando a fase online começar, cliente nunca será autoridade para:
- dinheiro;
- XP;
- inventário;
- dano;
- posição válida de combate;
- drops;
- conclusão de quest.

Esses estados serão validados pelo servidor para reduzir trapaças, duplicação de itens e manipulação de pacotes.
