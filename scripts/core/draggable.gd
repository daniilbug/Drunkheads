class_name Draggable
extends Node2D

signal drop_requested(name: String, sort_pos: Vector2, visual_pos: Vector2)
signal pickup_requested(name: String)

@onready var sprite: Sprite2D = $Sprite
@onready var placing_audio: AudioStreamPlayer2D = $PlacingAudio

@export var holder_peer_id: int = 0:
	set(value):
		holder_peer_id = value
		if placing_audio:
			placing_audio.play()

func _enter_tree() -> void:
	set_multiplayer_authority(1, true)
	var level := Level.find_level_node(self)
	if level != null and get_parent() != level:
		safe_reparent_with_unique_name(self, level, name)

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
	
func safe_reparent_with_unique_name(node: Node, new_parent: Node, base_name: String) -> void:
	node.reparent(new_parent)
	var unique_name: String = base_name
	var counter: int = 1
	
	while new_parent.has_node(unique_name):
		unique_name = base_name + "_" + str(counter)
		counter += 1
		
	node.name = unique_name
	#node.owner = new_parent.owner if new_parent.owner else new_parent
	#node.unique_name_in_owner = true

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
