extends SceneTree

var failures: Array[String] = []

const ENEMY_CASES := [
	{"node": "WastelandSpecter", "kind": "wasteland_specter", "yaw": 180.0},
	{"node": "SkeletonRaider", "kind": "skeleton_raider", "yaw": 180.0},
	{"node": "RuinsDemon", "kind": "ruins_demon", "yaw": 0.0},
	{"node": "SpringShadeA", "kind": "spring_shade", "yaw": 180.0},
	{"node": "SpringShadeB", "kind": "spring_shade", "yaw": 180.0},
]

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

	_validate_enemy_visual_pipeline(main_instance)
	_validate_presentation(main_instance)
	_validate_hud(main_instance)

	main_instance.queue_free()
	await process_frame
	_finish()

func _validate_enemy_visual_pipeline(main_instance: Node) -> void:
	for test_case in ENEMY_CASES:
		var node_name := String(test_case["node"])
		var enemy := main_instance.get_node_or_null(node_name) as CharacterBody3D
		if enemy == null:
			failures.append("Inimigo ausente: %s" % node_name)
			continue

		var adapter := enemy.get_node_or_null("VisualAdapter") as Node3D
		if adapter == null or not adapter.has_method("get_facing_yaw"):
			failures.append("%s sem ModelAdapter de facing" % node_name)
			continue

		# Grounding is now profile-driven and tied to the actual collision bottom.
		if not enemy.has_method("get_resolved_visual_feet_y") or not enemy.has_method("get_collision_floor_y"):
			failures.append("%s nao expoe grounding visual resolvido" % node_name)
		else:
			var feet_y := float(enemy.call("get_resolved_visual_feet_y"))
			var collider_floor_y := float(enemy.call("get_collision_floor_y"))
			if absf(feet_y - collider_floor_y) > 0.001:
				failures.append("%s nao esta ancorado ao fundo do collider" % node_name)

		# Known imported packs must resolve their forward-axis correction centrally.
		if not enemy.has_method("get_resolved_visual_yaw"):
			failures.append("%s nao expoe yaw visual resolvido" % node_name)
		else:
			var resolved_yaw := float(enemy.call("get_resolved_visual_yaw"))
			var expected_yaw := float(test_case["yaw"])
			if absf(wrapf(resolved_yaw - expected_yaw, -180.0, 180.0)) > 0.01:
				failures.append("%s usa yaw %.1f; esperado %.1f" % [node_name, resolved_yaw, expected_yaw])

		# Facing must rotate only presentation, never the physics body.
		var body_yaw_before := enemy.rotation.y
		var target := enemy.global_position + Vector3(0.0, 0.0, 5.0)
		if enemy.has_method("_face_target"):
			enemy.call("_face_target", target, 1.0)
		else:
			failures.append("%s nao expoe _face_target" % node_name)
			continue

		if absf(enemy.rotation.y - body_yaw_before) > 0.0001:
			failures.append("%s ainda gira o CharacterBody3D para mirar" % node_name)

		var visual_yaw: float = adapter.get_facing_yaw()
		if absf(absf(visual_yaw) - PI) > 0.02:
			failures.append("%s nao orientou o VisualAdapter para alvo em +Z" % node_name)

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
	if player_panel == null or quest_panel == null:
		failures.append("Estrutura do HUD fantasy incompleta")

func _finish() -> void:
	if failures.is_empty():
		print("MMORPG_VISUAL_TEST_OK")
		quit(0)
		return
	for failure in failures:
		push_error("MMORPG_VISUAL: %s" % failure)
	quit(1)
