class_name PokerBetting

const SMALL_BLIND := 2.0
const BIG_BLIND   := 4.0
const MIN_RAISE   := 4.0

var pot:         float        = 0.0
var current_bet: float        = 0.0
var player_bets: Array[float] = [0.0, 0.0, 0.0, 0.0]
var active_slot: int          = -1
var round_trip:  int          = 0
var folded:      Array[bool]  = [false, false, false, false]

var _i: PokerSession

func _init(interact) -> void:
	_i = interact as PokerSession

func reset() -> void:
	pot         = 0.0
	current_bet = BIG_BLIND
	player_bets = [0.0, 0.0, 0.0, 0.0]
	folded      = [false, false, false, false]
	round_trip  = 0

func reset_for_phase() -> void:
	round_trip  = 0
	current_bet = 0.0
	for s in range(4):
		player_bets[s] = 0.0

func post_blind(slot: int, amount: float) -> void:
	var actual := minf(amount, _i.money[slot])
	_i.money[slot]   -= actual
	player_bets[slot] += actual
	pot               += actual

func apply_action(slot: int, action: String, amount: float) -> bool:
	if slot != active_slot or folded[slot]:
		return false
	match action:
		"check":
			if not is_equal_approx(player_bets[slot], current_bet):
				return false
			round_trip += 1
		"call":
			var to_call := minf(current_bet - player_bets[slot], _i.money[slot])
			_i.money[slot]   -= to_call
			player_bets[slot] += to_call
			pot               += to_call
			round_trip += 1
		"raise":
			var to_call   := minf(current_bet - player_bets[slot], _i.money[slot])
			var remaining := _i.money[slot] - to_call
			if remaining <= 0.0:
				return false
			var raise_amt := clampf(amount - current_bet, minf(MIN_RAISE, remaining), remaining)
			var total     := to_call + raise_amt
			_i.money[slot]   -= total
			player_bets[slot] += total
			current_bet        = player_bets[slot]
			pot               += total
			if raise_amt >= MIN_RAISE:
				round_trip = 1
			else:
				round_trip += 1
		"fold":
			folded[slot] = true
		_:
			return false
	return true

func advance_turn() -> void:
	active_slot = _i.next_active_unfold_seat(active_slot)

func is_only_one_left() -> bool:
	return _i.active_seats_not_folded().size() <= 1

func is_round_complete() -> bool:
	var active := _i.active_seats_not_folded()
	if active.size() < 2:
		return true
	var can_act := 0
	for s in active:
		if not is_equal_approx(player_bets[s], current_bet):
			if _i.money[s] > 0.0:
				return false
		if _i.money[s] > 0.0:
			can_act += 1
	return round_trip >= can_act
