extends Node3D
class_name KnightFallbackVisual

## Stable procedural fallback plus bootstrap for the curated KayKit Knight.
## The fallback remains in the scene as a safety net, but production rendering
## upgrades to the rigged/animated CC0 model after all player nodes are ready.

const KAYKIT_KNIGHT: PackedScene = preload("res://assets/third_party/kaykit_adventurers/Knight.glb")

@onready var owner_body: CharacterBody3D = get_parent() as CharacterBody3D
@onready var left_arm: Node3D = $LeftArmPivot
@onready var right_arm: Node3D = $RightArmPivot
@onready var left_leg: Node3D = $LeftLegPivot
@onready var right_leg: Node3D = $RightLegPivot
@onready var cape: MeshInstance3D = $Cape

var _phase := 0.0
var _attack_remaining := 0.0
var _attack_duration := 0.45
var _dead := false

func _ready() -> void:
	call_deferred("_activate_imported_knight")

func _activate_imported_knight() -> void:
	var adapter := get_node_or_null("../VisualAdapter")
	if adapter == null:
		return
	adapter.set("use_imported_model", true)
	if adapter.has_method("configure"):
		adapter.configure(KAYKIT_KNIGHT, 1.82, 180.0, -0.92)

func _process(delta: float) -> void:
	if _dead:
		return

	if _attack_remaining > 0.0:
		_attack_remaining = maxf(_attack_remaining - delta, 0.0)
		_apply_attack_pose()
		return

	var speed := 0.0
	if is_instance_valid(owner_body):
		speed = Vector2(owner_body.velocity.x, owner_body.velocity.z).length()

	if speed > 0.08:
		_phase += delta * 9.0
		var swing := sin(_phase) * 0.48
		left_arm.rotation.x = swing
		right_arm.rotation.x = -swing * 0.78
		left_leg.rotation.x = -swing * 0.72
		right_leg.rotation.x = swing * 0.72
		cape.rotation.x = deg_to_rad(5.0 + absf(sin(_phase)) * 4.0)
	else:
		_relax_pose(delta)

func play_idle() -> void:
	if _dead:
		return
	_attack_remaining = 0.0

func play_move() -> void:
	pass

func play_attack(lock_seconds: float = 0.45) -> void:
	if _dead:
		return
	_attack_duration = maxf(lock_seconds, 0.12)
	_attack_remaining = _attack_duration

func play_death() -> void:
	_dead = true
	_attack_remaining = 0.0
	rotation_degrees = Vector3(0, 0, 78)

func reset_state() -> void:
	_dead = false
	_attack_remaining = 0.0
	rotation = Vector3.ZERO
	left_arm.rotation = Vector3.ZERO
	right_arm.rotation = Vector3.ZERO
	left_leg.rotation = Vector3.ZERO
	right_leg.rotation = Vector3.ZERO
	cape.rotation = Vector3.ZERO

func _apply_attack_pose() -> void:
	var normalized := 1.0 - (_attack_remaining / maxf(_attack_duration, 0.001))
	var arc := sin(normalized * PI)
	right_arm.rotation.x = deg_to_rad(-78.0) * arc
	right_arm.rotation.z = deg_to_rad(-28.0) * arc
	left_arm.rotation.x = deg_to_rad(20.0) * arc
	left_leg.rotation.x = 0.0
	right_leg.rotation.x = 0.0
	cape.rotation.x = deg_to_rad(8.0)

func _relax_pose(delta: float) -> void:
	var weight := minf(delta * 9.0, 1.0)
	left_arm.rotation.x = lerpf(left_arm.rotation.x, 0.0, weight)
	right_arm.rotation.x = lerpf(right_arm.rotation.x, 0.0, weight)
	right_arm.rotation.z = lerpf(right_arm.rotation.z, 0.0, weight)
	left_leg.rotation.x = lerpf(left_leg.rotation.x, 0.0, weight)
	right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.0, weight)
	cape.rotation.x = lerpf(cape.rotation.x, deg_to_rad(3.0), weight)
