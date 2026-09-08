# Política de Assets

O projeto não reutiliza artes, mapas, modelos, texturas, sons, nomes ou personagens extraídos de Talisman Online ou de outros jogos comerciais.

## Fontes aprovadas

### Quaternius
Uso preferencial para personagens, criaturas, vegetação e estruturas 3D quando o pack específico estiver marcado como **CC0**.

Packs usados ou candidatos:
- Animated Knight Pack
- Animated Monster Pack
- Ultimate Monsters
- RPG Character Pack
- Universal Base Characters
- Modular Character Outfits - Fantasy
- Ultimate Nature Pack
- Ultimate Modular Ruins Pack

Fonte: https://quaternius.com/

### Kenney
Uso preferencial para estruturas e props estilizados quando o pack específico estiver marcado como **Creative Commons CC0**.

Candidatos:
- Fantasy Town Kit
- Retro Fantasy Kit
- Modular Dungeon Kit

Fonte: https://kenney.nl/assets

## Registro obrigatório

Todo asset externo adicionado ao repositório deverá ter, no mínimo:

- nome do pack;
- autor/origem;
- URL de origem;
- licença;
- data de obtenção;
- transformação/conversão conhecida;
- arquivo/pasta onde é usado;
- hash SHA-256 quando o binário for distribuído com o projeto.

O registro oficial fica em `assets/ATTRIBUTION.md`.

## Importações reprodutíveis

Quando um asset externo for obtido de um espelho ou repositório intermediário:

1. a origem original e a licença precisam estar documentadas;
2. o espelho deve ser fixado em commit/versão imutável sempre que possível;
3. o importador deve validar o download;
4. o binário final deve receber SHA-256;
5. atualizações de asset entram por branch e CI, nunca silenciosamente na `main`.

O primeiro importador reprodutível está em `scripts/import_cc0_art.sh`.

## Regras de performance

Antes de um asset entrar na build principal:

- preferir glTF/GLB para Godot;
- importar somente modelos realmente usados;
- limitar materiais e texturas desnecessárias;
- compactar texturas quando aplicável;
- evitar modelos com densidade incompatível com hardware alvo;
- usar LOD/HLOD quando a cena crescer;
- testar custo de draw calls e memória;
- manter fallback/proxy simples durante desenvolvimento quando isso reduzir risco de regressão.

## Regra de identidade

Assets CC0 são matéria-prima, não identidade final. Modelos poderão receber variações de materiais, proporções, acessórios, iluminação e composição para criar uma linguagem visual própria do Reino da Promessa.

A direção atual usa personagens e criaturas baixas em custo como primeiro passe, enquanto terreno e cenário permanecem procedurais. Isso permite validar animação e escala antes de importar um kit ambiental maior.
