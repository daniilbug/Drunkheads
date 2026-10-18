class_name Main
extends Node2D

signal local_player_travel_changed

const PLAYER_SCENE := preload("res://scenes/core/player.tscn")

@export var auto_spawn_players := true

@onready var world_time: WorldTime = $WorldTime
@onready var bar: Bar = $Bar
@onready var home: Level = $Home
@onready var cafe: Level = $Cafe
@onready var home_entrance: Level = $HomeEntrance
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var hud: HUD = $HUD
@onready var headphone_player: HeadphonePlayer = $HeadphonePlayer
@onready var phone_controller: PhoneController = $PhoneController
@onready var transport: WorldTransport = $WorldTransport

var _levels: Dictionary = {}
var _name_registry: Dictionary = {}  # peer_id -> final display name (server only)
var local_player: Player

func _ready() -> void:
	_register_levels()
	transport.configure(self)
	transport.arrival_requested.connect(_on_transport_arrival_requested)
	transport.trip_completed.connect(_on_transport_trip_completed)
	local_player_travel_changed.connect(transport.refresh_local_travel_state)
	player_spawner.spawned.connect(_on_player_spawned)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	if multiplayer.is_server() and auto_spawn_players:
		multiplayer.peer_connected.connect(_on_peer_connected)
		_spawn_player(multiplayer.get_unique_id())
		_init_local_player(get_player(multiplayer.get_unique_id()))
		_register_player_setup(multiplayer.get_unique_id(), Player.local_setup)

func _register_levels() -> void:
	for child in get_children():
		if child is not Level:
			continue
		var level := child as Level
		if level.level_id.is_empty() or _levels.has(level.level_id):
			push_error("Levels need unique, nonempty IDs: %s" % child.name)
			continue
		if level.transport_destination != null and level.transport_destination.id != level.level_id:
			push_error("Transport destination must match its level ID: %s" % child.name)
			continue
		_levels[level.level_id] = level

func get_level(level_id: String) -> Level:
	return _levels.get(level_id) as Level

func get_levels() -> Array[Level]:
	var levels: Array[Level] = []
	levels.assign(_levels.values())
	return levels

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
	player.level_id = bar.level_id
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
	_init_local_player_ui(player)

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

func _init_local_player_ui(player: Player) -> void:
	player.player_data.stats_changed.connect(hud.update_stats.bind(player.player_data))
	phone_controller.configure(player, headphone_player, world_time,
		transport.get_destinations(), transport.is_local_taxi_available)
	player.phone_requested.connect(phone_controller.open)
	player.tree_exiting.connect(phone_controller.close)
	phone_controller.taxi_requested.connect(transport.request_taxi)
	transport.taxi_availability_changed.connect(phone_controller.refresh_taxi_context)
	player.bus_exit_requested.connect(transport.request_bus_exit)
	headphone_player.player = player
	hud.update_stats(player.player_data)

func get_player_level(peer_id: int) -> Level:
	var player := get_player(peer_id)
	return _levels.get(player.level_id) as Level if player != null else null

func _on_transport_arrival_requested(peer_id: int, destination: String, arrival_position: Vector2) -> void:
	if multiplayer.is_server():
		_begin_arrival.rpc(peer_id, destination, arrival_position)

func _on_transport_trip_completed(peer_id: int, destination: String, arrival_position: Vector2) -> void:
	if multiplayer.is_server():
		_apply_trip.rpc(peer_id, destination, arrival_position)

## Objects own their transitions; Main only applies a move between registered levels.
func transfer_player(peer_id: int, destination: Level, arrival_position: Vector2) -> bool:
	if not multiplayer.is_server() or not is_instance_valid(destination) or not arrival_position.is_finite():
		return false
	if _levels.get(destination.level_id) != destination:
		return false
	var player := get_player(peer_id)
	var source := get_player_level(peer_id)
	if player == null or player.is_queued_for_deletion() or source == null:
		return false
	transport.cancel_taxi(peer_id)
	_apply_trip.rpc(peer_id, destination.level_id, arrival_position)
	return true

@rpc("authority", "call_local", "reliable")
func _begin_arrival(peer_id: int, destination: String, arrival_position: Vector2) -> void:
	var player := get_player(peer_id)
	if player == null:
		return
	player.level_id = destination
	player.in_vehicle = true
	player.riding_vehicle_name = ""
	player.velocity = Vector2.ZERO
	player.global_position = arrival_position
	if player == local_player:
		_activate_local_level(destination)
		local_player_travel_changed.emit()

@rpc("authority", "call_local", "reliable")
func _apply_trip(peer_id: int, destination: String, arrival_position: Vector2) -> void:
	var player := get_player(peer_id)
	if player == null:
		return
	player.level_id = destination
	player.in_vehicle = false
	player.riding_vehicle_name = ""
	player.velocity = Vector2.ZERO
	player.global_position = arrival_position
	if player == local_player:
		_activate_local_level(destination)
		local_player_travel_changed.emit()

func _activate_local_level(level_id: String) -> void:
	if not _levels.has(level_id):
		return
	var current := _levels[level_id] as Level
	for level: Level in _levels.values():
		if level != current:
			level.deactivate_local_player()
	current.activate_local_player(local_player)

func _on_peer_disconnected(peer_id: int) -> void:
	if multiplayer.is_server():
		transport.cleanup_player(peer_id)
		for level: Level in _levels.values():
			level._cleanup_player(peer_id)
		var player := get_player(peer_id)
		if player != null:
			player.queue_free()
		_name_registry.erase(peer_id)
