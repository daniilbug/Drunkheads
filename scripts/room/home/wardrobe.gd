class_name Wardrobe
extends Interactable

@export var menu_scene: PackedScene

@onready var area: Area2D = $Area
var _menu: WardrobeMenu

func can_use(player: Player) -> bool:
	var level := Level.find_level_node(self)
	return is_instance_valid(player) and level != null and player.level_id == level.level_id \
		and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED \
		and not player.in_vehicle and not player.in_shower and not player.is_sitting \
		and area.overlaps_area(player.interaction_area)

func interact(player: Player) -> void:
	if not player.is_multiplayer_authority() or player.is_world_input_blocked or not can_use(player) \
		or is_instance_valid(_menu) or player.owned_tops.is_empty() or player.owned_bottoms.is_empty():
		return
	_menu = menu_scene.instantiate() as WardrobeMenu
	add_child(_menu)
	_menu.open(player, self)
	get_viewport().set_input_as_handled()

func equip(player: Player, is_top: bool, item: Vector2i) -> void:
	if multiplayer.is_server():
		_equip(int(player.name), is_top, item)
	else:
		_request_equip.rpc_id(1, is_top, item)

@rpc("any_peer", "reliable")
func _request_equip(is_top: bool, item: Vector2i) -> void:
	if multiplayer.is_server():
		_equip(multiplayer.get_remote_sender_id(), is_top, item)

func _equip(peer_id: int, is_top: bool, item: Vector2i) -> void:
	var level := Level.find_level_node(self)
	if level == null:
		return
	var player := level.get_player(peer_id)
	if not can_use(player) or item not in (player.owned_tops if is_top else player.owned_bottoms):
		if peer_id == multiplayer.get_unique_id():
			_reject_selection()
		else:
			_reject_selection.rpc_id(peer_id)
		return
	if is_top:
		player.top_id = item.x
		player.top_color_id = item.y
	else:
		player.pants_id = item.x
		player.pants_color_id = item.y
	var main := level.get_parent() as Main
	if main != null and player == main.local_player:
		main.world_save.request_save()

@rpc("authority", "call_local", "reliable")
func _reject_selection() -> void:
	if is_instance_valid(_menu):
		_menu.close()
