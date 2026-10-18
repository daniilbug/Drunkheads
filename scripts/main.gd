class_name Main
extends Node2D

const PHONE_SCENE := preload("res://scenes/core/phone.tscn")
const PLAYER_SCENE := preload("res://scenes/core/player.tscn")

@export var auto_spawn_players := true

@onready var world_time: WorldTime = $WorldTime
@onready var bar: Bar = $Bar
@onready var home: Level = $Home
@onready var cafe: Level = $Cafe
@onready var home_entrance: Level = $HomeEntrance
@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
@onready var respect_label: Label = $HUD/Stats/RespectLabel
@onready var mind_label: Label = $HUD/Stats/MindLabel
@onready var money_label: Label = $HUD/Stats/MoneyLabel
@onready var headphone_player: HeadphonePlayer = $HeadphonePlayer

var _taxi_destinations: Dictionary = {}
var _levels: Dictionary = {}
var _bus_trips: Dictionary = {}
var _next_bus_trip_id := 0
var _name_registry: Dictionary = {}  # peer_id -> final display name (server only)
var local_player: Player
var _phone: Phone
var _can_order_taxi := true

func _ready() -> void:
	_register_levels()
	player_spawner.spawned.connect(_on_player_spawned)
	for level_id: String in _levels:
		var stop := _get_taxi_stop(level_id)
		if stop == null:
			continue
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

func get_transport_destination(destination_id: String) -> TransportDestination:
	var level := _levels.get(destination_id) as Level
	return level.transport_destination if level != null else null

func get_transport_destinations(exclude_id := "") -> Array[TransportDestination]:
	var destinations: Array[TransportDestination] = []
	for level_id: String in _levels:
		var level := _levels[level_id] as Level
		if level_id != exclude_id and level.supports_transport():
			destinations.append(level.transport_destination)
	destinations.sort_custom(func(a: TransportDestination, b: TransportDestination) -> bool: return a.sort_order < b.sort_order)
	return destinations

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
	player.bus_exit_requested.connect(_on_bus_exit_requested)
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
	_phone.set_transport_destinations(get_transport_destinations())
	add_child(_phone)
	_phone.taxi_requested.connect(_on_phone_taxi_requested)
	_phone.closed.connect(_on_phone_closed)
	_phone.set_taxi_context(player.level_id)
	_phone.set_taxi_available(_is_local_taxi_available())

func _is_local_taxi_available() -> bool:
	if local_player == null:
		return false
	var level := get_player_level(int(local_player.name))
	return _can_order_taxi and not local_player.in_vehicle and level != null and level.supports_transport()

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
	var level := _levels.get(level_id) as Level
	return level.get_taxi_stop() if level != null else null

func get_player_level(peer_id: int) -> Level:
	var player := get_player(peer_id)
	return _levels.get(player.level_id) as Level if player != null else null

func _handle_taxi_request(peer_id: int, destination: String) -> void:
	var player := get_player(peer_id)
	if player == null:
		return
	var target := _levels.get(destination) as Level
	var source := _levels.get(player.level_id) as Level
	if player.in_vehicle or player.is_sitting or source == null or target == null or not source.supports_transport() or not target.supports_transport() or destination == player.level_id:
		_on_taxi_order_availability_changed(peer_id, true)
		return
	if _taxi_destinations.has(peer_id):
		return
	if source.transport_arrival_interior:
		if target.transport_arrival_interior:
			_apply_trip.rpc(peer_id, destination, target.get_transport_arrival_position())
			return
		_begin_arrival.rpc(peer_id, destination, target.get_transport_arrival_position())
		_get_taxi_stop(destination).queue_arrival(peer_id)
		return
	if source.get_taxi_stop() == null:
		_on_taxi_order_availability_changed(peer_id, true)
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
		_phone.set_taxi_available(_is_local_taxi_available())

func _update_stats() -> void:
	if local_player == null:
		return
	var data := local_player.player_data
	respect_label.text = "Respect  %d" % int(data.respect)
	mind_label.text = "Mind     %d" % int(data.mind)
	money_label.text = "Money   $%d" % int(data.money)

func _on_taxi_passenger_arrived(peer_id: int, level_id: String) -> void:
	_apply_trip.rpc(peer_id, level_id, (_levels[level_id] as Level).get_transport_arrival_position())
	_on_taxi_order_availability_changed(peer_id, true)

func _on_taxi_passenger_departed(peer_id: int, level_id: String) -> void:
	var destination: String = _taxi_destinations.get(peer_id, "home")
	_taxi_destinations.erase(peer_id)
	var player := get_player(peer_id)
	if player == null:
		return
	var target := _levels.get(destination) as Level
	if target == null:
		_apply_trip.rpc(peer_id, level_id, (_levels[level_id] as Level).get_transport_arrival_position())
		return
	if target.transport_arrival_interior:
		player.return_level_id = level_id
		_apply_trip.rpc(peer_id, destination, target.get_transport_arrival_position())
	else:
		_begin_arrival.rpc(peer_id, destination, target.get_transport_arrival_position())
		_get_taxi_stop(destination).queue_arrival(peer_id)

func _on_taxi_boarding_requested(player: Player, level_id: String) -> void:
	if player.level_id == level_id and _taxi_destinations.has(int(player.name)):
		_get_taxi_stop(level_id).board_player(player)

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
	var stop := source.get_taxi_stop()
	if stop != null:
		stop.remove_passenger(peer_id)
	_taxi_destinations.erase(peer_id)
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
		_receive_taxi_availability(false)

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
		_receive_taxi_availability(true)

func _activate_local_level(level_id: String) -> void:
	if not _levels.has(level_id):
		return
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
		for trip_id: int in _bus_trips.keys():
			var trip: Dictionary = _bus_trips[trip_id]
			(trip["passengers"] as Array).erase(peer_id)
			if trip["passengers"].is_empty():
				var arrival_stop := (_levels[trip["destination"]] as Level).get_bus_stop()
				if arrival_stop != null:
					arrival_stop.remove_arrival(trip_id)
				_bus_trips.erase(trip_id)
	_taxi_destinations.erase(peer_id)

func board_bus(player: Player, bus_stop: BusStop) -> void:
	if not multiplayer.is_server() or player == null or not is_instance_valid(bus_stop.bus):
		return
	var bus := bus_stop.bus
	var source_id := bus_stop.level.transport_destination.id
	var peer_id := int(player.name)
	if peer_id <= 0 or player.in_vehicle or player.is_sitting or player.level_id != source_id:
		return
	if not bus.boarding_enabled or bus.travel_state != Vehicle.TravelState.STOPPED or bus.service_state != Bus.ServiceState.BOARDING:
		return
	if bus.destination_id == source_id or not _levels.has(bus.destination_id) or not (_levels[bus.destination_id] as Level).supports_transport():
		return
	if not bus._interaction.area.overlaps_area(player.interaction_area) or bus.passenger_ids.has(peer_id):
		return
	# A passenger may switch from a queued taxi to the bus at the shared stop.
	var taxi_stop := _get_taxi_stop(source_id)
	if taxi_stop != null:
		taxi_stop.remove_passenger(peer_id)
	_taxi_destinations.erase(peer_id)
	bus.passenger_ids.append(peer_id)
	_set_bus_passenger.rpc(peer_id, bus.name)

func _on_bus_exit_requested(player: Player) -> void:
	if player != local_player:
		return
	if multiplayer.is_server():
		_handle_bus_exit(int(player.name))
	else:
		_request_bus_exit.rpc_id(1)

@rpc("any_peer", "reliable")
func _request_bus_exit() -> void:
	if multiplayer.is_server():
		_handle_bus_exit(multiplayer.get_remote_sender_id())

func _handle_bus_exit(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var player := get_player(peer_id)
	if player == null or not player.in_vehicle:
		return
	var level := get_player_level(peer_id)
	if level == null:
		return
	if level.transport_arrival_interior:
		# Interior destinations have no road or visible bus. Keep the completed
		# arrival in the trip registry until this passenger explicitly exits.
		for trip_id: int in _bus_trips:
			var trip: Dictionary = _bus_trips[trip_id]
			var passengers: Array = trip["passengers"]
			if trip["destination"] != player.level_id or not passengers.has(peer_id) or not player.riding_vehicle_name.is_empty():
				continue
			passengers.erase(peer_id)
			if passengers.is_empty():
				_bus_trips.erase(trip_id)
			_apply_trip.rpc(peer_id, player.level_id, level.get_transport_arrival_position())
			return
		return
	var bus_stop := level.get_bus_stop()
	if bus_stop == null or not is_instance_valid(bus_stop.bus):
		return
	var bus := bus_stop.bus
	if bus.service_state != Bus.ServiceState.BOARDING or bus.travel_state != Vehicle.TravelState.STOPPED:
		return
	if player.riding_vehicle_name != bus.name or not bus.passenger_ids.has(peer_id):
		return
	bus.passenger_ids.erase(peer_id)
	_apply_trip.rpc(peer_id, player.level_id, bus_stop.get_passenger_exit_position())

@rpc("authority", "call_local", "reliable")
func _set_bus_passenger(peer_id: int, vehicle_name: String) -> void:
	var player := get_player(peer_id)
	if player == null:
		return
	player.in_vehicle = true
	player.riding_vehicle_name = vehicle_name
	player.velocity = Vector2.ZERO
	if player == local_player:
		_receive_taxi_availability(false)

func depart_bus(bus_stop: BusStop, bus: Bus) -> void:
	if not multiplayer.is_server():
		return
	var source_id := bus_stop.level.transport_destination.id
	var passengers: Array[int] = []
	for peer_id in bus.passenger_ids:
		var player := get_player(peer_id)
		if player != null and player.in_vehicle and player.level_id == source_id and player.riding_vehicle_name == bus.name:
			passengers.append(peer_id)
	if passengers.is_empty():
		return
	var target := _levels.get(bus.destination_id) as Level
	if target == null or not target.supports_transport():
		recover_bus_passengers(passengers, bus_stop)
		return
	_next_bus_trip_id += 1
	var trip_id := _next_bus_trip_id
	_bus_trips[trip_id] = {"destination": bus.destination_id, "passengers": passengers, "vehicle_name": str(bus.name)}
	if target.transport_arrival_interior:
		for peer_id in passengers:
			get_player(peer_id).return_level_id = source_id
			_begin_arrival.rpc(peer_id, bus.destination_id, target.get_transport_arrival_position())
		return
	var arrival_stop := target.get_bus_stop()
	for peer_id in passengers:
		_begin_arrival.rpc(peer_id, bus.destination_id, arrival_stop.stop.global_position)
	arrival_stop.queue_arrival(trip_id)

func has_bus_trip(trip_id: int) -> bool:
	return _bus_trips.has(trip_id)

func get_bus_trip_vehicle_name(trip_id: int) -> String:
	return _bus_trips[trip_id]["vehicle_name"] if _bus_trips.has(trip_id) else ""

func attach_bus_arrival(trip_id: int, bus: Bus) -> void:
	if not multiplayer.is_server() or not _bus_trips.has(trip_id):
		return
	for peer_id: int in _bus_trips[trip_id]["passengers"]:
		_set_bus_passenger.rpc(peer_id, bus.name)

func reset_bus_arrival(trip_id: int, bus_stop: BusStop) -> void:
	if not multiplayer.is_server() or not _bus_trips.has(trip_id):
		return
	for peer_id: int in _bus_trips[trip_id]["passengers"]:
		_begin_arrival.rpc(peer_id, bus_stop.level.transport_destination.id, bus_stop.stop.global_position)

func complete_bus_arrival(trip_id: int, bus_stop: BusStop) -> void:
	if not multiplayer.is_server() or not _bus_trips.has(trip_id):
		return
	var trip: Dictionary = _bus_trips[trip_id]
	_bus_trips.erase(trip_id)
	bus_stop.bus.passenger_ids.assign(trip["passengers"])

func recover_bus_passengers(passengers: Array[int], bus_stop: BusStop) -> void:
	if not multiplayer.is_server():
		return
	var level_id := bus_stop.level.transport_destination.id
	for index in passengers.size():
		var player := get_player(passengers[index])
		if player != null and player.in_vehicle and player.level_id == level_id:
			_apply_trip.rpc(passengers[index], level_id, bus_stop.stop.get_exit_position(index))
