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

@export var floor_texture: Texture2D:
	set(v):
		floor_texture = v
		if is_node_ready():
			_floor.texture = v

@export var wall_top_texture: Texture2D:
	set(v):
		wall_top_texture = v
		if is_node_ready():
			_wall_top.texture = v

@export var wall_bottom_texture: Texture2D:
	set(v):
		wall_bottom_texture = v
		if is_node_ready():
			_wall_bottom_sprite.texture = v

@export_range(0.0, 1.0) var wall_hidden_alpha: float = 0.4

@onready var y_sort: Node2D = $YSort

@onready var _floor: Sprite2D = $Floor
@onready var _wall_top: Sprite2D = $WallTop
@onready var _wall_bottom: Node2D = $WallBottom
@onready var _wall_bottom_sprite: Sprite2D = $WallBottom/Sprite
@onready var _transparency_zone: Area2D = $TransparencyZone
@onready var _top_wall: StaticBody2D = $Collisions/TopWall
@onready var _bottom_wall_body: StaticBody2D = $Collisions/BottomWall
@onready var _left_wall: StaticBody2D = $Collisions/LeftWall
@onready var _right_wall: StaticBody2D = $Collisions/RightWall

func _ready() -> void:
	if floor_texture:
		_floor.texture = floor_texture
	if wall_top_texture:
		_wall_top.texture = wall_top_texture
	if wall_bottom_texture:
		_wall_bottom_sprite.texture = wall_bottom_texture
	if Engine.is_editor_hint():
		return
	_update_layout()
	_transparency_zone.body_entered.connect(_on_body_entered)
	_transparency_zone.body_exited.connect(_on_body_exited)

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
	_place_wall(_top_wall, Vector2(w * 0.5, 0.0), Vector2(w, t))
	_place_wall(_bottom_wall_body, Vector2(w * 0.5, h), Vector2(w, t))
	_place_wall(_left_wall, Vector2(0.0, h * 0.5), Vector2(t, h))
	_place_wall(_right_wall, Vector2(w, h * 0.5), Vector2(t, h))
	_transparency_zone.position = Vector2(w * 0.5, h * 0.5)
	var zone_shape := RectangleShape2D.new()
	zone_shape.size = Vector2(w - t * 2.0, h - t * 2.0)
	(_transparency_zone.get_node("Shape") as CollisionShape2D).shape = zone_shape

func _place_wall(body: StaticBody2D, pos: Vector2, size: Vector2) -> void:
	body.position = pos
	var shape := RectangleShape2D.new()
	shape.size = size
	(body.get_node("Shape") as CollisionShape2D).shape = shape

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
