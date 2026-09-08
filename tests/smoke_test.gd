extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var required_resources := [
		"res://scenes/world/main.tscn",
		"res://scenes/world/first_region.tscn",
		"res://scenes/player/player.tscn",
		"res://scenes/enemies/enemy_base.tscn",
		"res://scenes/npcs/eliabe.tscn",
		"res://scripts/player/player_controller.gd",
		"res://scripts/enemies/enemy_base.gd",
		"res://scripts/npcs/quest_giver.gd",
		"res://scripts/quests/quest_manager.gd",
		"res://scripts/world/first_region_builder.gd",
		"res://scripts/ui/hud.gd"
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

	# Permite que _ready e chamadas deferred conectem grupos e sinais.
	await process_frame
	await process_frame

	var player := main_instance.get_node_or_null("Player")
	var quest_manager := main_instance.get_node_or_null("QuestManager")
	var eliabe := main_instance.get_node_or_null("Eliabe")
	var region := main_instance.get_node_or_null("FirstRegion")
	var quest_label := main_instance.get_node_or_null("HUD/MarginContainer/Panel/VBox/QuestLabel")
	var enemies := get_nodes_in_group("enemies")
	var interactables := get_nodes_in_group("interactables")

	if player == null:
		failures.append("Player nao foi instanciado")
	if quest_manager == null:
		failures.append("QuestManager nao foi instanciado")
	if eliabe == null:
		failures.append("Eliabe nao foi instanciado")
	if region == null:
		failures.append("Primeira regiao nao foi instanciada")
	elif region.get_node_or_null("Ground") == null:
		failures.append("Primeira regiao nao construiu o terreno")
	if quest_label == null:
		failures.append("HUD nao possui QuestLabel")
	if enemies.size() != 3:
		failures.append("Esperados 3 inimigos, encontrados %d" % enemies.size())
	if interactables.size() < 1:
		failures.append("Nenhum interactable registrado")

	if player != null and quest_manager != null and enemies.size() == 3:
		_test_quest_loop(player, quest_manager, enemies)

	main_instance.queue_free()
	await process_frame
	_finish()

func _test_quest_loop(player: Node, quest_manager: Node, enemies: Array[Node]) -> void:
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

func _check_resource(path: String) -> void:
	if load(path) == null:
		failures.append("Falha ao carregar: %s" % path)

func _finish() -> void:
	if failures.is_empty():
		print("SMOKE TEST OK: regiao, inimigos, NPC, interacao e ciclo de missao validados.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
