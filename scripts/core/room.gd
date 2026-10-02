@tool
class_name Room
extends Node2D

@export var room_size: Vector2 = Vector2(80, 60):
	set(v):
		room_size = v
		queue_redraw()
		if is_node_ready():
			_update_layout()
			_update_navigation_region()

@export var wall_thickness: float = 4.0:
	set(v):
		wall_thickness = v
		queue_redraw()
		if is_node_ready():
			_update_layout()

@export_range(0.0, 1.0) var wall_hidden_alpha: float = 0.4

@onready var navigation_region: NavigationRegion2D = $NavigationRegion
@onready var y_sort: Node2D = $NavigationRegion/YSort

@onready var _floor: Sprite2D = $Floor
@onready var _wall_top: StaticBody2D = $Walls/Top
@onready var _wall_bottom: StaticBody2D = $Walls/Bottom
@onready var _wall_left: StaticBody2D = $Walls/Left
@onready var _wall_right: StaticBody2D = $Walls/Right
@onready var _wall_top_sprite: Sprite2D = $Walls/Top/Sprite
@onready var _wall_bottom_sprite: Sprite2D = $Walls/Bottom/Sprite
@onready var _transparency_zone: Area2D = $TransparencyZone

func _ready() -> void:
	_update_navigation_region()
	_update_layout()
	if Engine.is_editor_hint():
		return
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
	
func _update_navigation_region() -> void:
	var bounding_outline := PackedVector2Array([
		Vector2.ZERO,
		Vector2(room_size.x, 0.0),
		room_size,
		Vector2(0.0, room_size.y),
	])

	var polygon: NavigationPolygon
	if navigation_region.navigation_polygon:
		polygon = navigation_region.navigation_polygon.duplicate()
	else:
		polygon = NavigationPolygon.new()
		
	polygon.clear_outlines()
	polygon.clear_polygons()
	var source_data := NavigationMeshSourceGeometryData2D.new()
	NavigationServer2D.parse_source_geometry_data(
		polygon,
		source_data,
		self
	)
	source_data.add_traversable_outline(bounding_outline)
	NavigationServer2D.bake_from_source_geometry_data(
		polygon,
		source_data
	)
	navigation_region.navigation_polygon = polygon


	
func _place_wall(body: StaticBody2D, pos: Vector2, size: Vector2) -> void:
	body.position = pos
	var shape := RectangleShape2D.new()
	shape.size = size
	var collisionShape := body.find_child("*Shape") as CollisionShape2D
	collisionShape.shape = shape

func _on_body_entered(body: Node2D) -> void:
	if _is_local_player(body):
		_wall_bottom.z_index = 1
		_tween_wall_alpha(wall_hidden_alpha)

func _on_body_exited(body: Node2D) -> void:
	if _is_local_player(body):
		_wall_bottom.z_index = 0
		_tween_wall_alpha(1.0)

func _is_local_player(body: Node2D) -> bool:
	var level := Level.find_level_node(self)
	return level != null and body == level.local_player

func _tween_wall_alpha(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_wall_bottom, "modulate:a", alpha, 0.2)
