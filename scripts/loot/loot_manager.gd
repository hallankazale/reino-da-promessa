extends Node

const LOOT_TABLE = preload("res://scripts/loot/loot_table.gd")
const PICKUP_SCENE: PackedScene = preload("res://scenes/loot/world_pickup.tscn")

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("loot_manager")
	_rng.randomize()
	call_deferred("_connect_enemies")

func _connect_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_signal("loot_requested") and not enemy.loot_requested.is_connected(_on_loot_requested):
			enemy.loot_requested.connect(_on_loot_requested)

func _on_loot_requested(enemy_kind: String, world_position: Vector3) -> void:
	spawn_drops(enemy_kind, world_position)

func spawn_drops(enemy_kind: String, world_position: Vector3) -> int:
	var drops: Array[Dictionary] = LOOT_TABLE.roll(enemy_kind, _rng)
	var spawned := 0

	for index in range(drops.size()):
		var drop: Dictionary = drops[index]
		var pickup := PICKUP_SCENE.instantiate()
		if not pickup is Node3D:
			pickup.queue_free()
			continue

		var parent_node: Node = get_tree().current_scene
		if parent_node == null:
			parent_node = get_parent()
		parent_node.add_child(pickup)

		var lateral_offset := (float(index) - float(drops.size() - 1) * 0.5) * 0.72
		(pickup as Node3D).global_position = world_position + Vector3(lateral_offset, 0.12, 0.25 * float(index % 2))

		if drop.has("gold") and pickup.has_method("configure_gold"):
			pickup.configure_gold(int(drop["gold"]))
		elif drop.has("item_id") and pickup.has_method("configure_item"):
			pickup.configure_item(String(drop["item_id"]), int(drop.get("quantity", 1)))
		else:
			pickup.queue_free()
			continue

		spawned += 1

	return spawned

func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value
