class_name TrafficLane
extends Node2D

@export var vehicle_scene: PackedScene = preload("res://scenes/street/car.tscn")
@export_range(0.0, 1.0, 0.01) var bus_spawn_chance := 0.2

@export_range(0.1, 60.0, 0.1) var min_spawn_interval := 5.0
@export_range(0.1, 60.0, 0.1) var max_spawn_interval := 9.0
@export_range(1, 10, 1) var max_cars := 2
@export_range(1.0, 300.0, 1.0) var min_spawn_spacing := 90.0
@export_range(1.0, 300.0, 1.0) var min_speed := 65.0
@export_range(1.0, 300.0, 1.0) var max_speed := 120.0

@onready var _start: Marker2D = $Start
@onready var _end: Marker2D = $End
@onready var _level: Level = Level.find_level_node(self)

static var _next_car_id := 0
var _cars: Array[Vehicle] = []
var _spawn_timer := 0.0

func _ready() -> void:
	_spawn_timer = randf_range(1.0, 3.0)

func _process(delta: float) -> void:
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if not multiplayer.is_server():
		return
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	_spawn_timer = randf_range(min_spawn_interval, max_spawn_interval)
	_spawn_car()

func _spawn_car() -> void:
	for child in get_children():
		if child is TransportStop:
			var bus_stop := child.get_node("BusStop") as BusStop
			# A queued bus waits for the shared bay without suspending car traffic.
			if not bus_stop.has_pending_service() and randf() < bus_spawn_chance and bus_stop.request_departure():
				return
	var car := spawn_vehicle(vehicle_scene, _end.global_position, false)
	if car != null:
		car.route_finished.connect(car.queue_free, CONNECT_ONE_SHOT)

func spawn_vehicle(scene: PackedScene, destination: Vector2, stop_at_end: bool, vehicle_name := "", initial_properties: Dictionary = {}) -> Vehicle:
	if not multiplayer.is_server() or _level == null or scene == null or _cars.size() >= max_cars:
		return null
	var start_position := _level.to_local(_start.global_position)
	for car in _cars:
		if is_instance_valid(car) and car.position.distance_to(start_position) < min_spawn_spacing:
			return null
	var end_position := _level.to_local(destination)
	end_position.y = start_position.y
	var car := scene.instantiate() as Vehicle
	if car == null:
		push_error("Traffic lane vehicle scene must have a Vehicle root")
		return null
	_next_car_id += 1
	car.name = vehicle_name if not vehicle_name.is_empty() else "TrafficCar%d" % _next_car_id
	# Vehicles are spawned under Level, so carry over the lane's scale.
	car.scale = (_level.global_transform.affine_inverse() * global_transform).get_scale()
	for property: String in initial_properties:
		car.set(property, initial_properties[property])
	if car.randomize_appearance_on_spawn:
		car.randomize_appearance()
	car.configure_route(start_position, end_position, randf_range(min_speed, max_speed), stop_at_end)
	car.tree_exited.connect(_on_car_exited.bind(car), CONNECT_ONE_SHOT)
	_level.add_child(car)
	_cars.append(car)
	return car

func _on_car_exited(car: Vehicle) -> void:
	_cars.erase(car)
