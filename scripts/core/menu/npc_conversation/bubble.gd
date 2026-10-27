class_name NPCConversationBubble
extends Control

@onready var body: NinePatchRect = $Body
@onready var tail: Sprite2D = $Tail

func show_at(rect: Rect2, head: Vector2, fill: Color) -> void:
	position = rect.position
	size = rect.size
	body.self_modulate = fill
	tail.self_modulate = fill
	if head.y >= rect.end.y:
		tail.rotation = 0
		tail.position = Vector2(clampf(head.x - position.x, 16, size.x - 16), size.y + 6)
	elif head.y <= rect.position.y:
		tail.rotation = PI
		tail.position = Vector2(clampf(head.x - position.x, 16, size.x - 16), -6)
	else:
		var right := head.x > rect.get_center().x
		tail.rotation = -PI / 2 if right else PI / 2
		tail.position = Vector2(size.x + 6 if right else -6, clampf(head.y - position.y, 16, size.y - 16))
	show()
