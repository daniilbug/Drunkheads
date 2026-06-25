class_name DanceFloorController
extends Draggable

signal on_mode_change(mode: int)

const MODES = 4

@export var mode: int = 0:
	set(value):
		mode = value
		sprite.frame = mode

func _ready() -> void:
	sprite = $Sprite
	
func next_mode() -> void:
	if multiplayer.is_server():
		_local_next_mode()
	else:
		_remote_next_mode.rpc_id(get_multiplayer_authority())

@rpc("any_peer", "reliable")
func _remote_next_mode() -> void:
	if not multiplayer.is_server():
		return
	_local_next_mode()
	
func _local_next_mode() -> void:
	mode = (mode + 1) % MODES
	on_mode_change.emit(mode)
