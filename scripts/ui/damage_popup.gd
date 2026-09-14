extends Label3D

@export var rise_distance: float = 1.15
@export var lifetime: float = 0.72

## API usada pelo combate. Mantemos setup() como ponto de entrada para que o
## popup fique desacoplado da entidade que o criou.
func setup(amount: int, tint: Color = Color(1.0, 0.76, 0.28, 1.0)) -> void:
	show_value(amount, tint)

func show_value(amount: int, tint: Color = Color(1.0, 0.76, 0.28, 1.0)) -> void:
	text = "-%d" % maxi(amount, 0)
	modulate = tint
	scale = Vector3.ONE * 0.72

	var start_position := position
	var horizontal_drift := 0.14 if amount % 2 == 0 else -0.14
	var end_position := start_position + Vector3(horizontal_drift, rise_distance, 0)
	var end_color := Color(tint.r, tint.g, tint.b, 0.0)

	var motion_tween := create_tween()
	motion_tween.set_parallel(true)
	motion_tween.tween_property(self, "position", end_position, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	motion_tween.tween_property(self, "modulate", end_color, lifetime).set_delay(0.18)
	motion_tween.chain().tween_callback(queue_free)

	var punch_tween := create_tween()
	punch_tween.tween_property(self, "scale", Vector3.ONE * 1.18, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	punch_tween.tween_property(self, "scale", Vector3.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
