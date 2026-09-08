extends Node

## Presentation-only cleanup for procedural regions.
## This script never changes collision, quest state or gameplay. It only removes
## permanent billboard text that competes with the compact HUD.

func _ready() -> void:
	call_deferred("_apply_presentation")

func _apply_presentation() -> void:
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	_hide_landmark_billboards(scene_root)

func _hide_landmark_billboards(node: Node) -> void:
	if node is Label3D:
		var parent := node.get_parent()
		if parent != null and parent.name == "LandmarkSign":
			(node as Label3D).visible = false

	for child in node.get_children():
		_hide_landmark_billboards(child)
