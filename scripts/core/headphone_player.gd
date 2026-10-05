class_name HeadphonePlayer
extends AudioStreamPlayer

signal changed

const PLAYLIST: AudioStreamPlaylist = preload("res://assets/audio/background/playlist.tres")

var track_index := 0
var enabled := false

var player: Player
var _world_was_muted := false
@onready var _world_bus := AudioServer.get_bus_index("World")

func _ready() -> void:
	stream = PLAYLIST.get_list_stream(track_index)
	finished.connect(select_relative.bind(1))

func _exit_tree() -> void:
	if enabled:
		AudioServer.set_bus_mute(_world_bus, _world_was_muted)

func toggle() -> void:
	enabled = not enabled
	if enabled:
		_world_was_muted = AudioServer.is_bus_mute(_world_bus)
	stream_paused = not enabled
	if enabled and not has_stream_playback():
		play()
	AudioServer.set_bus_mute(_world_bus, true if enabled else _world_was_muted)
	if player != null:
		player.headphones_enabled = enabled
	changed.emit()

func select_relative(offset: int) -> void:
	track_index = posmod(track_index + offset, PLAYLIST.stream_count)
	stream = PLAYLIST.get_list_stream(track_index)
	if enabled:
		play()
