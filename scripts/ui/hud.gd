extends CanvasLayer

@onready var player: Node = get_node_or_null("../Player")
@onready var health_label: Label = $MarginContainer/Panel/VBox/HealthLabel
@onready var health_bar: ProgressBar = $MarginContainer/Panel/VBox/HealthBar
@onready var xp_label: Label = $MarginContainer/Panel/VBox/XPLabel
@onready var xp_bar: ProgressBar = $MarginContainer/Panel/VBox/XPBar
@onready var stats_label: Label = $MarginContainer/Panel/VBox/StatsLabel
@onready var target_label: Label = $MarginContainer/Panel/VBox/TargetLabel
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

	_sync_from_player()

func _sync_from_player() -> void:
	_on_health_changed(player.current_health, player.max_health)
	_on_stats_changed(player.level, player.xp, player.xp_to_next_level, player.attack_damage)
	_on_target_changed(player.selected_target)
	status_label.text = "Explore, selecione um alvo e lute."

func _on_health_changed(current_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = "VIDA  %d / %d" % [current_health, max_health]

func _on_stats_changed(level: int, xp: int, xp_to_next_level: int, attack_damage: int) -> void:
	xp_bar.max_value = xp_to_next_level
	xp_bar.value = xp
	xp_label.text = "XP  %d / %d" % [xp, xp_to_next_level]
	stats_label.text = "Nivel %d   |   Ataque %d" % [level, attack_damage]

func _on_target_changed(target: Node3D) -> void:
	if is_instance_valid(target):
		target_label.text = "Alvo: %s" % target.name
	else:
		target_label.text = "Alvo: nenhum"

func _on_player_died() -> void:
	status_label.text = "Voce caiu em batalha. Retornando ao ponto seguro..."

func _on_player_respawned() -> void:
	status_label.text = "Voce retornou. Continue a jornada."
