class_name Level
extends Node2D

const PLAYER_SCENE := preload("res://scenes/core/player.tscn")
const BOUNDS_WALL_THICKNESS := 16.0

static func find_level_node(node: Node2D) -> Level:
	var current := node
	while current.get_parent() != null:
		var parent := current.get_parent()
		if parent is not Level:
			current = parent
		else:
			return parent
	return null

var player_spawn: Node2D

@onready var _bounds_body: StaticBody2D = $LevelBounds
@onready var _bottom_left_bound: Marker2D = $LevelBounds/BottomLeft
@onready var _top_right_bound: Marker2D = $LevelBounds/TopRight

var local_player: Player = null

func _ready() -> void:
	_create_bounds_walls()
	if get_parent() is not Main and multiplayer.is_server():
		_spawn_standalone_player()
	for child in get_children():
		if child is Room:
			child.init_room()

func _spawn_standalone_player() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	player.name = str(multiplayer.get_unique_id())
	player.player_name = Player.local_setup.get("name", "Player")
	player.randomize_appearance()
	_prepare_player_spawn(player)
	add_child(player)
	var spawn_point := player_spawn if player_spawn != null else get_node_or_null("PlayerSpawn") as Node2D
	if spawn_point != null:
		player.global_position = spawn_point.global_position
	_init_local_player(player)

func _prepare_player_spawn(_player: Player) -> void:
	pass

func _cleanup_player(peer_id: int) -> void:
	for seat in find_children("*", "Seat", true, false):
		if seat.occupant_name == str(peer_id):
			seat.vacate()
	for child in get_children():
		if child is Draggable and (child as Draggable).holder_peer_id == peer_id:
			child.holder_peer_id = 0

func get_player(peer_id: int) -> Player:
	if peer_id < 0:
		return get_node_or_null(str(peer_id)) as Player
	var main := get_parent() as Main
	return main.get_player(peer_id) if main != null else get_node_or_null(str(peer_id)) as Player

func get_players() -> Array[Player]:
	var main := get_parent() as Main
	if main != null:
		return main.get_players()
	var players: Array[Player] = []
	for child in get_children():
		if child is Player and not child is NPC:
			players.append(child)
	return players

func _init_local_player(player: Player) -> void:
	if local_player != null:
		return
	player.player_data = PlayerData.new()
	player.settings = PlayerSettings.new()
	local_player = player
	var bounds := get_world_bounds()
	player.camera.limit_left = floori(bounds.position.x)
	player.camera.limit_top = floori(bounds.position.y)
	player.camera.limit_right = ceili(bounds.end.x)
	player.camera.limit_bottom = ceili(bounds.end.y)

func get_world_bounds() -> Rect2:
	var a := _bottom_left_bound.global_position
	var b := _top_right_bound.global_position
	var top_left := Vector2(minf(a.x, b.x), minf(a.y, b.y))
	var bottom_right := Vector2(maxf(a.x, b.x), maxf(a.y, b.y))
	return Rect2(top_left, bottom_right - top_left)

func _create_bounds_walls() -> void:
	var a := _bottom_left_bound.position
	var b := _top_right_bound.position
	var left := minf(a.x, b.x)
	var right := maxf(a.x, b.x)
	var top := minf(a.y, b.y)
	var bottom := maxf(a.y, b.y)
	var thickness := BOUNDS_WALL_THICKNESS
	if right <= left or bottom <= top:
		push_error("Level bounds must have a positive width and height")
		return
	_create_bounds_wall("Top", Vector2((left + right) / 2.0, top - thickness / 2.0), Vector2(right - left + thickness * 2.0, thickness))
	_create_bounds_wall("Bottom", Vector2((left + right) / 2.0, bottom + thickness / 2.0), Vector2(right - left + thickness * 2.0, thickness))
	_create_bounds_wall("Left", Vector2(left - thickness / 2.0, (top + bottom) / 2.0), Vector2(thickness, bottom - top))
	_create_bounds_wall("Right", Vector2(right + thickness / 2.0, (top + bottom) / 2.0), Vector2(thickness, bottom - top))

func _create_bounds_wall(wall_name: String, wall_position: Vector2, size: Vector2) -> void:
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	var wall := CollisionShape2D.new()
	wall.name = wall_name
	wall.position = wall_position
	wall.shape = rectangle
	_bounds_body.add_child(wall)

func _init_npc(npc: NPC) -> void:
	npc.player_data = PlayerData.new()
