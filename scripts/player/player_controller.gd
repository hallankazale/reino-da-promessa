extends CharacterBody3D

@export var move_speed = 4.5
@export var acceleration = 12.0
@export var gravity_force = 18.0
@export var attack_damage = 10
@export var attack_range = 2.2
@export var target_search_range = 12.0

var level = 1
var xp = 0
var xp_to_next_level = 20
var selected_target: Node3D = null

func _physics_process(delta):
	_handle_movement(delta)

	if Input.is_action_just_pressed("attack"):
		_attack_selected_target()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_select_nearest_target()
		get_viewport().set_input_as_handled()

func _handle_movement(delta):
	var input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)

	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()

	var desired_direction = Vector3(input_vector.x, 0.0, input_vector.y)
	velocity.x = move_toward(velocity.x, desired_direction.x * move_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, desired_direction.z * move_speed, acceleration * delta)

	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity_force * delta

	if desired_direction.length_squared() > 0.001:
		look_at(global_position + desired_direction, Vector3.UP)

	move_and_slide()

func _select_nearest_target():
	_clear_target()

	var nearest_enemy: Node3D = null
	var nearest_distance = target_search_range

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy is Node3D:
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance <= nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance

	if nearest_enemy != null:
		selected_target = nearest_enemy
		if selected_target.has_method("set_selected"):
			selected_target.set_selected(true)

func _clear_target():
	if is_instance_valid(selected_target) and selected_target.has_method("set_selected"):
		selected_target.set_selected(false)
	selected_target = null

func _attack_selected_target():
	if not is_instance_valid(selected_target):
		_select_nearest_target()

	if not is_instance_valid(selected_target):
		return

	var distance = global_position.distance_to(selected_target.global_position)
	if distance > attack_range:
		return

	if selected_target.has_method("take_damage"):
		selected_target.take_damage(attack_damage, self)

	if not is_instance_valid(selected_target):
		selected_target = null

func add_xp(amount):
	xp += amount

	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		xp_to_next_level = int(round(xp_to_next_level * 1.5))
		attack_damage += 2
