extends Node2D

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	var tween = create_tween().set_loops()
	tween.tween_interval(2.0)
	tween.tween_callback(func(): sprite.frame = (sprite.frame + 1) % sprite.hframes)
