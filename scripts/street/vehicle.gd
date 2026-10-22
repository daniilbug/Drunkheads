class_name Vehicle
extends AnimatableBody2D

signal route_finished
signal boarding_requested(player: Player)

enum TravelState { STOPPED, DRIVING }
const MIN_MOVING_SPEED := 1.0
const ARRIVAL_TOLERANCE := 0.25

@export var cruise_speed := 70.0
@export var acceleration := 140.0
@export var braking := 180.0
@export var wheel_reference_speed := 70.0
@export var obstacle_lookahead := 60.0
@export var obstacle_gap := 4.0
@export var honk_delay := 0.5
@export var honk_interval := 5.0
@export var interaction_detectable := false
@export var randomize_appearance_on_spawn := false

@export var boarding_enabled := false:
	set(value):
		boarding_enabled = value
		if is_node_ready():
			_update_interaction()

@export var travel_state: TravelState = TravelState.STOPPED:
	set(value):
		travel_state = value
		if is_node_ready():
			_update_interaction()
			_update_driving_audio()

@export var current_speed := 0.0:
	set(value):
		current_speed = value
		if is_node_ready():
			_update_wheels()
			_update_driving_audio()

@export var facing_right := true:
	set(value):
		facing_right = value
		if is_node_ready():
			_update_facing()

@onready var _visuals: Node2D = $Visuals
@onready var _rear_wheel: AnimatedSprite2D = $Visuals/Body/RearWheel
@onready var _front_wheel: AnimatedSprite2D = $Visuals/Body/FrontWheel
@onready var _interaction: VehicleInteraction = $VehicleInteraction
@onready var _driving_audio: AudioStreamPlayer2D = get_node_or_null("DrivingAudio")
@onready var _honk_audio: AudioStreamPlayer2D = $HonkAudio
@onready var _navigation_agent: NavigationAgent2D = $NavigationAgent
@onready var _forward_cast: ShapeCast2D = $ForwardCast

var _destination := Vector2.ZERO
var _stop_at_destination := false
var _pending_delta := 0.0
var _pending_speed := 0.0
var _pending_clearance := 0.0
var _world_units_per_local := 1.0
var _blocked_time := 0.0
var _honk_cooldown := 0.0

func _enter_tree() -> void:
	set_multiplayer_authority(1, true)

func _ready() -> void:
	_world_units_per_local = maxf(global_transform.x.length(), 0.001)
	# Routes follow their lane directly, including points outside the pedestrian navigation mesh.
	# Keep the agent for local avoidance without letting mesh borders stop traffic.
	_navigation_agent.navigation_layers = 0
	_navigation_agent.radius *= _world_units_per_local
	_navigation_agent.neighbor_distance *= _world_units_per_local
	_navigation_agent.avoidance_enabled = multiplayer.is_server()
	_navigation_agent.max_speed = maxf(cruise_speed * _world_units_per_local, 1.0)
	if multiplayer.is_server():
		_navigation_agent.velocity_computed.connect(_on_velocity_computed)
		if travel_state == TravelState.DRIVING:
			_navigation_agent.target_position = get_parent().to_global(_destination)
	_update_facing()
	_update_wheels()
	_update_interaction()
	_update_driving_audio()

func configure_route(start: Vector2, destination: Vector2, speed: float, stop_at_end: bool) -> void:
	if not is_equal_approx(start.y, destination.y):
		push_error("Vehicles currently support horizontal routes only")
		return
	position = start
	_destination = destination
	_stop_at_destination = stop_at_end
	cruise_speed = speed
	if is_node_ready():
		_navigation_agent.max_speed = maxf(cruise_speed * _world_units_per_local, 1.0)
		_navigation_agent.target_position = get_parent().to_global(destination)
	facing_right = destination.x >= start.x
	current_speed = 0.0
	_reset_honk()
	travel_state = TravelState.DRIVING

func randomize_appearance() -> void:
	pass

func _physics_process(delta: float) -> void:
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if not multiplayer.is_server() or travel_state != TravelState.DRIVING:
		return
	_navigation_agent.get_next_path_position()
	var remaining := absf(_destination.x - position.x)
	if remaining <= ARRIVAL_TOLERANCE:
		_finish_route()
		return
	var direction := 1.0 if facing_right else -1.0
	# Avoidance may suggest a side step, so sweep the full body along X as well.
	var clearance := _get_forward_clearance(direction)
	var target_speed := cruise_speed
	if _stop_at_destination:
		target_speed = minf(cruise_speed, sqrt(2.0 * braking * remaining))
	target_speed = minf(target_speed, sqrt(2.0 * braking * maxf(clearance - obstacle_gap, 0.0)))
	var rate := acceleration if target_speed >= current_speed else braking
	_pending_speed = move_toward(current_speed, target_speed, rate * delta)
	_pending_clearance = maxf(clearance - obstacle_gap, 0.0)
	_pending_delta = delta
	var world_direction := global_transform.x.normalized() * direction
	_navigation_agent.velocity = world_direction * _pending_speed * _world_units_per_local
	if not _navigation_agent.avoidance_enabled:
		_apply_safe_velocity(_navigation_agent.velocity)

func _get_forward_clearance(direction: float) -> float:
	var braking_distance := cruise_speed * cruise_speed / (2.0 * maxf(braking, 1.0))
	var lookahead := maxf(obstacle_lookahead, braking_distance + obstacle_gap + cruise_speed / 60.0)
	_forward_cast.target_position = Vector2(direction * lookahead, 0.0)
	_forward_cast.force_shapecast_update()
	if _forward_cast.is_colliding():
		return lookahead * _forward_cast.get_closest_collision_safe_fraction()
	return lookahead

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if multiplayer.is_server() and travel_state == TravelState.DRIVING:
		_apply_safe_velocity(safe_velocity)

func _apply_safe_velocity(safe_velocity: Vector2) -> void:
	var direction := 1.0 if facing_right else -1.0
	var world_direction := global_transform.x.normalized() * direction
	var speed := clampf(safe_velocity.dot(world_direction) / _world_units_per_local, 0.0, _pending_speed)
	var remaining := absf(_destination.x - position.x)
	var step := minf(minf(speed * _pending_delta, remaining), _pending_clearance)
	if step < MIN_MOVING_SPEED * _pending_delta:
		step = 0.0
	position.x += direction * step
	current_speed = step / maxf(_pending_delta, 0.001)
	if step >= remaining - ARRIVAL_TOLERANCE:
		_finish_route()
	else:
		_update_honk(_pending_delta)

func _update_honk(delta: float) -> void:
	# Destination stops and normal braking must not trigger the horn.
	if not _forward_cast.is_colliding() or current_speed >= MIN_MOVING_SPEED:
		_reset_honk()
		return
	_blocked_time += delta
	_honk_cooldown = maxf(_honk_cooldown - delta, 0.0)
	if _blocked_time >= honk_delay and _honk_cooldown <= 0.0:
		_play_honk.rpc()
		_honk_cooldown = maxf(honk_interval, _honk_audio.stream.get_length())

func _reset_honk() -> void:
	_blocked_time = 0.0
	_honk_cooldown = 0.0

@rpc("authority", "call_local", "reliable")
func _play_honk() -> void:
	_honk_audio.play()

func _finish_route() -> void:
	position = _destination
	_navigation_agent.velocity = Vector2.ZERO
	current_speed = 0.0
	travel_state = TravelState.STOPPED
	_reset_honk()
	route_finished.emit()

func request_interaction(player: Player) -> void:
	if multiplayer.is_server():
		_handle_interaction(int(player.name))
	else:
		_request_interaction.rpc_id(1)

@rpc("any_peer", "reliable")
func _request_interaction() -> void:
	if multiplayer.is_server():
		_handle_interaction(multiplayer.get_remote_sender_id())

func _handle_interaction(peer_id: int) -> void:
	if not boarding_enabled or travel_state != TravelState.STOPPED:
		return
	var level := Level.find_level_node(self)
	if level == null:
		return
	var player := level.get_player(peer_id)
	if player == null or player.in_vehicle or player.is_sitting or not _interaction.area.overlaps_area(player.interaction_area):
		return
	if level.transport_destination != null and player.level_id != level.transport_destination.id:
		return
	boarding_requested.emit(player)

func _update_facing() -> void:
	_visuals.scale.x = 1.0 if facing_right else -1.0

func _update_wheels() -> void:
	for wheel in [_rear_wheel, _front_wheel]:
		if current_speed <= 0.01:
			wheel.pause()
		else:
			wheel.speed_scale = current_speed / maxf(wheel_reference_speed, 1.0)
			if not wheel.is_playing():
				wheel.play(&"spin")

func _update_driving_audio() -> void:
	if _driving_audio == null:
		return
	var is_moving := travel_state == TravelState.DRIVING and current_speed > 0.01
	if is_moving and not _driving_audio.playing:
		_driving_audio.play()
	elif not is_moving and _driving_audio.playing:
		_driving_audio.stop()

func _update_interaction() -> void:
	_interaction.area.monitorable = interaction_detectable or (boarding_enabled and travel_state == TravelState.STOPPED)
