class_name ClothingShop
extends Node

signal changed

const TOP_PRICE := 10
const BOTTOM_PRICE := 8

@onready var player: Player = get_parent()

var purchase_pending := false
var _pending_item := Vector3i.ZERO
# Receipts bridge the interval between the reliable reply and inventory replication.
var _receipts: Dictionary = {}

func _enter_tree() -> void:
	set_multiplayer_authority(1)

static func price(is_top: bool) -> int:
	return TOP_PRICE if is_top else BOTTOM_PRICE

static func is_valid_item(is_top: bool, item: Vector2i) -> bool:
	var count := CharacterSprite.TOP_TEXTURES.size() if is_top else CharacterSprite.PANTS_TEXTURES.size()
	return item.x >= 0 and item.x < count and item.y >= 0 and item.y < CharacterSprite.CLOTHING_COLORS.size()

func owns(is_top: bool, item: Vector2i) -> bool:
	return item in (player.owned_tops if is_top else player.owned_bottoms) \
		or _receipts.has(Vector3i(int(is_top), item.x, item.y))

func buy(is_top: bool, item: Vector2i) -> void:
	if not player.is_multiplayer_authority() or purchase_pending or not is_valid_item(is_top, item) \
		or owns(is_top, item) or player.player_data.money < price(is_top) \
		or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	purchase_pending = true
	_pending_item = Vector3i(int(is_top), item.x, item.y)
	player.player_data.adjust_money(-price(is_top))
	changed.emit()
	if multiplayer.is_server():
		_purchase(is_top, item)
	else:
		_request_purchase.rpc_id(1, is_top, item)

@rpc("any_peer", "reliable")
func _request_purchase(is_top: bool, item: Vector2i) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == int(player.name):
		_purchase(is_top, item)

func _purchase(is_top: bool, item: Vector2i) -> void:
	var items := player.owned_tops if is_top else player.owned_bottoms
	var accepted := is_valid_item(is_top, item) and item not in items
	if accepted:
		items.append(item)
	if player.is_multiplayer_authority():
		_purchase_result(accepted)
	else:
		_purchase_result.rpc_id(int(player.name), accepted)

@rpc("authority", "reliable")
func _purchase_result(accepted: bool) -> void:
	if not purchase_pending:
		return
	purchase_pending = false
	if accepted:
		_receipts[_pending_item] = true
	else:
		player.player_data.adjust_money(price(_pending_item.x == 1))
	changed.emit()
