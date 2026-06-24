class_name Boombox
extends Draggable

const FRAMES = 4

func _ready() -> void:
	sprite = $Sprite
	_start_playing_animation()

func _start_playing_animation() -> void:
	var tween := create_tween().set_loops()
	tween.tween_interval(0.15)
	tween.tween_callback(func(): sprite.frame = (sprite.frame + 1) % FRAMES)
