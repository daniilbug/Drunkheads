class_name CafeRecordPlayer
extends StaticBody2D

const TRACKS: Array[AudioStream] = [
	preload("res://assets/audio/cafe/cafe_1.mp3"),
	preload("res://assets/audio/cafe/cafe_2.mp3"),
	preload("res://assets/audio/cafe/cafe_3.mp3"),
	preload("res://assets/audio/cafe/cafe_4.mp3"),
]

@export var playback_position := 0.0

@onready var slot: CafeRecordSlot = $RecordSlot
@onready var audio: AudioStreamPlayer2D = $Audio
@onready var platter: Sprite2D = $Platter
@onready var tonearm: Sprite2D = $Tonearm

var _record_id := -1
var _sync_elapsed := 0.0
var _animation_elapsed := 0.0

func _process(delta: float) -> void:
	var record := slot.get_record()
	var next_id := record.record_id if record != null else -1
	if next_id != _record_id:
		_record_id = next_id
		audio.stop()
		_animation_elapsed = 0.0
		if multiplayer.is_server():
			playback_position = 0.0
		if _record_id >= 0:
			var track := TRACKS[_record_id].duplicate() as AudioStreamMP3
			track.loop = true
			audio.stream = track
			audio.play(fmod(playback_position, track.get_length()))
		platter.visible = _record_id >= 0
		tonearm.frame = 1 if _record_id >= 0 else 0
	if _record_id < 0:
		return
	_animation_elapsed += delta
	platter.frame = _record_id + (int(_animation_elapsed / 0.18) % 4) * 4
	_sync_elapsed += delta
	if _sync_elapsed >= 0.5:
		_sync_elapsed = 0.0
		if multiplayer.is_server():
			playback_position = audio.get_playback_position()
		elif absf(audio.get_playback_position() - playback_position) > 1.0:
			audio.seek(playback_position)
