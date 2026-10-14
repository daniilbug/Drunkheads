extends Switch

@export var target_lamp: Lamp

func _ready() -> void:
	on_switch.connect(_toggle_light)

func _toggle_light() -> void:
	if not is_instance_valid(target_lamp):
		return
	if multiplayer.is_server():
		target_lamp.is_turned_on = not target_lamp.is_turned_on
	else:
		_request_toggle.rpc_id(1)

@rpc("any_peer", "reliable")
func _request_toggle() -> void:
	if not multiplayer.is_server():
		return
	var ancestor: Node = get_parent()
	while ancestor != null and not ancestor is Level:
		ancestor = ancestor.get_parent()
	var level := ancestor as Level
	if level == null:
		return
	var player := level.get_player(multiplayer.get_remote_sender_id())
	var switch_area := $Area as Area2D
	if player == null or not switch_area.overlaps_area(player.interaction_area):
		return
	_toggle_light()
