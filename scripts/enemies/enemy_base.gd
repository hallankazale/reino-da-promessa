extends CharacterBody3D

signal health_changed(current_health: int, max_health: int)
signal defeated(enemy_kind: String)
signal loot_requested(enemy_kind: String, world_position: Vector3)
signal died
signal respawned

const DAMAGE_POPUP_SCENE: PackedScene = preload("res://scenes/ui/damage_popup.tscn")

@export_category("Identity")
@export var display_name: String = "Criatura Hostil"
@export var enemy_kind: String = "hostile"
@export var body_color: Color = Color(0.62, 0.18, 0.15, 1.0)

@export_category("Visual")
@export var visual_scene: PackedScene
@export var visual_target_height: float = 1.45
@export var visual_feet_y: float = -0.7
@export var visual_yaw_degrees: float = 0.0
@export var death_visual_delay: float = 0.55
@export var health_ui_linger: float = 2.0

@export_category("Combat")
@export var max_health: int = 30
@export var xp_reward: int = 10
@export var attack_damage: int = 6
@export var attack_range: float = 1.8
@export var attack_cooldown: float = 1.25
@export var aggro_range: float = 8.0
@export var respawn_delay: float = 5.0

@export_category("Movement")
@export var move_speed: float = 2.0
@export var gravity_force: float = 18.0
@export var turn_speed: float = 7.0

var current_health: int = 0
var _attack_cooldown_remaining: float = 0.0
var _is_alive: bool = true
var _is_selected: bool = false
var _health_ui_timer: float = 0.0
var _spawn_transform: Transform3D

@onready var body: MeshInstance3D = $Body
@onready var visual_adapter: Node = $VisualAdapter
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var name_label: Label3D = $NameLabel
@onready var health_label: Label3D = $HealthLabel
@onready var health_bar: Node3D = $HealthBar
@onready var health_fill: MeshInstance3D = $HealthBar/Fill
@onready var selection_marker: MeshInstance3D = $SelectionMarker

func _ready() -> void:
	_spawn_transform = global_transform
	current_health = max_health
	add_to_group("enemies")
	name_label.text = display_name
	selection_marker.visible = false
	_set_health_ui_visible(false)
	_apply_body_color()
	_configure_visual()
	_update_health_ui()

func _physics_process(delta: float) -> void:
	_update_health_ui_visibility(delta)
	if not _is_alive:
		return

	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)
	_apply_gravity(delta)

	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player) or not player is Node3D:
		_stop_horizontal_motion()
		move_and_slide()
		return
	if player.has_method("is_alive") and not player.is_alive():
		_stop_horizontal_motion()
		move_and_slide()
		return

	var distance := global_position.distance_to(player.global_position)
	if distance > aggro_range:
		_stop_horizontal_motion()
		move_and_slide()
		return

	_face_target(player.global_position, delta)
	if distance > attack_range:
		_chase_target(player.global_position)
	else:
		_stop_horizontal_motion()
		_try_attack(player)

	move_and_slide()

func take_damage(amount: int, attacker: Node = null) -> void:
	if not _is_alive or amount <= 0:
		return

	_spawn_damage_popup(amount, Color(1.0, 0.78, 0.25, 1.0))
	current_health = maxi(current_health - amount, 0)
	_health_ui_timer = maxf(health_ui_linger, 0.0)
	_set_health_ui_visible(true)
	_update_health_ui()
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		_die(attacker)

func set_selected(is_selected: bool) -> void:
	_is_selected = is_selected and _is_alive
	selection_marker.visible = _is_selected
	_set_health_ui_visible(_is_selected or _health_ui_timer > 0.0)

func is_alive() -> bool:
	return _is_alive

func get_display_name() -> String:
	return display_name

func _chase_target(target_position: Vector3) -> void:
	var direction := target_position - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		_stop_horizontal_motion()
		return

	direction = direction.normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

func _stop_horizontal_motion() -> void:
	velocity.x = 0.0
	velocity.z = 0.0

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity_force * delta

## Facing is presentation-only. The physics body stays orientation-neutral so a
## capsule collider can never fight the imported rig orientation. ModelAdapter
## owns the visual forward convention and each asset's yaw correction.
func _face_target(target_position: Vector3, delta: float) -> void:
	var direction := target_position - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		return
	direction = direction.normalized()

	if visual_adapter != null and visual_adapter.has_method("face_direction"):
		visual_adapter.face_direction(direction, delta, turn_speed)
		return

	# Safe fallback for an enemy scene without ModelAdapter. Godot gameplay
	# convention is -Z forward, matching the player controller.
	var target_angle := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_angle, minf(turn_speed * delta, 1.0))

func _try_attack(player: Node) -> void:
	if _attack_cooldown_remaining > 0.0:
		return
	if player.has_method("take_damage"):
		if visual_adapter != null and visual_adapter.has_method("play_attack"):
			visual_adapter.play_attack(minf(attack_cooldown, 0.65))
		player.take_damage(attack_damage, self)
		_attack_cooldown_remaining = attack_cooldown

func _die(attacker: Node) -> void:
	if not _is_alive:
		return

	_is_alive = false
	_is_selected = false
	_health_ui_timer = 0.0
	velocity = Vector3.ZERO
	selection_marker.visible = false
	_set_health_ui_visible(false)
	collision_shape.set_deferred("disabled", true)
	if visual_adapter != null and visual_adapter.has_method("play_death"):
		visual_adapter.play_death()
	died.emit()
	defeated.emit(enemy_kind)
	loot_requested.emit(enemy_kind, global_position)

	if attacker != null and attacker.has_method("add_xp"):
		attacker.add_xp(xp_reward)

	var visible_death_time := minf(death_visual_delay, respawn_delay)
	if visible_death_time > 0.0:
		await get_tree().create_timer(visible_death_time).timeout
	visible = false

	var hidden_time := maxf(respawn_delay - visible_death_time, 0.0)
	if hidden_time > 0.0:
		await get_tree().create_timer(hidden_time).timeout
	_respawn()

func _respawn() -> void:
	global_transform = _spawn_transform
	current_health = max_health
	_attack_cooldown_remaining = 0.0
	_health_ui_timer = 0.0
	_is_selected = false
	_is_alive = true
	visible = true
	selection_marker.visible = false
	_set_health_ui_visible(false)
	collision_shape.set_deferred("disabled", false)
	if visual_adapter != null and visual_adapter.has_method("reset_state"):
		visual_adapter.reset_state()
	_update_health_ui()
	health_changed.emit(current_health, max_health)
	respawned.emit()

func _configure_visual() -> void:
	if visual_adapter == null or not visual_adapter.has_method("configure"):
		return
	visual_adapter.configure(
		visual_scene,
		visual_target_height,
		visual_yaw_degrees,
		visual_feet_y
	)

func _apply_body_color() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = body_color
	material.roughness = 0.95
	body.material_override = material

func _update_health_ui_visibility(delta: float) -> void:
	if _is_selected:
		_set_health_ui_visible(true)
		return
	if _health_ui_timer <= 0.0:
		_set_health_ui_visible(false)
		return
	_health_ui_timer = maxf(_health_ui_timer - delta, 0.0)
	_set_health_ui_visible(_health_ui_timer > 0.0)

func _set_health_ui_visible(is_visible: bool) -> void:
	if is_instance_valid(name_label):
		name_label.visible = is_visible
	if is_instance_valid(health_label):
		health_label.visible = is_visible
	if is_instance_valid(health_bar):
		health_bar.visible = is_visible

func _update_health_ui() -> void:
	var denominator := maxf(float(max_health), 1.0)
	var ratio := clampf(float(current_health) / denominator, 0.0, 1.0)
	health_label.text = "HP %d/%d" % [current_health, max_health]
	health_fill.scale.x = maxf(ratio, 0.001)
	health_fill.position.x = -0.5 * (1.0 - ratio)

func _spawn_damage_popup(amount: int, color: Color) -> void:
	if DAMAGE_POPUP_SCENE == null:
		return
	var popup := DAMAGE_POPUP_SCENE.instantiate()
	if not popup is Node3D:
		popup.queue_free()
		return
	get_tree().current_scene.add_child(popup)
	(popup as Node3D).global_position = global_position + Vector3(0, 2.1, 0)
	if popup.has_method("setup"):
		popup.setup(amount, color)
