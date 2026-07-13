class_name TableFootballInteract
extends Node2D

var player_slots: Array[int] = [-1, -1, -1, -1]
var _player_refs: Dictionary = {}
var _game: TableFootballGame = null
var _canvas: CanvasLayer = null

func open_game(player: Player) -> void:
	var peer_id := player.get_multiplayer_authority()
	_player_refs[peer_id] = player
	player.is_in_minigame = true
	if multiplayer.is_server():
		_handle_join(peer_id)
	else:
		_rpc_request_join.rpc_id(1)

func _handle_join(peer_id: int) -> void:
	for slot in [0, 2, 1, 3]:
		if player_slots[slot] == -1:
			player_slots[slot] = peer_id
			_rpc_assign_slot.rpc(peer_id, slot, player_slots.duplicate())
			if peer_id != multiplayer.get_unique_id():
				call_deferred("_send_snapshot_to", peer_id)
			return
	_rpc_spectate.rpc_id(peer_id, player_slots.duplicate())
	call_deferred("_send_snapshot_to", peer_id)

func _send_snapshot_to(peer_id: int) -> void:
	if _game != null and is_instance_valid(_game):
		_rpc_game_snapshot.rpc_id(peer_id, _game._build_snapshot())

func _handle_leave(peer_id: int) -> void:
	for slot in range(4):
		if player_slots[slot] == peer_id:
			player_slots[slot] = -1
			break
	_rpc_player_left.rpc(peer_id)

func notify_local_exit(peer_id: int) -> void:
	var player: Player = _player_refs.get(peer_id)
	if player != null and is_instance_valid(player):
		player.is_in_minigame = false
	_player_refs.erase(peer_id)

	if multiplayer.is_server():
		_rpc_close_game.rpc()
	else:
		_cleanup_local_canvas()
		_rpc_request_leave.rpc_id(1)

func _cleanup_local_canvas() -> void:
	if _canvas != null and is_instance_valid(_canvas):
		_canvas.queue_free()
	_canvas = null
	_game = null

func _ensure_game_exists() -> void:
	if _game != null and is_instance_valid(_game):
		return
	_canvas = CanvasLayer.new()
	_canvas.name = "TableFootballCanvas"
	_game = load("res://scenes/minigame/table-football/table_football_game.tscn").instantiate() as TableFootballGame
	_game.name = "TableFootballGame"
	_game.interact_node = self
	get_tree().root.add_child(_canvas)
	_canvas.add_child(_game)
	_game.visible = false

@rpc("any_peer", "reliable")
func _rpc_request_join() -> void:
	if multiplayer.is_server():
		_handle_join(multiplayer.get_remote_sender_id())

@rpc("authority", "call_local", "reliable")
func _rpc_assign_slot(peer_id: int, slot: int, slots: Array[int]) -> void:
	player_slots = slots
	if peer_id == multiplayer.get_unique_id():
		_ensure_game_exists()
		for s in range(4):
			if player_slots[s] >= 0:
				_game.on_player_joined(player_slots[s], s)
		_game.assign_local_player(slot, peer_id)
	elif _game != null and is_instance_valid(_game):
		_game.on_player_joined(peer_id, slot)

@rpc("authority", "reliable")
func _rpc_spectate(slots: Array[int]) -> void:
	player_slots = slots
	_ensure_game_exists()
	for s in range(4):
		if player_slots[s] >= 0:
			_game.on_player_joined(player_slots[s], s)
	_game.assign_local_player(-1, multiplayer.get_unique_id())

@rpc("any_peer", "reliable")
func _rpc_request_leave() -> void:
	if multiplayer.is_server():
		_handle_leave(multiplayer.get_remote_sender_id())

@rpc("authority", "call_local", "reliable")
func _rpc_player_left(peer_id: int) -> void:
	for slot in range(4):
		if player_slots[slot] == peer_id:
			player_slots[slot] = -1
			break
	if _game != null and is_instance_valid(_game):
		_game.on_player_left(peer_id)

@rpc("authority", "call_local", "reliable")
func _rpc_close_game() -> void:
	for pid in _player_refs:
		var player: Player = _player_refs[pid]
		if player != null and is_instance_valid(player):
			player.is_in_minigame = false
	_player_refs.clear()
	player_slots = [-1, -1, -1, -1]
	_cleanup_local_canvas()

@rpc("authority", "reliable")
func _rpc_game_snapshot(data: Dictionary) -> void:
	if _game != null and is_instance_valid(_game):
		_game.apply_snapshot(data)

@rpc("authority", "unreliable_ordered")
func _rpc_sync_state(ball_pos: Vector2, ball_vel: Vector2, serving: bool, serve_aim: float, serve_dir: float) -> void:
	if _game != null and is_instance_valid(_game):
		_game.apply_state_sync(ball_pos, ball_vel, serving, serve_aim, serve_dir)

@rpc("any_peer", "unreliable_ordered")
func _rpc_send_rod_state(rod_idx: int, slide: float, kick: float) -> void:
	if not multiplayer.is_server():
		return
	if _game != null and is_instance_valid(_game):
		_game.apply_rod_input(multiplayer.get_remote_sender_id(), rod_idx, slide, kick)
	_rpc_sync_rod.rpc(rod_idx, slide, kick)

@rpc("authority", "unreliable_ordered")
func _rpc_sync_rod(rod_idx: int, slide: float, kick: float) -> void:
	if _game != null and is_instance_valid(_game):
		_game.apply_rod_sync(rod_idx, slide, kick)

@rpc("any_peer", "reliable")
func _rpc_request_serve() -> void:
	if multiplayer.is_server() and _game != null and is_instance_valid(_game):
		_game.server_serve()

@rpc("authority", "call_local", "reliable")
func _rpc_do_serve(vel: Vector2) -> void:
	if _game != null and is_instance_valid(_game):
		_game.apply_serve(vel)

@rpc("authority", "call_local", "reliable")
func _rpc_goal_scored(score_a: int, score_b: int) -> void:
	if _game != null and is_instance_valid(_game):
		_game.apply_goal(score_a, score_b)

@rpc("authority", "call_local", "reliable")
func _rpc_game_over(w: int) -> void:
	if _game != null and is_instance_valid(_game):
		_game.apply_game_over(w)
