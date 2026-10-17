class_name Main
extends Node2D

const PHONE_SCENE := preload("res://scenes/core/phone.tscn")
const PLAYER_SCENE := preload("res://scenes/core/player.tscn")

@export var auto_spawn_players := true

@onready var world_time: WorldTime = $WorldTime
@onready var bar: Bar = $Bar
@onready var home: Level = $Home
@onready var cafe: Level = $Cafe
@onready var _levels: Dictionary = {"bar": bar, "cafe": cafe, "home": home}
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var respect_label: Label = $HUD/Stats/RespectLabel
@onready var mind_label: Label = $HUD/Stats/MindLabel
@onready var money_label: Label = $HUD/Stats/MoneyLabel
@onready var headphone_player: HeadphonePlayer = $HeadphonePlayer

var _taxi_destinations: Dictionary = {}
var _name_registry: Dictionary = {}  # peer_id -> final display name (server only)
var local_player: Player
var _phone: Phone
var _can_order_taxi := true

func _ready() -> void:
	player_spawner.spawned.connect(_on_player_spawned)
	for level_id: String in ["bar", "cafe"]:
		var stop := _get_taxi_stop(level_id)
		stop.boarding_requested.connect(_on_taxi_boarding_requested.bind(level_id))
		stop.passenger_arrived.connect(_on_taxi_passenger_arrived.bind(level_id))
		stop.passenger_departed.connect(_on_taxi_passenger_departed.bind(level_id))
		stop.order_availability_changed.connect(_on_taxi_order_availability_changed)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if multiplayer.is_server() and auto_spawn_players:
		multiplayer.peer_connected.connect(_on_peer_connected)
		_spawn_player(multiplayer.get_unique_id())
		_init_local_player(get_player(multiplayer.get_unique_id()))
		_register_player_setup(multiplayer.get_unique_id(), Player.local_setup)

func get_player(peer_id: int) -> Player:
	return get_node_or_null(str(peer_id)) as Player

func get_players() -> Array[Player]:
	var players: Array[Player] = []
	for child in get_children():
		if child is Player and not child is NPC:
			players.append(child)
	return players

func _on_peer_connected(peer_id: int) -> void:
	_spawn_player(peer_id)

func _spawn_player(peer_id: int) -> void:
	var player := PLAYER_SCENE.instantiate() as Player
	player.name = str(peer_id)
	player.randomize_appearance()
	bar._prepare_player_spawn(player)
	add_child(player)
	player.global_position = bar.player_spawn.global_position

func _on_player_spawned(node: Node) -> void:
	if node is Player and int(node.name) == multiplayer.get_unique_id() and local_player == null:
		var player := node as Player
		_init_local_player(player)
		if not multiplayer.is_server():
			_request_player_setup.rpc_id(1, Player.local_setup)

func _init_local_player(player: Player) -> void:
	if player == null or local_player != null:
		return
	local_player = player
	_activate_local_level(player.level_id)
	_init_hud(player)

func _resolve_name(desired: String, exclude_peer: int) -> String:
	var base := desired.strip_edges()
	if base.is_empty():
		base = "Player"
	var taken: Array[String] = []
	for pid in _name_registry:
		if pid != exclude_peer:
			taken.append(_name_registry[pid])
	if base not in taken:
		return base
	var idx := 2
	while ("%s %d" % [base, idx]) in taken:
		idx += 1
	return "%s %d" % [base, idx]

func _register_player_setup(peer_id: int, setup: Dictionary) -> void:
	var final_name := _resolve_name(setup.get("name", "Player"), peer_id)
	_name_registry[peer_id] = final_name
	var final_setup := setup.duplicate()
	final_setup["name"] = final_name
	var player := get_player(peer_id)
	if player != null:
		player.rpc_apply_player_setup.rpc(final_setup)

@rpc("any_peer", "reliable")
func _request_player_setup(setup: Dictionary) -> void:
	if multiplayer.is_server():
		_register_player_setup(multiplayer.get_remote_sender_id(), setup)

func _init_hud(player: Player) -> void:
	player.player_data.stats_changed.connect(_update_stats)
	player.phone_requested.connect(_on_phone_requested)
	headphone_player.player = player
	_update_stats()

func _on_phone_requested(player: Player) -> void:
	if player != local_player or _phone != null:
		return
	player.is_world_input_blocked = true
	call_deferred("_open_phone")

func _open_phone() -> void:
	var player := local_player
	if player == null:
		return
	_phone = PHONE_SCENE.instantiate() as Phone
	_phone.set_player_settings(player.settings)
	_phone.set_headphone_player(headphone_player)
	_phone.set_world_time(world_time)
	add_child(_phone)
	_phone.taxi_requested.connect(_on_phone_taxi_requested)
	_phone.closed.connect(_on_phone_closed)
	_phone.set_taxi_context(player.level_id)
	_phone.set_taxi_available(_can_order_taxi and not player.in_vehicle)

func _on_phone_closed() -> void:
	if _phone != null:
		_phone.queue_free()
		_phone = null
	if local_player != null:
		local_player.is_world_input_blocked = false

func _on_phone_taxi_requested(destination: String) -> void:
	_on_phone_closed()
	_can_order_taxi = false
	if multiplayer.is_server():
		_handle_taxi_request(multiplayer.get_unique_id(), destination)
	else:
		_request_taxi.rpc_id(1, destination)

@rpc("any_peer", "reliable")
func _request_taxi(destination: String) -> void:
	if multiplayer.is_server():
		_handle_taxi_request(multiplayer.get_remote_sender_id(), destination)

func _get_taxi_stop(level_id: String) -> TaxiStop:
	return (_levels[level_id] as Level).get_node("TrafficRoad/RightTrafficLane/TaxiStop") as TaxiStop

func get_player_level(peer_id: int) -> Level:
	var player := get_player(peer_id)
	return _levels.get(player.level_id) as Level if player != null else null

func _handle_taxi_request(peer_id: int, destination: String) -> void:
	var player := get_player(peer_id)
	if player == null:
		return
	if player.in_vehicle or player.is_sitting or not _levels.has(destination) or destination == player.level_id:
		_on_taxi_order_availability_changed(peer_id, true)
		return
	if _taxi_destinations.has(peer_id):
		return
	if player.level_id == "home":
		_begin_arrival.rpc(peer_id, destination)
		_get_taxi_stop(destination).queue_arrival(peer_id)
		return
	_taxi_destinations[peer_id] = destination
	_get_taxi_stop(player.level_id).request_pickup(peer_id)

func _on_taxi_order_availability_changed(peer_id: int, available: bool) -> void:
	if not multiplayer.is_server() or peer_id <= 0:
		return
	if available:
		_taxi_destinations.erase(peer_id)
	if peer_id == multiplayer.get_unique_id():
		_receive_taxi_availability(available)
	elif multiplayer.get_peers().has(peer_id):
		_receive_taxi_availability.rpc_id(peer_id, available)

@rpc("authority", "reliable")
func _receive_taxi_availability(available: bool) -> void:
	_can_order_taxi = available
	if _phone != null:
		_phone.set_taxi_context(local_player.level_id)
		_phone.set_taxi_available(available and not local_player.in_vehicle)

func _update_stats() -> void:
	if local_player == null:
		return
	var data := local_player.player_data
	respect_label.text = "Respect  %d" % int(data.respect)
	mind_label.text = "Mind     %d" % int(data.mind)
	money_label.text = "Money   $%d" % int(data.money)

func _on_taxi_passenger_arrived(peer_id: int, level_id: String) -> void:
	_apply_trip.rpc(peer_id, level_id)
	_on_taxi_order_availability_changed(peer_id, true)

func _on_taxi_passenger_departed(peer_id: int, level_id: String) -> void:
	var destination: String = _taxi_destinations.get(peer_id, "home")
	_taxi_destinations.erase(peer_id)
	var player := get_player(peer_id)
	if player == null:
		return
	if destination == "home":
		player.return_level_id = level_id
		_apply_trip.rpc(peer_id, "home")
	else:
		_begin_arrival.rpc(peer_id, destination)
		_get_taxi_stop(destination).queue_arrival(peer_id)

func _on_taxi_boarding_requested(player: Player, level_id: String) -> void:
	if player.level_id == level_id and _taxi_destinations.has(int(player.name)):
		_get_taxi_stop(level_id).board_player(player)

func return_from_home(peer_id: int) -> void:
	if not multiplayer.is_server() or not is_player_home(peer_id):
		return
	_handle_taxi_request(peer_id, get_player(peer_id).return_level_id)

@rpc("authority", "call_local", "reliable")
func _begin_arrival(peer_id: int, destination: String) -> void:
	var player := get_player(peer_id)
	if player == null:
		return
	player.level_id = destination
	player.in_vehicle = true
	player.riding_vehicle_name = ""
	player.velocity = Vector2.ZERO
	player.global_position = (_levels[destination] as Level).get_node("TaxiReturn").global_position
	if player == local_player:
		_activate_local_level(destination)
		_receive_taxi_availability(false)

func is_player_home(peer_id: int) -> bool:
	var player := get_player(peer_id)
	return player != null and player.level_id == "home"

@rpc("authority", "call_local", "reliable")
func _apply_trip(peer_id: int, destination: String) -> void:
	var player := get_player(peer_id)
	if player == null:
		return
	player.level_id = destination
	player.in_vehicle = false
	player.riding_vehicle_name = ""
	var level := _levels[destination] as Level
	var marker := level.get_node("PlayerSpawn" if destination == "home" else "TaxiReturn") as Node2D
	player.velocity = Vector2.ZERO
	player.global_position = marker.global_position
	if player == local_player:
		_activate_local_level(destination)
		_receive_taxi_availability(true)

func _activate_local_level(level_id: String) -> void:
	for level: Level in _levels.values():
		if level.local_player != null and level != _levels[level_id]:
			for child in level.get_children():
				if child is Room:
					child.reset_wall_visibility()
		level.local_player = null
	var current := _levels[level_id] as Level
	current._init_local_player(local_player)
	_set_camera_bounds(local_player, current.get_world_bounds())

func _set_camera_bounds(player: Player, bounds: Rect2) -> void:
	player.camera.limit_left = floori(bounds.position.x)
	player.camera.limit_top = floori(bounds.position.y)
	player.camera.limit_right = ceili(bounds.end.x)
	player.camera.limit_bottom = ceili(bounds.end.y)
	player.camera.reset_smoothing()

func _on_peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server():
		for level: Level in _levels.values():
			level._cleanup_player(peer_id)
		var player := get_player(peer_id)
		if player != null:
			player.queue_free()
		_name_registry.erase(peer_id)
	_taxi_destinations.erase(peer_id)
