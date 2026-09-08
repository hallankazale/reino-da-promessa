extends Label3D

@export var rise_distance: float = 1.15
@export var lifetime: float = 0.65

func show_value(amount: int, tint: Color = Color(1.0, 0.76, 0.28, 1.0)) -> void:
	text = "-%d" % maxi(amount, 0)
	modulate = tint

	var start_position := position
	var end_position := start_position + Vector3(0, rise_distance, 0)
	var end_color := Color(tint.r, tint.g, tint.b, 0.0)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", end_position, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate", end_color, lifetime)
	tween.chain().tween_callback(queue_free)
