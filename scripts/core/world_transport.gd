class_name WorldTransport
extends Node

## Owns taxi orders, bus trips and transport RPC. Main applies level transitions.
signal arrival_requested(peer_id: int, destination: String, arrival_position: Vector2)
signal trip_completed(peer_id: int, destination: String, arrival_position: Vector2)
signal taxi_availability_changed

var _world: Main
var _taxi_destinations: Dictionary = {}
var _bus_trips: Dictionary = {}
var _next_bus_trip_id := 0
var _can_order_taxi := true

func _enter_tree() -> void:
	set_multiplayer_authority(1, true)

func configure(world: Main) -> void:
	_world = world
	for level in _world.get_levels():
		var stop := level.get_taxi_stop()
		if stop == null:
			continue
		stop.boarding_requested.connect(_on_taxi_boarding_requested.bind(level.level_id))
		stop.passenger_arrived.connect(_on_taxi_passenger_arrived.bind(level.level_id))
		stop.passenger_departed.connect(_on_taxi_passenger_departed.bind(level.level_id))
		stop.order_availability_changed.connect(_on_taxi_order_availability_changed)

func get_destination(destination_id: String) -> TransportDestination:
	var level := _world.get_level(destination_id)
	return level.transport_destination if level != null else null

func get_destinations(exclude_id := "") -> Array[TransportDestination]:
	var destinations: Array[TransportDestination] = []
	for level in _world.get_levels():
		if level.level_id != exclude_id and level.supports_transport():
			destinations.append(level.transport_destination)
	destinations.sort_custom(func(a: TransportDestination, b: TransportDestination) -> bool: return a.sort_order < b.sort_order)
	return destinations

func refresh_local_travel_state() -> void:
	if _world.local_player != null:
		_receive_taxi_availability(not _world.local_player.in_vehicle)

func cancel_taxi(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var source := _world.get_player_level(peer_id)
	var stop := source.get_taxi_stop() if source != null else null
	if stop != null:
		stop.remove_passenger(peer_id)
	_taxi_destinations.erase(peer_id)

func cleanup_player(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	for level in _world.get_levels():
		var taxi_stop := level.get_taxi_stop()
		if taxi_stop != null:
			taxi_stop.remove_passenger(peer_id)
		var bus_stop := level.get_bus_stop()
		if bus_stop != null:
			bus_stop.remove_passenger(peer_id)
	for trip_id: int in _bus_trips.keys():
		var trip: Dictionary = _bus_trips[trip_id]
		(trip["passengers"] as Array).erase(peer_id)
		if trip["passengers"].is_empty():
			var arrival_stop := _world.get_level(trip["destination"]).get_bus_stop()
			if arrival_stop != null:
				arrival_stop.remove_arrival(trip_id)
			_bus_trips.erase(trip_id)
	_taxi_destinations.erase(peer_id)

func is_local_taxi_available() -> bool:
	if _world.local_player == null:
		return false
	var level := _world.get_player_level(int(_world.local_player.name))
	return _can_order_taxi and not _world.local_player.in_vehicle and level != null and level.supports_transport()

func request_taxi(destination: String) -> void:
	_receive_taxi_availability(false)
	if multiplayer.is_server():
		_handle_taxi_request(multiplayer.get_unique_id(), destination)
	else:
		_request_taxi.rpc_id(1, destination)

@rpc("any_peer", "reliable")
func _request_taxi(destination: String) -> void:
	if multiplayer.is_server():
		_handle_taxi_request(multiplayer.get_remote_sender_id(), destination)

func _get_taxi_stop(level_id: String) -> TaxiStop:
	var level := _world.get_level(level_id)
	return level.get_taxi_stop() if level != null else null

func _handle_taxi_request(peer_id: int, destination: String) -> void:
	var player := _world.get_player(peer_id)
	if player == null:
		return
	var target := _world.get_level(destination)
	var source := _world.get_level(player.level_id)
	if player.in_vehicle or player.is_sitting or source == null or target == null or not source.supports_transport() or not target.supports_transport() or destination == player.level_id:
		_on_taxi_order_availability_changed(peer_id, true)
		return
	if _taxi_destinations.has(peer_id):
		return
	if source.transport_arrival_interior:
		if target.transport_arrival_interior:
			trip_completed.emit(peer_id, destination, target.get_transport_arrival_position())
			return
		arrival_requested.emit(peer_id, destination, target.get_transport_arrival_position())
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
	taxi_availability_changed.emit()

func _on_taxi_passenger_arrived(peer_id: int, level_id: String) -> void:
	trip_completed.emit(peer_id, level_id, _world.get_level(level_id).get_transport_arrival_position())
	_on_taxi_order_availability_changed(peer_id, true)

func _on_taxi_passenger_departed(peer_id: int, level_id: String) -> void:
	var destination: String = _taxi_destinations.get(peer_id, "home")
	_taxi_destinations.erase(peer_id)
	var player := _world.get_player(peer_id)
	if player == null:
		return
	var target := _world.get_level(destination)
	if target == null:
		trip_completed.emit(peer_id, level_id, _world.get_level(level_id).get_transport_arrival_position())
		return
	if target.transport_arrival_interior:
		player.return_level_id = level_id
		trip_completed.emit(peer_id, destination, target.get_transport_arrival_position())
	else:
		arrival_requested.emit(peer_id, destination, target.get_transport_arrival_position())
		_get_taxi_stop(destination).queue_arrival(peer_id)

func _on_taxi_boarding_requested(player: Player, level_id: String) -> void:
	if player.level_id == level_id and _taxi_destinations.has(int(player.name)):
		_get_taxi_stop(level_id).board_player(player)

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
	if bus.destination_id == source_id or _world.get_level(bus.destination_id) == null or not _world.get_level(bus.destination_id).supports_transport():
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

func request_bus_exit(player: Player) -> void:
	if player != _world.local_player:
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
	var player := _world.get_player(peer_id)
	if player == null or not player.in_vehicle:
		return
	var level := _world.get_player_level(peer_id)
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
			trip_completed.emit(peer_id, player.level_id, level.get_transport_arrival_position())
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
	trip_completed.emit(peer_id, player.level_id, bus_stop.get_passenger_exit_position())

@rpc("authority", "call_local", "reliable")
func _set_bus_passenger(peer_id: int, vehicle_name: String) -> void:
	var player := _world.get_player(peer_id)
	if player == null:
		return
	player.in_vehicle = true
	player.riding_vehicle_name = vehicle_name
	player.velocity = Vector2.ZERO
	if player == _world.local_player:
		_receive_taxi_availability(false)

func depart_bus(bus_stop: BusStop, bus: Bus) -> void:
	if not multiplayer.is_server():
		return
	var source_id := bus_stop.level.transport_destination.id
	var passengers: Array[int] = []
	for peer_id in bus.passenger_ids:
		var player := _world.get_player(peer_id)
		if player != null and player.in_vehicle and player.level_id == source_id and player.riding_vehicle_name == bus.name:
			passengers.append(peer_id)
	if passengers.is_empty():
		return
	var target := _world.get_level(bus.destination_id)
	if target == null or not target.supports_transport():
		recover_bus_passengers(passengers, bus_stop)
		return
	_next_bus_trip_id += 1
	var trip_id := _next_bus_trip_id
	_bus_trips[trip_id] = {"destination": bus.destination_id, "passengers": passengers, "vehicle_name": str(bus.name)}
	if target.transport_arrival_interior:
		for peer_id in passengers:
			_world.get_player(peer_id).return_level_id = source_id
			arrival_requested.emit(peer_id, bus.destination_id, target.get_transport_arrival_position())
		return
	var arrival_stop := target.get_bus_stop()
	for peer_id in passengers:
		arrival_requested.emit(peer_id, bus.destination_id, arrival_stop.stop.global_position)
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
		arrival_requested.emit(peer_id, bus_stop.level.transport_destination.id, bus_stop.stop.global_position)

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
		var player := _world.get_player(passengers[index])
		if player != null and player.in_vehicle and player.level_id == level_id:
			trip_completed.emit(passengers[index], level_id, bus_stop.stop.get_exit_position(index))
