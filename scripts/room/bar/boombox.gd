class_name Boombox
extends Draggable

const PLAYING_FRAMES = 4

@onready var audio: AudioStreamPlayer2D = $Audio

@export var is_playing: bool = true:
	set(value):
		is_playing = value
		audio.stream_paused = not value
		if is_node_ready():
			if value:
				_playing_tween.play()
			else:
				_playing_tween.pause()
				sprite.frame = 0

var _playing_tween: Tween

func _ready() -> void:
	sprite = $Sprite
	_playing_tween = create_tween().set_loops()
	_playing_tween.tween_interval(0.15)
	_playing_tween.tween_callback(func(): sprite.frame = (sprite.frame + 1) % PLAYING_FRAMES)
	if multiplayer.is_server():
		resume()

func switch():
	if is_playing:
		pause()
	else:
		resume()

func resume():
	if multiplayer.is_server():
		_local_resume()
	else:
		_remote_resume.rpc_id(get_multiplayer_authority())

func pause():
	if multiplayer.is_server():
		_local_pause()
	else:
		_remote_pause.rpc_id(get_multiplayer_authority())
	
@rpc("any_peer", "reliable")
func _remote_resume():
	if not multiplayer.is_server():
		return
	_local_resume()
	
@rpc("any_peer", "reliable")
func _remote_pause():
	if not multiplayer.is_server():
		return
	_local_pause()
	
func _local_resume():
	is_playing = true
	
func _local_pause():
	is_playing = false
