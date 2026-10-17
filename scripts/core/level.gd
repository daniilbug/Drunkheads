class_name Level
extends Node2D

signal world_time_ready(clock: WorldTime)

const PLAYER_SCENE := preload("res://scenes/core/player.tscn")
const WORLD_TIME_SCENE := preload("res://scenes/core/world_time.tscn")
const BOUNDS_WALL_THICKNESS := 16.0

@export var transport_destination: TransportDestination
@export var transport_arrival_interior := false
@export var transport_arrival_path: NodePath = ^"PlayerSpawn"

static func find_level_node(node: Node2D) -> Level:
	var current: Node = node
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
var world_time: WorldTime

func _ready() -> void:
	if get_parent() is Main:
		world_time = get_parent().get_node("WorldTime") as WorldTime
	else:
		world_time = WORLD_TIME_SCENE.instantiate() as WorldTime
		add_child(world_time)
	world_time_ready.emit(world_time)
	_create_bounds_walls()
	if get_parent() is not Main and multiplayer.is_server():
		_spawn_standalone_player()
	for child in get_children():
		if child is Room:
			child.init_room()

func _spawn_standalone_player() -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	player.name = str(multiplayer.get_unique_id())
	if transport_destination != null:
		player.level_id = transport_destination.id
	player.player_name = Player.local_setup.get("name", "Player")
	player.randomize_appearance()
	_prepare_player_spawn(player)
	add_child(player)
	var spawn_point := get_node_or_null("TaxiReturn") as Node2D
	if spawn_point == null:
		spawn_point = player_spawn if player_spawn != null else get_node_or_null("PlayerSpawn") as Node2D
	if spawn_point != null:
		player.global_position = spawn_point.global_position
	_init_local_player(player)

func _prepare_player_spawn(_player: Player) -> void:
	pass

func get_transport_stop() -> TransportStop:
	for stop in find_children("*", "TransportStop", true, false):
		return stop as TransportStop
	return null

func get_taxi_stop() -> TaxiStop:
	var stop := get_transport_stop()
	return stop.get_node("TaxiStop") as TaxiStop if stop != null else null

func get_bus_stop() -> BusStop:
	var stop := get_transport_stop()
	return stop.get_node("BusStop") as BusStop if stop != null else null

func get_transport_arrival_position() -> Vector2:
	var stop := get_transport_stop()
	if not transport_arrival_interior and stop != null:
		return stop.get_exit_position()
	var marker := get_node_or_null(transport_arrival_path) as Node2D
	return marker.global_position if marker != null else global_position

func supports_transport() -> bool:
	if transport_arrival_interior:
		return get_node_or_null(transport_arrival_path) != null
	return get_transport_stop() != null

func _cleanup_player(peer_id: int) -> void:
	var taxi_stop := get_taxi_stop()
	if taxi_stop != null:
		taxi_stop.remove_passenger(peer_id)
	var bus_stop := get_bus_stop()
	if bus_stop != null:
		bus_stop.remove_passenger(peer_id)
	for seat in find_children("*", "Seat", true, false):
		if seat.occupant_name == str(peer_id):
			seat.vacate()
	for child in get_children():
		if child is Drink and child.customer_id == peer_id:
			child.queue_free()
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
	if player.player_data == null:
		player.player_data = PlayerData.new()
	if player.settings == null:
		player.settings = PlayerSettings.new()
	if not player.drink_action_requested.is_connected(_on_drink_action_requested):
		player.drink_action_requested.connect(_on_drink_action_requested)
		player.smoke_action_requested.connect(_on_smoke_action_requested)
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
	npc.drink_action_requested.connect(_on_drink_action_requested)

func _on_cigarette_spawned(node: Node) -> void:
	if node is CigarettePack and local_player != null:
		var pack := node as CigarettePack
		if pack.holder_peer_id == int(local_player.name):
			local_player.take_spawned_item(pack)

func _on_drink_action_requested(player_id: int, drink_name: String) -> void:
	if get_node_or_null(drink_name) is not Drink:
		return
	if multiplayer.is_server():
		_handle_drink_action(player_id, drink_name)
	else:
		_request_drink_action.rpc_id(1, player_id, drink_name)

@rpc("any_peer", "reliable")
func _request_drink_action(player_id: int, drink_name: String) -> void:
	if not multiplayer.is_server() or player_id != multiplayer.get_remote_sender_id():
		return
	_handle_drink_action(player_id, drink_name)

func _handle_drink_action(player_id: int, drink_name: String) -> void:
	var drink := get_node_or_null(drink_name) as Drink
	if drink == null or drink.holder_peer_id != player_id:
		return
	if drink.parts == 0:
		return
	drink.parts -= 1
	if drink.parts == 0:
		drink.holder_peer_id = 0
		drink.queue_free()

func _on_smoke_action_requested(player_id: int, pack_name: String) -> void:
	if get_node_or_null(pack_name) is not CigarettePack:
		return
	if multiplayer.is_server():
		_handle_smoke_action(player_id, pack_name)
	else:
		_request_smoke_action.rpc_id(1, player_id, pack_name)

@rpc("any_peer", "reliable")
func _request_smoke_action(player_id: int, pack_name: String) -> void:
	if not multiplayer.is_server() or player_id != multiplayer.get_remote_sender_id():
		return
	_handle_smoke_action(player_id, pack_name)

func _handle_smoke_action(player_id: int, pack_name: String) -> void:
	var pack := get_node_or_null(pack_name) as CigarettePack
	if pack == null or pack.holder_peer_id != player_id:
		return
	if pack.cigarettes_left <= 0 or pack.is_smoking:
		return
	pack.is_smoking = true
	pack.play_smoke.rpc()
	_finish_smoking(pack, player_id)

func _finish_smoking(pack: CigarettePack, player_id: int) -> void:
	await get_tree().create_timer(CigarettePack.SMOKE_DURATION).timeout
	if not is_instance_valid(pack):
		return
	pack.is_smoking = false
	if pack.holder_peer_id != player_id or pack.cigarettes_left <= 0:
		return
	pack.cigarettes_left -= 1
	_smoke_finished.rpc_id(player_id)
	if pack.cigarettes_left == 0:
		pack.holder_peer_id = 0
		pack.queue_free()

@rpc("authority", "call_local", "reliable")
func _smoke_finished() -> void:
	if local_player != null:
		local_player.on_cigarette_smoked()
