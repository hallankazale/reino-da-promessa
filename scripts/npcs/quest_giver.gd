extends Node3D

@export var npc_id: String = "eliabe"
@export var display_name: String = "Eliabe"
@export var interaction_text: String = "Falar"

@onready var prompt_label: Label3D = $PromptLabel
@onready var name_label: Label3D = $NameLabel
@onready var quest_marker: Label3D = get_node_or_null("QuestMarker") as Label3D

var _quest_manager: Node = null

func _ready() -> void:
	add_to_group("interactables")
	# O HUD contextual assume nomes e prompts; o mundo fica limpo.
	prompt_label.visible = false
	name_label.visible = false
	call_deferred("_bind_quest_manager")

func interact(_player: Node) -> void:
	if not is_instance_valid(_quest_manager):
		_bind_quest_manager()
	if is_instance_valid(_quest_manager) and _quest_manager.has_method("interact_with_npc"):
		_quest_manager.interact_with_npc(npc_id)
	elif is_instance_valid(_quest_manager) and _quest_manager.has_method("interact_with_quest_giver"):
		_quest_manager.interact_with_quest_giver()

func get_display_name() -> String:
	return display_name

func get_interaction_prompt() -> String:
	return "E  %s com %s" % [interaction_text, display_name]

func _bind_quest_manager() -> void:
	_quest_manager = get_tree().get_first_node_in_group("quest_manager")
	if is_instance_valid(_quest_manager) and _quest_manager.has_signal("quest_changed"):
		if not _quest_manager.quest_changed.is_connected(_on_quest_changed):
			_quest_manager.quest_changed.connect(_on_quest_changed)
	_update_marker()

func _on_quest_changed(_title: String, _objective: String, _progress: int, _goal: int, _state: String) -> void:
	_update_marker()

func _update_marker() -> void:
	if quest_marker == null:
		return
	if not is_instance_valid(_quest_manager) or not _quest_manager.has_method("get_npc_marker"):
		quest_marker.visible = false
		return
	var marker := String(_quest_manager.get_npc_marker(npc_id))
	quest_marker.text = marker
	quest_marker.visible = not marker.is_empty()
	quest_marker.modulate = Color(0.55, 1.0, 0.62, 1.0) if marker == "?" else Color(1.0, 0.82, 0.28, 1.0)
