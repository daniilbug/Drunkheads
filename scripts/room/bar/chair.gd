@tool
class_name Chair
extends Node2D

@export var facing_north := false

var is_occupied := false
var _occupant: Player = null

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	sprite.frame = 2 if facing_north else 0

func get_seat_position() -> Vector2:
	return global_position + (Vector2(0, -4) if facing_north else Vector2.ZERO)

func occupy(player: Player) -> void:
	is_occupied = true
	_occupant = player
	if facing_north:
		sprite.frame = 3
		player.direction = Vector2.UP
	else:
		sprite.frame = 1
		player.direction = Vector2.DOWN

func vacate() -> void:
	is_occupied = false
	_occupant = null
	sprite.frame = 2 if facing_north else 0
