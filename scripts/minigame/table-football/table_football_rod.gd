class_name TableFootballRod
extends Node2D

@export var kicker_count: int = 3:
	set(value):
		kicker_count = value
		if is_node_ready():
			_update_kicker_visibility()
@export var team: int = 0

@export var field_width: int = 330
@export var wall_thickness: int = 8
@export var player_width: int = 6
@export var player_height: int = 24
@export var max_kick: float = 18.0
@export var kick_speed: float = 360.0
@export var kick_impulse: float = 22.0
@export var slide_speed: float = 180.0
@export var slide_impulse: float = 8.0

@export var color_rod_wood: Color = Color("c8a87e")
@export var color_rod_sel: Color = Color("f0d060")

var color_player: Color = Color("4b7dc8")
var color_player_dk: Color = Color("2a4a80")

var slide_pos: float
var kick_offset: float = 0.0
var is_selected: bool = false

var _kicker_bodies: Array[StaticBody2D] = []
var _prev_kick_offset: float = 0.0
var _prev_slide_pos: float = 0.0

func _ready() -> void:
	for child in get_children():
		if child is StaticBody2D:
			_kicker_bodies.append(child)
	slide_pos = _compute_center_slide()
	_update_kicker_visibility()

func _kicker_min_x() -> float:
	return wall_thickness + player_width * 0.5

func _kicker_max_x() -> float:
	return float(field_width) - wall_thickness - player_width * 0.5

func _compute_center_slide() -> float:
	var spacing := _spacing()
	var min_slide := _kicker_min_x()
	var max_slide := _kicker_max_x() - spacing * (float(kicker_count) - 1.0)
	return (min_slide + max_slide) * 0.5

func _spacing() -> float:
	return (float(field_width) - wall_thickness * 2) / float(kicker_count)

func _physics_process(_delta: float) -> void:
	var kick_delta := kick_offset - _prev_kick_offset
	_prev_kick_offset = kick_offset

	var slide_delta := slide_pos - _prev_slide_pos
	_prev_slide_pos = slide_pos

	var spacing := _spacing()
	for i in range(mini(kicker_count, _kicker_bodies.size())):
		var px := clampf(spacing * i + slide_pos, _kicker_min_x(), _kicker_max_x())
		_kicker_bodies[i].position = Vector2(px, kick_offset)

		if absf(kick_delta) > 0.001 or absf(slide_delta) > 0.001:
			var shape_node := _kicker_bodies[i].get_child(0) as CollisionShape2D
			if shape_node != null:
				var space := get_world_2d().direct_space_state
				var query := PhysicsShapeQueryParameters2D.new()
				query.shape = shape_node.shape
				query.transform = _kicker_bodies[i].global_transform
				var results := space.intersect_shape(query, 8)
				for r in results:
					if r.collider is RigidBody2D:
						var impulse := Vector2(slide_delta * slide_impulse, kick_delta * kick_impulse)
						r.collider.apply_central_impulse(impulse)
						if r.collider is TableFootballBallPhysics:
							r.collider.trigger_hit_flash(impulse.length())

func _process(_delta: float) -> void:
	queue_redraw()

func set_state(slide: float, kick: float) -> void:
	slide_pos = slide
	kick_offset = kick
	_prev_slide_pos = slide
	_prev_kick_offset = kick

func _update_kicker_visibility() -> void:
	for i in range(_kicker_bodies.size()):
		_kicker_bodies[i].collision_layer = 2 if i < kicker_count else 0

func _draw() -> void:
	var rod_col := color_rod_sel if is_selected else color_rod_wood
	draw_rect(Rect2(wall_thickness, -1, field_width - wall_thickness * 2, 2), rod_col)

	if is_selected:
		draw_line(Vector2(-12, -4), Vector2(-6, 0), color_rod_sel, 2.0)
		draw_line(Vector2(-12, 4), Vector2(-6, 0), color_rod_sel, 2.0)

	var spacing := _spacing()
	for i in range(kicker_count):
		var px := clampf(spacing * i + slide_pos, _kicker_min_x(), _kicker_max_x())
		_draw_kicker(px, kick_offset, color_player, color_player_dk)

func _draw_kicker(px: float, py: float, col: Color, dark: Color) -> void:
	var pw := float(player_width)
	var ph := float(player_height)
	draw_rect(Rect2(px - pw * 0.5, py - ph * 0.5, pw, ph), col)
	draw_rect(Rect2(px - pw * 0.5, py - ph * 0.5, pw, 2), dark)
	draw_rect(Rect2(px - pw * 0.5, py - ph * 0.5, 1, ph), Color(col.r + 0.15, col.g + 0.15, col.b + 0.15))
