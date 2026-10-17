class_name BarSign
extends LightSource

@onready var sprite: Sprite2D = $Sprite
@onready var light: Light2D = $Light

func _ready() -> void:
	super._ready()
	var tween = create_tween().set_loops()
	tween.tween_interval(1)
	tween.tween_callback(
		func(): 
			if not is_light_active():
				return
			sprite.frame = (sprite.frame + 1) % sprite.hframes
			match sprite.frame:
				0: 
					set_flicker_strength(1.0)
				1:
					set_flicker_strength(0.5)
	)
