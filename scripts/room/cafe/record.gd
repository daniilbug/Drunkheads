class_name CafeRecord
extends Draggable

@export_range(0, 3) var record_id := 0
## The authoritative dock also determines which cover and platter are visible.
@export var dock_path: NodePath

func _process(delta: float) -> void:
	super._process(delta)
	sprite.frame = record_id
	sprite.visible = dock_path.is_empty()
	$Area.position = sprite.position if not dock_path.is_empty() else Vector2.ZERO

func _local_pickup(player_id: int) -> bool:
	if not super._local_pickup(player_id):
		return false
	dock_path = NodePath()
	_play_handling_sound.rpc()
	return true

func place_nearby(player: Player, areas: Array[Area2D]) -> void:
	var nearest: DropPlace
	for area in areas:
		var place := area.get_parent() as DropPlace
		if place != null and (nearest == null or player.global_position.distance_squared_to(place.shape.global_position) < player.global_position.distance_squared_to(nearest.shape.global_position)):
			nearest = place
	if nearest == null:
		return
	if multiplayer.is_server():
		_dock_result(int(player.name), _dock(int(player.name), nearest.get_path()))
	else:
		_request_dock.rpc_id(1, nearest.get_path())

@rpc("any_peer", "reliable")
func _request_dock(path: NodePath) -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	_dock_result.rpc_id(peer_id, peer_id, _dock(peer_id, path))

func _dock(player_id: int, path: NodePath) -> bool:
	var player := _level.get_player(player_id)
	var place := get_node_or_null(path) as DropPlace
	if player == null or holder_peer_id != player_id or place == null:
		return false
	if Level.find_level_node(place) != _level or not place.area.overlaps_area(player.interaction_area):
		return false
	if place is CafeRecordSlot and not place.accepts(self):
		return false
	# Ordinary tables can hold records too, but never stack them on another item.
	for child in _level.get_children():
		if child is Draggable and child != self and child.holder_peer_id == 0:
			if place.to_local(child.sprite.global_position).distance_to(place.to_local(place.shape.global_position)) < 6.0:
				return false
	super.drop(player, place)
	dock_path = place.get_path() if place is CafeRecordSlot else NodePath()
	_play_handling_sound.rpc()
	return true

@rpc("authority", "call_local", "reliable")
func _play_handling_sound() -> void:
	$HandlingAudio.play()

@rpc("authority", "reliable")
func _dock_result(player_id: int, accepted: bool) -> void:
	var player := _level.get_player(player_id)
	if accepted and player != null and player._hands_item == self:
		player._hands_item = null
