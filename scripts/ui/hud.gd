extends CanvasLayer

const ITEM_CATALOG = preload("res://scripts/inventory/item_catalog.gd")

@onready var player: Node = get_node_or_null("../Player")
@onready var inventory: Node = get_node_or_null("../Player/Inventory")
@onready var quest_manager: Node = get_node_or_null("../QuestManager")

@onready var gold_label: Label = $PlayerPanel/Panel/VBox/NameRow/GoldLabel
@onready var health_label: Label = $PlayerPanel/Panel/VBox/HealthRow/HealthLabel
@onready var health_bar: ProgressBar = $PlayerPanel/Panel/VBox/HealthRow/HealthBar
@onready var xp_label: Label = $PlayerPanel/Panel/VBox/XPRow/XPLabel
@onready var xp_bar: ProgressBar = $PlayerPanel/Panel/VBox/XPRow/XPBar
@onready var stats_label: Label = $PlayerPanel/Panel/VBox/StatsLabel

@onready var target_panel: Control = $TargetPanel
@onready var target_name: Label = $TargetPanel/Panel/VBox/Name
@onready var target_health_bar: ProgressBar = $TargetPanel/Panel/VBox/HealthBar
@onready var target_health_label: Label = $TargetPanel/Panel/VBox/HealthLabel

@onready var quest_panel: Control = $QuestPanel
@onready var quest_title: Label = $QuestPanel/Panel/VBox/Title
@onready var quest_progress: Label = $QuestPanel/Panel/VBox/Progress
@onready var quest_objective: Label = $QuestPanel/Panel/VBox/Objective

@onready var region_banner: Control = $RegionBanner
@onready var region_label: Label = $RegionBanner/Panel/Label
@onready var toast_panel: Control = $ToastPanel
@onready var toast_label: Label = $ToastPanel/Panel/Label
@onready var prompt_panel: Control = $PromptPanel
@onready var prompt_label: Label = $PromptPanel/Panel/Label
@onready var help_label: Label = $HelpLabel

var _current_target: Node = null
var _region_tween: Tween
var _toast_tween: Tween
var _quest_tween: Tween

func _ready() -> void:
	_apply_visual_polish()
	if player == null:
		_show_toast("Player nao encontrado", 3.0)
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

	if inventory != null:
		if inventory.has_signal("item_added"):
			inventory.item_added.connect(_on_item_added)
		if inventory.has_signal("gold_changed"):
			inventory.gold_changed.connect(_on_gold_changed)

	if quest_manager != null:
		if quest_manager.has_signal("quest_changed"):
			quest_manager.quest_changed.connect(_on_quest_changed)
		if quest_manager.has_signal("message_changed"):
			quest_manager.message_changed.connect(_on_message_changed)

	call_deferred("_connect_region_gates")
	_sync_from_player()
	_sync_quest()
	_show_region("Acampamento do Peregrino")

func _apply_visual_polish() -> void:
	# Keep the tracker useful without occupying a large chunk of the world view.
	quest_panel.offset_left = -258.0
	quest_panel.offset_top = 106.0
	quest_panel.offset_right = -14.0
	quest_panel.offset_bottom = 176.0
	quest_title.add_theme_font_size_override("font_size", 11)
	quest_progress.add_theme_font_size_override("font_size", 9)
	quest_objective.add_theme_font_size_override("font_size", 8)

	# Controls stay subtle, but a shadow makes them readable over grass or road.
	help_label.add_theme_color_override("font_color", Color(0.88, 0.9, 0.93, 0.88))
	help_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.86))
	help_label.add_theme_constant_override("shadow_offset_x", 1)
	help_label.add_theme_constant_override("shadow_offset_y", 1)
	help_label.add_theme_font_size_override("font_size", 9)

func _process(_delta: float) -> void:
	_update_interaction_prompt()

func _connect_region_gates() -> void:
	for gate in get_tree().get_nodes_in_group("region_gates"):
		if gate.has_signal("used") and not gate.used.is_connected(_on_region_changed):
			gate.used.connect(_on_region_changed)

func _sync_from_player() -> void:
	_on_health_changed(player.current_health, player.max_health)
	_on_stats_changed(player.level, player.xp, player.xp_to_next_level, player.attack_damage)
	_on_target_changed(player.selected_target)
	if inventory != null:
		_on_gold_changed(int(inventory.gold))

func _sync_quest() -> void:
	if quest_manager == null:
		quest_title.text = "Sem missao"
		quest_progress.text = ""
		quest_objective.text = ""
		return
	if quest_manager.has_method("publish_state"):
		quest_manager.call_deferred("publish_state")

func _on_health_changed(current_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = "HP %d/%d" % [current_health, max_health]

func _on_stats_changed(level: int, xp: int, xp_to_next_level: int, attack_damage: int) -> void:
	xp_bar.max_value = xp_to_next_level
	xp_bar.value = xp
	xp_label.text = "XP %d/%d" % [xp, xp_to_next_level]
	stats_label.text = "Nv.%d   ATQ %d" % [level, attack_damage]

func _on_target_changed(target: Node3D) -> void:
	_disconnect_target_health()
	_current_target = target

	if not is_instance_valid(target):
		target_panel.visible = false
		return

	target_panel.visible = true
	target_name.text = target.get_display_name() if target.has_method("get_display_name") else target.name
	_update_target_health_from_node(target)

	if target.has_signal("health_changed"):
		target.health_changed.connect(_on_target_health_changed)

func _disconnect_target_health() -> void:
	if not is_instance_valid(_current_target):
		return
	if _current_target.has_signal("health_changed") and _current_target.health_changed.is_connected(_on_target_health_changed):
		_current_target.health_changed.disconnect(_on_target_health_changed)

func _update_target_health_from_node(target: Node) -> void:
	var current := int(target.get("current_health")) if target.get("current_health") != null else 0
	var maximum := int(target.get("max_health")) if target.get("max_health") != null else maxi(current, 1)
	_on_target_health_changed(current, maximum)

func _on_target_health_changed(current_health: int, max_health: int) -> void:
	target_health_bar.max_value = maxi(max_health, 1)
	target_health_bar.value = current_health
	target_health_label.text = "HP %d/%d" % [current_health, max_health]

func _on_quest_changed(title: String, objective: String, progress: int, goal: int, state: String) -> void:
	if _quest_tween != null and _quest_tween.is_valid():
		_quest_tween.kill()
	quest_panel.visible = true
	quest_panel.modulate.a = 1.0
	quest_title.text = title if not title.is_empty() else "Missao"
	match state:
		"Disponivel":
			quest_progress.text = "Fale com Eliabe"
			quest_objective.text = "Uma tarefa espera no acampamento."
		"Concluida":
			quest_progress.text = "CONCLUIDA"
			quest_objective.text = "Passagem das ruinas liberada."
			_quest_tween = create_tween()
			_quest_tween.tween_interval(3.5)
			_quest_tween.tween_property(quest_panel, "modulate:a", 0.0, 0.35)
			_quest_tween.tween_callback(func(): quest_panel.visible = false)
		_:
			quest_progress.text = "%d/%d  %s" % [progress, goal, state]
			quest_objective.text = objective

func _on_message_changed(message: String) -> void:
	_show_toast(message)

func _on_item_added(item_id: String, amount: int) -> void:
	_show_toast("Obtido: %s x%d" % [ITEM_CATALOG.display_name(item_id), amount])

func _on_gold_changed(total: int) -> void:
	gold_label.text = "%d ouro" % total

func _on_region_changed(destination_name: String) -> void:
	_show_region(destination_name)
	_on_target_changed(null)

func _on_player_died() -> void:
	_show_toast("Derrotado. Retornando ao acampamento...", 2.5)

func _on_player_respawned() -> void:
	_show_region("Acampamento do Peregrino")
	_show_toast("De volta ao acampamento.")

func _show_region(name: String) -> void:
	region_label.text = name
	region_banner.visible = true
	region_banner.modulate.a = 0.0
	if _region_tween != null and _region_tween.is_valid():
		_region_tween.kill()
	_region_tween = create_tween()
	_region_tween.tween_property(region_banner, "modulate:a", 1.0, 0.20)
	_region_tween.tween_interval(1.7)
	_region_tween.tween_property(region_banner, "modulate:a", 0.0, 0.35)
	_region_tween.tween_callback(func(): region_banner.visible = false)

func _show_toast(message: String, duration: float = 1.8) -> void:
	if message.is_empty():
		return
	toast_label.text = message
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(toast_panel, "modulate:a", 1.0, 0.12)
	_toast_tween.tween_interval(duration)
	_toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.22)
	_toast_tween.tween_callback(func(): toast_panel.visible = false)

func _update_interaction_prompt() -> void:
	if not is_instance_valid(player) or not player is Node3D:
		prompt_panel.visible = false
		return

	var nearest: Node3D = null
	var max_range := float(player.get("interaction_range")) if player.get("interaction_range") != null else 3.2
	var nearest_distance := max_range

	for candidate in get_tree().get_nodes_in_group("interactables"):
		if not is_instance_valid(candidate) or not candidate is Node3D:
			continue
		var distance := (player as Node3D).global_position.distance_to(candidate.global_position)
		if distance <= nearest_distance:
			nearest = candidate
			nearest_distance = distance

	if not is_instance_valid(nearest):
		prompt_panel.visible = false
		return

	var prompt := "E  Interagir"
	if nearest.has_method("get_interaction_prompt"):
		prompt = String(nearest.get_interaction_prompt())
	prompt_label.text = prompt
	prompt_panel.visible = true
