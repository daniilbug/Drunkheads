@tool
class_name Card
extends Node2D

const CARD_W := 55.0
const CARD_H := 79.0
const RANK_NAMES := ["2","3","4","5","6","7","8","9","10","J","Q","K","A"]
const SUIT_SYMS  := ["♠","♥","♦","♣"]

@export var card_index: int  = -1
@export var face_up:    bool = true

@onready var audio: AudioStreamPlayer2D = $Audio

var _color_card_bg:     Color = Color.WHITE
var _color_card_border: Color = Color(0.3, 0.3, 0.3)
var _color_red_suit:    Color = Color("cc1111")
var _color_black_suit:  Color = Color(0.08, 0.08, 0.08)

const _BACK_TEX := preload("res://assets/sprites/poker/card_back.png")

const _SOUND_PLACING := preload("res://assets/audio/poker/placing.mp3")

var _font: Font

func _ready() -> void:
	_font = ThemeDB.fallback_font

func set_card(idx: int, is_face_up: bool = true) -> void:
	card_index = idx
	if face_up != is_face_up:
		face_up = is_face_up
		audio.stream = _SOUND_PLACING
		audio.play()
	queue_redraw()

func _draw() -> void:
	if card_index < 0 or not face_up:
		_draw_back()
	else:
		_draw_face()

func _draw_face() -> void:
	var r   := card_index / 4
	var s   := card_index % 4
	var col: Color = _color_red_suit if s == 1 or s == 2 else _color_black_suit

	draw_rect(Rect2(Vector2.ZERO, Vector2(CARD_W, CARD_H)), _color_card_bg,     true,  0.0)
	draw_rect(Rect2(Vector2.ZERO, Vector2(CARD_W, CARD_H)), _color_card_border, false, 1.0)

	var rname: String = RANK_NAMES[r]
	var ssym:  String = SUIT_SYMS[s]
	var fs  := 10
	var pad := 3
	var cx  := CARD_W / 2.0
	var cy  := CARD_H / 2.0

	var rw  := _font.get_string_size(rname, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var ssw := _font.get_string_size(ssym,  HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var ax  := pad + maxf(rw, ssw) / 2.0   # shared column center x

	draw_string(_font, Vector2(ax - rw  / 2.0, pad + fs),         rname, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	draw_string(_font, Vector2(ax - ssw / 2.0, pad + fs * 2 + 4), ssym,  HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

	var cfs := 20
	var sw  := _font.get_string_size(ssym, HORIZONTAL_ALIGNMENT_LEFT, -1, cfs).x
	draw_string(_font, Vector2(cx - sw * 0.5, cy + cfs * 0.35), ssym, HORIZONTAL_ALIGNMENT_LEFT, -1, cfs, col)

	draw_set_transform(Vector2(cx, cy), PI, Vector2.ONE)
	draw_string(_font, Vector2(-cx + ax - rw  / 2.0, -cy + pad + fs),         rname, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	draw_string(_font, Vector2(-cx + ax - ssw / 2.0, -cy + pad + fs * 2 + 4), ssym,  HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func _draw_back() -> void:
	draw_texture(_BACK_TEX, Vector2.ZERO)
