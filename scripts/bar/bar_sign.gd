class_name BarSign
extends Node2D

@onready var sprite: Sprite2D = $Sprite
@onready var light: Light2D = $Light

func _ready() -> void:
	var tween = create_tween().set_loops()
	tween.tween_interval(1)
	tween.tween_callback(
		func(): 
			sprite.frame = (sprite.frame + 1) % sprite.hframes
			match sprite.frame:
				0: 
					light.energy = 1.0
				1:
					light.energy = 0.5
	)
