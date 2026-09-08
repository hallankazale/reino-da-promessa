# Reino da Promessa

RPG 3D original de fantasia bíblica épica com sensação de MMORPG clássico. O projeto usa referências de gênero — câmera, progressão, combate por alvo e exploração — sem copiar conteúdo protegido de Talisman Online.

## Estado atual

O primeiro vertical slice está em construção com foco em hardware fraco:

- Godot 4.7.x;
- GDScript;
- GL Compatibility;
- resolução-base 960×540;
- movimento WASD relativo à câmera;
- câmera estilo MMORPG;
- seleção de alvo com TAB;
- ataque com ESPAÇO;
- HP do jogador;
- HP do inimigo;
- cooldown de ataque;
- inimigo contra-ataca;
- morte e respawn do jogador;
- morte e respawn do inimigo;
- recompensa de XP;
- level-up com aumento de ataque e vida;
- HUD com vida, XP, nível, alvo e estado.

## Controles

| Ação | Tecla |
|---|---|
| Mover | WASD |
| Selecionar inimigo próximo | TAB |
| Atacar | ESPAÇO |

## Estrutura

```text
scenes/
  enemies/
  player/
  world/
scripts/
  camera/
  enemies/
  player/
  ui/
docs/
  ARCHITECTURE.md
  ASSET_POLICY.md
tests/
  smoke_test.gd
```

A arquitetura completa e o roadmap estão em `docs/ARCHITECTURE.md`.

## Assets

O projeto só adotará conteúdo externo com licença compatível e origem registrada. As fontes aprovadas inicialmente são Quaternius e Kenney em packs explicitamente CC0. Consulte `docs/ASSET_POLICY.md`.

Não serão usados modelos, mapas, texturas, sons ou personagens extraídos de jogos comerciais.

## Teste rápido

Abra `project.godot` no Godot 4.7.x e execute o projeto.

### Smoke test headless

```bash
godot --headless --path . --script tests/smoke_test.gd
```

Critérios mínimos:

1. projeto carrega sem erro de parser/recurso;
2. WASD movimenta o personagem;
3. TAB seleciona o inimigo;
4. ESPAÇO causa dano apenas dentro do alcance;
5. inimigo contra-ataca quando o jogador aproxima;
6. morte do inimigo concede XP uma única vez;
7. inimigo reaparece após o respawn;
8. XP suficiente aumenta o nível;
9. morte do player não trava o jogo e ele retorna ao ponto inicial;
10. HUD acompanha vida, XP, nível e alvo.

## Próximo marco

Transformar o terreno de teste na primeira área jogável:

**Acampamento do Peregrino → Caminho dos Olivais → Ruínas Antigas**

Nessa etapa entram personagem animado CC0, cenário modular, três tipos de inimigos e o primeiro NPC com missão.
