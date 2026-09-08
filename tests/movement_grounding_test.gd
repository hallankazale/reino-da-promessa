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

	var second_region := main_instance.get_node_or_null("SecondRegion") as Node3D
	await _validate_bridge_walkability(main_instance, second_region)

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

func _validate_bridge_walkability(main_instance: Node, second_region: Node3D) -> void:
	if second_region == null:
		failures.append("Vale das Fontes ausente no teste da ponte")
		return

	var bridge := second_region.get_node_or_null("StoneBridge") as Node3D
	if bridge == null:
		failures.append("StoneBridge nao foi construida")
		return
	if bridge.get_node_or_null("BridgeDeckCollision") == null:
		failures.append("Ponte nao possui tabuleiro de colisao continuo")
		return

	# Godot pode renomear automaticamente o segundo filho com o mesmo nome.
	# Identificamos as rampas pela funcao fisica: StaticBody inclinado nas duas extremidades.
	var ramp_count := 0
	for child in bridge.get_children():
		if child is StaticBody3D:
			var body := child as StaticBody3D
			if absf(body.rotation_degrees.x) > 1.0 and absf(body.position.z) > 3.0:
				ramp_count += 1
	if ramp_count != 2:
		failures.append("Ponte deveria possuir 2 rampas caminhaveis")
		return

	# Probe com a mesma capsula do jogador. Ele precisa sair do caminho de chegada,
	# subir a primeira rampa, atravessar o tabuleiro e descer do outro lado.
	var probe := CharacterBody3D.new()
	probe.name = "BridgeTraversalProbe"
	probe.floor_snap_length = 0.45
	probe.floor_max_angle = deg_to_rad(46.0)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collision.shape = capsule
	probe.add_child(collision)
	main_instance.add_child(probe)
	probe.global_position = second_region.to_global(Vector3(0.0, 1.15, 6.4))

	for _frame in range(3):
		await physics_frame

	for _step in range(180):
		probe.velocity.x = 0.0
		probe.velocity.z = -4.0
		if probe.is_on_floor():
			probe.velocity.y = 0.0
		else:
			probe.velocity.y -= 18.0 / 60.0
		probe.move_and_slide()
		await physics_frame

	var end_local := second_region.to_local(probe.global_position)
	if end_local.z > -2.8:
		failures.append("Capsula do jogador continua bloqueada na ponte; terminou em Z=%.2f" % end_local.z)

	probe.queue_free()
	await process_frame

func _finish() -> void:
	if failures.is_empty():
		print("MOVEMENT_GROUNDING_TEST_OK")
		quit(0)
		return

	for failure in failures:
		push_error("MOVEMENT/GROUNDING: %s" % failure)
	quit(1)
