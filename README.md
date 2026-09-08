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
- personagem do jogador com modelo 3D animado CC0;
- três inimigos com modelos e animações próprios;
- adaptação automática de idle, movimento, ataque e morte;
- fallback visual simples preservado durante desenvolvimento;
- smoke test headless validando gameplay, assets e animações.

## Primeira região

A jornada começa no **Acampamento do Peregrino**, segue pelo **Caminho dos Olivais** e termina nas **Ruínas Antigas**.

Inimigos atuais:

1. **Espectro do Ermo** — rápido e fraco;
2. **Esqueleto Saqueador** — dificuldade intermediária;
3. **Demônio das Ruínas** — mais resistente e perigoso.

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
assets/
  third_party/
    quaternius/
scenes/
  enemies/
  npcs/
  player/
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

A arquitetura completa e o roadmap estão em `docs/ARCHITECTURE.md`.

## Assets

Os primeiros quatro modelos animados são de **Quaternius**, distribuídos em **CC0** e registrados em `assets/ATTRIBUTION.md` com origem, transformação conhecida e SHA-256.

O projeto mantém um importador reprodutível em `scripts/import_cc0_art.sh`. Nenhum modelo, mapa, textura, som ou personagem extraído de Talisman Online ou de outro jogo comercial é usado.

O terreno, tendas, oliveiras, fogueira e ruínas ainda são geometria procedural leve. A troca do cenário será feita separadamente para podermos medir impacto de desempenho antes/depois.

## Teste rápido

Abra `project.godot` no Godot 4.7.x e execute o projeto.

### Smoke test headless

Antes do smoke test em um clone novo, importe os recursos externos:

```bash
godot --headless --path . --import
godot --headless --path . --script tests/smoke_test.gd
```

O teste automatizado verifica:

1. carregamento das cenas e scripts;
2. importação dos quatro GLBs CC0;
3. presença de animações nos modelos;
4. instanciação da primeira região;
5. presença de Eliabe e dos três inimigos;
6. sistema de interação;
7. início e progresso da missão;
8. entrega da missão;
9. recompensa e progressão do jogador.

## Próximo marco

**Cenário modular + feedback de combate**:

- substituir tendas, oliveiras e ruínas procedurais por um conjunto visual otimizado;
- manter proxies de colisão simples e separados da arte;
- adicionar feedback de dano e impacto;
- melhorar leitura visual do alvo selecionado;
- preparar portal/saída para a segunda região;
- medir desempenho antes de aumentar densidade do mapa.
