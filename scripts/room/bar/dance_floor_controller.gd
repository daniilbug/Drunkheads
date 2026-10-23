class_name DanceFloorController
extends Draggable

signal on_mode_change(mode: int)

const MODES = 4

@onready var audio: AudioStreamPlayer2D = $Audio

@export var mode: int = 0:
	set(value):
		mode = value
		if is_node_ready():
			sprite.frame = mode
			audio.play()

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

func get_save_schema() -> Dictionary:
	return {"mode": [0, 1, 2, 3]}

func apply_save_data(data: Dictionary) -> void:
	super.apply_save_data(data)
	on_mode_change.emit(mode)
