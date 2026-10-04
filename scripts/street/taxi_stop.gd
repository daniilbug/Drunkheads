class_name TaxiStop
extends Marker2D

signal boarding_requested(player: Player)
signal passenger_arrived(peer_id: int)
signal passenger_departed(peer_id: int)
signal order_availability_changed(peer_id: int, available: bool)

const TAXI_SCENE := preload("res://scenes/street/taxi.tscn")

enum State { IDLE, TO_PICKUP, WAITING, DEPARTING, ARRIVING, LEAVING }

@export_range(5.0, 120.0, 1.0) var pickup_wait_seconds := 30.0

@onready var lane: TrafficLane = get_parent() as TrafficLane
@onready var level: Level = Level.find_level_node(self)
@onready var road_end: Marker2D = lane.get_node("End") as Marker2D

var taxi: Vehicle
var _state := State.IDLE
var _active_pickup_id := 0
var _arrival_passenger_id := 0
var _arrival_queue: Array[int] = []
var _pickup_queue: Array[int] = []
var _wait_remaining := 0.0

func queue_arrival(peer_id: int) -> void:
	if not multiplayer.is_server() or _arrival_passenger_id == peer_id or _arrival_queue.has(peer_id):
		return
	_arrival_queue.append(peer_id)

func request_pickup(peer_id: int) -> void:
	if not multiplayer.is_server() or _active_pickup_id == peer_id or _pickup_queue.has(peer_id):
		return
	_pickup_queue.append(peer_id)
	order_availability_changed.emit(peer_id, false)

func board_player(player: Player) -> void:
	if not multiplayer.is_server() or taxi == null or _state != State.WAITING:
		return
	if int(player.name) != _active_pickup_id or player.in_vehicle:
		return
	_set_passenger.rpc(_active_pickup_id, taxi.name)
	taxi.boarding_enabled = false
	_state = State.DEPARTING
	taxi.configure_route(taxi.position, level.to_local(road_end.global_position), taxi.cruise_speed, false)

func remove_passenger(peer_id: int) -> void:
	_arrival_queue.erase(peer_id)
	_pickup_queue.erase(peer_id)
	if _arrival_passenger_id == peer_id:
		_arrival_passenger_id = 0
		if _state == State.ARRIVING:
			_depart_taxi()
	if _active_pickup_id == peer_id:
		_active_pickup_id = 0
		if _state in [State.TO_PICKUP, State.WAITING]:
			_depart_taxi()

func _process(delta: float) -> void:
	if taxi != null and not is_instance_valid(taxi):
		taxi = null
		_handle_missing_taxi()
	if multiplayer.is_server():
		_prune_requests()
		if taxi == null:
			_spawn_next_taxi()
		elif _state == State.WAITING:
			_wait_remaining -= delta
			if _wait_remaining <= 0.0:
				_expire_pickup()
	for child in level.get_children():
		var passenger := child as Player
		if passenger == null or not passenger.in_vehicle or passenger.riding_vehicle_name.is_empty():
			continue
		var vehicle := level.get_node_or_null(passenger.riding_vehicle_name) as Vehicle
		if vehicle != null:
			passenger.global_position = vehicle.global_position + Vector2(0, -15)

func _prune_requests() -> void:
	for i in range(_arrival_queue.size() - 1, -1, -1):
		if level.get_node_or_null(str(_arrival_queue[i])) == null:
			_arrival_queue.remove_at(i)
	for i in range(_pickup_queue.size() - 1, -1, -1):
		var player := level.get_node_or_null(str(_pickup_queue[i])) as Player
		if player == null or player.in_vehicle:
			if player != null:
				order_availability_changed.emit(_pickup_queue[i], true)
			_pickup_queue.remove_at(i)

func _spawn_next_taxi() -> void:
	if _arrival_queue.is_empty() and _pickup_queue.is_empty():
		return
	taxi = lane.spawn_vehicle(TAXI_SCENE, global_position, true)
	if taxi == null:
		return
	taxi.route_finished.connect(_on_route_finished)
	taxi.boarding_requested.connect(_on_boarding_requested)
	if not _arrival_queue.is_empty():
		_arrival_passenger_id = _arrival_queue.pop_front()
		_state = State.ARRIVING
		var player := level.get_node_or_null(str(_arrival_passenger_id)) as Player
		if player != null:
			player.riding_vehicle_name = taxi.name
	else:
		_active_pickup_id = _pickup_queue.pop_front()
		_state = State.TO_PICKUP

func _on_route_finished() -> void:
	match _state:
		State.TO_PICKUP:
			_state = State.WAITING
			_wait_remaining = pickup_wait_seconds
			taxi.boarding_enabled = true
		State.ARRIVING:
			passenger_arrived.emit(_arrival_passenger_id)
			_arrival_passenger_id = 0
			_depart_taxi()
		State.DEPARTING, State.LEAVING:
			if _state == State.DEPARTING and _active_pickup_id != 0:
				passenger_departed.emit(_active_pickup_id)
				order_availability_changed.emit(_active_pickup_id, true)
			_active_pickup_id = 0
			_state = State.IDLE
			taxi.queue_free()

func _expire_pickup() -> void:
	order_availability_changed.emit(_active_pickup_id, true)
	_active_pickup_id = 0
	_depart_taxi()

func _depart_taxi() -> void:
	if taxi == null:
		return
	taxi.boarding_enabled = false
	_state = State.LEAVING
	taxi.configure_route(taxi.position, level.to_local(road_end.global_position), taxi.cruise_speed, false)

func _handle_missing_taxi() -> void:
	match _state:
		State.ARRIVING:
			if _arrival_passenger_id != 0:
				_arrival_queue.push_front(_arrival_passenger_id)
		State.TO_PICKUP, State.WAITING:
			if _active_pickup_id != 0:
				order_availability_changed.emit(_active_pickup_id, true)
		State.DEPARTING:
			if _active_pickup_id != 0:
				passenger_departed.emit(_active_pickup_id)
				order_availability_changed.emit(_active_pickup_id, true)
	_arrival_passenger_id = 0
	_active_pickup_id = 0
	_state = State.IDLE

func _on_boarding_requested(player: Player) -> void:
	if multiplayer.is_server() and _state == State.WAITING and int(player.name) == _active_pickup_id:
		boarding_requested.emit(player)

@rpc("authority", "call_local", "reliable")
func _set_passenger(peer_id: int, vehicle_name: String) -> void:
	var player := level.get_node_or_null(str(peer_id)) as Player
	if player == null:
		return
	player.in_vehicle = true
	player.riding_vehicle_name = vehicle_name
	player.velocity = Vector2.ZERO
