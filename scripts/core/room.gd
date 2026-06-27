@tool
class_name Room
extends Node2D

@export var room_size: Vector2 = Vector2(80, 60):
	set(v):
		room_size = v
		queue_redraw()
		if is_node_ready():
			_update_layout()

@export var wall_thickness: float = 4.0:
	set(v):
		wall_thickness = v
		queue_redraw()
		if is_node_ready():
			_update_layout()

@export_range(0.0, 1.0) var wall_hidden_alpha: float = 0.4

@onready var y_sort: Node2D = $YSort

@onready var _floor: Sprite2D = $Floor
@onready var _wall_top: StaticBody2D = $Walls/Top
@onready var _wall_bottom: StaticBody2D = $Walls/Bottom
@onready var _wall_left: StaticBody2D = $Walls/Left
@onready var _wall_right: StaticBody2D = $Walls/Right
@onready var _wall_top_sprite: Sprite2D = $Walls/Top/Sprite
@onready var _wall_bottom_sprite: Sprite2D = $Walls/Bottom/Sprite
@onready var _transparency_zone: Area2D = $TransparencyZone

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_update_layout()
	_transparency_zone.body_entered.connect(_on_body_entered)
	_transparency_zone.body_exited.connect(_on_body_exited)

func get_walls() -> Array[StaticBody2D]:
	var children = $Walls.get_children()
	var bodies = children.filter(func(node): return node is StaticBody2D)
	var walls: Array[StaticBody2D] = []
	walls.assign(bodies)
	return walls

func init_room() -> void:
	pass

func _init_draggable(draggable: Draggable) -> void:
	var level = Level.find_level_node(self)
	level.init_draggable(draggable)

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_rect(Rect2(Vector2.ZERO, room_size), Color(0.3, 0.6, 1.0, 0.07), true)
	draw_rect(Rect2(Vector2.ZERO, room_size), Color(0.3, 0.6, 1.0, 0.8), false)

func _update_layout() -> void:
	var w := room_size.x
	var h := room_size.y
	var t := wall_thickness
	_place_wall(_wall_top, Vector2(w * 0.5, 0.0), Vector2(w, t))
	_place_wall(_wall_bottom, Vector2(w * 0.5, h), Vector2(w, t))
	_place_wall(_wall_left, Vector2(0.0, h * 0.5), Vector2(t, h))
	_place_wall(_wall_right, Vector2(w, h * 0.5), Vector2(t, h))
	_transparency_zone.position = Vector2(w * 0.5, h * 0.5)
	var zone_shape := RectangleShape2D.new()
	zone_shape.size = Vector2(w - t * 2.0, h - t * 2.0)
	(_transparency_zone.get_node("Shape") as CollisionShape2D).shape = zone_shape

func _place_wall(body: StaticBody2D, pos: Vector2, size: Vector2) -> void:
	body.position = pos
	var shape := RectangleShape2D.new()
	shape.size = size
	var collisionShape := body.find_child("*Shape") as CollisionShape2D
	collisionShape.shape = shape

func _on_body_entered(body: Node2D) -> void:
	if body is Player and (body as Player).is_multiplayer_authority():
		_wall_bottom.z_index = 1
		_tween_wall_alpha(wall_hidden_alpha)

func _on_body_exited(body: Node2D) -> void:
	if body is Player and (body as Player).is_multiplayer_authority():
		_wall_bottom.z_index = 0
		_tween_wall_alpha(1.0)

func _tween_wall_alpha(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_wall_bottom, "modulate:a", alpha, 0.2)
