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
- primeira região redesenhada com cenário procedural leve;
- passagem bloqueada por progresso de quest;
- segunda área explorável: Vale das Fontes;
- ida e volta entre regiões sem resetar o jogador;
- smoke test headless validando gameplay, assets, missão e transição entre regiões.

## Mundo atual

### Região 1 — Acampamento do Peregrino

Fluxo:

**Acampamento do Peregrino → Caminho dos Olivais → Ruínas Antigas**.

Inimigos:

1. **Espectro do Ermo** — rápido e fraco;
2. **Esqueleto Saqueador** — dificuldade intermediária;
3. **Demônio das Ruínas** — mais resistente e perigoso.

NPC:

- **Eliabe — Guardião do Acampamento**.

Missão:

- **Limpe o Caminho** — fale com Eliabe, derrote 3 criaturas hostis, retorne ao acampamento e receba XP.

Após entregar a missão, a passagem das Ruínas Antigas é desbloqueada.

### Região 2 — Vale das Fontes

Primeira área de expansão do mundo. Atualmente funciona como zona segura de exploração com:

- riacho;
- ponte de pedra;
- vegetação própria;
- santuário da fonte;
- passagem de retorno às Ruínas Antigas.

Ela existe para validar crescimento regional mantendo estado do jogador no mesmo mundo.

## Controles

| Ação | Tecla |
|---|---|
| Mover | WASD |
| Selecionar inimigo próximo | TAB |
| Atacar | ESPAÇO |
| Interagir / falar / atravessar passagem | E |
| Girar câmera | botão direito + mouse |
| Zoom | roda do mouse |

## Estrutura

```text
assets/
  third_party/quaternius/
scenes/
  enemies/
  npcs/
  player/
  ui/
  world/
scripts/
  art/
  camera/
  enemies/
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

Os modelos animados atuais são de **Quaternius**, distribuídos em **CC0** e registrados em `assets/ATTRIBUTION.md` com origem e SHA-256.

O ambiente continua majoritariamente procedural para manter download e custo de renderização baixos. Nenhum modelo, mapa, textura, som ou personagem extraído de Talisman Online ou de outro jogo comercial é usado.

## Teste rápido

Abra `project.godot` no Godot 4.7.x e execute o projeto.

### Smoke test headless

```bash
godot --headless --path . --import
godot --headless --path . --script tests/smoke_test.gd
```

O teste automatizado valida:

1. cenas, scripts e inputs;
2. importação dos quatro GLBs CC0;
3. animações do jogador e inimigos;
4. primeira e segunda regiões;
5. Eliabe e os três inimigos;
6. missão completa e recompensa;
7. passagem trancada antes da missão;
8. desbloqueio após conclusão;
9. ida ao Vale das Fontes e retorno às Ruínas Antigas.

## Próximo marco

**RPG sistêmico — loot + inventário**:

- drops por inimigo;
- inventário desacoplado da UI;
- itens comuns e equipamentos;
- moeda do jogo;
- feedback ao coletar loot;
- preparação para loja/ferreiro e save local.
