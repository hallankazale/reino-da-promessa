extends RefCounted
class_name LootTable

static func roll(enemy_kind: String, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []

	match enemy_kind:
		"wasteland_specter":
			drops.append({"gold": rng.randi_range(1, 2)})
			if rng.randf() <= 0.72:
				drops.append({"item_id": "wisp_essence", "quantity": 1})
		"spring_shade":
			drops.append({"gold": rng.randi_range(2, 4)})
			if rng.randf() <= 0.80:
				drops.append({"item_id": "wisp_essence", "quantity": 1})
			if rng.randf() <= 0.28:
				drops.append({"item_id": "healing_herb", "quantity": 1})
		"skeleton_raider":
			drops.append({"gold": rng.randi_range(2, 4)})
			if rng.randf() <= 0.82:
				drops.append({"item_id": "bone_fragment", "quantity": rng.randi_range(1, 2)})
		"ruins_demon":
			drops.append({"gold": rng.randi_range(5, 8)})
			drops.append({"item_id": "ruin_shard", "quantity": 1})
		_:
			if rng.randf() <= 0.35:
				drops.append({"gold": 1})

	return drops
