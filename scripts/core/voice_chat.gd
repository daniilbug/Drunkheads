class_name VoiceChat
extends Node

@onready var input : AudioStreamPlayer2D = $Input
@onready var output : AudioStreamPlayer2D = $Output

var idx : int
var effect : AudioEffectCapture
var playback : AudioStreamGeneratorPlayback

func _ready() -> void:
	call_deferred("_setup_authority")

func _setup_authority() -> void:
	if is_multiplayer_authority():
		idx = AudioServer.get_bus_index("Record")
		effect = AudioServer.get_bus_effect(idx, 2)
		AudioServer.set_bus_mute(idx, true)
		output.stop()
	else:
		input.stop()
		playback = output.get_stream_playback()

func _process(_delta: float) -> void:
	if not is_multiplayer_authority() or effect == null:
		return
	if effect.can_get_buffer(512):
		send_data.rpc(effect.get_buffer(512))
	effect.clear_buffer()

@rpc("any_peer", "call_remote", "reliable")
func send_data(data : PackedVector2Array):
	if playback == null:
		return
	for i in range(0, 512):
		playback.push_frame(data[i])
