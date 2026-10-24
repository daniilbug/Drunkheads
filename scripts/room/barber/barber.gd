class_name Barber
extends Interactable

signal purchase_finished(accepted: bool)

const PRICE := 5

@export var menu_scene: PackedScene

@onready var area: Area2D = $InteractionArea
var _menu: CanvasLayer
var purchase_pending := false
var _pending_player: Player


func can_use(player: Player) -> bool:
	var level := Level.find_level_node(self)
	return is_instance_valid(player) and level != null and player.level_id == level.level_id \
		and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED \
		and not player.in_vehicle and not player.in_shower and not player.is_sitting \
		and area.overlaps_area(player.interaction_area)


func interact(player: Player) -> void:
	if not player.is_multiplayer_authority() or player.is_world_input_blocked or not can_use(player) or purchase_pending or is_instance_valid(_menu):
		return
	_menu = menu_scene.instantiate()
	add_child(_menu)
	_menu.open(player, self)
	get_viewport().set_input_as_handled()


func buy_hair(player: Player, style: int) -> void:
	if not player.is_multiplayer_authority() or purchase_pending or not can_use(player) \
		or style < 0 or style >= CharacterSprite.HAIR_TEXTURES.size() or style == player.hair_id \
		or player.player_data.money < PRICE:
		return
	purchase_pending = true
	_pending_player = player
	player.player_data.adjust_money(-PRICE)
	if multiplayer.is_server():
		_select_hair(int(player.name), style)
	else:
		_request_hair.rpc_id(1, style)


@rpc("any_peer", "reliable")
func _request_hair(style: int) -> void:
	if multiplayer.is_server():
		_select_hair(multiplayer.get_remote_sender_id(), style)


func _select_hair(peer_id: int, style: int) -> void:
	var level := Level.find_level_node(self)
	if level == null:
		return
	var player := level.get_player(peer_id)
	if player == null:
		return
	var accepted := can_use(player) and style >= 0 and style < CharacterSprite.HAIR_TEXTURES.size() and style != player.hair_id
	if accepted:
		player.hair_id = style
		var main := level.get_parent() as Main
		if main != null and player == main.local_player:
			main.world_save.request_save()
	_purchase_result.rpc_id(peer_id, accepted)


@rpc("authority", "call_local", "reliable")
func _purchase_result(accepted: bool) -> void:
	if not purchase_pending:
		return
	if not accepted and is_instance_valid(_pending_player):
		_pending_player.player_data.adjust_money(PRICE)
	purchase_pending = false
	_pending_player = null
	purchase_finished.emit(accepted)
