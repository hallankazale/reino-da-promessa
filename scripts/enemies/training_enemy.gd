extends Node3D

@export var display_name = "Inimigo de Treino"
@export var max_health = 30
@export var xp_reward = 10

var current_health = 0

@onready var name_label: Label3D = $NameLabel
@onready var health_label: Label3D = $HealthLabel
@onready var health_fill: MeshInstance3D = $HealthBar/Fill
@onready var selection_marker: MeshInstance3D = $SelectionMarker

func _ready():
	current_health = max_health
	add_to_group("enemies")
	name_label.text = display_name
	selection_marker.visible = false
	_update_health_ui()

func take_damage(amount, attacker):
	current_health = max(current_health - amount, 0)
	_update_health_ui()

	if current_health <= 0:
		if attacker != null and attacker.has_method("add_xp"):
			attacker.add_xp(xp_reward)
		queue_free()

func set_selected(is_selected):
	selection_marker.visible = is_selected

func _update_health_ui():
	var health_ratio = 0.0
	if max_health > 0:
		health_ratio = float(current_health) / float(max_health)

	health_label.text = "HP %d/%d" % [current_health, max_health]
	health_fill.scale.x = max(health_ratio, 0.001)
	health_fill.position.x = -0.75 * (1.0 - health_ratio)
