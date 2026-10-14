extends Lamp

@onready var _bulb_sprite: Sprite2D = $Sprite

func _ready() -> void:
	_light.visibility_changed.connect(_update_bulb_tint)
	_light.visible = is_turned_on
	_update_bulb_tint()

func _update_bulb_tint() -> void:
	_bulb_sprite.self_modulate = Color.WHITE if _light.visible else Color(0.42, 0.42, 0.42)
