@tool
class_name TableFootballServeOverlay
extends Node2D

@export var field_width: int = 330
@export var field_height: int = 560
@export var color_overlay: Color = Color(0, 0, 0, 0.5)

var aim_angle: float = 0.0
var dir_y: float = 1.0

func _draw() -> void:
	draw_rect(Rect2(0, 0, field_width, field_height), color_overlay)

	var cx := field_width * 0.5
	var cy := field_height * 0.5

	var arrow_len := 48.0
	var dx := sin(aim_angle) * arrow_len
	var dy := cos(aim_angle) * arrow_len * dir_y
	var tip := Vector2(cx + dx, cy + dy)
	var base := Vector2(cx, cy)

	draw_line(base, tip, Color("f0d060"), 2.0)
	var perp := Vector2(-dy, dx).normalized() * 6.0
	draw_line(tip, tip - Vector2(dx, dy).normalized() * 12.0 + perp, Color("f0d060"), 2.0)
	draw_line(tip, tip - Vector2(dx, dy).normalized() * 12.0 - perp, Color("f0d060"), 2.0)

	draw_string(
		ThemeDB.fallback_font,
		Vector2(cx - 90.0, cy - 28.0),
		"PRESS  E  TO  SERVE",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18,
		Color("f0d060")
	)
