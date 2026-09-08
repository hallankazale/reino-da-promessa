extends Node3D
class_name KayKitDecorator

## Lightweight visual dressing layer using curated CC0 KayKit props.
## It owns presentation only: no quest/combat/collision rules live here.

const BARREL: PackedScene = preload("res://assets/third_party/kaykit_dungeon/barrel_small.glb")
const CRATE: PackedScene = preload("res://assets/third_party/kaykit_dungeon/crate.glb")
const CHEST: PackedScene = preload("res://assets/third_party/kaykit_dungeon/chest.glb")
const TORCH: PackedScene = preload("res://assets/third_party/kaykit_dungeon/torch.glb")
const PILLAR: PackedScene = preload("res://assets/third_party/kaykit_dungeon/pillar.glb")
const BANNER: PackedScene = preload("res://assets/third_party/kaykit_dungeon/banner_blue.glb")

func _ready() -> void:
	_build_camp_props()
	_build_ruins_props()
	_build_valley_props()

func _build_camp_props() -> void:
	_spawn(BARREL, Vector3(5.8, 0.0, 20.3), Vector3(0, 28, 0), 0.78, "CampBarrelA")
	_spawn(BARREL, Vector3(6.6, 0.0, 20.8), Vector3(0, -20, 0), 0.68, "CampBarrelB")
	_spawn(CRATE, Vector3(5.5, 0.0, 18.6), Vector3(0, 18, 0), 0.85, "CampCrateA")
	_spawn(CRATE, Vector3(-5.3, 0.0, 19.0), Vector3(0, -22, 0), 0.76, "CampCrateB")
	_spawn(BANNER, Vector3(-5.6, 0.0, 21.8), Vector3(0, 10, 0), 0.86, "CampBanner")
	_spawn(TORCH, Vector3(-2.4, 0.0, 15.2), Vector3.ZERO, 0.92, "CampTorchL")
	_spawn(TORCH, Vector3(2.4, 0.0, 15.2), Vector3.ZERO, 0.92, "CampTorchR")

func _build_ruins_props() -> void:
	_spawn(PILLAR, Vector3(-4.6, 0.0, -30.5), Vector3(0, 6, 0), 1.10, "RuinsPillarL")
	_spawn(PILLAR, Vector3(4.6, 0.0, -30.5), Vector3(0, -8, 0), 1.10, "RuinsPillarR")
	_spawn(TORCH, Vector3(-3.2, 0.0, -34.2), Vector3.ZERO, 0.95, "RuinsTorchL")
	_spawn(TORCH, Vector3(3.2, 0.0, -34.2), Vector3.ZERO, 0.95, "RuinsTorchR")
	_spawn(CHEST, Vector3(-6.0, 0.0, -25.0), Vector3(0, 32, 0), 0.82, "RuinsChest")

func _build_valley_props() -> void:
	_spawn(PILLAR, Vector3(115.3, 0.0, -16.8), Vector3.ZERO, 0.92, "ValleyPillarL")
	_spawn(PILLAR, Vector3(124.6, 0.0, -16.8), Vector3.ZERO, 0.92, "ValleyPillarR")
	_spawn(BANNER, Vector3(117.8, 0.0, -13.8), Vector3(0, 24, 0), 0.80, "ValleyBanner")
	_spawn(CRATE, Vector3(116.7, 0.0, -14.0), Vector3(0, -16, 0), 0.72, "ValleySupplyCrate")
	_spawn(BARREL, Vector3(117.2, 0.0, -14.8), Vector3(0, 12, 0), 0.68, "ValleySupplyBarrel")

func _spawn(scene: PackedScene, world_position: Vector3, rotation_deg: Vector3, scale_value: float, node_name: String) -> Node3D:
	if scene == null:
		return null
	var instance := scene.instantiate()
	if not instance is Node3D:
		instance.queue_free()
		return null
	var node := instance as Node3D
	node.name = node_name
	add_child(node)
	node.global_position = world_position
	node.rotation_degrees = rotation_deg
	node.scale = Vector3.ONE * scale_value
	return node
