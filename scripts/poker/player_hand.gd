@tool
class_name PlayerHand
extends Node2D

@export var seat_slot: int = 0

@export_group("Colors")
@export var color_active: Color = Color("f0d060")
@export var color_normal: Color = Color("f0d8a0")
@export var color_folded: Color = Color(0.4, 0.4, 0.4)
@export var color_bet:    Color = Color("ffd700")

@onready var _chips_label: Label     = $ChipsLabel
@onready var _bet_label:   Label     = $BetLabel
@onready var _card1:       Card      = $Card1
@onready var _card2:       Card      = $Card2
@onready var _dealer_chip: Sprite2D  = $DealerChip
@onready var _chips_stack: ChipStack = $ChipsStack

func _ready() -> void:
	clear()

func update_state(pname: String, chips: float, bet: float,
		folded: bool, active: bool, dealer: bool, is_ready: bool = false) -> void:
	visible = true
	var col: Color = color_folded if folded else (color_active if active else color_normal)
	var ready_mark := " [✓]" if is_ready else ""
	_chips_label.text = pname + "  %.0f" % chips + (" [folded]" if folded else ready_mark)
	_chips_label.add_theme_color_override("font_color", col)
	_chips_stack.set_amount(chips)
	_bet_label.text = ("Bet: %.0f" % bet) if bet > 0.0 else ""
	_bet_label.add_theme_color_override("font_color", color_bet)
	_dealer_chip.visible = dealer

func set_cards(c1: int, c2: int, show_face_up: bool) -> void:
	_card1.visible = true
	_card2.visible = true
	_card1.set_card(c1, show_face_up)
	_card2.set_card(c2, show_face_up)

func set_cards_sequential(c1: int, c2: int, show_face_up: bool) -> void:
	_card1.visible = true
	_card2.visible = true
	_card1.set_card(c1, show_face_up)
	await get_tree().create_timer(1.0).timeout
	_card2.set_card(c2, show_face_up)

func clear_cards() -> void:
	_card1.set_card(-1, false)
	_card2.set_card(-1, false)

func clear() -> void:
	visible              = false
	_chips_label.text    = ""
	_bet_label.text      = ""
	_dealer_chip.visible = false
	_chips_stack.set_amount(0.0)
