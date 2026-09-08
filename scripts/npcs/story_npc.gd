extends Node3D
class_name StoryNPC

## Reusable NPC interaction controller. Presentation stays in each scene, while
## quest ownership and progression live in QuestManager.

@export var npc_id: String = ""
@export var display_name: String = "NPC"
@export var interaction_text: String = "Falar"

@onready var quest_marker: Label3D = get_node_or_null("QuestMarker") as Label3D

var _quest_manager: Node = null

func _ready() -> void:
	add_to_group("interactables")
	call_deferred("_bind_quest_manager")

func interact(_player: Node) -> void:
	if not is_instance_valid(_quest_manager):
		_bind_quest_manager()
	if is_instance_valid(_quest_manager) and _quest_manager.has_method("interact_with_npc"):
		_quest_manager.interact_with_npc(npc_id)

func get_display_name() -> String:
	return display_name

func get_interaction_prompt() -> String:
	return "E  %s com %s" % [interaction_text, display_name]

func _bind_quest_manager() -> void:
	_quest_manager = get_tree().get_first_node_in_group("quest_manager")
	if not is_instance_valid(_quest_manager):
		_update_marker()
		return
	if _quest_manager.has_signal("quest_changed") and not _quest_manager.quest_changed.is_connected(_on_quest_changed):
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
	if marker == "?":
		quest_marker.modulate = Color(0.55, 1.0, 0.62, 1.0)
	else:
		quest_marker.modulate = Color(1.0, 0.82, 0.28, 1.0)
