# Reino da Promessa

RPG 3D original de fantasia bíblica épica com sensação de MMORPG clássico. O projeto usa referências de gênero — câmera, progressão, combate por alvo e exploração — sem copiar conteúdo protegido de Talisman Online.

## Estado atual

O jogo já possui um vertical slice jogável em Godot 4.7.x com foco em hardware fraco:

- GDScript + GL Compatibility;
- movimento WASD relativo à câmera;
- câmera estilo MMORPG com zoom e rotação;
- seleção de alvo com TAB;
- ataque com ESPAÇO e interação com E;
- HP, morte, respawn, XP e level-up;
- HUD compacto com vida, XP, nível, alvo, missão e região;
- números de dano flutuantes;
- personagem e três inimigos com modelos/animações CC0;
- NPC Eliabe e ciclo completo de missão;
- duas regiões conectadas por progressão de quest;
- inventário de 20 slots com empilhamento;
- ouro;
- tabela de loot por tipo de inimigo;
- pickups no mundo coletados com E;
- janela de inventário aberta com I;
- feedback no HUD ao obter item ou ouro;
- smoke test headless cobrindo gameplay, mundo, inventário e loot.

## Mundo atual

### Região 1 — Acampamento do Peregrino

**Acampamento do Peregrino → Caminho dos Olivais → Ruínas Antigas**.

Inimigos:

1. **Espectro do Ermo** — pode derrubar Essência do Ermo e ouro;
2. **Esqueleto Saqueador** — pode derrubar Fragmentos de Osso e ouro;
3. **Demônio das Ruínas** — derruba Lasca das Ruínas e ouro.

NPC:

- **Eliabe — Guardião do Acampamento**.

Missão:

- **Limpe o Caminho** — fale com Eliabe, derrote 3 criaturas hostis, retorne ao acampamento e receba XP.

Após entregar a missão, a passagem das Ruínas Antigas é desbloqueada.

### Região 2 — Vale das Fontes

Zona segura de exploração com riacho, ponte de pedra, vegetação própria, santuário da fonte e passagem de retorno às Ruínas Antigas.

## Controles

| Ação | Tecla |
|---|---|
| Mover | WASD |
| Selecionar inimigo próximo | TAB |
| Atacar | ESPAÇO |
| Interagir / falar / coletar / atravessar passagem | E |
| Inventário | I |
| Girar câmera | botão direito + mouse |
| Zoom | roda do mouse |

## Arquitetura do inventário

```text
Enemy
  ↓ loot_requested
LootManager
  ↓ LootTable
WorldPickup
  ↓ interact(player)
Player/Inventory
  ↓ signals
HUD + InventoryPanel
```

A IA do inimigo nunca escreve diretamente no inventário. A UI também não decide regras de slots, stacks ou ouro.

## Estrutura

```text
assets/
  third_party/quaternius/
scenes/
  enemies/
  loot/
  npcs/
  player/
  ui/
  world/
scripts/
  art/
  camera/
  enemies/
  inventory/
  loot/
  npcs/
  player/
  quests/
  ui/
  world/
docs/
  ARCHITECTURE.md
  ASSET_POLICY.md
tests/
  smoke_test.gd
```

## Assets

Os modelos animados atuais são de **Quaternius**, distribuídos em **CC0** e registrados em `assets/ATTRIBUTION.md` com origem e SHA-256. O ambiente continua majoritariamente procedural para manter download e custo de renderização baixos.

## Teste rápido

Abra `project.godot` no Godot 4.7.x e execute o projeto.

### Smoke test headless

```bash
godot --headless --path . --import
godot --headless --path . --script tests/smoke_test.gd
```

O teste automatizado valida cenas, inputs, GLBs/animações, regiões, missão, passagem, stacks, ouro, gasto, remoção, pickups e loot garantido do Demônio das Ruínas.

## Próximo marco

**Equipamentos + atributos + persistência local**:

- slots de arma e armadura;
- bônus de ataque/vida derivados de equipamento;
- itens equipáveis no catálogo;
- interação da janela de inventário;
- save local versionado;
- preparação para ferreiro e loja.
