extends CharacterBody3D

@export var move_speed = 4.5
@export var acceleration = 12.0
@export var gravity_force = 18.0
@export var attack_damage = 10
@export var attack_range = 2.2

var level = 1
var xp = 0
var xp_to_next_level = 20

func _physics_process(delta):
	_handle_movement(delta)

	if Input.is_action_just_pressed("attack"):
		_attack_nearest_enemy()

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
		look_at(global_transform.origin + desired_direction, Vector3.UP)

	set_velocity(velocity)
	set_up_direction(Vector3.UP)
	move_and_slide()
	velocity = velocity

func _attack_nearest_enemy():
	var nearest_enemy = null
	var nearest_distance = attack_range

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue

		var distance = global_transform.origin.distance_to(enemy.global_transform.origin)
		if distance <= nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance

	if nearest_enemy != null:
		nearest_enemy.take_damage(attack_damage, self)

func add_xp(amount):
	xp += amount

	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		level += 1
		xp_to_next_level = int(round(xp_to_next_level * 1.5))
		attack_damage += 2
