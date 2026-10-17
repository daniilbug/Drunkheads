@tool
class_name PhoneMusicWave
extends Control

const BAR_WEIGHTS: Array[float] = [0.5, 0.75, 1.0, 0.7, 0.45]

@export var color := Color("d9af5b"):
	set(value):
		color = value
		queue_redraw()

var playback_position := 0.0
var playing := false

func update_playback(position_seconds: float, is_playing: bool) -> void:
	playback_position = position_seconds
	playing = is_playing
	queue_redraw()

func _draw() -> void:
	# Integer pixel steps match the phone's nearest-filtered sprites.
	var bar_width := floorf(size.x / 8.0 / 2.0) * 2.0
	var gap := (size.x - bar_width * BAR_WEIGHTS.size()) / (BAR_WEIGHTS.size() - 1)
	for i in BAR_WEIGHTS.size():
		var height := 4.0
		if playing or Engine.is_editor_hint():
			var pulse := 0.65 + 0.35 * sin(playback_position * (6.0 + i * 0.7) + i * 1.8)
			height = maxf(4.0, floorf(size.y * BAR_WEIGHTS[i] * pulse / 2.0) * 2.0)
		var x := roundf(i * (bar_width + gap) / 2.0) * 2.0
		draw_rect(Rect2(x, size.y - height, bar_width, height), color)
