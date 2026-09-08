extends Node

signal quest_changed(title: String, objective: String, progress: int, goal: int, state: String)
signal message_changed(message: String)

const QUEST_TITLE := "Limpe o Caminho"
const QUEST_OBJECTIVE := "Derrote criaturas hostis no Caminho dos Olivais"
const QUEST_GOAL := 3
const QUEST_REWARD_XP := 30

enum QuestState {
	NOT_STARTED,
	ACTIVE,
	READY_TO_TURN_IN,
	COMPLETED
}

var quest_state: QuestState = QuestState.NOT_STARTED
var progress: int = 0

func _ready() -> void:
	add_to_group("quest_manager")
	call_deferred("_connect_enemy_signals")
	_emit_state()

func interact_with_quest_giver() -> void:
	match quest_state:
		QuestState.NOT_STARTED:
			_start_quest()
		QuestState.ACTIVE:
			message_changed.emit("Eliabe: O caminho ainda nao esta seguro. Continue atento.")
			_emit_state()
		QuestState.READY_TO_TURN_IN:
			_complete_quest()
		QuestState.COMPLETED:
			message_changed.emit("Eliabe: Voce cumpriu sua palavra. O acampamento esta mais seguro.")
			_emit_state()

func _start_quest() -> void:
	quest_state = QuestState.ACTIVE
	progress = 0
	message_changed.emit("Nova missao: derrote 3 criaturas no Caminho dos Olivais.")
	_emit_state()

func _complete_quest() -> void:
	quest_state = QuestState.COMPLETED
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.has_method("add_xp"):
		player.add_xp(QUEST_REWARD_XP)
	message_changed.emit("Missao concluida! Recompensa: %d XP." % QUEST_REWARD_XP)
	_emit_state()

func _connect_enemy_signals() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_signal("defeated") and not enemy.defeated.is_connected(_on_enemy_defeated):
			enemy.defeated.connect(_on_enemy_defeated)

func _on_enemy_defeated(_enemy_kind: String) -> void:
	if quest_state != QuestState.ACTIVE:
		return

	progress = mini(progress + 1, QUEST_GOAL)
	if progress >= QUEST_GOAL:
		quest_state = QuestState.READY_TO_TURN_IN
		message_changed.emit("Objetivo concluido. Volte e fale com Eliabe.")
	else:
		message_changed.emit("Progresso da missao: %d/%d criaturas derrotadas." % [progress, QUEST_GOAL])
	_emit_state()

func _emit_state() -> void:
	quest_changed.emit(
		QUEST_TITLE,
		QUEST_OBJECTIVE,
		progress,
		QUEST_GOAL,
		_state_label()
	)

func _state_label() -> String:
	match quest_state:
		QuestState.NOT_STARTED:
			return "Disponivel"
		QuestState.ACTIVE:
			return "Em andamento"
		QuestState.READY_TO_TURN_IN:
			return "Volte a Eliabe"
		QuestState.COMPLETED:
			return "Concluida"
	return "Desconhecido"
