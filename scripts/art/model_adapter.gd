extends Node3D
class_name ModelAdapter

## Bridges gameplay entities to imported animated 3D models.
## Gameplay only calls semantic methods (attack/death/reset); this component
## owns model instantiation, scale normalization and animation-name discovery.

@export_category("Model")
@export var model_scene: PackedScene
@export var use_imported_model: bool = true
@export var target_height: float = 1.8
@export var feet_y: float = -0.9
@export var yaw_degrees: float = 0.0
@export var fallback_path: NodePath

@export_category("Animation discovery")
@export var idle_tokens: PackedStringArray = PackedStringArray(["idle", "stand"])
@export var move_tokens: PackedStringArray = PackedStringArray(["run", "walk", "move", "flying"])
@export var attack_tokens: PackedStringArray = PackedStringArray(["attack", "sword", "strike", "punch", "weapon", "headbutt"])
@export var death_tokens: PackedStringArray = PackedStringArray(["death", "die", "dead"])
@export var auto_locomotion: bool = true

var _model_root: Node3D = null
var _animation_player: AnimationPlayer = null
var _fallback: Node3D = null
var _action_lock_until_ms: int = 0
var _death_locked: bool = false
var _current_animation: StringName = &""

func _ready() -> void:
	if not String(fallback_path).is_empty():
		_fallback = get_node_or_null(fallback_path) as Node3D

	if not use_imported_model:
		_set_fallback_visible(true)
		return

	if model_scene != null:
		_instantiate_model()
	else:
		_set_fallback_visible(true)

func _process(_delta: float) -> void:
	if is_using_fallback():
		return
	if not auto_locomotion or _animation_player == null or _death_locked:
		return
	if Time.get_ticks_msec() < _action_lock_until_ms:
		return

	var owner_body := get_parent() as CharacterBody3D
	if owner_body == null:
		return

	var horizontal_speed := Vector2(owner_body.velocity.x, owner_body.velocity.z).length()
	if horizontal_speed > 0.08:
		play_move()
	else:
		play_idle()

func configure(scene: PackedScene, height: float, yaw: float = 0.0, local_feet_y: float = -0.9) -> void:
	model_scene = scene
	target_height = maxf(height, 0.1)
	yaw_degrees = yaw
	feet_y = local_feet_y
	if not use_imported_model:
		_set_fallback_visible(true)
		return
	if is_node_ready():
		_instantiate_model()

func has_loaded_model() -> bool:
	return is_instance_valid(_model_root)

func is_using_fallback() -> bool:
	return not use_imported_model or not is_instance_valid(_model_root)

func get_animation_names() -> PackedStringArray:
	if _animation_player == null:
		return PackedStringArray()
	return _animation_player.get_animation_list()

func play_idle() -> void:
	_death_locked = false
	if is_using_fallback():
		_call_fallback("play_idle")
		return
	_play_loop(idle_tokens)

func play_move() -> void:
	if is_using_fallback():
		_call_fallback("play_move")
		return
	_play_loop(move_tokens)

func play_attack(lock_seconds: float = 0.45) -> void:
	if _death_locked:
		return
	_action_lock_until_ms = Time.get_ticks_msec() + int(maxf(lock_seconds, 0.05) * 1000.0)
	if is_using_fallback():
		_call_fallback("play_attack", [lock_seconds])
		return
	_play_one_shot(attack_tokens)

func play_death() -> void:
	_death_locked = true
	_action_lock_until_ms = 0
	if is_using_fallback():
		_call_fallback("play_death")
		return
	_play_one_shot(death_tokens)

func reset_state() -> void:
	_death_locked = false
	_action_lock_until_ms = 0
	_current_animation = &""
	if is_using_fallback():
		_call_fallback("reset_state")
		return
	play_idle()

func _instantiate_model() -> void:
	if is_instance_valid(_model_root):
		_model_root.free()
	_model_root = null
	_animation_player = null
	_current_animation = &""

	if not use_imported_model or model_scene == null:
		_set_fallback_visible(true)
		return

	var instance := model_scene.instantiate()
	if not instance is Node3D:
		instance.queue_free()
		push_warning("ModelAdapter: imported model root is not Node3D")
		_set_fallback_visible(true)
		return

	_model_root = instance as Node3D
	_model_root.name = "ImportedModel"
	add_child(_model_root)
	_model_root.position = Vector3.ZERO
	_model_root.scale = Vector3.ONE
	_model_root.rotation_degrees = Vector3(0.0, yaw_degrees, 0.0)

	_normalize_height()
	_animation_player = _find_animation_player(_model_root)
	_set_fallback_visible(false)
	call_deferred("play_idle")

func _normalize_height() -> void:
	if _model_root == null:
		return

	var bounds_data := _calculate_bounds(_model_root)
	if not bounds_data["found"]:
		push_warning("ModelAdapter: model has no MeshInstance3D bounds")
		return

	var bounds: AABB = bounds_data["bounds"]
	if bounds.size.y <= 0.001:
		return

	var scale_factor := target_height / bounds.size.y
	_model_root.scale = Vector3.ONE * scale_factor
	_model_root.position.y = feet_y - bounds.position.y * scale_factor

func _calculate_bounds(root_node: Node3D) -> Dictionary:
	var found := false
	var combined := AABB()
	var adapter_inverse := global_transform.affine_inverse()
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(root_node, meshes)

	for mesh_instance in meshes:
		if mesh_instance.mesh == null:
			continue
		var box := mesh_instance.get_aabb()
		var to_adapter := adapter_inverse * mesh_instance.global_transform
		for x in [0.0, 1.0]:
			for y in [0.0, 1.0]:
				for z in [0.0, 1.0]:
					var local_point := box.position + Vector3(box.size.x * x, box.size.y * y, box.size.z * z)
					var point := to_adapter * local_point
					if not found:
						combined = AABB(point, Vector3.ZERO)
						found = true
					else:
						combined = combined.expand(point)

	return {"found": found, "bounds": combined}

func _collect_meshes(node: Node, output: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		output.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, output)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _find_animation(tokens: PackedStringArray) -> StringName:
	if _animation_player == null:
		return &""

	var names := _animation_player.get_animation_list()
	for token in tokens:
		var normalized_token := token.to_lower()
		for animation_name in names:
			if String(animation_name).to_lower().contains(normalized_token):
				return animation_name
	return &""

func _play_loop(tokens: PackedStringArray) -> void:
	if _animation_player == null:
		return
	var animation_name := _find_animation(tokens)
	if animation_name == &"":
		return
	if _current_animation == animation_name and _animation_player.is_playing():
		return

	var animation := _animation_player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR
	_animation_player.play(animation_name, 0.12)
	_current_animation = animation_name

func _play_one_shot(tokens: PackedStringArray) -> void:
	if _animation_player == null:
		return
	var animation_name := _find_animation(tokens)
	if animation_name == &"":
		return

	var animation := _animation_player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_NONE
	_animation_player.stop()
	_animation_player.play(animation_name, 0.08)
	_current_animation = animation_name

func _call_fallback(method: StringName, args: Array = []) -> void:
	if not is_instance_valid(_fallback) or not _fallback.has_method(method):
		return
	_fallback.callv(method, args)

func _set_fallback_visible(is_visible: bool) -> void:
	if is_instance_valid(_fallback):
		_fallback.visible = is_visible
