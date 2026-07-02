@tool
class_name TableFootballGame
extends Node2D

@export var field_width: int = 330
@export var field_height: int = 560
@export var goal_width: int = 50

@export var max_ball_speed: float = 800.0
@export var serve_speed: float = 250.0
@export var serve_max_angle: float = PI / 5.0
@export var serve_aim_speed: float = 2.0
@export var win_score: int = 5

@export var player_height: int = 24

@export_group("Colors")
@export var color_overlay: Color = Color(0, 0, 0, 0.72)
@export var color_hud_bg: Color = Color(0.1, 0.06, 0.02, 0.85)
@export var color_hud_text: Color = Color("f0d8a0")
@export var color_team_a: Color = Color("4b7dc8")
@export var color_team_a_dk: Color = Color("2a4a80")
@export var color_team_b: Color = Color("c83030")
@export var color_team_b_dk: Color = Color("801515")

const SLOT_RODS: Array = [[0, 4], [3, 7], [1, 5], [2, 6]]

var interact_node: TableFootballInteract = null
var local_slot: int = -1
var peer_slots: Dictionary = {}
var player_slots: Array[int] = [-1, -1, -1, -1]

var field_x: float:
	get: return (1280.0 - field_width) / 2.0

var field_y: float:
	get: return (720.0 - field_height) / 2.0

var score: Array[int] = [0, 0]
var game_over := false
var winner := -1
var flash_timer := 0.0
var is_serving := false
var _serve_block := 0.0
var _serve_aim_angle := 0.0
var _serve_aim_sweep := 1.0
var _serve_dir_y := 1.0

var selected_rod := 0

var _ball: TableFootballBallPhysics
var _rods: Array[TableFootballRod] = []
var _font: Font

@onready var Table: Node2D = $Table
@onready var ServeOverlay: Node2D = $Table/ServeOverlay
@onready var BallSpawnPoint: Node2D = $Table/BallSpawnPoint
@onready var Ball: RigidBody2D = $Ball

func _ready() -> void:
	_font = ThemeDB.fallback_font
	_ball = Ball as TableFootballBallPhysics

	for i in range(8):
		_rods.append(get_node("Table/Rod%d" % i) as TableFootballRod)

	_configure()
	_spawn_ball()

func _configure() -> void:
	Table.position = Vector2(field_x, field_y)
	Table.field_width = field_width
	Table.field_height = field_height
	Table.goal_width = goal_width
	ServeOverlay.visible = false
	ServeOverlay.set("field_width", field_width)
	ServeOverlay.set("field_height", field_height)

	for i in range(8):
		_rods[i].field_width = field_width
		_rods[i].player_height = player_height
		_rods[i].color_player = color_team_a if _rods[i].team == 0 else color_team_b
		_rods[i].color_player_dk = color_team_a_dk if _rods[i].team == 0 else color_team_b_dk

func assign_local_player(slot: int, peer_id: int) -> void:
	local_slot = slot
	if slot >= 0:
		peer_slots[peer_id] = slot
	visible = true

func on_player_joined(peer_id: int, slot: int) -> void:
	peer_slots[peer_id] = slot
	player_slots[slot] = peer_id

func on_player_left(peer_id: int) -> void:
	var slot: int = peer_slots.get(peer_id, -1)
	if slot >= 0:
		player_slots[slot] = -1
	peer_slots.erase(peer_id)

func _get_local_rods() -> Array[int]:
	if local_slot < 0:
		return []
	var rods: Array[int] = []
	rods.append_array(SLOT_RODS[local_slot])
	var partner_slot := local_slot ^ 1
	if player_slots[partner_slot] == -1:
		rods.append_array(SLOT_RODS[partner_slot])
	return rods

func _get_valid_rods_for_slot(slot: int) -> Array[int]:
	if slot < 0 or slot >= 4:
		return []
	var rods: Array[int] = []
	rods.append_array(SLOT_RODS[slot])
	var partner_slot := slot ^ 1
	if player_slots[partner_slot] == -1:
		rods.append_array(SLOT_RODS[partner_slot])
	return rods

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or interact_node == null:
		return
	if not multiplayer.is_server() or game_over:
		return
	interact_node._rpc_sync_state.rpc(
		_ball.position, _ball.linear_velocity,
		is_serving, _serve_aim_angle, _serve_dir_y
	)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return

	flash_timer = maxf(0.0, flash_timer - delta)
	_serve_block = maxf(0.0, _serve_block - delta)

	if Input.is_action_just_pressed("ui_cancel"):
		if interact_node != null:
			interact_node.notify_local_exit(multiplayer.get_unique_id())
		else:
			if get_parent() is CanvasLayer:
				get_parent().queue_free()
			else:
				queue_free()
		return

	if game_over:
		_disable_rod_input()
		queue_redraw()
		return

	if is_serving:
		_disable_rod_input()
		ServeOverlay.visible = true
		if _serve_block <= 0.0:
			if multiplayer.is_server():
				_serve_aim_angle += _serve_aim_sweep * serve_aim_speed * delta
				if absf(_serve_aim_angle) >= serve_max_angle:
					_serve_aim_angle = signf(_serve_aim_angle) * serve_max_angle
					_serve_aim_sweep *= -1.0
			ServeOverlay.aim_angle = _serve_aim_angle
			ServeOverlay.dir_y = _serve_dir_y
			ServeOverlay.queue_redraw()
			if local_slot >= 0 and Input.is_action_just_pressed("interact"):
				if interact_node != null:
					if multiplayer.is_server():
						server_serve()
					else:
						interact_node._rpc_request_serve.rpc_id(1)
				else:
					_serve_ball()
		return

	ServeOverlay.visible = false

	if local_slot >= 0:
		_handle_input(delta)
	if multiplayer.is_server():
		_check_goals()
		_clamp_ball()
		_check_speed()
	queue_redraw()

func _clamp_ball() -> void:
	var bx := _ball.position.x
	var by := _ball.position.y
	if bx < field_x - 20.0 or bx > field_x + field_width + 20.0 or by < field_y - 20.0 or by > field_y + field_height + 20.0:
		_ball.teleport(BallSpawnPoint.global_position)
		is_serving = true
		_serve_block = 0.3

func _check_speed() -> void:
	var spd := _ball.linear_velocity.length()
	if spd > max_ball_speed:
		_ball.linear_velocity = _ball.linear_velocity.normalized() * max_ball_speed

func _handle_input(delta: float) -> void:
	var local_rods := _get_local_rods()
	if local_rods.is_empty():
		return

	local_rods.sort_custom(func(a: int, b: int) -> bool: return _rods[a].position.y < _rods[b].position.y)

	if not local_rods.has(selected_rod):
		selected_rod = local_rods[0]

	if Input.is_action_just_pressed("up"):
		var cur_idx := local_rods.find(selected_rod)
		var next_idx := (cur_idx - 1 + local_rods.size()) % local_rods.size()
		selected_rod = local_rods[next_idx]
	if Input.is_action_just_pressed("down"):
		var cur_idx := local_rods.find(selected_rod)
		var next_idx := (cur_idx + 1) % local_rods.size()
		selected_rod = local_rods[next_idx]

	for i in range(8):
		_rods[i].is_selected = (i == selected_rod) and local_rods.has(i)

	var sel_rod: TableFootballRod = _rods[selected_rod]
	var min_slide := sel_rod._kicker_min_x()
	var max_slide := sel_rod._kicker_max_x() - sel_rod._spacing() * (float(sel_rod.kicker_count) - 1.0)

	var horizontal := Input.get_axis("tf_move_left", "tf_move_right")
	sel_rod.slide_pos = clampf(sel_rod.slide_pos + horizontal * sel_rod.slide_speed * delta, min_slide, max_slide)

	var vertical := Input.get_axis("tf_kick_down", "tf_kick_up")
	sel_rod.kick_offset = clampf(sel_rod.kick_offset - vertical * sel_rod.kick_speed * delta, -sel_rod.max_kick, sel_rod.max_kick)

	if interact_node != null and not multiplayer.is_server():
		interact_node._rpc_send_rod_state.rpc_id(1, selected_rod, sel_rod.slide_pos, sel_rod.kick_offset)

func _disable_rod_input() -> void:
	for rod in _rods:
		rod.is_selected = false

func _check_goals() -> void:
	var goal_l := field_x + (field_width - goal_width) * 0.5
	var goal_r := goal_l + goal_width
	var bp := _ball.position

	if bp.y < field_y and bp.x >= goal_l and bp.x <= goal_r:
		score[1] += 1
		_on_goal_scored()
	elif bp.y > field_y + field_height and bp.x >= goal_l and bp.x <= goal_r:
		score[0] += 1
		_on_goal_scored()

func _on_goal_scored() -> void:
	var new_winner := -1
	if score[0] >= win_score:
		new_winner = 0
	elif score[1] >= win_score:
		new_winner = 1

	if interact_node != null:
		interact_node._rpc_goal_scored.rpc(score[0], score[1])
		if new_winner >= 0:
			interact_node._rpc_game_over.rpc(new_winner)
	else:
		apply_goal(score[0], score[1])
		if new_winner >= 0:
			apply_game_over(new_winner)

func apply_goal(score_a: int, score_b: int) -> void:
	score[0] = score_a
	score[1] = score_b
	flash_timer = 0.4
	_spawn_ball()

func apply_game_over(w: int) -> void:
	game_over = true
	winner = w

func server_serve() -> void:
	if not is_serving or _serve_block > 0.0:
		return
	_serve_ball()
	if interact_node != null:
		interact_node._rpc_do_serve.rpc(_ball.linear_velocity)

func apply_serve(vel: Vector2) -> void:
	_ball.linear_velocity = vel
	is_serving = false

func apply_state_sync(ball_pos: Vector2, ball_vel: Vector2, serving: bool, serve_aim: float, serve_dir: float) -> void:
	if not multiplayer.is_server():
		_ball.sync_state(ball_pos, ball_vel)
	is_serving = serving
	_serve_aim_angle = serve_aim
	_serve_dir_y = serve_dir

func apply_rod_sync(rod_idx: int, slide: float, kick: float) -> void:
	var local_rods := _get_local_rods()
	if local_rods.has(rod_idx):
		return
	_rods[rod_idx].set_state(slide, kick)

func apply_rod_input(peer_id: int, rod_idx: int, slide: float, kick: float) -> void:
	var slot: int = peer_slots.get(peer_id, -1)
	if slot < 0:
		return
	var valid_rods := _get_valid_rods_for_slot(slot)
	if not valid_rods.has(rod_idx):
		return
	_rods[rod_idx].set_state(slide, kick)

func apply_snapshot(data: Dictionary) -> void:
	score[0] = data.score[0]
	score[1] = data.score[1]
	is_serving = data.is_serving
	_serve_dir_y = data.serve_dir_y
	_serve_aim_angle = data.serve_aim_angle
	game_over = data.game_over
	winner = data.winner
	_ball.teleport(data.ball_pos)
	_ball.linear_velocity = data.ball_vel
	for i in range(8):
		_rods[i].set_state(data.rods[i][0], data.rods[i][1])

func _build_snapshot() -> Dictionary:
	var rod_states := []
	for i in range(8):
		rod_states.append([_rods[i].slide_pos, _rods[i].kick_offset])
	return {
		"score": score.duplicate(),
		"is_serving": is_serving,
		"serve_dir_y": _serve_dir_y,
		"serve_aim_angle": _serve_aim_angle,
		"game_over": game_over,
		"winner": winner,
		"ball_pos": _ball.position,
		"ball_vel": _ball.linear_velocity,
		"rods": rod_states,
	}

func _spawn_ball() -> void:
	_ball.teleport(BallSpawnPoint.global_position)
	is_serving = true
	_serve_block = 0.3
	_serve_aim_angle = 0.0
	_serve_aim_sweep = 1.0
	_serve_dir_y *= -1.0

func _serve_ball() -> void:
	_ball.linear_velocity = Vector2(sin(_serve_aim_angle) * serve_speed, cos(_serve_aim_angle) * serve_speed * _serve_dir_y)
	is_serving = false

func _draw() -> void:
	_draw_overlay()
	_draw_hud()

	if flash_timer > 0.0 and int(flash_timer * 10.0) % 2 == 0:
		draw_string(_font, Vector2(field_x + field_width * 0.5 - 28.0, field_y + field_height * 0.5 + 8.0), "GOAL!",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)

	if game_over:
		var team_txt := "Team A wins!" if winner == 0 else "Team B wins!"
		var win_col := color_team_a if winner == 0 else color_team_b
		draw_string(_font, Vector2(field_x + field_width * 0.5 - 70.0, field_y + field_height * 0.5 + 8.0), team_txt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, win_col)

func _draw_overlay() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), color_overlay)

func _draw_hud() -> void:
	draw_rect(Rect2(field_x, field_y - 28.0, field_width, 22.0), color_hud_bg)
	var score_txt := "A  %d : %d  B" % [score[0], score[1]]
	draw_string(_font, Vector2(field_x + field_width * 0.5 - 60.0, field_y - 10.0), score_txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color_hud_text)

	draw_rect(Rect2(field_x, field_y + field_height + 4.0, field_width, 18.0), color_hud_bg)
	var hint_txt := "Press Esc to exit" if game_over else "Press E to serve" if is_serving else "W/S: switch rod     Arrows: move/kick     Esc: exit"
	draw_string(_font, Vector2(field_x + 8.0, field_y + field_height + 16.0), hint_txt,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color_hud_text)
