extends Node3D

@export var max_health = 30
@export var xp_reward = 10

var current_health = 0

func _ready():
    current_health = max_health
    add_to_group("enemies")

func take_damage(amount, attacker):
    current_health -= amount

    if current_health <= 0:
        if attacker != null and attacker.has_method("add_xp"):
            attacker.add_xp(xp_reward)
        queue_free()
