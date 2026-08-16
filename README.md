# Reino da Promessa

Protótipo de RPG 3D original com fantasia bíblica épica, inspirado apenas em estruturas clássicas de MMORPGs como Talisman Online. Não utiliza nomes, mapas, personagens, artes ou assets protegidos do jogo de referência.

## Objetivo do protótipo

Validar o ciclo mínimo jogável em hardware fraco:

1. Abrir o jogo.
2. Controlar o personagem com WASD.
3. Câmera acompanhar o jogador.
4. Caminhar pelo primeiro mapa de teste.
5. Em seguida: inimigo, combate, XP e level.

## Tecnologia

- Godot 4
- GDScript
- Renderer: GL Compatibility
- Plataforma inicial: Linux/PC

A escolha prioriza baixo consumo de recursos, desenvolvimento rápido e futura exportação para Android.

## Estrutura

```text
scenes/
  player/
    player.tscn
  world/
    main.tscn
scripts/
  player/
    player_controller.gd
assets/
  characters/
  environments/
  enemies/
  items/
  ui/
```

As pastas de assets serão adicionadas conforme conteúdo real entrar no projeto; não serão criadas pastas vazias apenas para aparência.

## Controles

- W: frente
- S: trás
- A: esquerda
- D: direita

## Teste atual

Abra `project.godot` no Godot 4 e execute o projeto. O personagem provisório é uma cápsula 3D. Ela será substituída por um modelo final posteriormente, preservando o controlador.

### Critérios de aprovação

- O projeto abre sem erros.
- O mapa aparece.
- A cápsula não atravessa o chão.
- WASD movimenta o personagem.
- A câmera acompanha o personagem.
- O jogo continua responsivo em hardware fraco.

## Próximo marco

Adicionar primeiro inimigo com vida, detecção, ataque básico, morte, recompensa de XP e progressão de nível.
