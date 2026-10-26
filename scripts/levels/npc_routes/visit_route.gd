class_name NPCVisitRoute
extends NPCRoute

const ARRIVAL_DELAY_MS := 1000
const SITTING_DURATION_MS := 5000
const BENCH_SITTING_DURATION_MS := 5000
const CABIN_DURATION_MS := 5000
const WASHING_DURATION_MS := 3000
const DRINK_INTERVAL_MS := 5000
const DRINK_WAIT_TIMEOUT_MS := 11000
const BENCH_VISIT_CHANCE := 0.33
# Includes visitors who stop at the bench before entering the bar.
const BAR_VISIT_CHANCE := 0.80
const ANOTHER_DRINK_CHANCE := 0.33
const WC_VISIT_CHANCE := 0.33
const SEAT_INTERACTION_DISTANCE := 24.0
const SINK_INTERACTION_DISTANCE := 16.0
const CABIN_APPROACH_OFFSET := Vector2(40.0, -4.5)
const CABIN_STAND_OFFSET := Vector2(21.0, -4.5)

var _target_seat: Seat
var _target_cabin: WcCabin
var _target_sink: Sink

var _level: Level
var _hall: Node2D
var _wc: Room
var _bench: Node2D
var _bartender: Bartender

func _init(hall: Room, wc: Room, bench: Node2D, start: Vector2, finish: Vector2) -> void:
	super(start, finish)
	_level = Level.find_level_node(hall)
	_hall = hall
	_wc = wc
	_bench = bench
	_bartender = hall.find_child("Bartender", true, false) as Bartender

func update(delta: float) -> bool:
	super.update(delta)
	match npc.state:
		NPC.State.ARRIVING:
			if npc._elapsed_ms >= ARRIVAL_DELAY_MS:
				_arriving()
		NPC.State.SITTING_ON_BENCH:
			if npc._elapsed_ms >= BENCH_SITTING_DURATION_MS:
				npc._stand_up()
				npc.state = NPC.State.LOOKING_FOR_SEAT
		NPC.State.SITTING:
			if npc._elapsed_ms >= SITTING_DURATION_MS:
				npc._stand_up()
				npc.state = NPC.State.GOING_TO_BARTENDER
		NPC.State.WAITING_TO_ORDER:
			_waiting_to_order()
		NPC.State.WAITING_FOR_DRINK:
			_waiting_for_drink()
		NPC.State.DRINKING:
			_drinking()
		NPC.State.USING_CABIN:
			if npc._elapsed_ms >= CABIN_DURATION_MS:
				npc.state = NPC.State.LEAVING_CABIN
		NPC.State.WASHING_HANDS:
			if npc._elapsed_ms >= WASHING_DURATION_MS:
				_target_sink.turn_off()
				_target_sink = null
				npc.state = NPC.State.LOOKING_FOR_SEAT

	var navigation_state := npc.state
	match npc.state:
		NPC.State.GOING_TO_BENCH:
			_go_to_seat(_bench, NPC.State.SITTING_ON_BENCH)
		NPC.State.LOOKING_FOR_SEAT:
			_go_to_seat(_hall, NPC.State.DRINKING if npc._hands_item is Drink else NPC.State.SITTING)
		NPC.State.GOING_TO_BARTENDER:
			_going_to_bartender()
		NPC.State.GOING_TO_CABIN:
			_going_to_cabin()
		NPC.State.GOING_TO_SINK:
			_going_to_sink()

	return npc.state == navigation_state

func is_navigating() -> bool:
	return npc.state in [NPC.State.GOING_TO_BENCH, NPC.State.LOOKING_FOR_SEAT, NPC.State.GOING_TO_BARTENDER,
		NPC.State.WAITING_TO_ORDER, NPC.State.WAITING_FOR_DRINK, NPC.State.GOING_TO_CABIN, NPC.State.GOING_TO_SINK, NPC.State.EXITING]

func move_direct(delta: float) -> bool:
	if npc.state not in [NPC.State.ENTERING_CABIN, NPC.State.LEAVING_CABIN]:
		return false
	# The cabin fits the rectangular body, but is narrower than the navmesh clearance.
	var entering := npc.state == NPC.State.ENTERING_CABIN
	var offset := CABIN_STAND_OFFSET if entering else CABIN_APPROACH_OFFSET
	var target := _target_cabin.to_global(offset)
	npc.velocity = (target - npc.global_position).limit_length(NPC.SPEED_AI * delta) / delta
	npc.move_and_slide()
	npc._animate_movement(delta, npc.velocity)
	if npc.global_position.distance_to(target) <= 2.0 * npc._world_scale:
		if entering:
			npc.state = NPC.State.USING_CABIN
		else:
			_target_cabin.is_being_used = false
			_target_cabin = null
			npc.state = NPC.State.GOING_TO_SINK
	return true

func _arriving() -> void:
	var choice := randf()
	if choice < BENCH_VISIT_CHANCE:
		npc.state = NPC.State.GOING_TO_BENCH
	elif choice < BAR_VISIT_CHANCE:
		npc.state = NPC.State.LOOKING_FOR_SEAT
	else:
		npc._begin_exit()

func _go_to_seat(parent: Node2D, seated_state: NPC.State) -> void:
	if not is_instance_valid(_target_seat) or _target_seat.is_occupied:
		_target_seat = _get_random_free_seat_in(parent)
		if _target_seat == null:
			if npc.state == NPC.State.GOING_TO_BENCH:
				npc.state = NPC.State.LOOKING_FOR_SEAT
			else:
				npc._begin_exit()
			return
	var arrival_distance := SEAT_INTERACTION_DISTANCE
	if _target_seat.interaction_radius > 0.0:
		arrival_distance = minf(arrival_distance, _target_seat.interaction_radius * 0.75)
	npc._set_destination(_target_seat.global_position, arrival_distance)
	if npc.nav_agent.is_target_reached():
		npc._sit_in(_target_seat)
		_target_seat = null
		if npc.is_sitting:
			npc.state = seated_state

func _going_to_bartender() -> void:
	npc._set_destination(_bartender.purchase_area.global_position)
	# Use the same reach check as the bartender; a navigation radius can stop too far away.
	if _bartender.purchase_area.overlaps_area(npc.interaction_area):
		npc.state = NPC.State.WAITING_TO_ORDER

func _waiting_to_order() -> void:
	if not _bartender.purchase_area.overlaps_area(npc.interaction_area):
		npc.state = NPC.State.GOING_TO_BARTENDER
		return
	var item: BarMenuItem = _bartender.get_menu_items().pick_random()
	if not _bartender.order_item(npc, item):
		if npc._elapsed_ms >= DRINK_WAIT_TIMEOUT_MS:
			npc._begin_exit()
		return
	npc.state = NPC.State.WAITING_FOR_DRINK

func _waiting_for_drink() -> void:
	var drinks = _get_drinks_nearby()
	if not drinks.is_empty():
		var drink = drinks[0]
		drink.pickup(npc)
		npc.take_spawned_item(drink)
		npc.state = NPC.State.LOOKING_FOR_SEAT
	elif npc._elapsed_ms >= DRINK_WAIT_TIMEOUT_MS:
		npc._begin_exit()

func _drinking() -> void:
	if not is_instance_valid(npc._hands_item) or not (npc._hands_item is Drink):
		npc._begin_exit()
		return
	var drink := npc._hands_item as Drink
	if drink.parts == 0:
		_finish_drink()
		return
	if npc._elapsed_ms >= DRINK_INTERVAL_MS:
		npc._elapsed_ms -= DRINK_INTERVAL_MS
		var is_last_part := drink.parts == 1
		npc._drink(drink)
		if is_last_part:
			_finish_drink()

func _finish_drink() -> void:
	if npc.is_sitting:
		npc._stand_up()
	npc._hands_item = null
	var choice := randf()
	if choice < ANOTHER_DRINK_CHANCE:
		npc.state = NPC.State.GOING_TO_BARTENDER
	elif choice < ANOTHER_DRINK_CHANCE + WC_VISIT_CHANCE:
		npc.state = NPC.State.GOING_TO_CABIN
	else:
		npc._begin_exit()

func _going_to_cabin() -> void:
	if not is_instance_valid(_target_cabin) or _target_cabin.is_being_used:
		_target_cabin = _get_random_free_cabin()
		if _target_cabin == null:
			npc._set_destination(npc.global_position)
			return
	npc._set_destination(_target_cabin.to_global(CABIN_APPROACH_OFFSET))
	if npc.nav_agent.is_target_reached():
		if _target_cabin.is_being_used:
			_target_cabin = null
			return
		_target_cabin.is_being_used = true
		npc.state = NPC.State.ENTERING_CABIN

func _going_to_sink() -> void:
	if not is_instance_valid(_target_sink):
		_target_sink = _get_random_free_sink()
		if _target_sink == null:
			npc._set_destination(npc.global_position)
			return
	npc._set_destination(_target_sink.global_position, SINK_INTERACTION_DISTANCE)
	if npc.nav_agent.is_target_reached():
		_target_sink.turn_on()
		npc.state = NPC.State.WASHING_HANDS

func cleanup() -> void:
	for child in _level.get_children():
		if child is Drink and child.customer_id == int(npc.name):
			child.queue_free()
	_target_seat = null
	if npc.state in [NPC.State.ENTERING_CABIN, NPC.State.USING_CABIN, NPC.State.LEAVING_CABIN] and is_instance_valid(_target_cabin):
		_target_cabin.is_being_used = false
	if npc.state == NPC.State.WASHING_HANDS and is_instance_valid(_target_sink):
		_target_sink.turn_off()
	_target_cabin = null
	_target_sink = null
	if npc.is_sitting:
		npc._stand_up()
	if is_instance_valid(npc._hands_item) and npc._hands_item is Drink:
		npc._hands_item.queue_free()
	npc._hands_item = null

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
		if child is not NPC or child == npc:
			continue
		var other_route := child.route as NPCVisitRoute
		if other_route != null and (other_route._target_seat == target or other_route._target_sink == target):
			return true
	return false

func _get_drinks_nearby() -> Array[Drink]:
	var drinks: Array[Drink] = []
	for area in npc.interaction_area.get_overlapping_areas():
		var drink := area.get_parent() as Drink
		if drink != null and drink.holder_peer_id == 0 and drink.customer_id in [0, int(npc.name)]:
			drinks.append(drink)
	return drinks
