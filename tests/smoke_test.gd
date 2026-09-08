extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var required_resources := [
		"res://scenes/world/main.tscn",
		"res://scenes/world/first_region.tscn",
		"res://scenes/world/second_region.tscn",
		"res://scenes/world/region_gate.tscn",
		"res://scenes/ui/damage_popup.tscn",
		"res://scenes/player/player.tscn",
		"res://scenes/enemies/enemy_base.tscn",
		"res://scenes/npcs/eliabe.tscn",
		"res://scripts/player/player_controller.gd",
		"res://scripts/enemies/enemy_base.gd",
		"res://scripts/art/model_adapter.gd",
		"res://scripts/npcs/quest_giver.gd",
		"res://scripts/quests/quest_manager.gd",
		"res://scripts/world/first_region_builder.gd",
		"res://scripts/world/second_region_builder.gd",
		"res://scripts/world/region_gate.gd",
		"res://scripts/ui/damage_popup.gd",
		"res://scripts/ui/hud.gd",
		"res://assets/third_party/quaternius/pilgrim_guardian.glb",
		"res://assets/third_party/quaternius/wasteland_specter.glb",
		"res://assets/third_party/quaternius/skeleton_raider.glb",
		"res://assets/third_party/quaternius/ruins_demon.glb"
	]

	for path in required_resources:
		_check_resource(path)

	for action in ["move_forward", "move_back", "move_left", "move_right", "target_next", "attack", "interact"]:
		if not InputMap.has_action(action):
			failures.append("Input ausente: %s" % action)

	if not failures.is_empty():
		_finish()
		return

	var main_scene: PackedScene = load("res://scenes/world/main.tscn")
	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)

	# Permite que _ready, builders procedurais e chamadas deferred terminem.
	await process_frame
	await process_frame
	await process_frame

	var player := main_instance.get_node_or_null("Player")
	var quest_manager := main_instance.get_node_or_null("QuestManager")
	var eliabe := main_instance.get_node_or_null("Eliabe")
	var first_region := main_instance.get_node_or_null("FirstRegion")
	var second_region := main_instance.get_node_or_null("SecondRegion")
	var gate := main_instance.get_node_or_null("RegionGate")
	var return_gate := main_instance.get_node_or_null("ReturnGate")
	var quest_label := main_instance.get_node_or_null("HUD/MarginContainer/Panel/VBox/QuestLabel")
	var region_label := main_instance.get_node_or_null("HUD/MarginContainer/Panel/VBox/RegionLabel")
	var enemies := get_nodes_in_group("enemies")
	var interactables := get_nodes_in_group("interactables")

	if player == null:
		failures.append("Player nao foi instanciado")
	if quest_manager == null:
		failures.append("QuestManager nao foi instanciado")
	if eliabe == null:
		failures.append("Eliabe nao foi instanciado")
	if first_region == null:
		failures.append("Primeira regiao nao foi instanciada")
	elif first_region.get_node_or_null("Ground") == null:
		failures.append("Primeira regiao nao construiu o terreno")
	if second_region == null:
		failures.append("Vale das Fontes nao foi instanciado")
	else:
		if second_region.get_node_or_null("Ground") == null:
			failures.append("Vale das Fontes nao construiu o terreno")
		if second_region.get_node_or_null("ArrivalMarker") == null:
			failures.append("Vale das Fontes nao possui ArrivalMarker")
	if gate == null or return_gate == null:
		failures.append("Passagens entre regioes nao foram instanciadas")
	if quest_label == null or region_label == null:
		failures.append("HUD nao possui labels essenciais")
	if enemies.size() != 3:
		failures.append("Esperados 3 inimigos, encontrados %d" % enemies.size())
	if interactables.size() < 3:
		failures.append("Esperados NPC + duas passagens como interactables")

	if player != null:
		_validate_visual_adapter(player, "jogador")

	for enemy in enemies:
		_validate_visual_adapter(enemy, enemy.get_display_name() if enemy.has_method("get_display_name") else enemy.name)

	if player != null and quest_manager != null and gate != null and return_gate != null and enemies.size() == 3:
		_test_world_progression(player, quest_manager, enemies, gate, return_gate)

	main_instance.queue_free()
	await process_frame
	_finish()

func _validate_visual_adapter(entity: Node, entity_label: String) -> void:
	var adapter := entity.get_node_or_null("VisualAdapter")
	if adapter == null:
		failures.append("%s nao possui VisualAdapter" % entity_label)
		return

	if not adapter.has_method("has_loaded_model") or not adapter.has_loaded_model():
		failures.append("%s nao carregou o modelo 3D importado" % entity_label)
		return

	if not adapter.has_method("get_animation_names"):
		failures.append("%s nao expoe lista de animacoes" % entity_label)
		return

	var animations: PackedStringArray = adapter.get_animation_names()
	if animations.is_empty():
		failures.append("%s carregou sem animacoes" % entity_label)
	else:
		print("ART OK %s: %s" % [entity_label, ", ".join(animations)])

func _test_world_progression(player: Node, quest_manager: Node, enemies: Array[Node], gate: Node, return_gate: Node) -> void:
	var initial_position: Vector3 = player.global_position
	if gate.has_method("is_unlocked") and gate.is_unlocked():
		failures.append("Passagem iniciou desbloqueada antes da missao")

	gate.interact(player)
	if player.global_position.distance_to(initial_position) > 0.05:
		failures.append("Passagem moveu o jogador antes da missao ser concluida")

	quest_manager.interact_with_quest_giver()
	if quest_manager.quest_state != 1:
		failures.append("Missao nao entrou no estado ACTIVE")

	for enemy in enemies:
		enemy.defeated.emit(enemy.enemy_kind)

	if quest_manager.progress != 3:
		failures.append("Progresso da missao deveria ser 3, atual %d" % quest_manager.progress)
	if quest_manager.quest_state != 2:
		failures.append("Missao nao entrou no estado READY_TO_TURN_IN")

	quest_manager.interact_with_quest_giver()
	if quest_manager.quest_state != 3:
		failures.append("Missao nao entrou no estado COMPLETED")
	if player.level < 2:
		failures.append("Recompensa da missao nao gerou progressao esperada")
	if gate.has_method("is_unlocked") and not gate.is_unlocked():
		failures.append("Passagem nao desbloqueou apos concluir a missao")

	gate.interact(player)
	var valley_spawn := Vector3(120.0, 1.15, 22.0)
	if player.global_position.distance_to(valley_spawn) > 0.10:
		failures.append("Jogador nao chegou ao Vale das Fontes")

	return_gate.interact(player)
	var ruins_return := Vector3(0.0, 1.15, -34.0)
	if player.global_position.distance_to(ruins_return) > 0.10:
		failures.append("Passagem de retorno nao levou o jogador as Ruinas Antigas")

func _check_resource(path: String) -> void:
	if load(path) == null:
		failures.append("Falha ao carregar: %s" % path)

func _finish() -> void:
	if failures.is_empty():
		print("SMOKE TEST OK: gameplay, arte, combate, quest e transicao entre regioes validados.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
