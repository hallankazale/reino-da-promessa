# Arquitetura — Reino da Promessa

## Objetivo

Construir um RPG 3D de fantasia bíblica com sensação de MMORPG clássico, começando offline/local para validar gameplay, performance e direção de arte antes de adicionar infraestrutura online.

## Princípios

1. **Gameplay antes de conteúdo em massa** — nenhum mapa gigante antes de combate, progressão e navegação estarem sólidos.
2. **Baixo custo de hardware** — GL Compatibility, geometria procedural leve e assets externos selecionados.
3. **Lógica desacoplada da arte** — combate e IA não dependem de um modelo 3D específico.
4. **Arte por contrato semântico** — gameplay pede `play_attack()`, `play_death()` etc.; não conhece rigs ou nomes de clips.
5. **Interação reutilizável** — NPCs, passagens, baús e vendedores usam `interact(player)`.
6. **Progressão abre o mundo** — regiões podem exigir estado de quest, nível ou item sem duplicar lógica no player.
7. **Estado contínuo entre regiões** — enquanto o jogo for local, as áreas coexistem no mesmo mundo para preservar XP, HP e progresso sem serialização prematura.
8. **Multiplayer só depois do vertical slice** — rede entra após profiling e regras de gameplay estabilizadas.

## Camadas

```text
scenes/
  player/        física + composição do jogador
  enemies/       cena-base reutilizável de hostis
  npcs/          NPCs e pontos de interação
  ui/            feedback visual reutilizável
  world/         regiões e passagens

scripts/
  art/           adaptação de modelos/animações importados
  player/        movimento, combate, interação e progressão
  enemies/       IA, dano, morte e respawn
  npcs/          contratos de interação
  quests/        regras e estado de missão
  camera/        câmera MMORPG
  ui/            HUD e feedback de combate
  world/         builders procedurais e transições regionais

assets/
  third_party/   conteúdo externo aprovado e rastreado
  ATTRIBUTION.md procedência/licença

data/            itens, classes, drops e quests quando o volume crescer
tests/           smoke tests de integração do vertical slice
```

## Fluxo atual

```text
Acampamento do Peregrino
        ↓
Eliabe entrega "Limpe o Caminho"
        ↓
Caminho dos Olivais
        ↓
3 criaturas derrotadas
        ↓
Volta a Eliabe
        ↓
Quest concluída + XP
        ↓
Passagem das Ruínas é desbloqueada
        ↓
Vale das Fontes
        ↕
Passagem de retorno às Ruínas Antigas
```

## Regiões

### Região 1 — Acampamento do Peregrino

Contém acampamento, estrada, oliveiras, ruínas, Eliabe e os três inimigos atuais. O cenário é gerado por `first_region_builder.gd` com materiais compartilhados e proxies de colisão simples.

### Região 2 — Vale das Fontes

Área segura de expansão gerada por `second_region_builder.gd`. Possui riacho, ponte, vegetação e santuário da fonte. Fica fisicamente afastada da primeira região dentro da mesma cena principal para manter estado do jogador sem introduzir save/load antes da hora.

## Contratos principais

### Player → Interactables

```text
interactable.interact(player)
```

O player não precisa saber se o objeto é NPC, passagem, baú ou vendedor.

### Gameplay → ModelAdapter

```text
visual_adapter.play_attack()
visual_adapter.play_death()
visual_adapter.reset_state()
```

`ModelAdapter` instancia o GLB, normaliza escala, alinha os pés e encontra animações por intenção.

### Enemy → QuestManager

Inimigos emitem `defeated(enemy_kind)`. O `QuestManager` decide se a morte conta para a missão.

### QuestManager → World Progression

O `QuestManager` expõe:

```text
is_first_quest_completed()
announce(message)
```

`RegionGate` consulta apenas essa API pública. A passagem não conhece detalhes internos do enum de quest.

### RegionGate → HUD

Passagens emitem:

```text
used(destination_name)
```

O HUD atualiza o nome da região sem controlar teleporte ou regras de desbloqueio.

### Combat → DamagePopup

Player e inimigos instanciam `damage_popup.tscn` ao receber dano. A cena controla animação e descarte do número flutuante; entidades apenas informam valor e cor.

## Estratégia de mundo

Por enquanto, regiões coexistem em uma única cena e ficam separadas espacialmente. Isso evita reset de estado e simplifica QA.

Quando o número de regiões ou custo de memória justificar, essa camada migra para streaming/carregamento regional. O contrato de `RegionGate` permanece e o destino poderá trocar de posição para um identificador de região carregável.

## Pipeline de assets

Assets externos só entram com licença/origem registradas em `assets/ATTRIBUTION.md`. O CI executa `godot --import` antes do smoke test para garantir que GLBs estejam totalmente importados.

## Roadmap técnico

### Marco 1 — Combate base ✅
- movimento e câmera
- target lock
- HP e ataque
- morte/respawn
- XP e level
- HUD

### Marco 2 — Mundo jogável ✅
- primeira região
- Eliabe
- 3 inimigos
- missão completa
- recompensa

### Marco 3 — Mundo expandido + feedback ✅
- câmera/HUD refinados
- cenário procedural redesenhado
- números de dano
- passagem bloqueada por quest
- Vale das Fontes
- ida e volta entre regiões
- teste de integração da progressão regional

### Marco 4 — RPG sistêmico — próximo
- inventário
- itens
- drops
- moeda
- equipamentos
- atributos
- loja/ferreiro
- save local versionado

### Marco 5 — Conteúdo e identidade
- habilidades
- VFX/SFX
- minimapa
- mapa geral
- primeira dungeon
- quests persistentes

### Marco 6 — Online
Somente após profiling e validação offline:
- servidor autoritativo
- autenticação
- persistência remota
- sincronização de entidades
- chat
- grupo/guilda
- comércio
- PvE/PvP

## Segurança futura do online

Quando a fase online começar, o cliente nunca será autoridade para dinheiro, XP, inventário, dano, posição válida de combate, drops ou conclusão de quest. Esses estados serão validados pelo servidor para reduzir trapaças, duplicação e manipulação de pacotes.
