# Reino da Promessa

RPG 3D original de fantasia bíblica épica com sensação de MMORPG clássico. O projeto usa referências de gênero — câmera, progressão, combate por alvo e exploração — sem copiar conteúdo protegido de Talisman Online.

## Estado atual

O jogo já possui um primeiro loop de RPG jogável em Godot 4.7.x com foco em hardware fraco:

- GDScript;
- GL Compatibility;
- resolução-base 960×540;
- movimento WASD relativo à câmera;
- câmera estilo MMORPG;
- seleção de alvo com TAB;
- ataque com ESPAÇO;
- interação com E;
- HP do jogador e inimigos;
- inimigos perseguem e contra-atacam;
- morte e respawn;
- XP e level-up;
- HUD com vida, XP, nível, alvo, missão e mensagens;
- primeira região jogável;
- NPC com missão;
- ciclo completo de aceitar → cumprir → entregar missão;
- smoke test headless com integração do loop principal.

## Primeira região

A jornada começa no **Acampamento do Peregrino**, segue pelo **Caminho dos Olivais** e termina nas **Ruínas Antigas**.

Inimigos atuais:

1. Chacal do Deserto — rápido e fraco;
2. Saqueador do Vale — dificuldade intermediária;
3. Guardião das Ruínas — mais resistente e perigoso.

NPC atual:

- **Eliabe — Guardião do Acampamento**.

Primeira missão:

- **Limpe o Caminho** — fale com Eliabe, derrote 3 criaturas hostis, retorne ao acampamento e receba XP.

## Controles

| Ação | Tecla |
|---|---|
| Mover | WASD |
| Selecionar inimigo próximo | TAB |
| Atacar | ESPAÇO |
| Interagir / falar | E |

## Estrutura

```text
scenes/
  enemies/
  npcs/
  player/
  world/
scripts/
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

A arquitetura completa e o roadmap estão em `docs/ARCHITECTURE.md`.

## Assets

O projeto só adotará conteúdo externo com licença compatível e origem registrada. As fontes aprovadas inicialmente são Quaternius e Kenney em packs explicitamente CC0. Consulte `docs/ASSET_POLICY.md`.

Não serão usados modelos, mapas, texturas, sons ou personagens extraídos de jogos comerciais.

O cenário atual usa geometria 3D leve de protótipo para validar gameplay e desempenho. A próxima etapa visual substituirá essas primitives por assets CC0 sem alterar a lógica do jogo.

## Teste rápido

Abra `project.godot` no Godot 4.7.x e execute o projeto.

### Smoke test headless

```bash
godot --headless --path . --script tests/smoke_test.gd
```

O teste automatizado verifica:

1. carregamento das cenas e scripts;
2. inputs essenciais;
3. instanciação da primeira região;
4. presença de Eliabe;
5. presença dos três inimigos;
6. sistema de interação;
7. início da missão;
8. progresso após derrotas;
9. entrega da missão;
10. recompensa e progressão do jogador.

## Próximo marco

**Direção de arte jogável**:

- substituir personagem provisório por modelo animado CC0;
- substituir inimigos provisórios por criaturas/hostis estilizados;
- trocar tendas, árvores e ruínas por assets modulares otimizados;
- adicionar animações de idle, caminhada e ataque;
- manter o jogo leve no GL Compatibility;
- preparar a saída para a segunda região.
