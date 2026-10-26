class_name NPC
extends Player

enum State {
	ARRIVING,
	GOING_TO_BENCH,
	SITTING_ON_BENCH,
	LOOKING_FOR_SEAT,
	SITTING,
	GOING_TO_BARTENDER,
	WAITING_TO_ORDER,
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

var route: NPCRoute
var _moving_directly := false

@onready var nav_agent: NavigationAgent2D = $NavigationAgent
@onready var _world_scale: float = global_transform.x.length()

var _elapsed_ms := 0.0

var state: State = State.ARRIVING:
	set(value):
		state = value
		_elapsed_ms = 0.0

const SPEED_AI := 150.0
const EXIT_DISTANCE := 24.0

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
		if route != null:
			route.start(self)

func _unhandled_input(_event: InputEvent) -> void:
	pass

func _setup_authority() -> void:
	pass

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server() or route == null:
		return
	if NavigationServer2D.map_get_iteration_id(nav_agent.get_navigation_map()) == 0:
		return

	_elapsed_ms += delta * 1000.0
	_moving_directly = false
	var can_move := route.update(delta)
	nav_agent.velocity = Vector2.ZERO
	if not can_move:
		return
	_moving_directly = route.move_direct(delta)
	if not _moving_directly and route.is_navigating():
		if not nav_agent.is_navigation_finished():
			var next_position := nav_agent.get_next_path_position()
			nav_agent.velocity = (next_position - global_position).limit_length(SPEED_AI * delta) / delta
		elif not nav_agent.is_target_reached() and state != State.EXITING:
			# Reaching the end of a partial path does not mean reaching the object.
			_begin_exit()

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if _moving_directly or is_sitting:
		return
	velocity = safe_velocity if route.is_navigating() else Vector2.ZERO
	move_and_slide()
	_animate_movement(get_physics_process_delta_time(), velocity)

func _set_destination(target: Vector2, arrival_distance: float = 4.0) -> void:
	# Navigation and interaction must agree on when the destination is reached.
	arrival_distance *= _world_scale
	if not nav_agent.target_position.is_equal_approx(target) or nav_agent.target_desired_distance != arrival_distance:
		nav_agent.target_desired_distance = arrival_distance
		nav_agent.target_position = target

func _begin_exit() -> void:
	route.cleanup()
	_set_destination(route.exit_position, EXIT_DISTANCE)
	state = State.EXITING
