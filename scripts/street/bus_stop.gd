class_name BusStop
extends Marker2D

@export var bus_scene: PackedScene
@export_range(1.0, 120.0, 1.0) var dwell_seconds := 10.0

@onready var stop: TransportStop = get_parent() as TransportStop
@onready var lane: TrafficLane = stop.get_parent() as TrafficLane
@onready var level: Level = Level.find_level_node(self)

var bus: Bus
var _wait_remaining := 0.0
var _arrival_trip_id := 0
var _arrival_queue: Array[int] = []
var _departure_pending := false
var _pending_destination := ""
var _exit_count := 0

func _get_transport() -> WorldTransport:
	var main := level.get_parent() as Main
	return main.transport if main != null else null

func has_pending_service() -> bool:
	return _departure_pending or not _arrival_queue.is_empty()

func request_departure() -> bool:
	if not multiplayer.is_server() or is_instance_valid(bus) or has_pending_service():
		return false
	_pending_destination = _choose_destination()
	if _get_transport() != null and _pending_destination.is_empty():
		return false
	_departure_pending = true
	_try_spawn()
	return true

func queue_arrival(trip_id: int) -> void:
	if multiplayer.is_server() and trip_id != _arrival_trip_id and not _arrival_queue.has(trip_id):
		_arrival_queue.append(trip_id)

func remove_arrival(trip_id: int) -> void:
	_arrival_queue.erase(trip_id)
	if _arrival_trip_id == trip_id:
		_arrival_trip_id = 0

func remove_passenger(peer_id: int) -> void:
	if is_instance_valid(bus):
		bus.passenger_ids.erase(peer_id)

func get_passenger_exit_position() -> Vector2:
	var exit_position := stop.get_exit_position(_exit_count)
	_exit_count += 1
	return exit_position

func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if not is_instance_valid(bus):
		bus = null
		_try_spawn()
	elif bus.service_state == Bus.ServiceState.BOARDING:
		_wait_remaining -= delta
		if _wait_remaining <= 0.0:
			bus.boarding_enabled = false
			bus.service_state = Bus.ServiceState.LEAVING
			bus.configure_route(bus.position, level.to_local((lane.get_node("End") as Marker2D).global_position), bus.cruise_speed, false)

func _choose_destination() -> String:
	var transport := _get_transport()
	if transport == null or level.transport_destination == null:
		return ""
	var destinations := transport.get_destinations(level.transport_destination.id)
	return destinations.pick_random().id if not destinations.is_empty() else ""

func _try_spawn() -> void:
	if not has_pending_service():
		stop.release_bay(self)
		return
	var transport := _get_transport()
	while not _arrival_queue.is_empty() and (transport == null or not transport.has_bus_trip(_arrival_queue[0])):
		_arrival_queue.pop_front()
	if not has_pending_service():
		stop.release_bay(self)
		return
	if not stop.request_bay(self):
		return
	var trip_id := _arrival_queue[0] if not _arrival_queue.is_empty() else 0
	var vehicle_name := transport.get_bus_trip_vehicle_name(trip_id) if trip_id != 0 else ""
	var destination := level.transport_destination.id if trip_id != 0 else _pending_destination
	bus = lane.spawn_vehicle(bus_scene, stop.global_position, true, vehicle_name, {"destination_id": destination}) as Bus
	if bus == null:
		stop.release_bay(self)
		return
	bus.route_finished.connect(_on_route_finished)
	bus.boarding_requested.connect(_on_boarding_requested)
	bus.tree_exiting.connect(_on_bus_exiting.bind(bus), CONNECT_ONE_SHOT)
	_arrival_trip_id = trip_id
	if trip_id != 0:
		_arrival_queue.pop_front()
		transport.attach_bus_arrival(trip_id, bus)
	else:
		_departure_pending = false
		_pending_destination = ""

func _on_route_finished() -> void:
	if bus.service_state == Bus.ServiceState.APPROACHING:
		if _arrival_trip_id != 0:
			_get_transport().complete_bus_arrival(_arrival_trip_id, self)
			_arrival_trip_id = 0
		# An incoming trip may have lost its last passenger before reaching the
		# stop. It still needs a new outward route rather than its current level.
		if level.transport_destination != null and bus.destination_id == level.transport_destination.id:
			bus.destination_id = _choose_destination()
		bus.service_state = Bus.ServiceState.BOARDING
		_exit_count = 0
		_wait_remaining = dwell_seconds
		bus.boarding_enabled = _get_transport() != null and not bus.destination_id.is_empty()
	else:
		var departing := bus
		bus = null
		stop.release_bay(self)
		if _get_transport() != null and not departing.passenger_ids.is_empty():
			_get_transport().depart_bus(self, departing)
		departing.queue_free()

func _on_boarding_requested(player: Player) -> void:
	var transport := _get_transport()
	if transport != null:
		transport.board_bus(player, self)

func _on_bus_exiting(exiting_bus: Bus) -> void:
	if bus != exiting_bus:
		return
	bus = null
	stop.release_bay(self)
	if not is_inside_tree() or level.get_parent().is_queued_for_deletion():
		return
	var transport := _get_transport()
	if transport == null:
		return
	if _arrival_trip_id != 0:
		transport.reset_bus_arrival(_arrival_trip_id, self)
		_arrival_queue.push_front(_arrival_trip_id)
		_arrival_trip_id = 0
	transport.recover_bus_passengers(exiting_bus.passenger_ids, self)
