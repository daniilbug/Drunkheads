class_name Draggable
extends Node2D

signal drop_requested(name: String, sort_pos: Vector2, visual_pos: Vector2)
signal pickup_requested(name: String)

var holder_peer_id: int = 0
var sprite: Sprite2D

func _enter_tree() -> void:
	set_multiplayer_authority(1, true)
	self.reparent(Level.find_level_node(self))

func pickup() -> void:
	pickup_requested.emit(name)

func drop(place: DropPlace) -> void:
	var visual_pos := place.shape.global_position
	var anchor := _get_top_ysort_anchor(place)
	var sort_y := visual_pos.y
	if anchor != null:
		sort_y = maxf(visual_pos.y, anchor.global_position.y + 5.0)
	var sort_pos = Vector2(visual_pos.x, sort_y)
	drop_requested.emit(name, sort_pos, visual_pos)
	return

func _get_top_ysort_anchor(node: Node) -> Node2D:
	var result := node
	var current := node
	while current.get_parent() != null:
		var parent := current.get_parent()
		if parent is Node2D:
			if result.global_position.y < current.global_position.y:
				result = current
		current = parent
	return result
