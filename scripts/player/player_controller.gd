extends CharacterBody3D

@export var move_speed: float = 4.5
@export var acceleration: float = 12.0
@export var gravity_force: float = 18.0

func _physics_process(delta: float) -> void:
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var desired_direction := Vector3(input_vector.x, 0.0, input_vector.y).normalized()

    velocity.x = move_toward(velocity.x, desired_direction.x * move_speed, acceleration * delta)
    velocity.z = move_toward(velocity.z, desired_direction.z * move_speed, acceleration * delta)

    if not is_on_floor():
        velocity.y -= gravity_force * delta
    else:
        velocity.y = 0.0

    if desired_direction.length_squared() > 0.001:
        look_at(global_position + desired_direction, Vector3.UP)

    move_and_slide()
