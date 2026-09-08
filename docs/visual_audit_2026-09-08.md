# Auditoria visual — 2026-09-08

Print validado após o Marco 6.

## Problemas observados
- O protagonista ainda aparece com o fallback procedural em blocos.
- Eliabe também continua procedural e destoa dos NPCs importados.
- As tendas e a composição do acampamento ainda parecem protótipo.
- HUD ocupa área demais da tela e compete com a leitura do mundo.

## Causa técnica confirmada
`scenes/player/player.tscn` ainda referencia o modelo antigo `pilgrim_guardian.glb` com `use_imported_model = false`, portanto o KayKit Knight nunca é instanciado no jogador.

## Próxima correção
1. Ativar KayKit Knight no protagonista.
2. Substituir Eliabe por KayKit Rogue_Hooded como guardião/scout, mantendo seu papel de quest giver.
3. Manter fallback procedural apenas como contingência invisível.
4. Em seguida, substituir tendas/arquitetura por kit medieval CC0 e reduzir HUD.
