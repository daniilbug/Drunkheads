class_name PokerGame
extends Node2D

# ── constants ──────────────────────────────────────────────────────────────

const SMALL_BLIND := 2.0
const BIG_BLIND   := 4.0
const MIN_RAISE   := 4.0

enum Phase {
	WAITING,
	BETTING_PREFLOP,
	BETTING_FLOP,
	BETTING_TURN,
	BETTING_RIVER,
	SHOWDOWN,
	ROUND_OVER,
}

const PHASE_NAMES := {
	Phase.WAITING:        "Waiting for players...",
	Phase.BETTING_PREFLOP:"Pre-Flop",
	Phase.BETTING_FLOP:   "Flop",
	Phase.BETTING_TURN:   "Turn",
	Phase.BETTING_RIVER:  "River",
	Phase.SHOWDOWN:       "Showdown",
	Phase.ROUND_OVER:     "Round Over",
}

@export_group("Colors")
@export var color_overlay: Color     = Color(0, 0, 0, 0.78)
@export var color_felt: Color        = Color("1a5c2a")
@export var color_felt_edge: Color   = Color("0f3a1a")
@export var color_hud_bg: Color      = Color(0.1, 0.06, 0.02, 0.88)
@export var color_hud_text: Color    = Color("f0d8a0")
@export var color_card_bg: Color     = Color.WHITE
@export var color_card_border: Color = Color(0.3, 0.3, 0.3)
@export var color_red_suit: Color    = Color("cc1111")
@export var color_black_suit: Color  = Color(0.08, 0.08, 0.08)
@export var color_btn_normal: Color  = Color(0.22, 0.16, 0.08)
@export var color_btn_hover: Color   = Color(0.35, 0.25, 0.10)
@export var color_btn_text: Color    = Color("f0d8a0")
@export var color_active_seat: Color = Color("f0d060")
@export var color_folded: Color      = Color(0.4, 0.4, 0.4)
@export var color_pot: Color         = Color("ffd700")

# ── layout constants ───────────────────────────────────────────────────────

const W  := 1280.0
const H  := 720.0
const TW := 700.0   # table width
const TH := 420.0   # table height
const TX := (W - TW) / 2.0
const TY := (H - TH) / 2.0

const CARD_W := 52.0
const CARD_H := 74.0

# Seat positions (absolute screen coords), 4 seats
const SEAT_POS := [
	Vector2(TX + 60,  TY + TH - 100),   # slot 0 – bottom-left
	Vector2(TX + TW - 60, TY + TH - 100),# slot 1 – bottom-right
	Vector2(TX + 60,  TY + 100),         # slot 2 – top-left
	Vector2(TX + TW - 60, TY + 100),     # slot 3 – top-right
]

# ── public state (set by interact node) ───────────────────────────────────

var interact_node: Node = null
var local_slot: int = -1

# ── game state (synced from server) ───────────────────────────────────────

var phase: Phase = Phase.WAITING
var player_slots: Array[int]  = [-1, -1, -1, -1]   # peer_id per seat
var player_names: Array[String] = ["", "", "", ""]
var money: Array[float]       = [0.0, 0.0, 0.0, 0.0]
var folded: Array[bool]       = [false, false, false, false]
var hole_cards: Array         = [[], [], [], []]     # only own slot filled on clients
var community: Array[int]     = []
var pot: float                = 0.0
var current_bet: float        = 0.0
var player_bets: Array[float] = [0.0, 0.0, 0.0, 0.0]
var active_slot: int          = -1
var dealer_slot: int          = 0
var winner_slot: int          = -1
var winner_hand: String       = ""
var round_over_timer: float   = 0.0

# ── raise input state ──────────────────────────────────────────────────────

var _raise_amount: float      = 0.0
var _raise_mode: bool         = false

# ── misc ───────────────────────────────────────────────────────────────────

var _font: Font
var _font_bold: Font

const RANK_NAMES := ["2","3","4","5","6","7","8","9","10","J","Q","K","A"]
const SUIT_SYMS  := ["♠","♥","♦","♣"]

# ── lifecycle ──────────────────────────────────────────────────────────────

func _ready() -> void:
	_font      = ThemeDB.fallback_font
	_font_bold = ThemeDB.fallback_font

func assign_local_player(slot: int, _peer_id: int) -> void:
	local_slot = slot
	visible    = true

func on_player_joined(peer_id: int, slot: int, pname: String, pmoney: float) -> void:
	player_slots[slot]  = peer_id
	player_names[slot]  = pname
	money[slot]         = pmoney

func on_player_left(peer_id: int) -> void:
	for s in range(4):
		if player_slots[s] == peer_id:
			player_slots[s]  = -1
			player_names[s]  = ""
			money[s]         = 0.0
			folded[s]        = false
			hole_cards[s]    = []
			player_bets[s]   = 0.0
			break

# ── input ──────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if interact_node != null:
			interact_node.notify_local_exit(multiplayer.get_unique_id())
		else:
			_self_free()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_handle_click(mb.position)

func _self_free() -> void:
	if get_parent() is CanvasLayer:
		get_parent().queue_free()
	else:
		queue_free()

# ── process ────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return

	if phase == Phase.ROUND_OVER:
		round_over_timer = maxf(0.0, round_over_timer - delta)

	queue_redraw()

func _handle_click(mp: Vector2) -> void:
	if local_slot < 0 or active_slot != local_slot:
		return
	if phase not in [Phase.BETTING_PREFLOP, Phase.BETTING_FLOP, Phase.BETTING_TURN, Phase.BETTING_RIVER]:
		return
	var btns := _get_action_buttons()
	for btn in btns:
		if btn.rect.has_point(mp):
			_on_button_pressed(btn.action, btn.amount)
			return

func _on_button_pressed(action: String, amount: float) -> void:
	if action == "raise_toggle":
		_raise_mode = not _raise_mode
		_raise_amount = current_bet + MIN_RAISE
		return
	if action == "raise_up":
		_raise_amount = minf(_raise_amount + MIN_RAISE, money[local_slot] + player_bets[local_slot])
		return
	if action == "raise_down":
		_raise_amount = maxf(_raise_amount - MIN_RAISE, current_bet + MIN_RAISE)
		return
	if interact_node != null:
		if multiplayer.is_server():
			interact_node.server_player_action(local_slot, action, amount)
		else:
			interact_node._rpc_player_action.rpc_id(1, action, amount)
	_raise_mode = false

# ── apply (called by interact node via RPC) ────────────────────────────────

func apply_state(data: Dictionary) -> void:
	var new_phase: int = data.get("phase", Phase.WAITING)
	if new_phase == Phase.BETTING_PREFLOP and phase != Phase.BETTING_PREFLOP:
		hole_cards = [[], [], [], []]
	phase        = new_phase
	pot          = data.get("pot", 0.0)
	current_bet  = data.get("current_bet", 0.0)
	player_bets  = data.get("player_bets", [0.0, 0.0, 0.0, 0.0])
	active_slot  = data.get("active_slot", -1)
	dealer_slot  = data.get("dealer_slot", 0)
	community    = data.get("community", [])
	folded       = data.get("folded", [false, false, false, false])
	money        = data.get("money", money)
	queue_redraw()

func apply_hole_cards(card1: int, card2: int) -> void:
	if local_slot >= 0:
		hole_cards[local_slot] = [card1, card2]
	queue_redraw()

func apply_showdown(w_slot: int, hands: Dictionary, p: float) -> void:
	winner_slot = w_slot
	var winner_data: Dictionary = hands.get(str(w_slot), {})
	winner_hand = winner_data.get("name", "")
	pot         = p
	phase       = Phase.SHOWDOWN
	for s in hands:
		var hand_data: Dictionary = hands[s]
		hole_cards[int(s)] = hand_data.get("cards", [])
	queue_redraw()

func apply_round_over(w_slot: int, p: float) -> void:
	winner_slot      = w_slot
	pot              = p
	phase            = Phase.ROUND_OVER
	round_over_timer = 3.5
	queue_redraw()

func apply_snapshot(data: Dictionary) -> void:
	phase        = data.get("phase", Phase.WAITING)
	player_slots = data.get("player_slots", [-1, -1, -1, -1])
	player_names = data.get("player_names", ["", "", "", ""])
	money        = data.get("money", [0.0, 0.0, 0.0, 0.0])
	folded       = data.get("folded", [false, false, false, false])
	community    = data.get("community", [])
	pot          = data.get("pot", 0.0)
	current_bet  = data.get("current_bet", 0.0)
	player_bets  = data.get("player_bets", [0.0, 0.0, 0.0, 0.0])
	active_slot  = data.get("active_slot", -1)
	dealer_slot  = data.get("dealer_slot", 0)
	winner_slot  = data.get("winner_slot", -1)
	winner_hand  = data.get("winner_hand", "")
	queue_redraw()

func build_snapshot() -> Dictionary:
	return {
		"phase":        phase,
		"player_slots": player_slots.duplicate(),
		"player_names": player_names.duplicate(),
		"money":        money.duplicate(),
		"folded":       folded.duplicate(),
		"community":    community.duplicate(),
		"pot":          pot,
		"current_bet":  current_bet,
		"player_bets":  player_bets.duplicate(),
		"active_slot":  active_slot,
		"dealer_slot":  dealer_slot,
		"winner_slot":  winner_slot,
		"winner_hand":  winner_hand,
	}

# ── drawing ────────────────────────────────────────────────────────────────

func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), color_overlay)
	_draw_table()
	_draw_community_cards()
	_draw_pot()
	_draw_seats()
	_draw_hole_cards()
	_draw_phase_label()
	_draw_action_buttons()
	_draw_winner_overlay()
	_draw_hint()

func _draw_table() -> void:
	draw_rect(Rect2(TX - 6, TY - 6, TW + 12, TH + 12), color_felt_edge, true, 0.0)
	draw_rect(Rect2(TX, TY, TW, TH), color_felt, true, 0.0)

func _draw_community_cards() -> void:
	var n   := community.size()
	var cw  := CARD_W
	var gap := 8.0
	var total_w := n * cw + (n - 1) * gap
	var cx  := W * 0.5 - total_w * 0.5
	var cy  := H * 0.5 - CARD_H * 0.5
	for i in range(n):
		_draw_card(Vector2(cx + i * (cw + gap), cy), community[i])

func _draw_pot() -> void:
	if pot <= 0.0 and phase == Phase.WAITING:
		return
	var txt := "Pot: $%.0f" % pot
	var pos := Vector2(W * 0.5, H * 0.5 - CARD_H * 0.5 - 24.0)
	draw_string(_font, pos, txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, color_pot)

func _draw_seats() -> void:
	for s in range(4):
		if player_slots[s] < 0:
			continue
		var sp: Vector2 = SEAT_POS[s]
		var col  := color_active_seat if s == active_slot else color_hud_text
		if folded[s]:
			col = color_folded
		var name_str := player_names[s] if player_names[s] != "" else "P%d" % (s + 1)
		var bet_str  := "$%.0f" % player_bets[s] if player_bets[s] > 0 else ""
		var chips    := "$%.0f" % money[s]
		var dealer_m := " (D)" if s == dealer_slot else ""
		var fold_m   := " [folded]" if folded[s] else ""
		draw_string(_font, sp + Vector2(-60, -24), name_str + dealer_m + fold_m,
			HORIZONTAL_ALIGNMENT_LEFT, 120, 13, col)
		draw_string(_font, sp + Vector2(-60, -8), chips,
			HORIZONTAL_ALIGNMENT_LEFT, 120, 12, color_hud_text)
		if bet_str != "":
			draw_string(_font, sp + Vector2(-60, 6), "Bet: " + bet_str,
				HORIZONTAL_ALIGNMENT_LEFT, 120, 12, color_pot)

func _draw_hole_cards() -> void:
	for s in range(4):
		if player_slots[s] < 0 or folded[s]:
			continue
		var cards: Array = hole_cards[s]
		var sp: Vector2 = SEAT_POS[s]
		var ox    := -CARD_W - 4.0
		var oy    := 14.0
		for i in range(2):
			var pos := sp + Vector2(ox + i * (CARD_W + 4.0), oy)
			if cards.size() > i:
				_draw_card(pos, cards[i])
			else:
				_draw_card_back(pos)

func _draw_phase_label() -> void:
	var txt: String = PHASE_NAMES.get(phase, "")
	draw_string(_font, Vector2(W * 0.5, TY - 12.0), txt,
		HORIZONTAL_ALIGNMENT_CENTER, -1, 14, color_hud_text)

func _draw_action_buttons() -> void:
	if local_slot < 0 or active_slot != local_slot:
		return
	if phase not in [Phase.BETTING_PREFLOP, Phase.BETTING_FLOP, Phase.BETTING_TURN, Phase.BETTING_RIVER]:
		return
	var mp   := get_viewport().get_mouse_position()
	var btns := _get_action_buttons()
	for btn in btns:
		var hover: bool = btn.rect.has_point(mp)
		draw_rect(btn.rect, color_btn_hover if hover else color_btn_normal, true, 0.0)
		draw_rect(btn.rect, color_hud_text, false, 1.0)
		draw_string(_font, btn.rect.position + Vector2(6, 16),
			btn.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color_btn_text)
	if _raise_mode:
		draw_string(_font, Vector2(W * 0.5, TY + TH + 54.0),
			"Raise to: $%.0f" % _raise_amount,
			HORIZONTAL_ALIGNMENT_CENTER, -1, 14, color_pot)

func _draw_winner_overlay() -> void:
	if phase == Phase.SHOWDOWN and winner_slot >= 0:
		var pname := player_names[winner_slot] if player_names[winner_slot] != "" else "P%d" % (winner_slot + 1)
		var txt   := "%s wins $%.0f  (%s)" % [pname, pot, winner_hand]
		draw_string(_font, Vector2(W * 0.5, H * 0.5 + CARD_H * 0.5 + 32.0),
			txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, color_pot)
	elif phase == Phase.ROUND_OVER and winner_slot >= 0:
		var pname := player_names[winner_slot] if player_names[winner_slot] != "" else "P%d" % (winner_slot + 1)
		var txt   := "%s wins $%.0f" % [pname, pot]
		if winner_hand != "":
			txt += "  (%s)" % winner_hand
		draw_string(_font, Vector2(W * 0.5, H * 0.5 + CARD_H * 0.5 + 32.0),
			txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, color_pot)

func _draw_hint() -> void:
	var txt: String
	if phase == Phase.WAITING:
		txt = "Waiting for at least 2 players   Esc: leave"
	elif active_slot == local_slot:
		txt = "Click an action button   Esc: leave"
	else:
		txt = "Waiting for other player   Esc: leave"
	draw_string(_font, Vector2(W * 0.5, TY + TH + 22.0),
		txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, color_hud_text)

# ── button layout helpers ──────────────────────────────────────────────────

class BtnDef:
	var rect:   Rect2
	var label:  String
	var action: String
	var amount: float
	func _init(r: Rect2, lbl: String, act: String, amt: float = 0.0) -> void:
		rect = r; label = lbl; action = act; amount = amt

func _get_action_buttons() -> Array:
	var btns   := []
	var by     := TY + TH + 30.0
	var bh     := 28.0
	var bw     := 90.0
	var gap    := 8.0
	var can_check := is_equal_approx(player_bets[local_slot], current_bet)
	var to_call   := current_bet - player_bets[local_slot]
	var can_raise := money[local_slot] > to_call + MIN_RAISE

	var items := []
	if can_check:
		items.append(["Check", "check", 0.0])
	else:
		items.append(["Call $%.0f" % to_call, "call", to_call])
	if can_raise:
		items.append(["Raise", "raise_toggle", 0.0])
		if _raise_mode:
			items.append(["▲", "raise_up", 0.0])
			items.append(["▼", "raise_down", 0.0])
			items.append(["Bet $%.0f" % _raise_amount, "raise", _raise_amount])
	items.append(["Fold", "fold", 0.0])

	var total_w := items.size() * bw + (items.size() - 1) * gap
	var bx      := W * 0.5 - total_w * 0.5
	for it in items:
		btns.append(BtnDef.new(Rect2(bx, by, bw, bh), it[0], it[1], it[2]))
		bx += bw + gap
	return btns

# ── card drawing ───────────────────────────────────────────────────────────

func _draw_card(pos: Vector2, card: int) -> void:
	var r    := card / 4
	var s    := card % 4
	var col  := color_red_suit if s == 1 or s == 2 else color_black_suit
	draw_rect(Rect2(pos, Vector2(CARD_W, CARD_H)), color_card_bg, true, 0.0)
	draw_rect(Rect2(pos, Vector2(CARD_W, CARD_H)), color_card_border, false, 1.0)
	var rname: String = RANK_NAMES[r]
	var ssym:  String = SUIT_SYMS[s]
	draw_string(_font, pos + Vector2(4, 14),  rname, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
	draw_string(_font, pos + Vector2(4, 28),  ssym,  HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
	draw_string(_font, pos + Vector2(CARD_W - 18, CARD_H - 4), rname,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)

func _draw_card_back(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(CARD_W, CARD_H)), Color("1a3d7c"), true, 0.0)
	draw_rect(Rect2(pos, Vector2(CARD_W, CARD_H)), color_card_border, false, 1.0)
	draw_string(_font, pos + Vector2(8, CARD_H * 0.5 + 6), "?",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
