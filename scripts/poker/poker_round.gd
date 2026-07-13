class_name PokerRound

var phase:       PokerGame.Phase = PokerGame.Phase.WAITING
var deck:        Array[int]      = []
var hole_cards:  Array           = [[], [], [], []]
var community:   Array[int]      = []
var dealer_slot: int             = 0
var _resolving:  bool            = false
var _advancing:  bool            = false

var _i: PokerSession
var _b: PokerBetting

func _init(interact, betting: PokerBetting) -> void:
	_i = interact as PokerSession
	_b = betting

func try_start() -> void:
	if phase != PokerGame.Phase.WAITING:
		return
	if _i.active_non_spectator_count() < 2:
		return
	_i._enter_ready_phase()

func start() -> void:
	_resolving = false
	_advancing = false
	deck.clear()
	for n in 52:
		deck.append(n)
	deck.shuffle()
	community  = []
	hole_cards = [[], [], [], []]

	# chips persist in _i.money[slot] from buy-in — do not overwrite from player_data
	_b.reset()
	dealer_slot    = _i.next_active_seat(dealer_slot)
	var sb_slot: int
	var bb_slot: int
	if _i.active_seat_count() == 2:
		sb_slot = dealer_slot                          # heads-up: dealer = SB
		bb_slot = _i.next_active_seat(dealer_slot)
	else:
		sb_slot = _i.next_active_seat(dealer_slot)
		bb_slot = _i.next_active_seat(sb_slot)
	_b.post_blind(sb_slot, PokerBetting.SMALL_BLIND)
	_b.post_blind(bb_slot, PokerBetting.BIG_BLIND)

	phase          = PokerGame.Phase.BETTING_PREFLOP
	_b.active_slot = _i.next_active_unfold_seat(bb_slot)
	_i.sync_state()

	for slot in range(4):
		if _i.player_slots[slot] < 0:
			continue
		var c1: int = deck.pop_back()
		var c2: int = deck.pop_back()
		hole_cards[slot] = [c1, c2]
		var target := _i.player_slots[slot]
		if target == _i.multiplayer.get_unique_id():
			if _i.game != null and is_instance_valid(_i.game):
				_i.game.apply_hole_cards(c1, c2)
		else:
			_i.remote_deal_hole_cards.rpc_id(target, c1, c2)

	await _i.get_tree().create_timer(1.5).timeout
	if _i.game != null and is_instance_valid(_i.game):
		_i.game.play_shuffle_sound()

func advance_phase() -> void:
	if _advancing:
		return
	_advancing = true
	_b.reset_for_phase()
	match phase:
		PokerGame.Phase.BETTING_PREFLOP:
			phase          = PokerGame.Phase.BETTING_FLOP
			_b.active_slot = -1
			for i in range(3):
				community.append(deck.pop_back())
				_i.sync_state()
				if i < 2:
					await _i.get_tree().create_timer(1.5).timeout
					if phase != PokerGame.Phase.BETTING_FLOP:
						_advancing = false
						return
		PokerGame.Phase.BETTING_FLOP:
			_deal_community(1)
			phase = PokerGame.Phase.BETTING_TURN
		PokerGame.Phase.BETTING_TURN:
			_deal_community(1)
			phase = PokerGame.Phase.BETTING_RIVER
		PokerGame.Phase.BETTING_RIVER:
			resolve()   # _advancing stays true; reset_to_waiting() clears it
			return
	var active_phases := [PokerGame.Phase.BETTING_FLOP, PokerGame.Phase.BETTING_TURN, PokerGame.Phase.BETTING_RIVER]
	if phase not in active_phases:
		_advancing = false
		return
	_b.active_slot = _i.next_active_unfold_seat(dealer_slot)
	_i.sync_state()
	_advancing = false
	if _b.is_round_complete():
		await _i.get_tree().create_timer(2.0).timeout
		advance_phase()

func _deal_community(count: int) -> void:
	for _c in range(count):
		community.append(deck.pop_back())

func _award_pot(slot: int) -> float:
	var won := _b.pot
	_i.money[slot] += won
	_b.pot        = 0.0
	_b.player_bets = [0.0, 0.0, 0.0, 0.0]
	return won

func _split_pot(slots: Array) -> float:
	var total  := _b.pot
	var share  := floorf(total / slots.size())
	var odd    := total - share * slots.size()
	for s in slots:
		_i.money[s] += share
	if odd > 0.0:
		_i.money[slots[0]] += odd   # odd chip to first winner
	_b.pot        = 0.0
	_b.player_bets = [0.0, 0.0, 0.0, 0.0]
	return total   # return full pot for display ("X wins Y (Split)")

func resolve() -> void:
	if _resolving:
		return
	_resolving = true
	var active := _i.active_seats_not_folded()
	if active.size() == 0:
		phase = PokerGame.Phase.ROUND_OVER
		reset_to_waiting()
		return
	if active.size() == 1:
		var ws:  int   = active[0]
		var won: float = _award_pot(ws)
		_i.remote_round_over.rpc(ws, won, "")
		phase = PokerGame.Phase.ROUND_OVER
		_i.sync_state()
		await _i.get_tree().create_timer(3.5).timeout
		reset_to_waiting()
		return

	var all_cards  := community.duplicate()
	var best_slot  := -1
	var best_hand  := {}
	var hands_dict := {}
	for s in active:
		var my_cards: Array = hole_cards[s].duplicate()
		my_cards.append_array(all_cards)
		var h := PokerHandEvaluator.best_hand(my_cards)
		h["cards"] = hole_cards[s].duplicate()
		hands_dict[str(s)] = h
		if best_slot < 0 or PokerHandEvaluator.compare_hands(h, best_hand) > 0:
			best_slot = s
			best_hand = h

	var winners: Array = []
	for s in active:
		if PokerHandEvaluator.compare_hands(hands_dict[str(s)], best_hand) == 0:
			winners.append(s)
	var won: float = _award_pot(best_slot) if winners.size() == 1 else _split_pot(winners)

	_i.remote_showdown.rpc(best_slot, hands_dict, won)
	phase = PokerGame.Phase.SHOWDOWN
	_i.sync_state()
	await _i.get_tree().create_timer(4.0).timeout
	var hand_name: String
	if winners.size() == 1:
		hand_name = best_hand.get("name", "")
	else:
		var names := winners.map(func(s): return "P%d" % (s + 1))
		hand_name  = "Split: " + ", ".join(names)
	_i.remote_round_over.rpc(best_slot, won, hand_name)
	phase = PokerGame.Phase.ROUND_OVER
	_i.sync_state()
	await _i.get_tree().create_timer(3.5).timeout
	reset_to_waiting()

func reset_to_waiting() -> void:
	if phase != PokerGame.Phase.ROUND_OVER:
		return
	_resolving     = false
	_advancing     = false
	_b.active_slot = -1
	_b.pot         = 0.0
	_b.current_bet = 0.0
	if _i.active_seat_count() >= 2:
		_i._enter_ready_phase()
	elif _i.active_seat_count() >= 1:
		phase = PokerGame.Phase.WAITING
		_i.sync_state()
		try_start()
	else:
		phase = PokerGame.Phase.WAITING
		_i.sync_state()
