@tool
class_name PokerGame
extends Node2D

const SMALL_BLIND := 2.0
const BIG_BLIND   := 4.0
const MIN_RAISE   := 4.0

enum Phase {
	WAITING,
	READY_UP,
	BETTING_PREFLOP,
	BETTING_FLOP,
	BETTING_TURN,
	BETTING_RIVER,
	SPECTATING,
	SHOWDOWN,
	ROUND_OVER,
}

const PHASE_NAMES := {
	Phase.WAITING:        "Waiting for players...",
	Phase.READY_UP:       "Ready Up",
	Phase.BETTING_PREFLOP:"Pre-Flop",
	Phase.BETTING_FLOP:   "Flop",
	Phase.BETTING_TURN:   "Turn",
	Phase.BETTING_RIVER:  "River",
	Phase.SPECTATING:     "Spectating",
	Phase.SHOWDOWN:       "Showdown",
	Phase.ROUND_OVER:     "Round Over",
}

const W  := 1280.0
const H  := 720.0
const TW := 700.0
const TH := 420.0
const TX := (W - TW) / 2.0
const TY := (H - TH) / 2.0

var interact_node: Node = null
var local_slot: int = -1

var phase: Phase                = Phase.WAITING
var player_slots: Array[int]    = [-1, -1, -1, -1]
var player_names: Array[String] = ["", "", "", ""]
var money: Array[float]         = [0.0, 0.0, 0.0, 0.0]
var folded: Array[bool]         = [false, false, false, false]
var readiness: Array[bool]      = [false, false, false, false]
var spectating: Array[bool]     = [false, false, false, false]
var hole_cards: Array           = [[], [], [], []]
var community: Array[int]       = []
var pot: float                  = 0.0
var current_bet: float          = 0.0
var player_bets: Array[float]   = [0.0, 0.0, 0.0, 0.0]
var active_slot: int            = -1
var dealer_slot: int            = 0
var winner_slot: int            = -1
var winner_hand: String         = ""
var is_spectator: bool          = false

@onready var _community: CommunityCards = $Cards
@onready var _seat0:     PlayerHand     = $Seat0
@onready var _seat1:     PlayerHand     = $Seat1
@onready var _seat2:     PlayerHand     = $Seat2
@onready var _seat3:     PlayerHand     = $Seat3
@onready var _actions:   ActionButtons  = $ActionButtons
@onready var _pot_label:    Label       = $PotLabel
@onready var _phase_label:  Label       = $PhaseLabel
@onready var _hint_label:   Label       = $HintLabel
@onready var _winner_label: Label       = $WinnerLabel
@onready var _bet_chips0:   ChipStack   = $BetChips0
@onready var _bet_chips1:   ChipStack   = $BetChips1
@onready var _bet_chips2:   ChipStack   = $BetChips2
@onready var _bet_chips3:   ChipStack   = $BetChips3
@onready var _pot_chips:    ChipStack   = $PotChips
@onready var _shuffle_audio: AudioStreamPlayer2D = $ShuffleAudio

func _ready() -> void:
	_actions.action_chosen.connect(_on_action_chosen)
	_actions.deactivate()

func on_player_joined(peer_id: int, slot: int, pname: String, pmoney: float) -> void:
	player_slots[slot] = peer_id
	player_names[slot] = pname
	money[slot]        = pmoney
	if is_node_ready():
		_update_seat(slot)

func on_player_left(peer_id: int) -> void:
	for s in range(4):
		if player_slots[s] == peer_id:
			player_slots[s] = -1
			player_names[s] = ""
			money[s]        = 0.0
			folded[s]       = false
			hole_cards[s]   = []
			player_bets[s]  = 0.0
			if is_node_ready():
				_update_seat(s)
			break

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if interact_node != null:
			interact_node.notify_local_exit(multiplayer.get_unique_id())
		else:
			_self_free()

func _self_free() -> void:
	if get_parent() is CanvasLayer:
		get_parent().queue_free()
	else:
		queue_free()

func apply_state(data: Dictionary) -> void:
	var new_phase: int = data.get("phase", Phase.WAITING)
	if new_phase == Phase.WAITING or (new_phase == Phase.BETTING_PREFLOP and phase != Phase.BETTING_PREFLOP):
		hole_cards = [[], [], [], []]
	phase = new_phase
	if local_slot >= 0:
		var spec_arr: Array = data.get("spectators", [false, false, false, false])
		is_spectator = spec_arr[local_slot] if local_slot < spec_arr.size() else false
	pot = data.get("pot", 0.0)
	current_bet = data.get("current_bet", 0.0)
	player_bets = data.get("player_bets", [0.0, 0.0, 0.0, 0.0])
	active_slot = data.get("active_slot", -1)
	dealer_slot = data.get("dealer_slot", 0)
	community = data.get("community", [])
	folded = data.get("folded", [false, false, false, false])
	readiness = data.get("readiness", [false, false, false, false])
	money = data.get("money", money)
	if not is_node_ready():
		return
	_community.set_cards(community)
	for s in range(4):
		_update_seat(s)
	_pot_label.text   = ("Pot: %.0f" % pot) if (pot > 0.0 or phase != Phase.WAITING) else ""
	_phase_label.text = PHASE_NAMES.get(phase, "")
	if new_phase not in [Phase.SHOWDOWN, Phase.ROUND_OVER]:
		_winner_label.text = ""
	_update_pot_chips()
	if phase == Phase.WAITING:
		_hint_label.text = "Waiting for at least 2 players   Esc: leave"
	elif phase == Phase.READY_UP:
		var all_ready := true
		for s in range(4):
			if player_slots[s] >= 0 and not readiness[s]:
				all_ready = false
		if all_ready:
			_hint_label.text = "All ready! Starting soon...   Esc: leave"
		elif active_slot == local_slot:
			_hint_label.text = "Ready up to start!   Esc: leave"
		else:
			_hint_label.text = "Waiting for players to ready...   Esc: leave"
	elif phase == Phase.SPECTATING:
		_hint_label.text = "Spectating... waiting for next round   Esc: leave"
	elif active_slot == local_slot:
		_hint_label.text = "Your turn   Esc: leave"
	else:
		_hint_label.text = "Waiting for other player   Esc: leave"
	var is_betting: bool = phase in [
		Phase.BETTING_PREFLOP, Phase.BETTING_FLOP,
		Phase.BETTING_TURN,    Phase.BETTING_RIVER
	]
	if phase == Phase.READY_UP and local_slot >= 0 and player_slots[local_slot] >= 0 and not readiness[local_slot]:
		_actions.update_ready_state(not readiness[local_slot])
	elif local_slot >= 0 and active_slot == local_slot and is_betting \
			and not folded[local_slot] and money[local_slot] > 0.0:
		_actions.update_state(player_bets[local_slot], current_bet, money[local_slot])
	else:
		_actions.deactivate()

func apply_hole_cards(card1: int, card2: int) -> void:
	if local_slot >= 0:
		hole_cards[local_slot] = [card1, card2]
		if is_node_ready():
			await _get_seat(local_slot).set_cards_sequential(card1, card2, true)
			if not is_instance_valid(self):
				return

func apply_ready_state(data: Dictionary) -> void:
	readiness = data.get("readiness", [false, false, false, false])
	phase = data.get("phase", Phase.READY_UP)
	if local_slot >= 0:
		var spec_arr: Array = data.get("spectators", [false, false, false, false])
		is_spectator = spec_arr[local_slot] if local_slot < spec_arr.size() else false
	if not is_node_ready():
		return
	for s in range(4):
		_update_seat(s)
	_phase_label.text = PHASE_NAMES.get(phase, "")
	if phase == Phase.READY_UP and local_slot >= 0 and player_slots[local_slot] >= 0 and not readiness[local_slot]:
		_actions.update_ready_state(true)
	else:
		_actions.deactivate()
	var all_ready2 := true
	for s in range(4):
		if player_slots[s] >= 0 and not readiness[s]:
			all_ready2 = false
	if all_ready2:
		_hint_label.text = "All ready! Starting soon...   Esc: leave"
	elif is_spectator:
		_hint_label.text = "Spectating... waiting for next round   Esc: leave"
	else:
		_hint_label.text = "Waiting for players to ready...   Esc: leave"

func apply_showdown(w_slot: int, hands: Dictionary, p: float) -> void:
	winner_slot = w_slot
	var winner_data: Dictionary = hands.get(str(w_slot), {})
	winner_hand = winner_data.get("name", "")
	pot   = p
	phase = Phase.SHOWDOWN
	for s in hands:
		var hand_data: Dictionary = hands[s]
		hole_cards[int(s)] = hand_data.get("cards", [])
	if not is_node_ready():
		return
	if winner_slot < 0:
		return
	for s in range(4):
		_update_seat(s)
	var pname: String = player_names[winner_slot] if player_names[winner_slot] != "" \
		else "P%d" % (winner_slot + 1)
	_winner_label.text = "%s wins %.0f  (%s)" % [pname, pot, winner_hand]
	_hint_label.text   = "Esc: leave"
	_actions.deactivate()
	_pot_chips.set_amount(pot)

func apply_round_over(w_slot: int, p: float, hand: String = "") -> void:
	winner_slot = w_slot
	winner_hand = hand
	pot         = p
	phase       = Phase.ROUND_OVER
	if not is_node_ready():
		return
	if winner_slot < 0:
		return
	var pname: String = player_names[winner_slot] if player_names[winner_slot] != "" \
		else "P%d" % (winner_slot + 1)
	var txt: String = "%s wins %.0f" % [pname, pot]
	if winner_hand != "":
		txt += "  (%s)" % winner_hand
	_winner_label.text = txt
	_hint_label.text   = "Esc: leave"
	_actions.deactivate()
	_pot_chips.set_amount(pot)

func apply_snapshot(data: Dictionary) -> void:
	phase = data.get("phase", Phase.WAITING)
	player_slots.assign(data.get("player_slots", [-1, -1, -1, -1]))
	player_names.assign(data.get("player_names", ["", "", "", ""]))
	money.assign(data.get("money", [0.0, 0.0, 0.0, 0.0]))
	folded.assign(data.get("folded", [false, false, false, false]))
	readiness.assign(data.get("readiness", [false, false, false, false]))
	community = data.get("community", [])
	pot = data.get("pot", 0.0)
	current_bet = data.get("current_bet", 0.0)
	player_bets.assign(data.get("player_bets", [0.0, 0.0, 0.0, 0.0]))
	active_slot = data.get("active_slot", -1)
	dealer_slot = data.get("dealer_slot", 0)
	winner_slot = data.get("winner_slot", -1)
	winner_hand = data.get("winner_hand", "")
	if local_slot >= 0:
		var spec_arr: Array = data.get("spectators", [false, false, false, false])
		is_spectator = spec_arr[local_slot] if local_slot < spec_arr.size() else false
	if not is_node_ready():
		return
	_community.set_cards(community)
	for s in range(4):
		_update_seat(s)
	_phase_label.text = PHASE_NAMES.get(phase, "")
	_pot_label.text   = ("Pot: %.0f" % pot) if pot > 0.0 else ""
	_update_pot_chips()
	_winner_label.text = ""
	var is_betting := phase in [
		Phase.BETTING_PREFLOP, Phase.BETTING_FLOP, Phase.BETTING_TURN, Phase.BETTING_RIVER
	]
	if phase == Phase.READY_UP and local_slot >= 0 and player_slots[local_slot] >= 0 and not readiness[local_slot]:
		_hint_label.text = "Ready up to start!   Esc: leave"
		_actions.update_ready_state(true)
	elif local_slot >= 0 and active_slot == local_slot and is_betting \
			and not folded[local_slot] and money[local_slot] > 0.0:
		_hint_label.text = "Your turn   Esc: leave"
		_actions.update_state(player_bets[local_slot], current_bet, money[local_slot])
	elif is_spectator:
		_hint_label.text = "Spectating... waiting for next round   Esc: leave"
		_actions.deactivate()
	elif phase == Phase.WAITING:
		_hint_label.text = "Waiting for at least 2 players   Esc: leave"
		_actions.deactivate()
	else:
		_hint_label.text = "Waiting for other player   Esc: leave"
		_actions.deactivate()

func _on_action_chosen(action: String, amount: float) -> void:
	if interact_node == null:
		return
	if action == "ready":
		if multiplayer.is_server():
			interact_node.local_player_action(local_slot, action, amount)
		else:
			interact_node.remote_player_action.rpc_id(1, action, amount)
		return
	if multiplayer.is_server():
		interact_node.local_player_action(local_slot, action, amount)
	else:
		interact_node.remote_player_action.rpc_id(1, action, amount)

func _update_seat(s: int) -> void:
	var seat: PlayerHand = _get_seat(s)
	if seat == null:
		return
	var cs := _get_bet_chips(s)
	if player_slots[s] < 0:
		seat.clear()
		if cs != null:
			cs.set_amount(0.0)
		return
	var pname: String = player_names[s] if player_names[s] != "" else "P%d" % (s + 1)
	var is_ready: bool = readiness[s]
	seat.update_state(pname, money[s], player_bets[s], folded[s], active_slot == s, dealer_slot == s, is_ready)
	var cards: Array = hole_cards[s]
	if folded[s]:
		seat.clear_cards()
	elif cards.size() >= 2:
		var show: bool = (s == local_slot) or (phase == Phase.SHOWDOWN)
		seat.set_cards(cards[0], cards[1], show)
	else:
		seat.clear_cards()
	if cs != null:
		cs.set_amount(player_bets[s])

func _get_seat(s: int) -> PlayerHand:
	match s:
		0: return _seat0
		1: return _seat1
		2: return _seat2
		3: return _seat3
	return null

func _update_pot_chips() -> void:
	for b in player_bets:
		if b > 0.0:
			return
	_pot_chips.set_amount(pot)

func _get_bet_chips(s: int) -> ChipStack:
	match s:
		0: return _bet_chips0
		1: return _bet_chips1
		2: return _bet_chips2
		3: return _bet_chips3
	return null

func play_shuffle_sound() -> void:
	if _shuffle_audio != null:
		_shuffle_audio.play()
