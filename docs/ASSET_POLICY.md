# Política de Assets

O projeto não reutiliza artes, mapas, modelos, texturas, sons, nomes ou personagens extraídos de Talisman Online ou de outros jogos comerciais.

## Fontes aprovadas inicialmente

### Quaternius
Uso preferencial para personagens, criaturas, vegetação e estruturas 3D quando o pack específico estiver marcado como **CC0**.

Candidatos para o protótipo/produção:
- RPG Character Pack
- Universal Base Characters
- Modular Character Outfits - Fantasy
- Ultimate Monsters
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
- alterações realizadas;
- pasta onde é usado.

Esse registro ficará em `assets/ATTRIBUTION.md` quando os primeiros arquivos externos forem importados.

## Regras de performance

Antes de um asset entrar na build principal:

- preferir glTF/GLB para Godot;
- limitar materiais e texturas desnecessárias;
- compactar texturas;
- evitar modelos com densidade incompatível com hardware alvo;
- usar LOD/HLOD quando a cena crescer;
- testar custo de draw calls e memória;
- não importar o pack inteiro quando apenas poucos modelos forem usados.

## Regra de identidade

Assets CC0 são matéria-prima, não identidade final. Modelos poderão receber variações de materiais, proporções, acessórios, iluminação e composição para criar uma linguagem visual própria do Reino da Promessa.
