# Arquitetura — Reino da Promessa

## Objetivo

Construir um RPG 3D de fantasia bíblica com sensação de MMORPG clássico, começando offline/local para validar gameplay, performance e direção de arte antes de adicionar infraestrutura online.

## Princípios

1. **Gameplay antes de conteúdo em massa** — nenhum mapa gigante antes de combate, progressão e navegação estarem sólidos.
2. **Baixo custo de hardware** — GL Compatibility, geometria procedural leve e assets externos selecionados.
3. **Lógica desacoplada da arte** — combate e IA não dependem de um modelo 3D específico.
4. **Arte por contrato semântico** — gameplay pede `play_attack()`, `play_death()` etc.; não conhece rigs ou nomes de clips.
5. **Interação reutilizável** — NPCs, passagens, pickups, baús e vendedores usam `interact(player)`.
6. **Progressão abre o mundo** — regiões podem exigir quest, nível ou item sem duplicar lógica no player.
7. **Domínio não depende de UI** — inventário decide stacks, slots e ouro; painéis apenas apresentam estado.
8. **Loot não pertence à IA** — inimigos anunciam uma morte; `LootManager` resolve a tabela e cria pickups.
9. **Estado contínuo entre regiões** — áreas coexistem no mesmo mundo enquanto a escala permitir.
10. **Multiplayer só depois do vertical slice** — rede entra após profiling e regras de gameplay estabilizadas.

## Camadas

```text
scenes/
  player/        física + composição do jogador
  enemies/       cena-base reutilizável de hostis
  loot/          pickups visuais/interativos
  npcs/          NPCs e pontos de interação
  ui/            HUD, inventário e feedback visual
  world/         regiões e passagens

scripts/
  art/           adaptação de modelos/animações
  player/        movimento, combate, interação e progressão
  enemies/       IA, dano, morte e respawn
  inventory/     catálogo, slots, stacks e moeda
  loot/          tabelas, resolução e pickups
  npcs/          contratos de interação
  quests/        regras e estado de missão
  camera/        câmera MMORPG
  ui/            apresentação e feedback
  world/         builders e transições regionais

assets/
  third_party/   conteúdo externo aprovado
  ATTRIBUTION.md procedência/licença

tests/           smoke tests de integração do vertical slice
```

## Fluxo atual

```text
Acampamento do Peregrino
        ↓
Eliabe → "Limpe o Caminho"
        ↓
Combate → dano → morte do inimigo
       ↙                     ↘
quest defeated             loot_requested
       ↓                     ↓
QuestManager              LootManager
                             ↓
                         LootTable
                             ↓
                        WorldPickup
                             ↓ E
                     Player/Inventory
                             ↓ signals
                    HUD + InventoryPanel
        ↓
Quest concluída → passagem abre
        ↓
Vale das Fontes ↔ Ruínas Antigas
```

## Regiões

### Região 1 — Acampamento do Peregrino

Contém acampamento, Caminho dos Olivais, Ruínas Antigas, Eliabe e três inimigos. O cenário é procedural, com materiais compartilhados e proxies de colisão simples.

### Região 2 — Vale das Fontes

Área segura com riacho, ponte, vegetação e santuário. Fica fisicamente afastada da primeira região para manter o estado do jogador sem serialização prematura.

## Contratos principais

### Player → Interactables

```text
interactable.interact(player)
```

O player não precisa saber se o objeto é NPC, passagem ou pickup.

### Gameplay → ModelAdapter

```text
visual_adapter.play_attack()
visual_adapter.play_death()
visual_adapter.reset_state()
```

`ModelAdapter` instancia GLB, normaliza escala, alinha os pés e encontra animações por intenção.

### Enemy → QuestManager

```text
defeated(enemy_kind)
```

`QuestManager` decide se a morte conta para a missão.

### Enemy → LootManager

```text
loot_requested(enemy_kind, world_position)
```

A IA não conhece item, chance, ouro ou inventário. `LootManager` consulta `LootTable` e instancia `WorldPickup`.

### WorldPickup → Inventory

Pickup chama apenas:

```text
inventory.add_item(item_id, quantity)
inventory.add_gold(amount)
```

Se o inventário não comportar a pilha inteira, o pickup mantém a quantidade restante no chão.

### Inventory → UI

`PlayerInventory` emite:

```text
changed
item_added(item_id, amount)
gold_changed(total)
```

`InventoryPanel` e HUD observam esses sinais; nunca alteram diretamente a estrutura de slots.

### QuestManager → World Progression

`RegionGate` consulta `is_first_quest_completed()` e não conhece o enum interno da missão.

### RegionGate → HUD

Passagens emitem `used(destination_name)`. O HUD atualiza apenas a apresentação da região.

### Combat → DamagePopup

Player e inimigos instanciam `damage_popup.tscn`. A cena controla animação e descarte; entidades fornecem valor e cor.

## Inventário

O inventário atual possui 20 slots. Cada item define `max_stack` no `ItemCatalog`. A operação `add_item()` tenta primeiro completar pilhas existentes e só então abre novos slots. O retorno é a quantidade que não coube, permitindo que pickups permaneçam parcialmente no mundo.

Ouro é armazenado no mesmo domínio, mas separado dos slots. `spend_gold()` rejeita transações sem saldo suficiente.

## Loot

`LootTable` concentra regras de drop por `enemy_kind`. Isso evita probabilidades espalhadas pelos scripts dos inimigos e prepara o sistema para raridade, bônus de mapa, chefes e tabelas externas depois.

## Estratégia de mundo

Por enquanto, regiões coexistem numa única cena. Quando custo de memória justificar, o contrato de `RegionGate` poderá migrar para streaming regional sem alterar o player ou a UI.

## Pipeline de assets

Assets externos só entram com licença/origem registradas em `assets/ATTRIBUTION.md`. O CI executa `godot --import` antes do smoke test.

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

### Marco 4 — Inventário + loot ✅
- catálogo de itens
- slots e empilhamento
- ouro
- tabelas de drop
- pickups interativos
- janela de inventário
- feedback de coleta
- testes de domínio e integração

### Marco 5 — Equipamentos + persistência — próximo
- arma e armadura
- atributos derivados
- equipar/desequipar pela UI
- save local versionado
- restauração de inventário, ouro, nível e equipamentos
- preparação para ferreiro/loja

### Marco 6 — Conteúdo e identidade
- habilidades
- VFX/SFX
- minimapa
- mapa geral
- primeira dungeon
- quests persistentes

### Marco 7 — Online
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
