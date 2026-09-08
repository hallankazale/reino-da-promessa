extends Node3D

## Third-person camera tuned for MMORPG readability.
## The rig follows the player independently from gameplay while SpringArm3D
## handles obstacles. The default framing keeps the avatar clearly visible
## without sacrificing enough world space to read the route ahead.

@export var target_path: NodePath = NodePath("..")
@export var follow_height: float = 1.75
@export var mouse_sensitivity: float = 0.003
@export var min_pitch_deg: float = -50.0
@export var max_pitch_deg: float = 16.0
@export var min_zoom: float = 3.8
@export var max_zoom: float = 8.5
@export var default_zoom: float = 5.35
@export var zoom_step: float = 0.55

@onready var spring_arm: SpringArm3D = $SpringArm3D

var target: Node3D
var dragging := false
var yaw := 0.0
var pitch := deg_to_rad(-18.0)

func _ready() -> void:
	target = get_node_or_null(target_path) as Node3D
	top_level = true
	spring_arm.spring_length = clampf(default_zoom, min_zoom, max_zoom)
	_update_rig_transform()

func _process(_delta: float) -> void:
	_update_rig_transform()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if dragging else Input.MOUSE_MODE_VISIBLE
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clampf(spring_arm.spring_length - zoom_step, min_zoom, max_zoom)
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clampf(spring_arm.spring_length + zoom_step, min_zoom, max_zoom)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clampf(pitch, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
		get_viewport().set_input_as_handled()

func _update_rig_transform() -> void:
	if not is_instance_valid(target):
		return
	global_position = target.global_position + Vector3(0.0, follow_height, 0.0)
	rotation = Vector3(pitch, yaw, 0.0)
