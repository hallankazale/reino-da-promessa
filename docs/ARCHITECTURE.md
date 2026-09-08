# Arquitetura — Reino da Promessa

## Objetivo

Construir um RPG 3D de fantasia bíblica com sensação de MMORPG clássico, começando offline e local para validar gameplay, performance e direção de arte antes de adicionar infraestrutura online.

## Princípios

1. **Gameplay antes de conteúdo em massa** — nenhum mapa gigante antes de combate, progressão e navegação estarem sólidos.
2. **Baixo custo de hardware** — GL Compatibility, geometrias simples no protótipo, LOD e assets otimizados na produção.
3. **Lógica desacoplada da arte** — player, combate, progressão, quests e HUD não dependem de um modelo 3D específico.
4. **Arte por contrato semântico** — gameplay pede `play_attack()`, `play_death()` ou locomotion; não conhece nomes de clips, ossos ou meshes importados.
5. **Interação reutilizável** — NPCs, baús, portas e vendedores usam o mesmo contrato `interact(player)`.
6. **Dados antes de duplicação** — itens, inimigos, classes e quests migrarão para Resources/arquivos de dados conforme o volume crescer.
7. **Multiplayer só depois do vertical slice** — rede prematura aumenta drasticamente custo de depuração e segurança.

## Camadas

```text
scenes/
  player/        física + composição do jogador
  enemies/       cena-base reutilizável de entidades hostis
  npcs/          NPCs e pontos de interação
  world/         mapas e composição de regiões

scripts/
  art/           adaptação de modelos/animações importados
  player/        movimento, seleção, combate, interação e progressão
  enemies/       IA reutilizável de perseguição/combate/respawn
  npcs/          contratos de interação com NPCs
  quests/        estado e progressão de missões
  camera/        câmera estilo MMORPG
  ui/            apresentação e feedback ao jogador
  world/         composição procedural leve das regiões

assets/
  third_party/   arquivos externos aprovados e rastreados
  ATTRIBUTION.md manifesto de procedência/licença

data/            classes, itens, quests e drops quando o volume justificar
tests/           smoke tests de recursos + integração do loop jogável
```

## Fluxo atual

```text
Jogador nasce no Acampamento do Peregrino
        ↓
E interage com Eliabe
        ↓
Missão "Limpe o Caminho" inicia
        ↓
Jogador segue pelo Caminho dos Olivais
        ↓
TAB seleciona inimigo / ESPAÇO ataca
        ↓
3 criaturas derrotadas
        ↓
Missão fica pronta para entrega
        ↓
Jogador retorna a Eliabe
        ↓
Missão concluída → recompensa XP
        ↓
Progressão de nível continua normalmente
```

## Primeira região

A primeira região é intencionalmente compacta e legível:

```text
Acampamento do Peregrino
        ↓
Espectro do Ermo
        ↓
Caminho dos Olivais
        ↓
Esqueleto Saqueador
        ↓
Ruínas Antigas
        ↓
Demônio das Ruínas
```

O cenário ainda usa primitives geradas por `first_region_builder.gd`. Personagem e inimigos já usam modelos animados CC0. A próxima troca ambiental pode acontecer sem alterar player, combate, quests, NPCs ou HUD.

## Camada de arte animada

`ModelAdapter` é a fronteira entre gameplay e arquivos importados.

```text
Player / Enemy AI
        ↓ intenção semântica
ModelAdapter
        ↓ descoberta de clips
AnimationPlayer do GLB
```

Responsabilidades do adaptador:

- instanciar o `PackedScene` importado;
- medir bounds e normalizar altura;
- alinhar os pés à cápsula física;
- ocultar o fallback procedural quando o modelo carrega;
- descobrir clips por intenção (`idle`, `run`, `attack`, `death` etc.);
- tocar loops e one-shots sem expor detalhes do asset ao gameplay.

Assim um modelo pode ser substituído sem reescrever IA ou combate.

## Contratos principais

### Player → Interactables
O player busca o objeto mais próximo no grupo `interactables` dentro do alcance e chama:

```text
interactable.interact(player)
```

Isso evita criar teclas e fluxos exclusivos para cada tipo de objeto.

### Gameplay → ModelAdapter
Controladores chamam apenas métodos semânticos:

```text
visual_adapter.play_attack()
visual_adapter.play_death()
visual_adapter.reset_state()
```

Locomoção é inferida pela velocidade horizontal do `CharacterBody3D`.

### Enemy → QuestManager
Todo inimigo-base emite `defeated(enemy_kind)` uma única vez por morte. O `QuestManager` escuta esse evento e decide se a derrota conta para a missão ativa.

### QuestManager → HUD
O sistema de missões expõe sinais de estado e mensagem. O HUD apenas apresenta esses eventos; ele não decide regras de missão.

## Pipeline de assets

Arquivos externos só entram com origem/licença registrada em `assets/ATTRIBUTION.md`.

O importador `scripts/import_cc0_art.sh` fixa a versão do espelho e gera SHA-256 dos GLBs. O CI usa `godot --import` antes do smoke test, garantindo que recursos não nativos terminem a importação antes dos testes.

## Roadmap técnico

### Marco 1 — Combate base ✅
- movimento e câmera
- target lock
- HP de player/inimigo
- ataque e cooldown
- morte/respawn
- XP e level
- HUD

### Marco 2 — Mundo jogável ✅
- Acampamento do Peregrino
- Caminho dos Olivais
- Ruínas Antigas
- 3 perfis de inimigos
- colisões essenciais
- NPC de missão
- ciclo de missão com recompensa

### Marco 2.5 — Direção de arte jogável — em andamento
- ✅ personagem animado CC0
- ✅ três inimigos animados CC0
- ✅ adaptador visual desacoplado
- ✅ importação/QA de GLB no CI
- ⏳ cenário modular otimizado
- ⏳ feedback de impacto/dano
- ⏳ portal/saída para segunda região

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
- variações de personagem
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

Quando a fase online começar, o cliente nunca será autoridade para:
- dinheiro;
- XP;
- inventário;
- dano;
- posição válida de combate;
- drops;
- conclusão de quest.

Esses estados serão validados pelo servidor para reduzir trapaças, duplicação de itens e manipulação de pacotes.
