extends SceneTree

var failures: Array[String] = []

const EXPECTED_ASSET_YAW := {
	"wasteland_specter": 0.0,
	"spring_shade": 0.0,
	"skeleton_raider": 180.0,
	"ruins_demon": 0.0,
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main_scene: PackedScene = load("res://scenes/world/main.tscn")
	if main_scene == null:
		failures.append("Cena principal nao carregou")
		_finish()
		return

	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)
	for _frame in range(8):
		await process_frame

	await _validate_all_enemy_visuals(main_instance)
	_validate_presentation(main_instance)
	_validate_hud(main_instance)

	main_instance.queue_free()
	await process_frame
	_finish()

func _validate_all_enemy_visuals(main_instance: Node) -> void:
	var enemies := main_instance.get_tree().get_nodes_in_group("enemies")
	if enemies.size() < 5:
		failures.append("Esperava pelo menos 5 inimigos ativos; encontrou %d" % enemies.size())

	for enemy_node in enemies:
		if not enemy_node is CharacterBody3D:
			continue
		var enemy := enemy_node as CharacterBody3D
		var kind := String(enemy.get("enemy_kind"))
		var adapter := enemy.get_node_or_null("VisualAdapter") as Node3D
		if adapter == null:
			failures.append("%s sem VisualAdapter" % enemy.name)
			continue

		if enemy.floor_snap_length < 0.45:
			failures.append("%s sem floor snap fisico suficiente" % enemy.name)

		if EXPECTED_ASSET_YAW.has(kind):
			var resolved_yaw := float(enemy.call("get_resolved_visual_yaw"))
			var expected_yaw := float(EXPECTED_ASSET_YAW[kind])
			if absf(resolved_yaw - expected_yaw) > 0.01:
				failures.append("%s calibrou yaw %.1f; esperado %.1f" % [enemy.name, resolved_yaw, expected_yaw])

		_validate_enemy_grounding(enemy, adapter)
		_validate_enemy_facing(enemy, adapter)
		if kind == "skeleton_raider":
			await _validate_grounded_rogue_locomotion(enemy, adapter)

func _validate_enemy_grounding(enemy: CharacterBody3D, adapter: Node3D) -> void:
	if not enemy.has_method("get_collision_floor_y") or not enemy.has_method("get_resolved_visual_feet_y"):
		failures.append("%s nao expoe diagnostico de grounding" % enemy.name)
		return

	var collider_floor := float(enemy.call("get_collision_floor_y"))
	var resolved_feet := float(enemy.call("get_resolved_visual_feet_y"))
	if resolved_feet > collider_floor + 0.02:
		failures.append("%s ainda posiciona os pes acima do collider" % enemy.name)

	var imported_model := adapter.get_node_or_null("ImportedModel") as Node3D
	if imported_model == null:
		failures.append("%s caiu no fallback em vez do modelo importado" % enemy.name)
		return

	var kind := String(enemy.get("enemy_kind"))
	if kind == "skeleton_raider":
		# KayKit includes crossbows/weapons whose AABBs extend below the boots.
		# Validate the actual leg meshes, not the combined asset bounds.
		var left_leg := _find_mesh(imported_model, "Rogue_LegLeft")
		var right_leg := _find_mesh(imported_model, "Rogue_LegRight")
		if left_leg == null or right_leg == null:
			failures.append("Saqueador sem meshes de pernas para validar grounding")
			return
		for leg in [left_leg, right_leg]:
			var leg_min_y := _mesh_min_y_in_adapter_space(leg, adapter)
			if absf(leg_min_y - resolved_feet) > 0.06:
				failures.append("%s: sola visual %.3f difere do pe resolvido %.3f" % [leg.name, leg_min_y, resolved_feet])
		return

	var bounds_data: Dictionary = adapter.call("_calculate_bounds", imported_model)
	if not bool(bounds_data.get("found", false)):
		failures.append("%s sem bounds visuais para validar os pes" % enemy.name)
		return
	var bounds: AABB = bounds_data["bounds"]
	if absf(bounds.position.y - resolved_feet) > 0.06:
		failures.append("%s: fundo visual %.3f difere do pe resolvido %.3f" % [enemy.name, bounds.position.y, resolved_feet])

func _validate_grounded_rogue_locomotion(enemy: CharacterBody3D, adapter: Node3D) -> void:
	if not adapter.has_method("play_move"):
		failures.append("Saqueador sem locomocao no ModelAdapter")
		return
	adapter.call("play_move")
	await process_frame
	var animation_player := _find_animation_player(adapter)
	if animation_player == null:
		failures.append("Saqueador sem AnimationPlayer")
		return
	var animation_name := String(animation_player.current_animation).to_lower()
	if not animation_name.contains("walking"):
		failures.append("Saqueador ainda usa locomocao aerea/rapida: %s" % animation_player.current_animation)

func _mesh_min_y_in_adapter_space(mesh_instance: MeshInstance3D, adapter: Node3D) -> float:
	var box := mesh_instance.get_aabb()
	var to_adapter := adapter.global_transform.affine_inverse() * mesh_instance.global_transform
	var min_y := INF
	for x in [0.0, 1.0]:
		for y in [0.0, 1.0]:
			for z in [0.0, 1.0]:
				var p := box.position + Vector3(box.size.x * x, box.size.y * y, box.size.z * z)
				min_y = minf(min_y, (to_adapter * p).y)
	return min_y

func _find_mesh(node: Node, mesh_name: String) -> MeshInstance3D:
	if node is MeshInstance3D and node.name == mesh_name:
		return node as MeshInstance3D
	for child in node.get_children():
		var found := _find_mesh(child, mesh_name)
		if found != null:
			return found
	return null

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null

func _validate_enemy_facing(enemy: CharacterBody3D, adapter: Node3D) -> void:
	if not enemy.has_method("_face_target"):
		failures.append("%s sem _face_target" % enemy.name)
		return

	var body_yaw_before := enemy.rotation.y
	var target := enemy.global_position + Vector3(0.0, 0.0, 5.0)
	enemy.call("_face_target", target, 1.0)

	if absf(enemy.rotation.y - body_yaw_before) > 0.0001:
		failures.append("%s ainda gira o CharacterBody3D" % enemy.name)

	var adapter_yaw := float(adapter.call("get_facing_yaw"))
	if absf(absf(adapter_yaw) - PI) > 0.02:
		failures.append("%s nao orientou o adapter para alvo em +Z" % enemy.name)

func _validate_presentation(main_instance: Node) -> void:
	var atmosphere := main_instance.get_node_or_null("FantasyAtmosphere")
	if atmosphere == null:
		failures.append("FantasyAtmosphere nao foi instanciado")
		return
	for required_name in ["RuinsRuneOuter", "RuinsAura", "ValleyRuneOuter", "ValleyAura", "CampWarmth"]:
		if atmosphere.get_node_or_null(required_name) == null:
			failures.append("Elemento visual ausente: %s" % required_name)

func _validate_hud(main_instance: Node) -> void:
	var hud := main_instance.get_node_or_null("HUD")
	if hud == null:
		failures.append("HUD ausente")
		return
	var player_panel := hud.get_node_or_null("PlayerPanel/Panel")
	var quest_panel := hud.get_node_or_null("QuestPanel/Panel")
	var build_label := hud.get_node_or_null("BuildLabel") as Label
	if player_panel == null or quest_panel == null:
		failures.append("Estrutura do HUD fantasy incompleta")
	if build_label == null or not build_label.text.contains("v0.9.1"):
		failures.append("Identificador de build v0.9.1 ausente")

func _finish() -> void:
	if failures.is_empty():
		print("MMORPG_VISUAL_TEST_OK")
		quit(0)
		return
	for failure in failures:
		push_error("MMORPG_VISUAL: %s" % failure)
	quit(1)
