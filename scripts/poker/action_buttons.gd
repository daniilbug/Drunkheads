class_name ActionButtons
extends Control

var min_raise: float = PokerBetting.MIN_RAISE

@export_group("Colors")
@export var color_btn_normal: Color = Color(0.22, 0.16, 0.08)
@export var color_btn_hover:  Color = Color(0.35, 0.25, 0.10)
@export var color_btn_text:   Color = Color("f0d8a0")

signal action_chosen(action: String, amount: float)

@onready var _check_call_btn: Button         = $HBox/CheckCallButton
@onready var _raise_btn:      Button         = $HBox/RaiseButton
@onready var _fold_btn:       Button         = $HBox/FoldButton
@onready var _ready_btn:      Button         = $HBox/ReadyButton
@onready var _raise_panel:    HBoxContainer  = $HBox/RaisePanel
@onready var _down_btn:       Button         = $HBox/RaisePanel/DownButton
@onready var _amount_label:   Label          = $HBox/RaisePanel/AmountLabel
@onready var _up_btn:         Button         = $HBox/RaisePanel/UpButton
@onready var _confirm_btn:    Button         = $HBox/RaisePanel/ConfirmButton

var _raise_amount: float = 0.0
var _current_bet:  float = 0.0
var _player_money: float = 0.0
var _player_bet:   float = 0.0
var _raise_mode:   bool  = false
var _ready_mode:   bool  = false

func _ready() -> void:
	var buttons: Array = [_check_call_btn, _raise_btn, _fold_btn, _ready_btn, _down_btn, _up_btn, _confirm_btn]
	for btn in buttons:
		_style_button(btn as Button)

	deactivate()

func update_ready_state(can_ready: bool) -> void:
	_ready_mode = true
	_check_call_btn.visible = false
	_raise_btn.visible      = false
	_fold_btn.visible       = false
	_raise_panel.visible    = false
	_ready_btn.visible      = can_ready
	visible = true

func update_state(player_bet: float, current_bet: float, money: float) -> void:
	_player_bet   = player_bet
	_current_bet  = current_bet
	_player_money = money
	_ready_mode   = false
	visible       = true

	_ready_btn.visible      = false
	_fold_btn.visible       = true
	var to_call:   float = current_bet - player_bet
	var can_check: bool  = is_equal_approx(player_bet, current_bet)
	var can_raise: bool  = money > to_call

	_check_call_btn.text = "Check" if can_check else "Call %.0f" % to_call
	_check_call_btn.visible = true
	_raise_btn.visible   = can_raise

	_raise_amount = clampf(_raise_amount, current_bet + min_raise, money + player_bet)

	_raise_panel.visible = _raise_mode and can_raise
	_update_raise_display()

func deactivate() -> void:
	visible     = false
	_raise_mode = false
	_ready_mode = false

func _on_ready() -> void:
	action_chosen.emit("ready", 0.0)

func _on_check_call() -> void:
	if is_equal_approx(_player_bet, _current_bet):
		action_chosen.emit("check", 0.0)
	else:
		action_chosen.emit("call", 0.0)
	_raise_mode = false

func _on_raise_toggle() -> void:
	_raise_mode          = not _raise_mode
	_raise_panel.visible = _raise_mode
	if _raise_mode:
		_raise_amount = _current_bet + min_raise
	_update_raise_display()

func _on_fold() -> void:
	action_chosen.emit("fold", 0.0)

func _on_raise_up() -> void:
	_raise_amount = minf(_raise_amount + min_raise, _player_money + _player_bet)
	_update_raise_display()

func _on_raise_down() -> void:
	_raise_amount = maxf(_raise_amount - min_raise, _current_bet + min_raise)
	_update_raise_display()

func _on_confirm_raise() -> void:
	action_chosen.emit("raise", _raise_amount)
	_raise_mode          = false
	_raise_panel.visible = false

func _update_raise_display() -> void:
	_amount_label.text  = "%.0f" % _raise_amount
	_confirm_btn.text   = "Bet %.0f" % _raise_amount

func _style_button(btn: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = color_btn_normal
	normal.set_corner_radius_all(4)
	normal.content_margin_left   = 6.0
	normal.content_margin_right  = 6.0
	normal.content_margin_top    = 4.0
	normal.content_margin_bottom = 4.0
	var hover := StyleBoxFlat.new()
	hover.bg_color = color_btn_hover
	hover.set_corner_radius_all(4)
	hover.content_margin_left   = 6.0
	hover.content_margin_right  = 6.0
	hover.content_margin_top    = 4.0
	hover.content_margin_bottom = 4.0
	btn.add_theme_stylebox_override("normal",  normal)
	btn.add_theme_stylebox_override("hover",   hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", color_btn_text)
