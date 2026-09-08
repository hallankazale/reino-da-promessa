extends Node

signal quest_changed(title: String, objective: String, progress: int, goal: int, state: String)
signal message_changed(message: String)

enum QuestState {
	NOT_STARTED,
	ACTIVE,
	READY_TO_TURN_IN,
	COMPLETED
}

const QUESTS: Array[Dictionary] = [
	{
		"id": "clear_path",
		"giver": "eliabe",
		"giver_name": "Eliabe",
		"title": "Limpe o Caminho",
		"available_objective": "Fale com Eliabe no Acampamento do Peregrino.",
		"objective": "Derrote 3 criaturas hostis no Caminho dos Olivais.",
		"type": "kill",
		"target": "*",
		"goal": 3,
		"reward_xp": 30,
		"reward_gold": 5
	},
	{
		"id": "spring_shadows",
		"giver": "miriam",
		"giver_name": "Miriam",
		"title": "A Fonte Profanada",
		"available_objective": "Procure Miriam no Vale das Fontes.",
		"objective": "Derrote 2 Sombras da Fonte perto do santuário.",
		"type": "kill",
		"target": "spring_shade",
		"goal": 2,
		"reward_xp": 40,
		"reward_gold": 8
	},
	{
		"id": "watch_weapons",
		"giver": "benaya",
		"giver_name": "Benaya",
		"title": "Armas para a Vigília",
		"available_objective": "Fale com Benaya no Acampamento do Peregrino.",
		"objective": "Entregue 2 Fragmentos de Osso e 1 Lasca das Ruínas.",
		"type": "collect_multi",
		"requirements": {"bone_fragment": 2, "ruin_shard": 1},
		"goal": 3,
		"reward_xp": 55,
		"reward_gold": 20
	}
]

var quest_state: QuestState = QuestState.NOT_STARTED
var progress: int = 0
var quest_index: int = 0
var completed_quests: Dictionary = {}
var _inventory: Node = null

func _ready() -> void:
	add_to_group("quest_manager")
	call_deferred("_connect_runtime_signals")
	publish_state()

func interact_with_quest_giver() -> void:
	interact_with_npc("eliabe")

func interact_with_npc(npc_id: String) -> void:
	var quest := _current_quest()
	if quest.is_empty():
		announce("Todos os pedidos deste capítulo foram concluídos.")
		publish_state()
		return

	var giver := String(quest.get("giver", ""))
	var giver_name := String(quest.get("giver_name", giver))
	if npc_id != giver:
		match quest_state:
			QuestState.NOT_STARTED:
				announce("Procure %s para receber a próxima missão." % giver_name)
			QuestState.ACTIVE:
				announce("Missão ativa: %s." % String(quest.get("title", "Missão")))
			QuestState.READY_TO_TURN_IN:
				announce("Volte a %s para concluir a missão." % giver_name)
			_:
				pass
		publish_state()
		return

	match quest_state:
		QuestState.NOT_STARTED:
			_start_quest()
		QuestState.ACTIVE:
			_refresh_collection_progress(false)
			if quest_state == QuestState.READY_TO_TURN_IN:
				announce("Você já cumpriu o objetivo. Fale novamente com %s para entregar." % giver_name)
			else:
				announce("%s: %s" % [giver_name, String(quest.get("objective", "Continue a missão."))])
			publish_state()
		QuestState.READY_TO_TURN_IN:
			_complete_quest()
		QuestState.COMPLETED:
			announce("Todos os pedidos deste capítulo foram concluídos.")
			publish_state()

func publish_state() -> void:
	var quest := _current_quest()
	if quest.is_empty():
		quest_changed.emit(
			"Jornada do Peregrino",
			"O capítulo atual foi concluído. Explore o mundo enquanto novas tarefas são preparadas.",
			0,
			0,
			"Jornada concluida"
		)
		return

	var objective := String(quest.get("objective", ""))
	if quest_state == QuestState.NOT_STARTED:
		objective = String(quest.get("available_objective", objective))

	quest_changed.emit(
		String(quest.get("title", "Missão")),
		objective,
		progress,
		int(quest.get("goal", 0)),
		_state_label()
	)

func announce(message: String) -> void:
	message_changed.emit(message)

func is_first_quest_completed() -> bool:
	return is_quest_completed("clear_path")

func is_quest_completed(quest_id: String) -> bool:
	return bool(completed_quests.get(quest_id, false))

func get_current_quest_id() -> String:
	var quest := _current_quest()
	return String(quest.get("id", ""))

func get_npc_marker(npc_id: String) -> String:
	var quest := _current_quest()
	if quest.is_empty() or String(quest.get("giver", "")) != npc_id:
		return ""
	match quest_state:
		QuestState.NOT_STARTED:
			return "!"
		QuestState.READY_TO_TURN_IN:
			return "?"
	return ""

func _connect_runtime_signals() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_signal("defeated") and not enemy.defeated.is_connected(_on_enemy_defeated):
			enemy.defeated.connect(_on_enemy_defeated)

	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		_inventory = player.get_node_or_null("Inventory")
	if is_instance_valid(_inventory) and _inventory.has_signal("changed"):
		if not _inventory.changed.is_connected(_on_inventory_changed):
			_inventory.changed.connect(_on_inventory_changed)
	_refresh_collection_progress(false)

func _start_quest() -> void:
	var quest := _current_quest()
	if quest.is_empty():
		return
	quest_state = QuestState.ACTIVE
	progress = 0
	_refresh_collection_progress(false)
	announce("Nova missão: %s" % String(quest.get("title", "Missão")))
	publish_state()

func _complete_quest() -> void:
	var quest := _current_quest()
	if quest.is_empty():
		return

	if String(quest.get("type", "")) == "collect_multi" and not _consume_collection_requirements(quest):
		quest_state = QuestState.ACTIVE
		_refresh_collection_progress(false)
		announce("Você ainda não possui todos os materiais pedidos.")
		publish_state()
		return

	var player := get_tree().get_first_node_in_group("player")
	var reward_xp := int(quest.get("reward_xp", 0))
	var reward_gold := int(quest.get("reward_gold", 0))
	if is_instance_valid(player) and player.has_method("add_xp"):
		player.add_xp(reward_xp)
	if is_instance_valid(_inventory) and _inventory.has_method("add_gold"):
		_inventory.add_gold(reward_gold)

	var completed_id := String(quest.get("id", ""))
	completed_quests[completed_id] = true
	announce("Missão concluída: %s. Recompensa: %d XP e %d ouro." % [String(quest.get("title", "Missão")), reward_xp, reward_gold])

	quest_index += 1
	progress = 0
	if quest_index >= QUESTS.size():
		quest_state = QuestState.COMPLETED
	else:
		quest_state = QuestState.NOT_STARTED
	publish_state()

func _on_enemy_defeated(enemy_kind: String) -> void:
	if quest_state != QuestState.ACTIVE:
		return
	var quest := _current_quest()
	if quest.is_empty() or String(quest.get("type", "")) != "kill":
		return

	var target := String(quest.get("target", "*"))
	if target != "*" and target != enemy_kind:
		return

	var goal := int(quest.get("goal", 0))
	progress = mini(progress + 1, goal)
	if progress >= goal:
		quest_state = QuestState.READY_TO_TURN_IN
		announce("Objetivo concluído. Volte e fale com %s." % String(quest.get("giver_name", "o responsável")))
	else:
		announce("Progresso: %d/%d." % [progress, goal])
	publish_state()

func _on_inventory_changed() -> void:
	_refresh_collection_progress(true)

func _refresh_collection_progress(announce_ready: bool) -> void:
	if quest_state != QuestState.ACTIVE:
		return
	var quest := _current_quest()
	if quest.is_empty() or String(quest.get("type", "")) != "collect_multi":
		return
	if not is_instance_valid(_inventory):
		return

	var requirements: Dictionary = quest.get("requirements", {})
	var total := 0
	for item_id in requirements.keys():
		var required := int(requirements[item_id])
		var owned := int(_inventory.count_item(String(item_id))) if _inventory.has_method("count_item") else 0
		total += mini(owned, required)
	progress = total

	var goal := int(quest.get("goal", 0))
	if progress >= goal:
		quest_state = QuestState.READY_TO_TURN_IN
		if announce_ready:
			announce("Materiais reunidos. Volte e fale com %s." % String(quest.get("giver_name", "o responsável")))
	publish_state()

func _consume_collection_requirements(quest: Dictionary) -> bool:
	if not is_instance_valid(_inventory):
		return false
	var requirements: Dictionary = quest.get("requirements", {})
	for item_id in requirements.keys():
		var required := int(requirements[item_id])
		if int(_inventory.count_item(String(item_id))) < required:
			return false
	for item_id in requirements.keys():
		_inventory.remove_item(String(item_id), int(requirements[item_id]))
	return true

func _current_quest() -> Dictionary:
	if quest_index < 0 or quest_index >= QUESTS.size():
		return {}
	return QUESTS[quest_index]

func _state_label() -> String:
	var quest := _current_quest()
	match quest_state:
		QuestState.NOT_STARTED:
			return "Disponivel"
		QuestState.ACTIVE:
			return "Em andamento"
		QuestState.READY_TO_TURN_IN:
			return "Volte a %s" % String(quest.get("giver_name", "NPC"))
		QuestState.COMPLETED:
			return "Jornada concluida"
	return "Desconhecido"
