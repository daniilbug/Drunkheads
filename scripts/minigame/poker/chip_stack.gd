@tool
class_name ChipStack
extends Node2D

const _CHIP_TEX  := preload("res://assets/sprites/poker/chip.png")
const _STACK_DX  := 0.0
const _STACK_DY  := 2.0
const _MAX_CHIPS := 10

@onready var audio: AudioStreamPlayer2D = $Audio

@export var amount: float = 0.0:
	set(v):
		if amount != v and is_node_ready():
			audio.play()
		amount = v
		queue_redraw()

func set_amount(a: float) -> void:
	amount = a

func _draw() -> void:
	if amount <= 0.0:
		return
	var count := clampi(int(ceil(amount / 2.0)), 1, _MAX_CHIPS)
	var tw    := float(_CHIP_TEX.get_width())
	var th    := float(_CHIP_TEX.get_height())
	for i in range(count):
		var pos := Vector2(float(i) * _STACK_DX - tw * 0.5,
						   float(-i) * _STACK_DY - th * 0.5)
		draw_texture(_CHIP_TEX, pos)
