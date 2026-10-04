class_name TaxiStop
extends Marker2D

signal boarding_requested(player: Player)
signal passenger_arrived(peer_id: int)
signal passenger_departed(peer_id: int)

const TAXI_SCENE := preload("res://scenes/street/taxi.tscn")

enum State { TO_PICKUP, WAITING, DEPARTING, ARRIVING, LEAVING }

@onready var lane: TrafficLane = get_parent() as TrafficLane
@onready var level: Level = Level.find_level_node(self)
@onready var road_end: Marker2D = lane.get_node("End") as Marker2D

var taxi: Vehicle
var _state := State.TO_PICKUP
var _passenger_id := 0
var _arrival_passenger_id := 0
var _arrival_queue: Array[int] = []

func queue_arrival(peer_id: int) -> void:
	_arrival_queue.append(peer_id)

func board_player(player: Player) -> void:
	if not multiplayer.is_server() or taxi == null or _state != State.WAITING:
		return
	_passenger_id = int(player.name)
	_set_passenger.rpc(_passenger_id, taxi.name)
	taxi.boarding_enabled = false
	_state = State.DEPARTING
	taxi.configure_route(taxi.position, level.to_local(road_end.global_position), taxi.cruise_speed, false)

func remove_passenger(peer_id: int) -> void:
	_arrival_queue.erase(peer_id)
	if _arrival_passenger_id == peer_id:
		_arrival_passenger_id = 0
	if _passenger_id == peer_id:
		_passenger_id = 0

func _process(_delta: float) -> void:
	if not is_instance_valid(taxi):
		taxi = null
	if multiplayer.is_server():
		if taxi == null:
			while not _arrival_queue.is_empty() and level.get_node_or_null(str(_arrival_queue[0])) == null:
				_arrival_queue.pop_front()
			taxi = lane.spawn_vehicle(TAXI_SCENE, global_position, true)
			if taxi != null:
				_state = State.TO_PICKUP
				_assign_arrival()
				taxi.route_finished.connect(_on_route_finished)
				taxi.boarding_requested.connect(_on_boarding_requested)
		elif _state == State.TO_PICKUP:
			_assign_arrival()
		elif _state == State.WAITING and not _arrival_queue.is_empty():
			_depart_taxi()
	for child in level.get_children():
		var passenger := child as Player
		if passenger == null or not passenger.in_vehicle or passenger.riding_vehicle_name.is_empty():
			continue
		var vehicle := level.get_node_or_null(passenger.riding_vehicle_name) as Vehicle
		if vehicle != null:
			passenger.global_position = vehicle.global_position + Vector2(0, -15)

func _assign_arrival() -> void:
	while not _arrival_queue.is_empty():
		var peer_id: int = _arrival_queue.pop_front()
		var player := level.get_node_or_null(str(peer_id)) as Player
		if player == null:
			continue
		_arrival_passenger_id = peer_id
		_state = State.ARRIVING
		player.riding_vehicle_name = taxi.name
		return

func _on_route_finished() -> void:
	match _state:
		State.TO_PICKUP:
			_assign_arrival()
			if _state == State.ARRIVING:
				_finish_arrival()
			else:
				_state = State.WAITING
				taxi.boarding_enabled = true
		State.ARRIVING:
			_finish_arrival()
		State.DEPARTING:
			passenger_departed.emit(_passenger_id)
			_passenger_id = 0
			taxi.queue_free()
		State.LEAVING:
			taxi.queue_free()

func _finish_arrival() -> void:
	passenger_arrived.emit(_arrival_passenger_id)
	_arrival_passenger_id = 0
	_depart_taxi()

func _depart_taxi() -> void:
	taxi.boarding_enabled = false
	_state = State.LEAVING
	taxi.configure_route(taxi.position, level.to_local(road_end.global_position), taxi.cruise_speed, false)

func _on_boarding_requested(player: Player) -> void:
	if multiplayer.is_server() and _state == State.WAITING:
		boarding_requested.emit(player)

@rpc("authority", "call_local", "reliable")
func _set_passenger(peer_id: int, vehicle_name: String) -> void:
	var player := level.get_node_or_null(str(peer_id)) as Player
	if player == null:
		return
	player.in_vehicle = true
	player.riding_vehicle_name = vehicle_name
	player.velocity = Vector2.ZERO
