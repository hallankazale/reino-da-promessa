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

	_validate_all_enemy_visuals(main_instance)
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

	# Valida o resultado da normalizacao, nao apenas o parametro calculado.
	# Isso corrige a lacuna do teste anterior que ficava verde mesmo com o mesh alto.
	var bounds_data: Dictionary = adapter.call("_calculate_bounds", imported_model)
	if not bool(bounds_data.get("found", false)):
		failures.append("%s sem bounds visuais para validar os pes" % enemy.name)
		return
	var bounds: AABB = bounds_data["bounds"]
	if absf(bounds.position.y - resolved_feet) > 0.06:
		failures.append("%s: fundo visual %.3f difere do pe resolvido %.3f" % [enemy.name, bounds.position.y, resolved_feet])

func _validate_enemy_facing(enemy: CharacterBody3D, adapter: Node3D) -> void:
	if not enemy.has_method("_face_target"):
		failures.append("%s sem _face_target" % enemy.name)
		return

	var body_yaw_before := enemy.rotation.y
	var target := enemy.global_position + Vector3(0.0, 0.0, 5.0)
	enemy.call("_face_target", target, 1.0)

	if absf(enemy.rotation.y - body_yaw_before) > 0.0001:
		failures.append("%s ainda gira o CharacterBody3D" % enemy.name)

	# Para um alvo em +Z, o adapter deve girar PI pela convencao -Z-forward do jogo.
	# A correcao nativa do asset e validada separadamente por enemy_kind acima.
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
