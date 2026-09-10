# Reino da Promessa — Direcao Visual

## Regra de produto
A direcao visual deve transmitir fantasia MMORPG estilizada, com leitura clara de combate, areas sagradas/hostis distintas e interface ornamentada sem copiar UI, personagens ou assets de outros jogos.

## Pilares
- Silhueta forte para jogador, NPCs e inimigos.
- Dourado para progresso/quest, vermelho para perigo, ciano/violeta para magia.
- HUD compacto com molduras e hierarquia forte.
- Pontos focais luminosos em ruinas, fontes e portais.
- Props modulares e repeticao controlada para manter performance em GPUs antigas.
- Camada de apresentacao desacoplada de colisao, quests e combate.

## Performance
- Luzes decorativas sem sombras por padrao.
- Evitar materiais transparentes em excesso.
- MultiMesh para vegetacao repetida.
- Efeitos visuais devem poder ser desativados sem afetar gameplay.
