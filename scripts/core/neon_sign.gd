extends LightSource

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	super._ready()
	var tween = create_tween().set_loops()
	tween.tween_interval(2.0)
	tween.tween_callback(func():
		if is_light_active():
			sprite.frame = (sprite.frame + 1) % sprite.hframes
	)
