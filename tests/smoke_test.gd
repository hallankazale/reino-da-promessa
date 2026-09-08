extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	_check_resource("res://scenes/world/main.tscn")
	_check_resource("res://scenes/player/player.tscn")
	_check_resource("res://scenes/enemies/training_enemy.tscn")
	_check_resource("res://scripts/player/player_controller.gd")
	_check_resource("res://scripts/enemies/training_enemy.gd")
	_check_resource("res://scripts/ui/hud.gd")

	for action in ["move_forward", "move_back", "move_left", "move_right", "target_next", "attack"]:
		if not InputMap.has_action(action):
			failures.append("Input ausente: %s" % action)

	if failures.is_empty():
		print("SMOKE TEST OK: cenas, scripts e inputs essenciais carregaram.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)

func _check_resource(path: String) -> void:
	if load(path) == null:
		failures.append("Falha ao carregar: %s" % path)
