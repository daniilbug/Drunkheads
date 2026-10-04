@tool
class_name HomeRoom
extends Room

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, room_size), Color("#b5a28c"))
	for y in range(12, int(room_size.y), 12):
		draw_line(Vector2(4, y), Vector2(room_size.x - 4, y), Color("#a3907a"), 1.0)
	for x in range(20, int(room_size.x), 40):
		draw_line(Vector2(x, 4), Vector2(x, room_size.y - 4), Color("#aa977f"), 1.0)
	draw_rect(Rect2(0, 0, room_size.x, 5), Color("#625a56"))
	draw_rect(Rect2(0, room_size.y - 5, room_size.x, 5), Color("#625a56"))
	draw_rect(Rect2(0, 0, 5, room_size.y), Color("#625a56"))
	draw_rect(Rect2(room_size.x - 5, 0, 5, room_size.y), Color("#625a56"))
	super._draw()
