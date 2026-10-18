class_name HomeElevator
extends Interactable
## Owns the doors, cabin, passengers and complete trip to its paired elevator.

enum State { CLOSED, OPENING, OPEN, CLOSING, TRAVELLING }

@export var ding_scene: PackedScene
@export var destination: HomeElevator
@export var remember_departure := false
@export_range(0.1, 3.0, 0.05) var door_duration := 0.65
@export_range(0.1, 5.0, 0.05) var travel_duration := 0.65
@export_range(2.0, 30.0, 0.5) var boarding_timeout := 8.0
## Space occupied by the whole player's collision body before departure.
@export var cabin_space := Rect2(-9, -20, 18, 18)
@export var state: State = State.CLOSED:
	set(value):
		state = value
		if is_node_ready():
			_update_visuals()
@export_range(0.0, 1.0) var door_open_ratio := 0.0:
	set(value):
		door_open_ratio = clampf(value, 0.0, 1.0)
		if is_node_ready():
			_update_visuals()

@onready var area: Area2D = $Area
@onready var _left: Sprite2D = $DoorLeft
@onready var _right: Sprite2D = $DoorRight
@onready var _door_shape: CollisionShape2D = $DoorBody/Shape
@onready var _level := Level.find_level_node(self)
@onready var _main := _level.get_parent() as Main if _level != null else null

var _motion: Tween
var _empty_time := 0.0
var _cabin_was_occupied := false
var _trip_partner: HomeElevator
var _passengers: Array[Player] = []

func _enter_tree() -> void:
	set_multiplayer_authority(1, true)

func _ready() -> void:
	_update_visuals()

func _exit_tree() -> void:
	if _motion != null:
		_motion.kill()
	_finish_trip()

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or state != State.OPEN:
		_empty_time = 0.0
		return
	if is_busy():
		return
	if has_cabin_occupants():
		_cabin_was_occupied = true
		_empty_time = 0.0
	elif not is_doorway_clear():
		_empty_time = 0.0
	else:
		_empty_time += delta
		if _empty_time >= (1.2 if _cabin_was_occupied else boarding_timeout):
			move_doors(false)

func interact(player: Player) -> void:
	if multiplayer.is_server():
		_try_enter(int(player.name))
	else:
		_request_enter.rpc_id(1)

@rpc("any_peer", "reliable")
func _request_enter() -> void:
	if multiplayer.is_server():
		_try_enter(multiplayer.get_remote_sender_id())

func _try_enter(peer_id: int) -> void:
	var player := _level.get_player(peer_id) if _level != null else null
	if not can_interact(player) or is_busy():
		return
	if state == State.CLOSED:
		move_doors(true)
	elif state == State.OPEN and contains_player(player):
		_start_trip()

func is_busy() -> bool:
	return is_instance_valid(_trip_partner)

func _start_trip() -> void:
	var target := destination
	if _main == null or not is_instance_valid(target) or target == self \
		or not target.is_inside_tree() or target._main != _main:
		return
	if target.is_busy() or target.state not in [State.CLOSED, State.OPEN] \
		or target.has_cabin_occupants() or not target.is_doorway_clear() or not is_doorway_clear():
		return
	_passengers = get_passengers()
	_trip_partner = target
	target._trip_partner = self
	move_doors(false)
	target.move_doors(false)
	if not await _wait_for_doors(target):
		_finish_trip()
		return
	# Late movement packets may have reached either doorway during closing.
	if not _can_depart(target):
		_cancel_trip(target)
		return
	state = State.TRAVELLING
	target.state = State.TRAVELLING
	await get_tree().create_timer(travel_duration).timeout
	if not is_instance_valid(target) or not target.is_inside_tree():
		_finish_trip()
		return
	if not _can_depart(target):
		_cancel_trip(target)
		return
	var passenger_arrived := false
	for passenger in _passengers:
		if not is_instance_valid(passenger) or passenger.is_queued_for_deletion():
			continue
		# Passengers can walk inside the closed cabin; preserve their current place.
		var arrival := target.to_global(to_local(passenger.global_position))
		if remember_departure:
			passenger.return_level_id = _level.level_id
		if _main.transfer_player(int(passenger.name), target._level, arrival):
			passenger_arrived = true
	state = State.CLOSED
	target.move_doors(true)
	if await _wait_for_doors(target) and passenger_arrived:
		target._play_ding.rpc()
	_finish_trip()

func _can_depart(target: HomeElevator) -> bool:
	if target.has_cabin_occupants() or has_cabin_occupants(_passengers):
		return false
	for passenger in _passengers:
		if is_instance_valid(passenger) and not passenger.is_queued_for_deletion() \
			and (passenger.level_id != _level.level_id or not contains_player(passenger)):
			return false
	return true

func _cancel_trip(target: HomeElevator) -> void:
	move_doors(true)
	target.move_doors(true)
	await _wait_for_doors(target)
	_finish_trip()

func _wait_for_doors(target: HomeElevator) -> bool:
	while is_instance_valid(target) and target.is_inside_tree():
		if state not in [State.OPENING, State.CLOSING] and target.state not in [State.OPENING, State.CLOSING]:
			return true
		await get_tree().physics_frame
	return false

func _finish_trip() -> void:
	if is_instance_valid(_trip_partner):
		_trip_partner._trip_partner = null
	_trip_partner = null
	_passengers.clear()

func can_interact(player: Player) -> bool:
	return player != null and player.level_id == _level.level_id \
		and not player.in_vehicle and not player.is_sitting \
		and Rect2(-20, -12.05, 40, 36.05).has_point(to_local(player.global_position)) \
		and area.overlaps_area(player.interaction_area)

func _player_body_rect(player: Player) -> Rect2:
	var body := player.get_node("Shape") as CollisionShape2D
	var size := (body.shape as RectangleShape2D).size
	return global_transform.affine_inverse() * body.global_transform * Rect2(-size * 0.5, size)

func contains_player(player: Player) -> bool:
	return player != null and cabin_space.grow(0.02).encloses(_player_body_rect(player))

func get_passengers() -> Array[Player]:
	var passengers: Array[Player] = []
	for player in _level.get_players():
		if player.level_id == _level.level_id and not player.in_vehicle \
			and not player.is_sitting and contains_player(player):
			passengers.append(player)
	return passengers

func has_cabin_occupants(excluded: Array[Player] = []) -> bool:
	for player in _level.get_players():
		if player.level_id != _level.level_id or player.in_vehicle or player in excluded:
			continue
		if cabin_space.intersects(_player_body_rect(player)):
			return true
	return false

func is_doorway_clear() -> bool:
	var doorway := Rect2(-9, -2, 18, 4)
	for player in _level.get_players():
		if player.level_id == _level.level_id and not player.in_vehicle \
			and doorway.intersects(_player_body_rect(player)):
			return false
	return true

func move_doors(opened: bool) -> void:
	if not multiplayer.is_server():
		return
	if _motion != null:
		_motion.kill()
	var target := 1.0 if opened else 0.0
	var final_state := State.OPEN if opened else State.CLOSED
	if is_equal_approx(door_open_ratio, target):
		state = final_state
		return
	state = State.OPENING if opened else State.CLOSING
	_motion = create_tween()
	_motion.tween_property(self, "door_open_ratio", target, door_duration * absf(target - door_open_ratio))
	_motion.finished.connect(_finish_motion.bind(final_state))

func _finish_motion(final_state: State) -> void:
	state = final_state
	if state == State.OPEN:
		_cabin_was_occupied = has_cabin_occupants()

func _update_visuals() -> void:
	# Clip each translated leaf to the opening instead of drawing it on the wall.
	var displacement := roundi(9.0 * door_open_ratio)
	var width := 9 - displacement
	_left.visible = width > 0
	_right.visible = width > 0
	if width > 0:
		_left.region_rect = Rect2(displacement, 0, width, 22)
		_right.region_rect = Rect2(9, 0, width, 22)
		_right.offset = Vector2(displacement, -28)
	var passable := state == State.OPEN and is_equal_approx(door_open_ratio, 1.0)
	_door_shape.set_deferred("disabled", passable)

@rpc("authority", "call_local", "reliable")
func _play_ding() -> void:
	if ding_scene == null:
		return
	var audio := ding_scene.instantiate() as AudioStreamPlayer2D
	add_child(audio)
	audio.play()
