class_name TableFootballBallPhysics
extends RigidBody2D

@export var color_ball: Color = Color("f5e87a")
@export var color_ball_sh: Color = Color("a09030")

@export_group("Physics")
@export var ball_mass: float = 0.5
@export var ball_bounce: float = 0.72
@export var ball_friction: float = 0.1
@export var ball_linear_damp: float = 0.4

var _teleport_to: Vector2 = Vector2.INF
var _hit_flash: float = 0.0
var _sync_pos: Vector2 = Vector2.INF
var _sync_vel: Vector2 = Vector2.ZERO
var _needs_sync: bool = false

func _ready() -> void:
	gravity_scale = 0.0
	mass = ball_mass
	linear_damp = ball_linear_damp
	var mt := PhysicsMaterial.new()
	mt.friction = ball_friction
	mt.bounce = ball_bounce
	physics_material_override = mt
	continuous_cd = 2
	lock_rotation = true

func teleport(pos: Vector2) -> void:
	_teleport_to = pos

func sync_state(pos: Vector2, vel: Vector2) -> void:
	_sync_pos = pos
	_sync_vel = vel
	_needs_sync = true

func trigger_hit_flash(impulse_magnitude: float) -> void:
	_hit_flash = clampf(impulse_magnitude / 80.0, 0.08, 0.22)

func _process(delta: float) -> void:
	if _hit_flash > 0.0:
		_hit_flash = maxf(0.0, _hit_flash - delta)
		queue_redraw()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _teleport_to != Vector2.INF:
		state.transform = Transform2D(0.0, _teleport_to)
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		_teleport_to = Vector2.INF
		_needs_sync = false
		reset_physics_interpolation()
	elif _needs_sync:
		var error := state.transform.origin.distance_to(_sync_pos)
		if error > 20.0:
			state.transform = Transform2D(0.0, _sync_pos)
			reset_physics_interpolation()
		state.linear_velocity = _sync_vel
		_needs_sync = false

func _draw() -> void:
	var r := ($CollisionShape2D.shape as CircleShape2D).radius
	var t := _hit_flash / 0.22
	var base := color_ball.lerp(Color.WHITE, t)
	draw_circle(Vector2.ZERO, r, base)
	if t < 0.5:
		draw_circle(Vector2(-r * 0.3, -r * 0.3), r * 0.35, Color(base.r + 0.2, base.g + 0.2, base.b + 0.2))
		draw_circle(Vector2(r * 0.25, r * 0.25), r * 0.2, color_ball_sh)
