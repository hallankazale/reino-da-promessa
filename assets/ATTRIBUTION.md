# Registro de Assets Externos

Este arquivo registra a procedência dos arquivos externos distribuídos com **Reino da Promessa**.

> CC0 não exige atribuição, mas mantemos este manifesto por rastreabilidade, manutenção e auditoria de licença.

## Importação 2026-09-08 — personagens e criaturas

Os modelos abaixo são de **Quaternius**, publicados em **CC0 1.0 / domínio público**. Para tornar a build reprodutível, os bytes GLB foram obtidos de um espelho público que documenta a origem Quaternius e sua conversão. O espelho foi fixado no commit `71bbfbdfacd118196994b26da68eec1876d55c6b`.

| Arquivo no projeto | Uso no jogo | Origem original | Transformação registrada pelo espelho | SHA-256 |
|---|---|---|---|---|
| `third_party/quaternius/pilgrim_guardian.glb` | personagem do jogador | Quaternius — Animated Knight Pack: https://quaternius.com/packs/knightcharacter.html | FBX → GLB via Blender | `71d710f21e01566e4c4d8fb3e2f06af9222f62132a01455855fd9353ee54a685` |
| `third_party/quaternius/wasteland_specter.glb` | Espectro do Ermo | Quaternius — Ultimate Monsters: https://quaternius.com/packs/ultimatemonsters.html | glTF → GLB | `430fb42e7b1c0af455ff89cd5bfdf490d133658e844935d5ffe44e9d9912ffd4` |
| `third_party/quaternius/skeleton_raider.glb` | Esqueleto Saqueador | Quaternius — Animated Monster Pack: https://quaternius.com/packs/animatedmonster.html | FBX → GLB via Blender | `95f5ca2f6851d4c47d8a8830d040177e5e19eee7fbdcd78cc517aed4e6ba70a7` |
| `third_party/quaternius/ruins_demon.glb` | Demônio das Ruínas | Quaternius — Ultimate Monsters: https://quaternius.com/packs/ultimatemonsters.html | glTF → GLB | `3ed33ef522b40b3dcee0a5d6790cc243779b573ed1d79134ad834bf92e0f9487` |

### Espelho reprodutível

- Repositório: `ilrein/warptracker`
- Commit fixado: `71bbfbdfacd118196994b26da68eec1876d55c6b`
- Manifesto de origem do espelho: `ASSETS.md`
- Importador deste projeto: `scripts/import_cc0_art.sh`
- Checksums locais: `assets/third_party/quaternius/SHA256SUMS.txt`

## Assets procedurais

O terreno, tendas, oliveiras, fogueira e ruínas usados nesta etapa continuam sendo gerados pelo código do próprio projeto e não dependem de conteúdo de terceiros.

## Regra permanente

Nenhum arquivo extraído de Talisman Online ou de outro jogo comercial pode ser adicionado a este projeto. Toda nova dependência visual ou sonora externa deve receber uma entrada neste manifesto antes de entrar na `main`.
