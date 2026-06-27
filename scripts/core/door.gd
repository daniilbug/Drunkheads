@tool
class_name Door
extends Node2D

@export var is_open: bool = false:
	set(v):
		is_open = v
		if is_node_ready():
			_apply_state()

@onready var _closed_sprite: Sprite2D = $ClosedSprite
@onready var _open_sprite: Sprite2D = $OpenSprite
@onready var _collision: CollisionShape2D = $Body/Shape

func _ready() -> void:
	_apply_state()
	if not Engine.is_editor_hint():
		_punch_wall_hole()

func toggle() -> void:
	is_open = not is_open

func _apply_state() -> void:
	_closed_sprite.visible = not is_open
	_open_sprite.visible = is_open
	_collision.disabled = is_open

func _punch_wall_hole() -> void:
	var room := get_parent() as Room
	if not room:
		return
	var walls := room.get_walls()
	if not walls:
		return

	var door_center := room.to_local(_collision.global_position)
	var door_shape := _collision.shape as RectangleShape2D
	if not door_shape:
		return
	var door_hw := door_shape.size.x * 0.5
	var door_hh := door_shape.size.y * 0.5

	for wall in walls:
		var shape_node := wall.find_child("*Shape") as CollisionShape2D
		print(shape_node)
		if not shape_node:
			continue
		var wall_shape := shape_node.shape as RectangleShape2D
		if not wall_shape:
			continue
			
		var wall_center := wall.position
		var wall_hw := wall_shape.size.x * 0.5
		var wall_hh := wall_shape.size.y * 0.5

		if abs(door_center.x - wall_center.x) >= wall_hw + door_hw:
			continue
		if abs(door_center.y - wall_center.y) >= wall_hh + door_hh:
			continue

		shape_node.disabled = true

		if wall_hw >= wall_hh:
			_add_h_segment(wall, wall_center.x - wall_hw, door_center.x - door_hw, wall_hh * 2.0)
			_add_h_segment(wall, door_center.x + door_hw, wall_center.x + wall_hw, wall_hh * 2.0)
		else:
			_add_v_segment(wall, wall_center.y - wall_hh, door_center.y - door_hh, wall_hw * 2.0)
			_add_v_segment(wall, door_center.y + door_hh, wall_center.y + wall_hh, wall_hw * 2.0)
		break

func _add_h_segment(wall: StaticBody2D, x_from: float, x_to: float, height: float) -> void:
	var w := x_to - x_from
	if w <= 0.0:
		return
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, height)
	var col := CollisionShape2D.new()
	col.position = Vector2((x_from + x_to) * 0.5 - wall.position.x, 0.0)
	col.shape = shape
	wall.add_child(col)

func _add_v_segment(wall: StaticBody2D, y_from: float, y_to: float, width: float) -> void:
	var h := y_to - y_from
	if h <= 0.0:
		return
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, h)
	var col := CollisionShape2D.new()
	col.position = Vector2(0.0, (y_from + y_to) * 0.5 - wall.position.y)
	col.shape = shape
	wall.add_child(col)
