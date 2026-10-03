class_name CigarettePack
extends Draggable

const SMOKE_DURATION := 3.0
const SMOKE_FRAMES := 8

@onready var smoke_sprite: Sprite2D = $Sprite/Smoke

@export var cigarettes_left: int = 5:
	set(value):
		cigarettes_left = value
		if is_node_ready():
			$Sprite.modulate = Color.WHITE.lerp(Color(0.55, 0.55, 0.55), 1.0 - float(value) / 5.0)

var is_smoking := false
var _smoke_tween: Tween

@rpc("authority", "call_local", "reliable")
func play_smoke() -> void:
	if _smoke_tween:
		_smoke_tween.kill()
	smoke_sprite.frame = 0
	smoke_sprite.show()
	_smoke_tween = create_tween()
	for frame_index in range(1, SMOKE_FRAMES):
		_smoke_tween.tween_interval(SMOKE_DURATION / SMOKE_FRAMES)
		_smoke_tween.tween_callback(_set_smoke_frame.bind(frame_index))
	_smoke_tween.tween_interval(SMOKE_DURATION / SMOKE_FRAMES)
	_smoke_tween.tween_callback(smoke_sprite.hide)

func _set_smoke_frame(frame_index: int) -> void:
	smoke_sprite.frame = frame_index
