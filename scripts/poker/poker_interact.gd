class_name PokerInteract
extends Node2D

const SMALL_BLIND := 2.0
const BIG_BLIND   := 4.0
const MIN_RAISE   := 4.0

var player_slots: Array[int]    = [-1, -1, -1, -1]
var _player_refs: Dictionary    = {}
var _game: PokerGame            = null
var _canvas: CanvasLayer        = null

# ── server-only game state ─────────────────────────────────────────────────

var _phase: PokerGame.Phase     = PokerGame.Phase.WAITING
var _deck: Array[int]           = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _hole_cards: Array          = [[], [], [], []]
var _community: Array[int]      = []
var _pot: float                 = 0.0
var _current_bet: float         = 0.0
var _player_bets: Array[float]  = [0.0, 0.0, 0.0, 0.0]
var _folded: Array[bool]        = [false, false, false, false]
var _active_slot: int           = -1
var _dealer_slot: int           = 0
var _money: Array[float]        = [0.0, 0.0, 0.0, 0.0]
var _round_trip: int            = 0   # how many players have acted since last raise

# ── public entry points ────────────────────────────────────────────────────

func open_game(player: Player) -> void:
	var peer_id := player.get_multiplayer_authority()
	_player_refs[peer_id] = player
	player.is_in_minigame  = true
	if multiplayer.is_server():
		_handle_join(peer_id)
	else:
		_rpc_request_join.rpc_id(1)

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

func server_player_action(slot: int, action: String, amount: float) -> void:
	_apply_action(slot, action, amount)

# ── server join/leave logic ────────────────────────────────────────────────

func _handle_join(peer_id: int) -> void:
	for slot in [0, 2, 1, 3]:
		if player_slots[slot] == -1:
			player_slots[slot] = peer_id
			var player: Player = _player_refs.get(peer_id)
			var pname:  String = player.name if player != null else "P"
			var pmoney: float  = player.player_data.money if player != null else 50.0
			_money[slot] = pmoney
			_rpc_assign_seat.rpc(peer_id, slot, player_slots.duplicate(), pname, pmoney)
			if peer_id != multiplayer.get_unique_id():
				call_deferred("_send_snapshot_to", peer_id)
			_try_start_round()
			return
	_rpc_spectate.rpc_id(peer_id, player_slots.duplicate())
	call_deferred("_send_snapshot_to", peer_id)

func _handle_leave(peer_id: int) -> void:
	var slot := _slot_of(peer_id)
	if slot >= 0:
		player_slots[slot] = -1
		_money[slot]       = 0.0
		_folded[slot]      = false
		_hole_cards[slot]  = []
		_player_bets[slot] = 0.0
	_rpc_player_left.rpc(peer_id)
	if _phase != PokerGame.Phase.WAITING:
		if slot == _active_slot:
			_advance_turn()
		_check_round_end()

func _send_snapshot_to(peer_id: int) -> void:
	if _game != null and is_instance_valid(_game):
		_rpc_game_snapshot.rpc_id(peer_id, _game.build_snapshot())

# ── round management ───────────────────────────────────────────────────────

func _try_start_round() -> void:
	if _phase != PokerGame.Phase.WAITING:
		return
	if _active_seat_count() < 2:
		return
	_start_round()

func _start_round() -> void:
	_deck.clear()
	for i in 52:
		_deck.append(i)
	_deck.shuffle()
	_community   = []
	_pot         = 0.0
	_current_bet = BIG_BLIND
	_player_bets = [0.0, 0.0, 0.0, 0.0]
	_folded      = [false, false, false, false]
	_hole_cards  = [[], [], [], []]
	_round_trip  = 0

	# Sync money from PlayerData before dealing
	for slot in range(4):
		if player_slots[slot] >= 0:
			var player: Player = _player_refs.get(player_slots[slot])
			if player != null and is_instance_valid(player):
				_money[slot] = player.player_data.money

	# Advance dealer
	_dealer_slot = _next_active_seat(_dealer_slot)

	# Post blinds
	var sb_slot := _next_active_seat(_dealer_slot)
	var bb_slot := _next_active_seat(sb_slot)
	_post_blind(sb_slot, SMALL_BLIND)
	_post_blind(bb_slot, BIG_BLIND)

	# Sync BETTING_PREFLOP phase first so clients clear stale hole cards
	_phase       = PokerGame.Phase.BETTING_PREFLOP
	_active_slot = _next_active_seat(bb_slot)
	_sync_state()

	# Deal hole cards after sync — clients receive clear then new cards in order
	for slot in range(4):
		if player_slots[slot] < 0:
			continue
		var c1: int = _deck.pop_back()
		var c2: int = _deck.pop_back()
		_hole_cards[slot] = [c1, c2]
		var target := player_slots[slot]
		if target == multiplayer.get_unique_id():
			if _game != null and is_instance_valid(_game):
				_game.apply_hole_cards(c1, c2)
		else:
			_rpc_deal_hole_cards.rpc_id(target, c1, c2)

func _post_blind(slot: int, amount: float) -> void:
	var actual := minf(amount, _money[slot])
	_money[slot]       -= actual
	_player_bets[slot] += actual
	_pot               += actual
	var player: Player  = _player_refs.get(player_slots[slot])
	if player != null and is_instance_valid(player):
		player.player_data.adjust_money(-actual)

func _apply_action(slot: int, action: String, amount: float) -> void:
	if slot != _active_slot or _folded[slot]:
		return

	match action:
		"check":
			if not is_equal_approx(_player_bets[slot], _current_bet):
				return
			_round_trip += 1
		"call":
			var to_call := minf(_current_bet - _player_bets[slot], _money[slot])
			_money[slot]       -= to_call
			_player_bets[slot] += to_call
			_pot               += to_call
			_deduct_player_money(slot, to_call)
			_round_trip += 1
		"raise":
			var to_call   := minf(_current_bet - _player_bets[slot], _money[slot])
			var raise_amt := clampf(amount - _current_bet, MIN_RAISE, _money[slot] - to_call)
			var total     := to_call + raise_amt
			_money[slot]       -= total
			_player_bets[slot] += total
			_current_bet        = _player_bets[slot]
			_pot               += total
			_deduct_player_money(slot, total)
			_round_trip = 1   # reset: everyone must act again
		"fold":
			_folded[slot] = true
			_round_trip   = maxi(_round_trip, 1)

	_rpc_player_action_broadcast.rpc(slot, action, amount)

	if _check_only_one_left():
		return
	_advance_turn()
	_check_round_end()

func _deduct_player_money(slot: int, amount: float) -> void:
	var player: Player = _player_refs.get(player_slots[slot])
	if player != null and is_instance_valid(player):
		player.player_data.adjust_money(-amount)

func _advance_turn() -> void:
	var next := _next_active_unfold_seat(_active_slot)
	_active_slot = next
	_sync_state()

func _check_round_end() -> void:
	var active := _active_seats_not_folded()
	if active.size() < 2:
		_resolve()
		return

	var all_equal := true
	for s in active:
		if not is_equal_approx(_player_bets[s], _current_bet):
			if _money[s] > 0.0:
				all_equal = false
				break

	if all_equal and _round_trip >= active.size():
		_advance_phase()

func _advance_phase() -> void:
	_round_trip  = 0
	_current_bet = 0.0
	for s in range(4):
		_player_bets[s] = 0.0

	match _phase:
		PokerGame.Phase.BETTING_PREFLOP:
			_deal_community(3)
			_phase = PokerGame.Phase.BETTING_FLOP
		PokerGame.Phase.BETTING_FLOP:
			_deal_community(1)
			_phase = PokerGame.Phase.BETTING_TURN
		PokerGame.Phase.BETTING_TURN:
			_deal_community(1)
			_phase = PokerGame.Phase.BETTING_RIVER
		PokerGame.Phase.BETTING_RIVER:
			_resolve()
			return

	_active_slot = _next_active_unfold_seat(_dealer_slot)
	_sync_state()

func _deal_community(count: int) -> void:
	for _i in range(count):
		_community.append(_deck.pop_back())

func _resolve() -> void:
	var active := _active_seats_not_folded()
	if active.size() == 1:
		var ws: int = active[0]
		_money[ws] += _pot
		var player: Player = _player_refs.get(player_slots[ws])
		if player != null and is_instance_valid(player):
			player.player_data.adjust_money(_pot)
		_rpc_round_over.rpc(ws, _pot, "")
		_phase = PokerGame.Phase.ROUND_OVER
		_sync_state()
		await get_tree().create_timer(3.5).timeout
		_reset_to_waiting()
		return

	# Showdown: evaluate best hand for each remaining player
	var all_cards := _community.duplicate()
	var best_slot := -1
	var best_hand := {}
	var hands_dict := {}
	for s in active:
		var my_cards: Array = _hole_cards[s].duplicate()
		my_cards.append_array(all_cards)
		var h := PokerHandEvaluator.best_hand(my_cards)
		h["cards"] = _hole_cards[s].duplicate()
		hands_dict[str(s)] = h
		if best_slot < 0 or PokerHandEvaluator.compare_hands(h, best_hand) > 0:
			best_slot = s
			best_hand = h

	_money[best_slot] += _pot
	var winner_player: Player = _player_refs.get(player_slots[best_slot])
	if winner_player != null and is_instance_valid(winner_player):
		winner_player.player_data.adjust_money(_pot)

	_rpc_showdown.rpc(best_slot, hands_dict, _pot)
	_phase = PokerGame.Phase.SHOWDOWN
	_sync_state()
	await get_tree().create_timer(4.0).timeout
	_rpc_round_over.rpc(best_slot, _pot, best_hand.get("name", ""))
	_phase = PokerGame.Phase.ROUND_OVER
	_sync_state()
	await get_tree().create_timer(3.5).timeout
	_reset_to_waiting()

func _reset_to_waiting() -> void:
	_phase       = PokerGame.Phase.WAITING
	_active_slot = -1
	_pot         = 0.0
	_current_bet = 0.0
	_sync_state()
	_try_start_round()

func _check_only_one_left() -> bool:
	var active := _active_seats_not_folded()
	if active.size() > 1:
		return false
	if active.size() == 1:
		_resolve()
	return true

func _sync_state() -> void:
	var data := {
		"phase":        _phase,
		"pot":          _pot,
		"current_bet":  _current_bet,
		"player_bets":  _player_bets.duplicate(),
		"active_slot":  _active_slot,
		"dealer_slot":  _dealer_slot,
		"community":    _community.duplicate(),
		"folded":       _folded.duplicate(),
		"money":        _money.duplicate(),
	}
	_rpc_sync_state.rpc(data)

# ── seat helpers ───────────────────────────────────────────────────────────

func _slot_of(peer_id: int) -> int:
	for s in range(4):
		if player_slots[s] == peer_id:
			return s
	return -1

func _active_seat_count() -> int:
	var c := 0
	for s in range(4):
		if player_slots[s] >= 0:
			c += 1
	return c

func _active_seats_not_folded() -> Array:
	var out := []
	for s in range(4):
		if player_slots[s] >= 0 and not _folded[s]:
			out.append(s)
	return out

func _next_active_seat(from: int) -> int:
	for i in range(1, 5):
		var s := (from + i) % 4
		if player_slots[s] >= 0:
			return s
	return from

func _next_active_unfold_seat(from: int) -> int:
	for i in range(1, 5):
		var s := (from + i) % 4
		if player_slots[s] >= 0 and not _folded[s]:
			return s
	return from

# ── canvas management ──────────────────────────────────────────────────────

func _ensure_game_exists() -> void:
	if _game != null and is_instance_valid(_game):
		return
	_canvas      = CanvasLayer.new()
	_canvas.name = "PokerCanvas"
	_game        = load("res://scenes/poker/poker_game.tscn").instantiate() as PokerGame
	_game.name   = "PokerGame"
	_game.interact_node = self
	get_tree().root.add_child(_canvas)
	_canvas.add_child(_game)
	_game.visible = false

func _cleanup_local_canvas() -> void:
	if _canvas != null and is_instance_valid(_canvas):
		_canvas.queue_free()
	_canvas = null
	_game   = null

# ── RPCs ───────────────────────────────────────────────────────────────────

@rpc("any_peer", "reliable")
func _rpc_request_join() -> void:
	if multiplayer.is_server():
		_handle_join(multiplayer.get_remote_sender_id())

@rpc("authority", "call_local", "reliable")
func _rpc_assign_seat(peer_id: int, slot: int, slots: Array[int], pname: String, pmoney: float) -> void:
	player_slots = slots
	if peer_id == multiplayer.get_unique_id():
		_ensure_game_exists()
		for s in range(4):
			if player_slots[s] >= 0:
				var n: String = pname if s == slot else "P%d" % (s + 1)
				var m: float  = pmoney if s == slot else 50.0
				_game.on_player_joined(player_slots[s], s, n, m)
		_game.assign_local_player(slot, peer_id)
	elif _game != null and is_instance_valid(_game):
		_game.on_player_joined(peer_id, slot, pname, pmoney)

@rpc("authority", "reliable")
func _rpc_spectate(slots: Array[int]) -> void:
	player_slots = slots
	_ensure_game_exists()
	for s in range(4):
		if player_slots[s] >= 0:
			_game.on_player_joined(player_slots[s], s, "P%d" % (s + 1), 50.0)
	_game.assign_local_player(-1, multiplayer.get_unique_id())

@rpc("any_peer", "reliable")
func _rpc_request_leave() -> void:
	if multiplayer.is_server():
		_handle_leave(multiplayer.get_remote_sender_id())

@rpc("authority", "call_local", "reliable")
func _rpc_player_left(peer_id: int) -> void:
	if _game != null and is_instance_valid(_game):
		_game.on_player_left(peer_id)
	for s in range(4):
		if player_slots[s] == peer_id:
			player_slots[s] = -1
			break

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

@rpc("authority", "call_local", "reliable")
func _rpc_sync_state(data: Dictionary) -> void:
	if _game != null and is_instance_valid(_game):
		_game.apply_state(data)

@rpc("reliable")
func _rpc_deal_hole_cards(card1: int, card2: int) -> void:
	if _game != null and is_instance_valid(_game):
		_game.apply_hole_cards(card1, card2)

@rpc("authority", "call_local", "reliable")
func _rpc_player_action_broadcast(slot: int, action: String, amount: float) -> void:
	pass  # game redraws on next _sync_state; reserved for future action log

@rpc("any_peer", "reliable")
func _rpc_player_action(action: String, amount: float) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	var slot    := _slot_of(peer_id)
	if slot < 0:
		return
	_apply_action(slot, action, amount)

@rpc("authority", "call_local", "reliable")
func _rpc_showdown(winner_slot: int, hands: Dictionary, p: float) -> void:
	if _game != null and is_instance_valid(_game):
		_game.apply_showdown(winner_slot, hands, p)

@rpc("authority", "call_local", "reliable")
func _rpc_round_over(winner_slot: int, p: float, hand_name: String) -> void:
	if _game != null and is_instance_valid(_game):
		_game.apply_round_over(winner_slot, p)
