extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var main_scene: PackedScene = load("res://scenes/world/main.tscn")
	if main_scene == null:
		failures.append("Nao foi possivel carregar a cena principal")
		_finish()
		return

	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)

	# GroundSnap e os StaticBody3D procedurais precisam de alguns frames para
	# entrar no physics space antes das assercoes de posicionamento.
	for _frame in range(5):
		await process_frame

	var player := main_instance.get_node_or_null("Player") as CharacterBody3D
	if player == null:
		failures.append("Player ausente no teste de movimento")
	else:
		_validate_player_facing(player)
		await _validate_model_root_stability(player)

	for npc_name in ["Eliabe", "Benaya", "Miriam"]:
		var npc := main_instance.get_node_or_null(npc_name) as Node3D
		_validate_npc_grounding(npc_name, npc)

	main_instance.queue_free()
	await process_frame
	_finish()

func _validate_player_facing(player: CharacterBody3D) -> void:
	var adapter := player.get_node_or_null("VisualAdapter") as Node3D
	if adapter == null or not adapter.has_method("face_direction"):
		failures.append("Player nao possui orientacao visual desacoplada")
		return

	var body_yaw_before := player.rotation.y
	adapter.face_direction(Vector3.RIGHT, 0.0, 10.0)

	if absf(player.rotation.y - body_yaw_before) > 0.0001:
		failures.append("Orientacao visual alterou a rotacao fisica do Player")

	if not adapter.has_method("get_facing_yaw"):
		failures.append("VisualAdapter nao expoe get_facing_yaw")
		return

	var right_yaw: float = adapter.get_facing_yaw()
	if absf(right_yaw + PI * 0.5) > 0.02:
		failures.append("Cavaleiro nao olha para +X com convencao -Z forward")

	adapter.face_direction(Vector3(0.0, 0.0, -1.0), 0.0, 10.0)
	var forward_yaw: float = adapter.get_facing_yaw()
	if absf(forward_yaw) > 0.02:
		failures.append("Cavaleiro nao volta a olhar para -Z")

func _validate_model_root_stability(player: CharacterBody3D) -> void:
	var adapter := player.get_node_or_null("VisualAdapter") as Node3D
	if adapter == null:
		return
	var imported_model := adapter.get_node_or_null("ImportedModel") as Node3D
	if imported_model == null:
		# O smoke test principal ja valida o fallback; aqui nao duplicamos essa regra.
		return

	var anchored_position := imported_model.position
	imported_model.position += Vector3(3.0, 2.0, -4.0)
	await process_frame
	if imported_model.position.distance_to(anchored_position) > 0.001:
		failures.append("Root motion conseguiu deslocar a raiz visual do cavaleiro")

func _validate_npc_grounding(npc_name: String, npc: Node3D) -> void:
	if npc == null:
		failures.append("NPC ausente: %s" % npc_name)
		return

	var snap := npc.get_node_or_null("GroundSnap")
	if snap == null or not snap.has_method("snap_now"):
		failures.append("%s nao possui GroundSnap" % npc_name)
		return

	if not bool(snap.snap_now()):
		failures.append("%s nao encontrou terreno abaixo" % npc_name)
		return

	var ground_y: float = float(snap.get("last_ground_y"))
	if absf(npc.global_position.y - ground_y) > 0.02:
		failures.append("%s continua fora do nivel do terreno" % npc_name)

func _finish() -> void:
	if failures.is_empty():
		print("MOVEMENT_GROUNDING_TEST_OK")
		quit(0)
		return

	for failure in failures:
		push_error("MOVEMENT/GROUNDING: %s" % failure)
	quit(1)
