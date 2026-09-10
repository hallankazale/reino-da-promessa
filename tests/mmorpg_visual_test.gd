extends SceneTree

var failures: Array[String] = []

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
	for _frame in range(6):
		await process_frame

	_validate_enemy_facing(main_instance)
	_validate_presentation(main_instance)
	_validate_hud(main_instance)

	main_instance.queue_free()
	await process_frame
	_finish()

func _validate_enemy_facing(main_instance: Node) -> void:
	var enemy := main_instance.get_node_or_null("SkeletonRaider") as CharacterBody3D
	if enemy == null:
		failures.append("Saqueador Sombrio ausente")
		return
	var adapter := enemy.get_node_or_null("VisualAdapter") as Node3D
	if adapter == null or not adapter.has_method("get_facing_yaw"):
		failures.append("Saqueador sem ModelAdapter de facing")
		return

	var body_yaw_before := enemy.rotation.y
	var target := enemy.global_position + Vector3(0.0, 0.0, 5.0)
	if enemy.has_method("_face_target"):
		enemy.call("_face_target", target, 1.0)
	else:
		failures.append("EnemyBase nao expoe _face_target")
		return

	if absf(enemy.rotation.y - body_yaw_before) > 0.0001:
		failures.append("Facing do inimigo ainda gira o CharacterBody3D")

	var visual_yaw: float = adapter.get_facing_yaw()
	if absf(absf(visual_yaw) - PI) > 0.02:
		failures.append("Saqueador nao orientou o visual para alvo em +Z")

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
