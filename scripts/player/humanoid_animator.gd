extends Node3D

@export var walk_frequency := 8.0
@export var walk_arm_angle_deg := 28.0
@export var walk_leg_angle_deg := 30.0
@export var idle_bob_height := 0.025
@export var attack_duration := 0.32

@onready var player: CharacterBody3D = get_parent() as CharacterBody3D
@onready var left_arm: Node3D = $LeftArm
@onready var right_arm: Node3D = $RightArm
@onready var left_leg: Node3D = $LeftLeg
@onready var right_leg: Node3D = $RightLeg
@onready var torso: Node3D = $Torso
@onready var head: Node3D = $Head

var locomotion_time := 0.0
var attack_time := 0.0
var base_position := Vector3.ZERO

func _ready() -> void:
	base_position = position

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("attack"):
		attack_time = attack_duration

	if attack_time > 0.0:
		attack_time = max(attack_time - delta, 0.0)
		_animate_attack()
		return

	var horizontal_speed := Vector2(player.velocity.x, player.velocity.z).length() if player else 0.0
	if horizontal_speed > 0.15:
		locomotion_time += delta * walk_frequency
		_animate_walk()
	else:
		locomotion_time += delta * 2.0
		_animate_idle()

func _animate_idle() -> void:
	var bob := sin(locomotion_time) * idle_bob_height
	position = base_position + Vector3(0.0, bob, 0.0)
	left_arm.rotation.x = lerp(left_arm.rotation.x, deg_to_rad(4.0), 0.12)
	right_arm.rotation.x = lerp(right_arm.rotation.x, deg_to_rad(-4.0), 0.12)
	left_leg.rotation.x = lerp(left_leg.rotation.x, 0.0, 0.15)
	right_leg.rotation.x = lerp(right_leg.rotation.x, 0.0, 0.15)
	torso.rotation.z = sin(locomotion_time * 0.5) * deg_to_rad(1.2)
	head.rotation.z = -torso.rotation.z * 0.35

func _animate_walk() -> void:
	var swing := sin(locomotion_time)
	position = base_position + Vector3(0.0, abs(sin(locomotion_time * 2.0)) * 0.035, 0.0)
	left_arm.rotation.x = deg_to_rad(walk_arm_angle_deg) * -swing
	right_arm.rotation.x = deg_to_rad(walk_arm_angle_deg) * swing
	left_leg.rotation.x = deg_to_rad(walk_leg_angle_deg) * swing
	right_leg.rotation.x = deg_to_rad(walk_leg_angle_deg) * -swing
	torso.rotation.z = deg_to_rad(2.5) * -swing
	head.rotation.z = deg_to_rad(1.0) * swing

func _animate_attack() -> void:
	var progress := 1.0 - (attack_time / attack_duration)
	var strike := sin(progress * PI)
	position = base_position
	right_arm.rotation.x = deg_to_rad(-120.0 + 155.0 * strike)
	right_arm.rotation.z = deg_to_rad(8.0 - 28.0 * strike)
	left_arm.rotation.x = deg_to_rad(20.0 * strike)
	left_leg.rotation.x = deg_to_rad(-8.0 * strike)
	right_leg.rotation.x = deg_to_rad(8.0 * strike)
	torso.rotation.y = deg_to_rad(-18.0 * strike)
	head.rotation.y = deg_to_rad(8.0 * strike)
