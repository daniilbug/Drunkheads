class_name Draggable
extends Node2D

signal drop_requested(name: String, sort_pos: Vector2, visual_pos: Vector2)
signal pickup_requested(name: String)

var holder_peer_id: int = 0
var sprite: Sprite2D

func _enter_tree() -> void:
	set_multiplayer_authority(1, true)

func pickup() -> void:
	pickup_requested.emit(name)

func drop(place: DropPlace) -> void:
	var visual_pos := place.shape.global_position
	var anchor := YSort._get_top_ysort_anchor(place)
	var sort_y := visual_pos.y
	if anchor != null:
		sort_y = maxf(visual_pos.y, anchor.global_position.y + 5.0)
	var sort_pos = Vector2(visual_pos.x, sort_y)
	drop_requested.emit(name, sort_pos, visual_pos)
	return
