extends Node3D
class_name ModelAdapter

## Bridges gameplay entities to imported animated 3D models.
## Gameplay only calls semantic methods (attack/death/reset); this component
## owns model instantiation, scale normalization, facing and animation discovery.

@export_category("Model")
@export var model_scene: PackedScene
@export var use_imported_model: bool = true
@export var target_height: float = 1.8
@export var feet_y: float = -0.9
@export var yaw_degrees: float = 0.0
@export var fallback_path: NodePath
@export var stabilize_model_root: bool = true
## Some imported GLBs bake locomotion into the parent/root bone. Gameplay already
## moves the CharacterBody3D, so that translation must not move the skinned body
## independently from its collision, UI and rigid accessories.
@export var stabilize_skeleton_roots: bool = true

@export_category("Rendering safety")
## Skinned meshes can leave their bind-pose AABB during combat animations and be
## incorrectly culled while rigid accessories remain visible. Expand the local
## bounds and add a world-space margin so animated bodies never disappear.
@export var prevent_animation_culling: bool = true
@export var render_guard_multiplier: float = 2.5
@export var render_guard_world_margin: float = 3.0

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
var _model_anchor_position := Vector3.ZERO
var _model_anchor_rotation := Vector3.ZERO
var _model_anchor_scale := Vector3.ONE
var _guarded_meshes: Array[MeshInstance3D] = []
var _skeleton_root_anchors: Array = []

func _ready() -> void:
	# AnimationPlayer nodes imported from GLB use the default process priority (0).
	# Running this adapter later guarantees root-motion correction happens after
	# the animation has written its bone pose for the frame.
	process_priority = 100

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

	if stabilize_model_root:
		_restore_model_root_transform()
	if stabilize_skeleton_roots:
		_restore_skeleton_root_anchors()

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

## Faces the presentation toward a world-space movement direction without rotating
## the CharacterBody3D. Godot's gameplay forward is -Z; yaw_degrees remains only
## the imported asset correction inside this adapter.
func face_direction(direction: Vector3, delta: float = 0.0, turn_speed: float = 10.0) -> void:
	var flat_direction := Vector3(direction.x, 0.0, direction.z)
	if flat_direction.length_squared() <= 0.0001:
		return
	flat_direction = flat_direction.normalized()

	var target_yaw := atan2(-flat_direction.x, -flat_direction.z)
	var weight := 1.0 if delta <= 0.0 else minf(maxf(turn_speed, 0.0) * delta, 1.0)
	rotation.y = lerp_angle(rotation.y, target_yaw, weight)

	if is_using_fallback() and is_instance_valid(_fallback):
		_fallback.rotation.y = rotation.y

func get_facing_yaw() -> float:
	return rotation.y

func has_loaded_model() -> bool:
	return is_instance_valid(_model_root)

func is_using_fallback() -> bool:
	return not use_imported_model or not is_instance_valid(_model_root)

func get_animation_names() -> PackedStringArray:
	if _animation_player == null:
		return PackedStringArray()
	return _animation_player.get_animation_list()

func get_render_guard_mesh_count() -> int:
	var count := 0
	for mesh_instance in _guarded_meshes:
		if is_instance_valid(mesh_instance):
			count += 1
	return count

func get_skeleton_root_anchor_count() -> int:
	var count := 0
	for entry in _skeleton_root_anchors:
		var skeleton := entry.get("skeleton") as Skeleton3D
		if is_instance_valid(skeleton):
			count += 1
	return count

func are_loaded_meshes_visible() -> bool:
	if is_using_fallback():
		return is_instance_valid(_fallback) and _fallback.visible
	if _guarded_meshes.is_empty():
		return false
	for mesh_instance in _guarded_meshes:
		if is_instance_valid(mesh_instance) and not mesh_instance.visible:
			return false
	return true

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
	_restore_model_root_transform()
	_restore_skeleton_root_anchors()
	_apply_render_guard()
	play_idle()

func _instantiate_model() -> void:
	if is_instance_valid(_model_root):
		_model_root.free()
	_model_root = null
	_animation_player = null
	_current_animation = &""
	_guarded_meshes.clear()
	_skeleton_root_anchors.clear()

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
	_capture_model_root_transform()
	_capture_skeleton_root_anchors()
	_apply_render_guard()
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

func _capture_model_root_transform() -> void:
	if not is_instance_valid(_model_root):
		return
	_model_anchor_position = _model_root.position
	_model_anchor_rotation = _model_root.rotation
	_model_anchor_scale = _model_root.scale

func _restore_model_root_transform() -> void:
	if not is_instance_valid(_model_root):
		return
	_model_root.position = _model_anchor_position
	_model_root.rotation = _model_anchor_rotation
	_model_root.scale = _model_anchor_scale

func _capture_skeleton_root_anchors() -> void:
	_skeleton_root_anchors.clear()
	if not stabilize_skeleton_roots or not is_instance_valid(_model_root):
		return

	var skeletons: Array[Skeleton3D] = []
	_collect_skeletons(_model_root, skeletons)
	for skeleton in skeletons:
		for bone_index in range(skeleton.get_bone_count()):
			if skeleton.get_bone_parent(bone_index) != -1:
				continue
			_skeleton_root_anchors.append({
				"skeleton": skeleton,
				"bone": bone_index,
				"position": skeleton.get_bone_pose_position(bone_index)
			})

func _restore_skeleton_root_anchors() -> void:
	if not stabilize_skeleton_roots:
		return
	for entry in _skeleton_root_anchors:
		var skeleton := entry.get("skeleton") as Skeleton3D
		if not is_instance_valid(skeleton):
			continue
		var bone_index := int(entry.get("bone", -1))
		if bone_index < 0 or bone_index >= skeleton.get_bone_count():
			continue
		skeleton.set_bone_pose_position(bone_index, entry.get("position", Vector3.ZERO))

func _apply_render_guard() -> void:
	_guarded_meshes.clear()
	if not prevent_animation_culling or not is_instance_valid(_model_root):
		return

	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(_model_root, meshes)
	for mesh_instance in meshes:
		if mesh_instance.mesh == null:
			continue

		# Skinned animation deforms vertices after the static mesh AABB is computed.
		# Grow in mesh-local units so the protection remains correct even when an
		# imported pack uses centimeters and ModelAdapter normalizes the root scale.
		var base_bounds := mesh_instance.get_aabb()
		var local_margin := maxf(base_bounds.size.length() * maxf(render_guard_multiplier, 0.0), 0.5)
		mesh_instance.custom_aabb = base_bounds.grow(local_margin)
		mesh_instance.extra_cull_margin = maxf(mesh_instance.extra_cull_margin, render_guard_world_margin)
		mesh_instance.ignore_occlusion_culling = true
		mesh_instance.visible = true
		_guarded_meshes.append(mesh_instance)

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

func _collect_skeletons(node: Node, output: Array[Skeleton3D]) -> void:
	if node is Skeleton3D:
		output.append(node as Skeleton3D)
	for child in node.get_children():
		_collect_skeletons(child, output)

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
