extends Node
class_name GroundSnap

## Grounds a static world actor without coupling its presentation to terrain code.
## It raycasts against the world after the procedural regions have built their
## collision and moves only the actor root, keeping ModelAdapter feet offsets local.

@export var target_path: NodePath = NodePath("..")
@export var ray_start_height: float = 4.0
@export var ray_depth: float = 10.0
@export var y_offset: float = 0.0
@export_flags_3d_physics var collision_mask: int = 1

var last_ground_y: float = 0.0
var has_ground: bool = false

func _ready() -> void:
	call_deferred("snap_now")

func snap_now() -> bool:
	var target := get_node_or_null(target_path) as Node3D
	if target == null or target.get_world_3d() == null:
		has_ground = false
		return false

	var origin := target.global_position
	var ray_from := origin + Vector3.UP * ray_start_height
	var ray_to := origin + Vector3.DOWN * ray_depth
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to, collision_mask)
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var hit := target.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		has_ground = false
		return false

	var hit_position: Vector3 = hit.get("position", origin)
	last_ground_y = hit_position.y
	origin.y = last_ground_y + y_offset
	target.global_position = origin
	has_ground = true
	return true
