class_name Sink
extends Interactable

const WATERING_FRAMES = 5

@onready var sprite: Sprite2D = $Sprite
@onready var audio: AudioStreamPlayer2D = $Audio

@export var is_watering: bool = false:
	set(value):
		is_watering = value
		if is_node_ready():
			if value:
				_playing_tween.play()
				audio.play()
			else:
				_playing_tween.pause()
				sprite.frame = 0
				audio.stop()

var _playing_tween: Tween

func _ready() -> void:
	_playing_tween = create_tween().set_loops()
	_playing_tween.tween_interval(0.15)
	_playing_tween.tween_callback(
		func(): sprite.frame = (sprite.frame + 1) % WATERING_FRAMES + 1
	)
	_playing_tween.stop()

func interact() -> void:
	if is_watering:
		turn_off()
	else:
		turn_on()

func turn_on():
	if multiplayer.is_server():
		_local_turn_on()
	else:
		_remote_turn_on.rpc_id(get_multiplayer_authority())

func turn_off():
	if multiplayer.is_server():
		_local_turn_off()
	else:
		_remote_turn_off.rpc_id(get_multiplayer_authority())
	
@rpc("any_peer", "reliable")
func _remote_turn_on():
	if not multiplayer.is_server():
		return
	_local_turn_on()
	
@rpc("any_peer", "reliable")
func _remote_turn_off():
	if not multiplayer.is_server():
		return
	_local_turn_off()
	
func _local_turn_on():
	is_watering = true
	
func _local_turn_off():
	is_watering = false
