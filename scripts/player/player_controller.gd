extends KinematicBody

export var move_speed = 4.5
export var acceleration = 12.0
export var gravity_force = 18.0

var velocity = Vector3.ZERO

func _physics_process(delta):
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

    velocity = move_and_slide(velocity, Vector3.UP)
