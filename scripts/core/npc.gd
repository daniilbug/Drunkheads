class_name NPC
extends Player

enum State {
	ARRIVING,
	GOING_TO_BENCH,
	SITTING_ON_BENCH,
	LOOKING_FOR_SEAT,
	SITTING,
	GOING_TO_BARTENDER,
	WAITING_FOR_DRINK,
	DRINKING,
	GOING_TO_CABIN,
	ENTERING_CABIN,
	USING_CABIN,
	LEAVING_CABIN,
	GOING_TO_SINK,
	WASHING_HANDS,
	EXITING
}

@onready var nav_agent: NavigationAgent2D = $NavigationAgent
@onready var _level: Level = Level.find_level_node(self)
@onready var _bar: Node2D = _level.get_node("BarHall")
@onready var _wc: BarWC = _level.get_node("BarWC")
@onready var _bench: Node2D = _level.get_node("Bench")
@onready var _bartender: Bartender = _level.find_child("Bartender", true, false)
@onready var _npc_manager: NPCManager = _level.get_node("NPCManager")
@onready var _world_scale: float = global_transform.x.length()

var _elapsed_ms := 0.0

var state: State = State.ARRIVING:
	set(value):
		state = value
		_elapsed_ms = 0.0

const ARRIVAL_DELAY_MS := 1000
const SITTING_DURATION_MS := 5000
const BENCH_SITTING_DURATION_MS := 5000
const CABIN_DURATION_MS := 5000
const WASHING_DURATION_MS := 3000
const DRINK_INTERVAL_MS := 5000
const DRINK_WAIT_TIMEOUT_MS := 11000
const BENCH_VISIT_CHANCE := 0.33
const BAR_VISIT_CHANCE := 0.80
const ANOTHER_DRINK_CHANCE := 0.33
const WC_VISIT_CHANCE := 0.33
const INTERACTION_DISTANCE := 20.0
const SEAT_INTERACTION_DISTANCE := 24.0
const SINK_INTERACTION_DISTANCE := 16.0
const CABIN_APPROACH_OFFSET := Vector2(40.0, -4.5)
const CABIN_STAND_OFFSET := Vector2(21.0, -4.5)

const SPEED_AI := 150.0
const EXIT_DISTANCE := 24.0
var _target_seat: Seat
var _target_cabin: WcCabin
var _target_sink: Sink

func _enter_tree() -> void:
	set_multiplayer_authority(1, true)

func _ready() -> void:
	super._ready()
	# NavigationAgent2D distances are world units; it does not inherit the world's scale.
	nav_agent.path_desired_distance *= _world_scale
	nav_agent.path_max_distance *= _world_scale
	nav_agent.radius *= _world_scale
	nav_agent.neighbor_distance *= _world_scale
	nav_agent.avoidance_enabled = multiplayer.is_server()
	if multiplayer.is_server():
		nav_agent.velocity_computed.connect(_on_velocity_computed)

func _unhandled_input(_event: InputEvent) -> void:
	pass

func _setup_authority() -> void:
	pass

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if NavigationServer2D.map_get_iteration_id(nav_agent.get_navigation_map()) == 0:
		return

	_elapsed_ms += delta * 1000.0
	match state:
		State.ARRIVING:
			if _elapsed_ms >= ARRIVAL_DELAY_MS:
				_arriving()
		State.SITTING_ON_BENCH:
			if _elapsed_ms >= BENCH_SITTING_DURATION_MS:
				_stand_up()
				state = State.LOOKING_FOR_SEAT
		State.SITTING:
			if _elapsed_ms >= SITTING_DURATION_MS:
				_stand_up()
				state = State.GOING_TO_BARTENDER
		State.WAITING_FOR_DRINK:
			_waiting_for_drink()
		State.DRINKING:
			_drinking()
		State.USING_CABIN:
			if _elapsed_ms >= CABIN_DURATION_MS:
				state = State.LEAVING_CABIN
		State.WASHING_HANDS:
			if _elapsed_ms >= WASHING_DURATION_MS:
				_target_sink.turn_off()
				_target_sink = null
				state = State.LOOKING_FOR_SEAT

	var navigation_state := state
	match state:
		State.GOING_TO_BENCH:
			_go_to_seat(_bench, State.SITTING_ON_BENCH)
		State.LOOKING_FOR_SEAT:
			_go_to_seat(_bar, State.DRINKING if _hands_item is Drink else State.SITTING)
		State.GOING_TO_BARTENDER:
			_going_to_bartender()
		State.GOING_TO_CABIN:
			_going_to_cabin()
		State.GOING_TO_SINK:
			_going_to_sink()
		State.EXITING:
			if nav_agent.is_target_reached():
				queue_free()

	nav_agent.velocity = Vector2.ZERO
	# A new state must select its destination before we inspect the old path.
	if state != navigation_state:
		return
	if state in [State.ENTERING_CABIN, State.LEAVING_CABIN]:
		_move_through_cabin(delta)
	elif _is_navigating():
		if not nav_agent.is_navigation_finished():
			var next_position := nav_agent.get_next_path_position()
			nav_agent.velocity = (next_position - global_position).limit_length(SPEED_AI * delta) / delta
		elif not nav_agent.is_target_reached() and state != State.EXITING:
			# Reaching the end of a partial path does not mean reaching the object.
			_begin_exit()

func _is_navigating() -> bool:
	return state in [State.GOING_TO_BENCH, State.LOOKING_FOR_SEAT, State.GOING_TO_BARTENDER,
		State.WAITING_FOR_DRINK, State.GOING_TO_CABIN, State.GOING_TO_SINK, State.EXITING]

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if state in [State.ENTERING_CABIN, State.LEAVING_CABIN] or is_sitting:
		return
	velocity = safe_velocity if _is_navigating() else Vector2.ZERO
	move_and_slide()
	_animate_movement(get_physics_process_delta_time(), velocity)

func _move_through_cabin(delta: float) -> void:
	# The cabin fits the rectangular body, but is narrower than the navmesh clearance.
	var entering := state == State.ENTERING_CABIN
	var offset := CABIN_STAND_OFFSET if entering else CABIN_APPROACH_OFFSET
	var target := _target_cabin.to_global(offset)
	velocity = (target - global_position).limit_length(SPEED_AI * delta) / delta
	move_and_slide()
	_animate_movement(delta, velocity)
	if global_position.distance_to(target) <= 2.0 * _world_scale:
		if entering:
			state = State.USING_CABIN
		else:
			_target_cabin.is_being_used = false
			_target_cabin = null
			state = State.GOING_TO_SINK

func _arriving() -> void:
	var choice := randf()
	if choice < BENCH_VISIT_CHANCE:
		state = State.GOING_TO_BENCH
	elif choice < BENCH_VISIT_CHANCE + BAR_VISIT_CHANCE:
		state = State.LOOKING_FOR_SEAT
	else:
		_begin_exit()

func _go_to_seat(parent: Node2D, seated_state: State) -> void:
	if not is_instance_valid(_target_seat) or _target_seat.is_occupied:
		_target_seat = _get_random_free_seat_in(parent)
		if _target_seat == null:
			if state == State.GOING_TO_BENCH:
				state = State.LOOKING_FOR_SEAT
			else:
				_begin_exit()
			return
	_set_destination(_target_seat.global_position, SEAT_INTERACTION_DISTANCE)
	if nav_agent.is_target_reached():
		_sit_in(_target_seat)
		_target_seat = null
		if is_sitting:
			state = seated_state

func _set_destination(target: Vector2, arrival_distance: float = 4.0) -> void:
	# Navigation and interaction must agree on when the destination is reached.
	arrival_distance *= _world_scale
	if not nav_agent.target_position.is_equal_approx(target) or nav_agent.target_desired_distance != arrival_distance:
		nav_agent.target_desired_distance = arrival_distance
		nav_agent.target_position = target

func _going_to_bartender() -> void:
	_set_destination(_bartender.purchase_area.global_position, INTERACTION_DISTANCE)
	if nav_agent.is_target_reached():
		var item = BarMenu.get_all_items().pick_random()
		_bartender.order_item(self, item)
		_set_destination(_bartender.purchase_area.global_position)
		state = State.WAITING_FOR_DRINK

func _waiting_for_drink() -> void:
	var drinks = _get_drinks_nearby()
	if not drinks.is_empty():
		var drink = drinks[0]
		drink.pickup(self)
		take_spawned_item(drink)
		state = State.LOOKING_FOR_SEAT
	elif _elapsed_ms >= DRINK_WAIT_TIMEOUT_MS:
		_begin_exit()

func _drinking() -> void:
	if not is_instance_valid(_hands_item) or not (_hands_item is Drink):
		_begin_exit()
		return
	var drink := _hands_item as Drink
	if drink.parts == 0:
		_finish_drink()
		return
	if _elapsed_ms >= DRINK_INTERVAL_MS:
		_elapsed_ms -= DRINK_INTERVAL_MS
		var is_last_part := drink.parts == 1
		_drink(drink)
		if is_last_part:
			_finish_drink()

func _finish_drink() -> void:
	if is_sitting:
		_stand_up()
	_hands_item = null
	var choice := randf()
	if choice < ANOTHER_DRINK_CHANCE:
		state = State.GOING_TO_BARTENDER
	elif choice < ANOTHER_DRINK_CHANCE + WC_VISIT_CHANCE:
		state = State.GOING_TO_CABIN
	else:
		_begin_exit()

func _going_to_cabin() -> void:
	if not is_instance_valid(_target_cabin) or _target_cabin.is_being_used:
		_target_cabin = _get_random_free_cabin()
		if _target_cabin == null:
			_set_destination(global_position)
			return
	_set_destination(_target_cabin.to_global(CABIN_APPROACH_OFFSET))
	if nav_agent.is_target_reached():
		if _target_cabin.is_being_used:
			_target_cabin = null
			return
		_target_cabin.is_being_used = true
		state = State.ENTERING_CABIN

func _going_to_sink() -> void:
	if not is_instance_valid(_target_sink):
		_target_sink = _get_random_free_sink()
		if _target_sink == null:
			_set_destination(global_position)
			return
	_set_destination(_target_sink.global_position, SINK_INTERACTION_DISTANCE)
	if nav_agent.is_target_reached():
		_target_sink.turn_on()
		state = State.WASHING_HANDS

func _begin_exit() -> void:
	_target_seat = null
	if state in [State.ENTERING_CABIN, State.USING_CABIN, State.LEAVING_CABIN] and is_instance_valid(_target_cabin):
		_target_cabin.is_being_used = false
	if state == State.WASHING_HANDS and is_instance_valid(_target_sink):
		_target_sink.turn_off()
	_target_cabin = null
	_target_sink = null
	if is_sitting:
		_stand_up()
	if is_instance_valid(_hands_item) and _hands_item is Drink:
		_hands_item.queue_free()
	_hands_item = null
	_set_destination(_npc_manager.exit_point.global_position, EXIT_DISTANCE)
	state = State.EXITING

func _get_random_free_seat_in(parent: Node2D) -> Seat:
	var seats = parent.find_children("*", "Seat", true, false)
	var free_seats = seats.filter(func(seat: Seat):
		return seat.available_to_npc and not seat.is_occupied and not _is_targeted(seat))
	if free_seats.is_empty():
		return null

	return free_seats.pick_random()

func _get_random_free_cabin() -> WcCabin:
	var cabins = _wc.find_children("*", "WcCabin", true, false)
	var free_cabins = cabins.filter(func(cabin: WcCabin): return not cabin.is_being_used)
	if free_cabins.is_empty():
		return null
	return free_cabins.pick_random()

func _get_random_free_sink() -> Sink:
	var sinks = _wc.find_children("*", "Sink", true, false)
	var available_sinks = sinks.filter(func(sink: Sink): return not _is_targeted(sink))
	if available_sinks.is_empty():
		return null
	var dry_sinks = available_sinks.filter(func(sink: Sink): return not sink.is_watering)
	return dry_sinks.pick_random() if not dry_sinks.is_empty() else available_sinks.pick_random()

func _is_targeted(target: Node2D) -> bool:
	# Reserve a place while approaching it, before its occupancy changes.
	for child in _level.get_children():
		if child is NPC and child != self and (child._target_seat == target or child._target_sink == target):
			return true
	return false

func _get_drinks_nearby() -> Array[Drink]:
	var drinks: Array[Drink] = []
	for area in interaction_area.get_overlapping_areas():
		if area.get_parent() is Drink and area.get_parent().holder_peer_id == 0:
			drinks.append(area.get_parent())
	return drinks
