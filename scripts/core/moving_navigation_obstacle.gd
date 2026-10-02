extends NavigationObstacle2D

@export var max_reported_speed := 350.0

var _last_position: Vector2
var _has_last_position := false

func _ready() -> void:
	avoidance_enabled = multiplayer.is_server()

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if not _has_last_position:
		_last_position = global_position
		_has_last_position = true
		return
	velocity = ((global_position - _last_position) / delta).limit_length(max_reported_speed)
	_last_position = global_position
