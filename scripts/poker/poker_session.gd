class_name PokerSession
extends Node2D

const ENTRY_FEE      := 20.0
const STARTING_CHIPS := 200.0
const CHIP_RATE      := STARTING_CHIPS / ENTRY_FEE   # chips per dollar

var player_slots: Array[int]    = [-1, -1, -1, -1]
var player_names: Array[String] = ["", "", "", ""]
var player_refs: Dictionary    = {}
var game: PokerGame            = null
var _canvas: CanvasLayer        = null
var money: Array[float]        = [0.0, 0.0, 0.0, 0.0]
var readiness: Array[bool]      = [false, false, false, false]
var spectating: Array[bool]    = [false, false, false, false]

var _betting: PokerBetting
var _round:   PokerRound

func _ready() -> void:
	_betting = PokerBetting.new(self)
	_round   = PokerRound.new(self, _betting)
	multiplayer.peer_disconnected.connect(_handle_leave)

func open_game(player: Player) -> void:
	var peer_id := player.get_multiplayer_authority()
	if player.is_in_minigame:
		if game == null or not is_instance_valid(game) or not game.visible:
			notify_local_exit(peer_id)
		return
	if not multiplayer.is_server():
		if player.player_data.money < ENTRY_FEE:
			return
		player.player_data.adjust_money(-ENTRY_FEE)
	player_refs[peer_id] = player
	player.is_in_minigame  = true
	if multiplayer.is_server():
		_handle_join(peer_id, player.player_name)
	else:
		_remote_request_join.rpc_id(1, player.player_name)

func notify_local_exit(peer_id: int) -> void:
	var slot := _slot_of(peer_id)
	if slot >= 0:
		var player: Player = player_refs.get(peer_id)
		if player != null and is_instance_valid(player):
			var chips: float = money[slot]
			if game != null and is_instance_valid(game):
				chips = game.money[slot]
			player.player_data.adjust_money(chips / CHIP_RATE)
	var player: Player = player_refs.get(peer_id)
	if player != null and is_instance_valid(player):
		player.is_in_minigame = false
	player_refs.erase(peer_id)
	_cleanup_local_canvas()
	if multiplayer.is_server():
		_handle_leave(peer_id)
	else:
		_remote_request_leave.rpc_id(1)

func local_player_action(slot: int, action: String, amount: float) -> void:
	if action == "ready":
		if _round.phase == PokerGame.Phase.READY_UP:
			readiness[slot] = true
			_check_ready_complete()
			if _round.phase == PokerGame.Phase.READY_UP:
				_broadcast_ready_state()
		return
	if _round.phase == PokerGame.Phase.READY_UP:
		return
	if not _betting.apply_action(slot, action, amount):
		return
	if _betting.is_only_one_left():
		_round.resolve()
		return
	_betting.advance_turn()
	if _betting.is_round_complete():
		_round.advance_phase()
	else:
		sync_state()

func _handle_join(peer_id: int, player_name: String = "") -> void:
	if _slot_of(peer_id) >= 0:
		return
	var player: Player = player_refs.get(peer_id)
	if player != null:
		if player.player_data.money < ENTRY_FEE:
			_remote_buy_in_rejected.rpc_id(peer_id)
			player_refs.erase(peer_id)
			return
		player.player_data.adjust_money(-ENTRY_FEE)

	var in_progress := _round.phase in [
		PokerGame.Phase.BETTING_PREFLOP, PokerGame.Phase.BETTING_FLOP,
		PokerGame.Phase.BETTING_TURN,    PokerGame.Phase.BETTING_RIVER,
		PokerGame.Phase.SPECTATING,      PokerGame.Phase.SHOWDOWN,
		PokerGame.Phase.ROUND_OVER,
	]

	var free_slot := -1
	for s in [0, 2, 1, 3]:
		if player_slots[s] == -1:
			free_slot = s
			break

	if free_slot < 0:
		_remote_spectate.rpc_id(peer_id, player_slots.duplicate())
		return

	var pname: String = player.player_name if (player != null and player.player_name != "") else (player_name if player_name != "" else "P%d" % (free_slot + 1))
	player_slots[free_slot] = peer_id
	player_names[free_slot] = pname
	money[free_slot]        = STARTING_CHIPS
	readiness[free_slot]    = false
	spectating[free_slot]   = in_progress

	var snap := _build_snapshot()
	var my_cards: Array = []
	if _round.hole_cards[free_slot].size() >= 2:
		my_cards = _round.hole_cards[free_slot].duplicate()

	if peer_id == multiplayer.get_unique_id():
		_setup_local_game(free_slot, snap, my_cards)
	else:
		_remote_welcome.rpc_id(peer_id, free_slot, snap, my_cards)

	_remote_player_joined.rpc(peer_id, free_slot, pname, STARTING_CHIPS,
		player_slots.duplicate(), player_names.duplicate(),
		readiness.duplicate(), spectating.duplicate())

	if not in_progress:
		_try_enter_ready_phase()

func _handle_leave(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	var slot := _slot_of(peer_id)
	if slot >= 0:
		player_slots[slot] = -1
		player_names[slot] = ""
		money[slot] = 0.0
		readiness[slot] = false
		spectating[slot] = false
		_betting.folded[slot] = false
		_round.hole_cards[slot] = []
		_betting.player_bets[slot] = 0.0
	if slot >= 0:
		_remote_player_left.rpc(peer_id)
	var active_betting := _round.phase in [
		PokerGame.Phase.BETTING_PREFLOP, PokerGame.Phase.BETTING_FLOP,
		PokerGame.Phase.BETTING_TURN, PokerGame.Phase.BETTING_RIVER,
	]
	if active_betting:
		if slot >= 0 and slot == _betting.active_slot:
			_betting.advance_turn()
		if _betting.is_only_one_left():
			_round.resolve()
		elif _betting.is_round_complete():
			_round.advance_phase()
	if _round.phase == PokerGame.Phase.READY_UP:
		if active_seat_count() < 2:
			_round.phase = PokerGame.Phase.WAITING
			sync_state()
		else:
			_check_ready_complete()

func _setup_local_game(my_slot: int, snap: Dictionary, my_cards: Array) -> void:
	_ensure_game_exists()
	game.local_slot = my_slot
	game.visible    = true
	game.apply_snapshot(snap)
	if my_cards.size() >= 2:
		game.apply_hole_cards(my_cards[0], my_cards[1])

func _build_snapshot() -> Dictionary:
	return {
		"phase":        _round.phase,
		"player_slots": player_slots.duplicate(),
		"player_names": player_names.duplicate(),
		"money":        money.duplicate(),
		"folded":       _betting.folded.duplicate(),
		"readiness":    readiness.duplicate(),
		"community":    _round.community.duplicate(),
		"pot":          _betting.pot,
		"current_bet":  _betting.current_bet,
		"player_bets":  _betting.player_bets.duplicate(),
		"active_slot":  _betting.active_slot,
		"dealer_slot":  _round.dealer_slot,
		"winner_slot":  -1,
		"winner_hand":  "",
		"spectators":   spectating.duplicate(),
	}

func sync_state() -> void:
	var data := {
		"phase":       _round.phase,
		"pot":         _betting.pot,
		"current_bet": _betting.current_bet,
		"player_bets": _betting.player_bets.duplicate(),
		"active_slot": _betting.active_slot,
		"dealer_slot": _round.dealer_slot,
		"community":   _round.community.duplicate(),
		"folded":      _betting.folded.duplicate(),
		"readiness":   readiness.duplicate(),
		"spectators":  spectating.duplicate(),
		"money":       money.duplicate(),
	}
	_remote_sync_state.rpc(data)

func _slot_of(peer_id: int) -> int:
	for s in range(4):
		if player_slots[s] == peer_id:
			return s
	return -1

func _try_enter_ready_phase() -> void:
	if _round.phase == PokerGame.Phase.READY_UP:
		return
	if active_seat_count() >= 2:
		_enter_ready_phase()
	elif active_seat_count() >= 1:
		_round.phase = PokerGame.Phase.WAITING
		sync_state()

func _enter_ready_phase() -> void:
	_round.phase = PokerGame.Phase.READY_UP
	for s in range(4):
		if player_slots[s] >= 0:
			readiness[s] = false
	_betting.active_slot = -1
	sync_state()
	_broadcast_ready_state()

func _broadcast_ready_state() -> void:
	for s in range(4):
		if player_slots[s] < 0:
			continue
		var target := player_slots[s]
		var data := {
			"phase":      _round.phase,
			"readiness":  readiness.duplicate(),
			"spectators": spectating.duplicate(),
		}
		if target == multiplayer.get_unique_id():
			if game != null and is_instance_valid(game):
				game.apply_ready_state(data)
		else:
			_remote_ready_state.rpc_id(target, data)


func _check_ready_complete() -> void:
	var active_count := 0
	var ready_count := 0
	for s in range(4):
		if player_slots[s] >= 0 and not spectating[s]:
			active_count += 1
			if readiness[s]:
				ready_count += 1
	if active_count >= 2 and ready_count >= active_count:
		_activate_spectators()
		_round.start()

func _activate_spectators() -> void:
	for s in range(4):
		if player_slots[s] >= 0 and spectating[s]:
			spectating[s] = false
			readiness[s] = false

func active_seat_count() -> int:
	var c := 0
	for s in range(4):
		if player_slots[s] >= 0:
			c += 1
	return c

func active_non_spectator_count() -> int:
	var c := 0
	for s in range(4):
		if player_slots[s] >= 0 and not spectating[s]:
			c += 1
	return c

func active_seats_not_folded() -> Array:
	var out := []
	for s in range(4):
		if player_slots[s] >= 0 and not _betting.folded[s] and _round.hole_cards[s].size() >= 2:
			out.append(s)
	return out

func next_active_seat(from: int) -> int:
	for i in range(1, 5):
		var s := (from + i) % 4
		if player_slots[s] >= 0:
			return s
	return from

func next_active_unfold_seat(from: int) -> int:
	for i in range(1, 5):
		var s := (from + i) % 4
		if player_slots[s] >= 0 and not _betting.folded[s] and money[s] > 0.0 \
				and _round.hole_cards[s].size() >= 2:
			return s
	return from

func _ensure_game_exists() -> void:
	if game != null and is_instance_valid(game):
		return
	_canvas = CanvasLayer.new()
	_canvas.name = "PokerCanvas"
	game = load("res://scenes/poker/poker_game.tscn").instantiate() as PokerGame
	game.name = "PokerGame"
	game.interact_node = self
	get_tree().root.add_child(_canvas)
	_canvas.add_child(game)
	game.visible = false

func _cleanup_local_canvas() -> void:
	if _canvas != null and is_instance_valid(_canvas):
		_canvas.queue_free()
	_canvas = null
	game   = null

@rpc("any_peer", "reliable")
func _remote_request_join(player_name: String) -> void:
	if multiplayer.is_server():
		_handle_join(multiplayer.get_remote_sender_id(), player_name)

@rpc("authority", "reliable")
func _remote_buy_in_rejected() -> void:
	var peer_id := multiplayer.get_unique_id()
	var player: Player = player_refs.get(peer_id)
	if player != null and is_instance_valid(player):
		player.player_data.adjust_money(ENTRY_FEE)
		player.is_in_minigame = false
	player_refs.erase(peer_id)

@rpc("authority", "reliable")
func _remote_welcome(my_slot: int, snap: Dictionary, my_cards: Array) -> void:
	player_slots.assign(snap.get("player_slots", [-1, -1, -1, -1]))
	player_names.assign(snap.get("player_names", ["", "", "", ""]))
	readiness.assign(snap.get("readiness",  [false, false, false, false]))
	spectating.assign(snap.get("spectators", [false, false, false, false]))
	_setup_local_game(my_slot, snap, my_cards)

@rpc("authority", "call_local", "reliable")
func _remote_player_joined(peer_id: int, slot: int, pname: String, pmoney: float,
		slots: Array[int], names: Array[String], r: Array[bool], spec: Array[bool]) -> void:
	player_slots = slots
	player_names = names
	readiness    = r
	spectating   = spec
	if peer_id == multiplayer.get_unique_id():
		return
	if game != null and is_instance_valid(game):
		game.on_player_joined(peer_id, slot, pname, pmoney)

@rpc("authority", "reliable")
func _remote_spectate(slots: Array[int]) -> void:
	var peer_id := multiplayer.get_unique_id()
	var player: Player = player_refs.get(peer_id)
	if player != null and is_instance_valid(player):
		player.player_data.adjust_money(ENTRY_FEE)
		player.is_in_minigame = false
	player_refs.erase(peer_id)

@rpc("any_peer", "reliable")
func _remote_request_leave() -> void:
	if multiplayer.is_server():
		_handle_leave(multiplayer.get_remote_sender_id())

@rpc("authority", "call_local", "reliable")
func _remote_player_left(peer_id: int) -> void:
	if game != null and is_instance_valid(game):
		game.on_player_left(peer_id)
	for s in range(4):
		if player_slots[s] == peer_id:
			player_slots[s] = -1
			break

@rpc("authority", "call_local", "reliable")
func _remote_ready_state(data: Dictionary) -> void:
	if game != null and is_instance_valid(game):
		game.apply_ready_state(data)

@rpc("authority", "call_local", "reliable")
func _remote_sync_state(data: Dictionary) -> void:
	if game != null and is_instance_valid(game):
		game.apply_state(data)

@rpc("authority", "reliable")
func remote_deal_hole_cards(card1: int, card2: int) -> void:
	if game != null and is_instance_valid(game):
		game.apply_hole_cards(card1, card2)

@rpc("any_peer", "reliable")
func remote_player_action(action: String, amount: float) -> void:
	if not multiplayer.is_server():
		return
	if not is_finite(amount):
		return
	var peer_id := multiplayer.get_remote_sender_id()
	var slot    := _slot_of(peer_id)
	if slot < 0:
		return
	local_player_action(slot, action, amount)

@rpc("authority", "call_local", "reliable")
func remote_showdown(winner_slot: int, hands: Dictionary, p: float) -> void:
	if game != null and is_instance_valid(game):
		game.apply_showdown(winner_slot, hands, p)

@rpc("authority", "call_local", "reliable")
func remote_round_over(winner_slot: int, p: float, hand_name: String) -> void:
	if game != null and is_instance_valid(game):
		game.apply_round_over(winner_slot, p, hand_name)
