@tool
class_name Chair
extends Node2D

@export var facing_north := false:
	set(value):
		facing_north = value
		if is_node_ready():
			_update_orientation()

@export var sit_offset := Vector2.ZERO:
	set(value):
		sit_offset = value
		if is_node_ready():
			_update_orientation()

@onready var sprite: Sprite2D = $Sprite
@onready var seat: Seat = $Seat

func _ready() -> void:
	seat.occupancy_changed.connect(_update_sprite)
	_update_orientation()

func _update_orientation() -> void:
	seat.facing_north = facing_north
	seat.seat_position_offset = Vector2(0, -1 if facing_north else 2) + sit_offset
	_update_sprite()

func _update_sprite() -> void:
	sprite.frame = (3 if seat.is_occupied else 2) if facing_north else (1 if seat.is_occupied else 0)
