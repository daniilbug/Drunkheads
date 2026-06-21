class_name FloatingText
extends Label

static func spawn(parent: Node, pos: Vector2, msg: String, color: Color = Color.WHITE) -> void:
	var ft := FloatingText.new()
	ft.text = msg
	ft.modulate = color
	ft.position = pos + Vector2(-16.0, -24.0)
	ft.z_index = 100
	ft.add_theme_font_size_override("font_size", 7)
	parent.add_child(ft)

	var move := ft.create_tween()
	move.tween_property(ft, "position:y", ft.position.y - 20.0, 1.0) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	move.tween_callback(ft.queue_free)

	var fade := ft.create_tween()
	fade.tween_interval(0.35)
	fade.tween_property(ft, "modulate:a", 0.0, 0.65)
