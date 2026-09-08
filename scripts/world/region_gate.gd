extends Node3D

signal used(destination_name: String)

@export var destination_name: String = "Vale das Fontes"
@export var destination_position: Vector3 = Vector3(120.0, 1.15, 22.0)
@export var locked_message: String = "A passagem esta selada. Conclua a missao de Eliabe primeiro."

@onready var barrier_visual: MeshInstance3D = $LockedBarrier/BarrierVisual
@onready var barrier_collision: CollisionShape3D = $LockedBarrier/CollisionShape3D
@onready var portal_plane: MeshInstance3D = $PortalPlane
@onready var portal_light: OmniLight3D = $PortalLight
@onready var label: Label3D = $Label

func _ready() -> void:
	add_to_group("interactables")
	add_to_group("region_gates")
	call_deferred("_connect_quest_manager")
	call_deferred("_sync_state")

func interact(player: Node) -> void:
	if not is_instance_valid(player) or not player is Node3D:
		return
	if not _is_unlocked():
		_announce(locked_message)
		return

	var body := player as Node3D
	body.global_position = destination_position
	if body is CharacterBody3D:
		(body as CharacterBody3D).velocity = Vector3.ZERO
	_announce("Voce chegou a: %s." % destination_name)
	used.emit(destination_name)

func is_unlocked() -> bool:
	return _is_unlocked()

func _connect_quest_manager() -> void:
	var quest_manager := _quest_manager()
	if quest_manager == null:
		return
	if quest_manager.has_signal("quest_changed") and not quest_manager.quest_changed.is_connected(_on_quest_changed):
		quest_manager.quest_changed.connect(_on_quest_changed)

func _on_quest_changed(_title: String, _objective: String, _progress: int, _goal: int, _state: String) -> void:
	_sync_state()

func _sync_state() -> void:
	var unlocked := _is_unlocked()
	barrier_visual.visible = not unlocked
	barrier_collision.set_deferred("disabled", unlocked)
	portal_plane.visible = unlocked
	portal_light.visible = unlocked
	label.text = "%s  [E]" % destination_name if unlocked else "Passagem Selada"
	label.modulate = Color(0.74, 0.95, 1.0, 1.0) if unlocked else Color(0.78, 0.68, 0.52, 1.0)

func _is_unlocked() -> bool:
	var quest_manager := _quest_manager()
	return quest_manager != null and quest_manager.has_method("is_first_quest_completed") and quest_manager.is_first_quest_completed()

func _announce(message: String) -> void:
	var quest_manager := _quest_manager()
	if quest_manager != null and quest_manager.has_method("announce"):
		quest_manager.announce(message)

func _quest_manager() -> Node:
	return get_tree().get_first_node_in_group("quest_manager")
