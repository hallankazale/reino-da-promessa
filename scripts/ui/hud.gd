extends CanvasLayer

@onready var player: Node = get_node_or_null("../Player")
@onready var quest_manager: Node = get_node_or_null("../QuestManager")
@onready var health_label: Label = $MarginContainer/Panel/VBox/HealthLabel
@onready var health_bar: ProgressBar = $MarginContainer/Panel/VBox/HealthBar
@onready var xp_label: Label = $MarginContainer/Panel/VBox/XPLabel
@onready var xp_bar: ProgressBar = $MarginContainer/Panel/VBox/XPBar
@onready var stats_label: Label = $MarginContainer/Panel/VBox/StatsLabel
@onready var target_label: Label = $MarginContainer/Panel/VBox/TargetLabel
@onready var quest_label: Label = $MarginContainer/Panel/VBox/QuestLabel
@onready var status_label: Label = $MarginContainer/Panel/VBox/StatusLabel

func _ready() -> void:
	if player == null:
		status_label.text = "Player nao encontrado"
		return

	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_health_changed)
	if player.has_signal("stats_changed"):
		player.stats_changed.connect(_on_stats_changed)
	if player.has_signal("target_changed"):
		player.target_changed.connect(_on_target_changed)
	if player.has_signal("died"):
		player.died.connect(_on_player_died)
	if player.has_signal("respawned"):
		player.respawned.connect(_on_player_respawned)

	if quest_manager != null:
		if quest_manager.has_signal("quest_changed"):
			quest_manager.quest_changed.connect(_on_quest_changed)
		if quest_manager.has_signal("message_changed"):
			quest_manager.message_changed.connect(_on_message_changed)

	_sync_from_player()
	_sync_quest()

func _sync_from_player() -> void:
	_on_health_changed(player.current_health, player.max_health)
	_on_stats_changed(player.level, player.xp, player.xp_to_next_level, player.attack_damage)
	_on_target_changed(player.selected_target)
	status_label.text = "Procure Eliabe no acampamento."

func _sync_quest() -> void:
	if quest_manager == null:
		quest_label.text = "Missao indisponivel"
		return
	if quest_manager.has_method("publish_state"):
		quest_manager.call_deferred("publish_state")

func _on_health_changed(current_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = "HP  %d / %d" % [current_health, max_health]

func _on_stats_changed(level: int, xp: int, xp_to_next_level: int, attack_damage: int) -> void:
	xp_bar.max_value = xp_to_next_level
	xp_bar.value = xp
	xp_label.text = "XP  %d / %d" % [xp, xp_to_next_level]
	stats_label.text = "Nv.%d   ATQ %d" % [level, attack_damage]

func _on_target_changed(target: Node3D) -> void:
	if not is_instance_valid(target):
		target_label.text = "Alvo: -"
		return

	if target.has_method("get_display_name"):
		target_label.text = "Alvo: %s" % target.get_display_name()
	else:
		target_label.text = "Alvo: %s" % target.name

func _on_quest_changed(title: String, objective: String, progress: int, goal: int, state: String) -> void:
	if state == "Disponivel":
		quest_label.text = "Missao: fale com Eliabe"
		return
	if state == "Concluida":
		quest_label.text = "%s - CONCLUIDA" % title
		return
	quest_label.text = "%s  %d/%d  %s" % [title, progress, goal, state]
	if not objective.is_empty():
		status_label.text = objective

func _on_message_changed(message: String) -> void:
	status_label.text = message

func _on_player_died() -> void:
	status_label.text = "Derrotado. Retornando ao acampamento..."

func _on_player_respawned() -> void:
	status_label.text = "De volta ao acampamento."
