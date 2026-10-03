class_name Draggable
extends Node2D

@onready var sprite: Sprite2D = $Sprite
@onready var placing_audio: AudioStreamPlayer2D = get_node_or_null("PlacingAudio")
@onready var _level: Level = Level.find_level_node(self)

@export var can_be_discarded: bool = false

@export var holder_peer_id: int = 0:
	set(value):
		holder_peer_id = value
		if placing_audio:
			placing_audio.play()

func _enter_tree() -> void:
	if _level != null and get_parent() != _level:
		safe_reparent_with_unique_name(self, _level, name)
	set_multiplayer_authority(1, true)

func _process(_delta: float) -> void:
	if not multiplayer.is_server():
		return
	if holder_peer_id == 0:
		return
	var holder := _level.get_node_or_null(str(holder_peer_id)) as Player
	if holder == null:
		holder_peer_id = 0
		return
	var hands_pos := holder.hands.global_position
	if holder.direction.y < 0:
		global_position = hands_pos
		sprite.position = Vector2.ZERO
	else:
		global_position = Vector2(hands_pos.x, holder.global_position.y + 5.0)
		sprite.position = to_local(hands_pos)

func pickup(player: Player) -> void:
	if multiplayer.is_server():
		_local_pickup(int(player.name))
	else:
		_remote_pickup.rpc_id(1, int(player.name))

func drop(player: Player, place: DropPlace) -> void:
	var visual_pos := place.shape.global_position
	var anchor := _get_top_ysort_anchor(place)
	var sort_y := visual_pos.y
	if anchor != null:
		sort_y = maxf(visual_pos.y, anchor.global_position.y + 5.0)
	var sort_pos = Vector2(visual_pos.x, sort_y)
	if multiplayer.is_server():
		_local_drop(sort_pos, visual_pos)
	else:
		_remote_drop.rpc_id(1, int(player.name), sort_pos, visual_pos)

@rpc("any_peer", "reliable")
func _remote_pickup(player_id: int) -> void:
	if not multiplayer.is_server() or multiplayer.get_remote_sender_id() != player_id:
		return
	_local_pickup(player_id)

@rpc("any_peer", "reliable")
func _remote_drop(player_id: int, sort_pos: Vector2, visual_pos: Vector2) -> void:
	if not multiplayer.is_server() or multiplayer.get_remote_sender_id() != player_id:
		return
	_local_drop(sort_pos, visual_pos)

func _local_pickup(player_id: int) -> void:
	sprite.position = Vector2.ZERO
	holder_peer_id = player_id

func _local_drop(sort_pos: Vector2, visual_pos: Vector2) -> void:
	holder_peer_id = 0
	global_position = sort_pos
	sprite.position = to_local(visual_pos)
	
func safe_reparent_with_unique_name(node: Node, new_parent: Node, base_name: String) -> void:
	node.reparent(new_parent)
	var unique_name: String = base_name
	var counter: int = 1
	
	while new_parent.has_node(unique_name):
		unique_name = base_name + "_" + str(counter)
		counter += 1
		
	node.name = unique_name

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
