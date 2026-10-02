class_name NPC
extends Player

enum State { 
	LOOKING_FOR_CHAIR,
	SITTING, 
	GOING_TO_BARTENDER, 
	WAITING_FOR_DRINK,
	DRINKING,
	EXITING
}

@onready var nav_agent: NavigationAgent2D = $NavigationAgent
@onready var _level: Level = Level.find_level_node(self)
@onready var _bar: Bar = _level.find_child("Bar", true, false)
@onready var _bartender: Bartender = _level.find_child("Bartender", true, false)
@onready var _npc_manager: NPCManager = _level.get_node("NPCManager")

var _state_machine_delta: float = 0.0
var _state_machine_tick: int = 0
var _sitting_delta: float = 0.0

var state: State = State.LOOKING_FOR_CHAIR

const MAX_SITTING_TIME_SECONDS = 5
const STATE_MACHINE_TICK_DELTA_SECONDS = 1

const SPEED_AI := 150.0
const EXIT_DISTANCE := 10.0

func _enter_tree() -> void:
	set_multiplayer_authority(1, true)

func _ready() -> void:
	super._ready()
	if multiplayer.is_server():
		nav_agent.velocity_computed.connect(_on_velocity_computed)

func _unhandled_input(_event: InputEvent) -> void:
	pass

func _setup_authority() -> void:
	pass

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	
	_state_machine(delta)
	var direction_to_target := Vector2.ZERO
	if not nav_agent.is_navigation_finished():
		var next_path_position: Vector2 = nav_agent.get_next_path_position()
		direction_to_target = global_position.direction_to(next_path_position)
	nav_agent.velocity = direction_to_target * SPEED_AI
	if not nav_agent.avoidance_enabled:
		velocity = nav_agent.velocity

	_animate_physics(delta, nav_agent.velocity)

	if not is_sitting and not nav_agent.avoidance_enabled:
		move_and_slide()

func _state_machine(delta: float) -> void:
	_state_machine_delta += delta
	
	if _state_machine_delta >= STATE_MACHINE_TICK_DELTA_SECONDS:
		_state_machine_delta = 0.0
		_state_machine_tick += 1
	
		var initial_state = state
		match state:
			State.LOOKING_FOR_CHAIR:
				_looking_for_chair()
			State.SITTING:
				_sitting()
			State.GOING_TO_BARTENDER:
				_going_to_bartender()
			State.WAITING_FOR_DRINK:
				_waiting_for_drink()
			State.DRINKING:
				_drinking()
			State.EXITING:
				_exiting()
		if initial_state != state:
			_state_machine_tick = 0

func _looking_for_chair() -> void:
	if _state_machine_tick == 1 or no_target():
		var chair := _get_random_free_chair()
		if chair == null:
			_begin_exit()
		else:
			nav_agent.target_position = chair.global_position
	elif nav_agent.is_navigation_finished():
		var nodes = _get_nodes_nearby()
		var chairs_to_sit = nodes.filter(
			func(node: Node2D) -> bool: return node is Chair and not node.is_occupied
		)
		if chairs_to_sit.is_empty():
			_drop_target()
		else:
			_sit_in(chairs_to_sit[0])
			if _hands_item and _hands_item is Drink:
				state = State.DRINKING
			else:
				state = State.SITTING

func _sitting() -> void:
	if _state_machine_tick >= MAX_SITTING_TIME_SECONDS:
		_stand_up()
		state = _randomize_next_state()

func _going_to_bartender() -> void:
	nav_agent.target_position = _bartender.purchase_area.global_position
	if nav_agent.is_navigation_finished():
		var item = BarMenu.get_all_items().pick_random()
		_bartender.order_item(self, item)
		state = State.WAITING_FOR_DRINK

func _waiting_for_drink() -> void:
	var drinks = _get_drinks_nearby()
	if not drinks.is_empty():
		var drink = drinks[0]
		drink.pickup(self)
		_hands_item = drink
		drink.tree_exiting.connect(func(): _hands_item = null, CONNECT_ONE_SHOT)
		state = State.LOOKING_FOR_CHAIR
	elif _state_machine_tick > 10:
		_begin_exit()
		
func _drinking() -> void:
	if not is_instance_valid(_hands_item) or not (_hands_item is Drink):
		_begin_exit()
		return
	var drink := _hands_item as Drink
	if drink.parts == 0:
		_begin_exit()
		return
	if _state_machine_tick % 5 == 0:
		_drink(drink)

func _begin_exit() -> void:
	if is_sitting:
		_stand_up()
	if is_instance_valid(_hands_item) and _hands_item is Drink:
		_hands_item.queue_free()
	_hands_item = null
	nav_agent.avoidance_enabled = false
	for child in _level.get_children():
		if child is Player and child != self:
			add_collision_exception_with(child as PhysicsBody2D)
	nav_agent.target_position = _npc_manager.exit_point.global_position
	state = State.EXITING

func _exiting() -> void:
	if nav_agent.is_navigation_finished() and global_position.distance_to(_npc_manager.exit_point.global_position) <= EXIT_DISTANCE:
		_exit_bar()

func _animate_physics(delta: float, dir: Vector2) -> void:
	var walking := dir != Vector2.ZERO
	if walking != _is_walking:
		_is_walking = walking
		if walking:
			_idle_tween.pause()
			sprite.scale.y = 1.0
			_anim_t = 0.0
		else:
			sprite.position.y = 0.0
			_idle_tween.play()
			_anim_row = _dir_to_idle_row(direction)
			sprite.frame = _anim_row * 4
	if walking:
		direction = dir
		_anim_t += delta
		if not is_zero_approx(dir.x):
			_anim_row = ROW_WALK_E if dir.x > 0 else ROW_WALK_W
		elif not is_zero_approx(dir.y):
			_anim_row = ROW_WALK_S if dir.y > 0 else ROW_WALK_N
		sprite.frame = _anim_row * 4 + (int(_anim_t * FPS_WALK) % 4)

func _exit_bar() -> void:
	queue_free()

func _randomize_next_state() -> State:
	return State.GOING_TO_BARTENDER

func _get_random_free_chair() -> Chair:
	var chairs = _bar.find_children("*", "Chair", true, false)
	var free_chairs = chairs.filter(func(chair: Chair): return not chair.is_occupied)
	if free_chairs.is_empty():
		return null
	
	return free_chairs.pick_random()
	
func _get_drinks_nearby() -> Array[Drink]:
	var drinks: Array[Drink] = []
	for node in _get_nodes_nearby():
		if node is Drink:
			drinks.append(node)
	return drinks
	
func _get_nodes_nearby() -> Array[Node2D]:
	var owners: Array[Node2D] = []
	for area in interaction_area.get_overlapping_areas():
		if area.owner is Node2D:
			owners.append(area.owner)
	return owners
	
func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if is_sitting or not nav_agent.avoidance_enabled:
		return
	velocity = safe_velocity
	move_and_slide()
	
func no_target() -> bool:
	return nav_agent.target_position == Vector2.ZERO

func _drop_target() -> void:
	nav_agent.target_position = Vector2.ZERO
