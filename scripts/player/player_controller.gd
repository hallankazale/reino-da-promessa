extends CharacterBody3D

signal health_changed(current_health: int, max_health: int)
signal stats_changed(level: int, xp: int, xp_to_next_level: int, attack_damage: int)
signal target_changed(target: Node3D)
signal died
signal respawned

const DAMAGE_POPUP_SCENE: PackedScene = preload("res://scenes/ui/damage_popup.tscn")

@export_category("Movement")
@export var move_speed: float = 4.5
@export var acceleration: float = 12.0
@export var gravity_force: float = 18.0
@export var turn_speed: float = 10.0

@export_category("Step traversal")
## Regra global do projeto: degraus baixos nao podem virar paredes invisiveis.
## O Player sobe automaticamente superficies com topo caminhavel ate esta altura.
@export_range(0.10, 0.70, 0.01) var max_step_height: float = 0.45
@export_range(0.01, 0.20, 0.01) var step_landing_margin: float = 0.04

@export_category("Combat")
@export var max_health: int = 100
@export var attack_damage: int = 10
@export var attack_range: float = 2.2
@export var attack_cooldown: float = 0.55
@export var target_search_range: float = 12.0
@export var respawn_delay: float = 2.0
@export var death_visual_delay: float = 0.6

@export_category("Interaction")
@export var interaction_range: float = 3.2

var current_health: int
var level: int = 1
var xp: int = 0
var xp_to_next_level: int = 20
var selected_target: Node3D = null

var _attack_cooldown_remaining: float = 0.0
var _spawn_transform: Transform3D
var _is_alive: bool = true

@onready var visual_adapter: Node = get_node_or_null("VisualAdapter")

func _ready() -> void:
	_spawn_transform = global_transform
	current_health = max_health
	add_to_group("player")
	# A fisica nunca gira para acompanhar a arte. O adaptador visual assume a
	# orientacao do cavaleiro e preserva a camera/colisao completamente desacopladas.
	if visual_adapter != null and visual_adapter.has_method("face_direction"):
		visual_adapter.face_direction(Vector3(0.0, 0.0, -1.0), 0.0, turn_speed)
	_emit_full_state()

func _physics_process(delta: float) -> void:
	if not _is_alive:
		return

	_attack_cooldown_remaining = maxf(_attack_cooldown_remaining - delta, 0.0)
	_handle_movement(delta)

	if Input.is_action_just_pressed("target_next"):
		_select_nearest_target()

	if Input.is_action_just_pressed("attack"):
		_attack_selected_target()

	if Input.is_action_just_pressed("interact"):
		_interact_with_nearest()

func _handle_movement(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)

	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	var desired_direction := _camera_relative_direction(input_vector)
	velocity.x = move_toward(velocity.x, desired_direction.x * move_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_direction.z * move_speed, acceleration * delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity_force * delta

	# O CharacterBody3D fica neutro. Somente o visual olha para a direcao em que
	# o jogador realmente se desloca, evitando o duplo giro do KayKit + yaw local.
	if desired_direction.length_squared() > 0.001:
		if visual_adapter != null and visual_adapter.has_method("face_direction"):
			visual_adapter.face_direction(desired_direction, delta, turn_speed)

	# Godot trata a face vertical de um degrau como parede. Antes do movimento
	# normal, tentamos descobrir se existe um topo caminhavel logo acima dela.
	# A funcao altera apenas Y; X/Z continuam sendo resolvidos por move_and_slide().
	var horizontal_motion := Vector3(velocity.x, 0.0, velocity.z) * delta
	if _try_step_up(horizontal_motion):
		velocity.y = 0.0

	move_and_slide()

## Sobe um degrau baixo sem adicionar rampas especiais ao mapa.
## Retorna true somente quando ha obstaculo horizontal, espaco livre acima e um
## piso caminhavel dentro de max_step_height. Paredes altas continuam bloqueando.
func _try_step_up(horizontal_motion: Vector3) -> bool:
	if max_step_height <= 0.0:
		return false
	if horizontal_motion.length_squared() <= 0.000001:
		return false
	if not is_on_floor():
		return false

	# Se o movimento horizontal ja esta livre, nao existe degrau para resolver.
	if not test_move(global_transform, horizontal_motion):
		return false

	var upward_motion := Vector3.UP * max_step_height
	# Nao sobe se nao houver espaco para o corpo inteiro.
	if test_move(global_transform, upward_motion):
		return false

	var raised_transform := global_transform.translated(upward_motion)
	if test_move(raised_transform, horizontal_motion):
		return false

	var raised_forward_transform := raised_transform.translated(horizontal_motion)
	var down_collision := KinematicCollision3D.new()
	var down_distance := max_step_height + maxf(floor_snap_length, 0.05) + step_landing_margin
	if not test_move(
		raised_forward_transform,
		Vector3.DOWN * down_distance,
		down_collision
	):
		return false

	var landing_normal := down_collision.get_normal()
	var min_floor_dot := cos(floor_max_angle)
	if landing_normal.dot(Vector3.UP) < min_floor_dot:
		return false

	var landing_transform := raised_forward_transform.translated(down_collision.get_travel())
	var step_height := landing_transform.origin.y - global_position.y
	if step_height <= 0.015 or step_height > max_step_height + step_landing_margin:
		return false

	# Aplicamos somente a subida vertical. O deslocamento horizontal e feito uma
	# unica vez por move_and_slide(), evitando ganho artificial de velocidade.
	global_position.y = landing_transform.origin.y
	return true

func _camera_relative_direction(input_vector: Vector2) -> Vector3:
	if input_vector == Vector2.ZERO:
		return Vector3.ZERO

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Vector3(input_vector.x, 0.0, input_vector.y).normalized()

	var forward := -camera.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var right := camera.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()

	return (right * input_vector.x + forward * -input_vector.y).normalized()

func _select_nearest_target() -> void:
	_clear_target()

	var nearest_enemy: Node3D = null
	var nearest_distance := target_search_range

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy is Node3D:
			continue
		if enemy.has_method("is_alive") and not enemy.is_alive():
			continue

		var distance := global_position.distance_to(enemy.global_position)
		if distance <= nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance

	if nearest_enemy != null:
		selected_target = nearest_enemy
		if selected_target.has_method("set_selected"):
			selected_target.set_selected(true)
		target_changed.emit(selected_target)

func _clear_target() -> void:
	if is_instance_valid(selected_target) and selected_target.has_method("set_selected"):
		selected_target.set_selected(false)
	selected_target = null
	target_changed.emit(null)

func _attack_selected_target() -> void:
	if _attack_cooldown_remaining > 0.0:
		return

	if not is_instance_valid(selected_target):
		_select_nearest_target()

	if not is_instance_valid(selected_target):
		return
	if selected_target.has_method("is_alive") and not selected_target.is_alive():
		_clear_target()
		return

	var distance := global_position.distance_to(selected_target.global_position)
	if distance > attack_range:
		return

	var to_target := selected_target.global_position - global_position
	if visual_adapter != null and visual_adapter.has_method("face_direction"):
		visual_adapter.face_direction(to_target, 0.0, turn_speed)

	_attack_cooldown_remaining = attack_cooldown
	if visual_adapter != null and visual_adapter.has_method("play_attack"):
		visual_adapter.play_attack(attack_cooldown)
	if selected_target.has_method("take_damage"):
		selected_target.take_damage(attack_damage, self)

	if is_instance_valid(selected_target) and selected_target.has_method("is_alive") and not selected_target.is_alive():
		_clear_target()

func _interact_with_nearest() -> void:
	var nearest: Node3D = null
	var nearest_distance := interaction_range

	for interactable in get_tree().get_nodes_in_group("interactables"):
		if not is_instance_valid(interactable) or not interactable is Node3D:
			continue
		var distance := global_position.distance_to(interactable.global_position)
		if distance <= nearest_distance:
			nearest = interactable
			nearest_distance = distance

	if is_instance_valid(nearest) and nearest.has_method("interact"):
		nearest.interact(self)

func take_damage(amount: int, _attacker: Node = null) -> void:
	if not _is_alive or amount <= 0:
		return

	_spawn_damage_popup(amount, Color(1.0, 0.30, 0.24, 1.0))
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		_die()

func add_xp(amount: int) -> void:
	if amount <= 0:
		return

	xp += amount
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		xp_to_next_level = int(round(xp_to_next_level * 1.5))
		attack_damage += 2
		max_health += 10
		current_health = max_health
		health_changed.emit(current_health, max_health)

	stats_changed.emit(level, xp, xp_to_next_level, attack_damage)

func is_alive() -> bool:
	return _is_alive

func _die() -> void:
	if not _is_alive:
		return

	_is_alive = false
	velocity = Vector3.ZERO
	_clear_target()
	if visual_adapter != null and visual_adapter.has_method("play_death"):
		visual_adapter.play_death()
	died.emit()

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
	_is_alive = true
	visible = true
	if visual_adapter != null and visual_adapter.has_method("reset_state"):
		visual_adapter.reset_state()
	if visual_adapter != null and visual_adapter.has_method("face_direction"):
		visual_adapter.face_direction(Vector3(0.0, 0.0, -1.0), 0.0, turn_speed)
	health_changed.emit(current_health, max_health)
	respawned.emit()

func _spawn_damage_popup(amount: int, tint: Color) -> void:
	var popup := DAMAGE_POPUP_SCENE.instantiate()
	if not popup is Node3D:
		popup.queue_free()
		return
	var parent_node: Node = get_tree().current_scene
	if parent_node == null:
		parent_node = get_parent()
	parent_node.add_child(popup)
	(popup as Node3D).global_position = global_position + Vector3(0, 2.0, 0)
	if popup.has_method("show_value"):
		popup.show_value(amount, tint)

func _emit_full_state() -> void:
	health_changed.emit(current_health, max_health)
	stats_changed.emit(level, xp, xp_to_next_level, attack_damage)
	target_changed.emit(selected_target)
