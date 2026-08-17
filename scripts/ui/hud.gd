extends CanvasLayer

@onready var player = get_node("../Player")
@onready var stats_label = $MarginContainer/StatsLabel

func _process(_delta):
    if player == null:
        return

    stats_label.text = "Nivel %d  |  XP %d/%d  |  Ataque %d  |  ESPACO = atacar" % [
        player.level,
        player.xp,
        player.xp_to_next_level,
        player.attack_damage
    ]
