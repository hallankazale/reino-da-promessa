extends Node3D

signal health_changed(current_health: int, max_health: int)
signal died
signal respawned

@export var display_name: String = "Inimigo de Treino"
@export var max_health: int = 30
@export var xp_reward: int = 10
@export var attack_damage: int = 6
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.25
@export var respawn_delay: float = 3.0

var current_health: int = 0
var _attack_cooldown_remaining: float = 0.0
var _is_alive: bool = true

@onready var name_label: Label3D = $NameLabel
@onready var health_label: Label3D = $HealthLabel
@onready var health_fill: MeshInstance3D = $HealthBar/Fill
@onready var selection_marker: MeshInstance3D = $SelectionMarker

func _ready() -> void:
	current_health = max_health
	add_to_group("enemies")
	name_label.text = display_name
	selection_marker.visible = false
	_update_health_ui()

func _process(delta: float) -> void:
	if not _is_alive:
		return

	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)
	if _attack_cooldown_remaining > 0.0:
		return

	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player) or not player is Node3D:
		return
	if player.has_method("is_alive") and not player.is_alive():
		return

	if global_position.distance_to(player.global_position) <= attack_range:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage, self)
			_attack_cooldown_remaining = attack_cooldown

func take_damage(amount: int, attacker: Node = null) -> void:
	if not _is_alive or amount <= 0:
		return

	current_health = maxi(current_health - amount, 0)
	_update_health_ui()
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		_die(attacker)

func set_selected(is_selected: bool) -> void:
	selection_marker.visible = is_selected and _is_alive

func is_alive() -> bool:
	return _is_alive

func _die(attacker: Node) -> void:
	if not _is_alive:
		return

	_is_alive = false
	selection_marker.visible = false
	visible = false
	died.emit()

	if attacker != null and attacker.has_method("add_xp"):
		attacker.add_xp(xp_reward)

	await get_tree().create_timer(respawn_delay).timeout
	_respawn()

func _respawn() -> void:
	current_health = max_health
	_attack_cooldown_remaining = 0.0
	_is_alive = true
	visible = true
	_update_health_ui()
	health_changed.emit(current_health, max_health)
	respawned.emit()

func _update_health_ui() -> void:
	var health_ratio := 0.0
	if max_health > 0:
		health_ratio = float(current_health) / float(max_health)

	health_label.text = "HP %d/%d" % [current_health, max_health]
	health_fill.scale.x = maxf(health_ratio, 0.001)
	health_fill.position.x = -0.75 * (1.0 - health_ratio)
