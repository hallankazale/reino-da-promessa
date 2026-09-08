extends Node3D

@export var display_name: String = "Eliabe"
@export var interaction_text: String = "Falar"

@onready var prompt_label: Label3D = $PromptLabel

func _ready() -> void:
	add_to_group("interactables")
	# Prompt 3D permanente poluia a cena. A HUD contextual assume essa funcao.
	prompt_label.visible = false

func interact(_player: Node) -> void:
	var quest_manager := get_tree().get_first_node_in_group("quest_manager")
	if is_instance_valid(quest_manager) and quest_manager.has_method("interact_with_quest_giver"):
		quest_manager.interact_with_quest_giver()

func get_display_name() -> String:
	return display_name

func get_interaction_prompt() -> String:
	return "E  %s com %s" % [interaction_text, display_name]
