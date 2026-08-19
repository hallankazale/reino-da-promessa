# Guerreiro Principal — Reino da Promessa

## Direção visual
Guerreiro humano de fantasia bíblica épica, inspirado no conceito aprovado: armadura marfim, bronze e couro escuro, capa clara, detalhes dourados, espada e escudo. O visual deve parecer antigo, nobre e funcional, sem copiar personagens, símbolos ou equipamentos de outras franquias.

## Pipeline definitivo
- Modelo final: Blender -> GLB/GLTF 2.0.
- Rig: esqueleto humanoide único, root motion desabilitado inicialmente.
- Animações mínimas: idle, walk, run, attack_01, attack_02, block, hit, death.
- Texturas: PBR (base color, normal, roughness, metallic), 2K como padrão; 4K apenas para material mestre/high-end.
- Orçamento inicial: 25k–60k triângulos para o personagem equipado.
- LODs futuros: LOD0, LOD1 e LOD2.

## Contrato com o Godot
A lógica de movimento, câmera, alvo e combate não deve depender da malha final. O personagem visual fica como filho de `Player/Visual`, permitindo substituir o protótipo geométrico pelo GLB sem alterar `player_controller.gd`.

## Estrutura planejada
```text
assets/characters/player/
  warrior.glb
  textures/
  materials/
  animations/
scenes/player/
  player.tscn
scripts/player/
  player_controller.gd
  humanoid_animator.gd
```

## Critérios de validação
1. Silhueta legível a distância de câmera MMORPG.
2. Espada e escudo acompanham corretamente as mãos.
3. Capa não atravessa excessivamente o corpo.
4. Movimento, TAB, ataque, HP e XP continuam funcionando.
5. Importação sem erros no Godot 4.
