@tool
extends Room


func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		$Walls/Top/Mirrors.hide()


func _on_body_entered(body: Node2D) -> void:
	super._on_body_entered(body)
	if _is_local_player(body):
		$Walls/Top/Mirrors.show()


func reset_wall_visibility() -> void:
	super.reset_wall_visibility()
	if is_node_ready() and not Engine.is_editor_hint():
		$Walls/Top/Mirrors.hide()
