class_name Trash
extends Interactable

@onready var area: Area2D = $Area
@onready var audio: AudioStreamPlayer2D = $Audio

func interact(player: Player) -> void:
	var item := player._hands_item
	if item == null or not item.can_be_discarded:
		return
	var level := Level.find_level_node(self)
	if level == null:
		return
	var item_path := level.get_path_to(item)
	if multiplayer.is_server():
		_discard(int(player.name), item_path)
	else:
		_request_discard.rpc_id(1, item_path)

@rpc("any_peer", "reliable")
func _request_discard(item_path: NodePath) -> void:
	if not multiplayer.is_server():
		return
	_discard(multiplayer.get_remote_sender_id(), item_path)

func _discard(peer_id: int, item_path: NodePath) -> void:
	var level := Level.find_level_node(self)
	if level == null or item_path.is_absolute():
		return
	var player := level.get_node_or_null(str(peer_id)) as Player
	var item := level.get_node_or_null(item_path) as Draggable
	if player == null or item == null:
		return
	if not area.overlaps_area(player.interaction_area):
		return
	if item.holder_peer_id != peer_id or not item.can_be_discarded or item.is_queued_for_deletion():
		return
	_play_discard_sound.rpc()
	if item.get_parent() == level:
		# Level children are managed by their MultiplayerSpawner.
		item.queue_free()
	else:
		# Room items are created on every peer, so they need an explicit removal.
		_remove_room_item.rpc(item_path)

@rpc("authority", "call_local", "reliable")
func _remove_room_item(item_path: NodePath) -> void:
	var level := Level.find_level_node(self)
	if level == null:
		return
	var item := level.get_node_or_null(item_path) as Draggable
	if item != null:
		item.queue_free()

@rpc("authority", "call_local", "reliable")
func _play_discard_sound() -> void:
	audio.play()
