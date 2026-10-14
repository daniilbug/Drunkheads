class_name HomeShower
extends Sink

func _on_inside_body_entered(body: Node2D) -> void:
	if multiplayer.is_server() and body is Player and not body is NPC:
		(body as Player).in_shower = true

func _on_inside_body_exited(body: Node2D) -> void:
	if multiplayer.is_server() and body is Player and not body is NPC:
		(body as Player).in_shower = false
