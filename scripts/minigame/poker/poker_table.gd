extends Node2D

@export var color_overlay: Color = Color(0, 0, 0, 0.78)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), color_overlay)
