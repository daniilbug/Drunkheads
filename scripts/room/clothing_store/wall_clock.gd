@tool
extends Sprite2D

var _world_time: WorldTime
var _minute := 610 # Editor preview: 10:10.


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var level := Level.find_level_node(self)
	if level == null:
		return
	if level.world_time != null:
		_bind_world_time(level.world_time)
	else:
		level.world_time_ready.connect(_bind_world_time, CONNECT_ONE_SHOT)


func _exit_tree() -> void:
	if is_instance_valid(_world_time) and _world_time.time_changed.is_connected(_on_time_changed):
		_world_time.time_changed.disconnect(_on_time_changed)
	_world_time = null


func _bind_world_time(clock: WorldTime) -> void:
	_world_time = clock
	clock.time_changed.connect(_on_time_changed)
	_on_time_changed(clock.get_hour())


func _on_time_changed(hour: float) -> void:
	var minute := int(floorf(hour * 60.0))
	if minute != _minute:
		_minute = minute
		queue_redraw()


func _draw() -> void:
	var center := Vector2.ZERO
	var color := Color("6d7874")
	var hour_tip := center + (Vector2.UP.rotated((_minute % 720) / 720.0 * TAU) * 3.0).round()
	draw_line(center, hour_tip, color, 1.0)
	draw_rect(Rect2(-1, -1, 2, 2), color)
