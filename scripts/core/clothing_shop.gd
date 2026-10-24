class_name ClothingShop
extends Node

signal changed
signal purchase_finished(accepted: bool)

const TOP_PRICE := 10
const BOTTOM_PRICE := 8

@onready var player: Player = get_parent()

var purchase_pending := false
var _pending_items: Array[Vector3i] = []
var _pending_cost := 0
# Receipts bridge the interval between the reliable reply and inventory replication.
var _receipts: Dictionary = {}
var _fitting_source: Node

@export var fitting_top := Vector2i(-1, -1):
	set(value):
		fitting_top = value
		if is_instance_valid(player):
			player._refresh_appearance()

@export var fitting_bottom := Vector2i(-1, -1):
	set(value):
		fitting_bottom = value
		if is_instance_valid(player):
			player._refresh_appearance()


func preview_fitting(source: Node, top: Vector2i, bottom: Vector2i) -> void:
	if is_inside_tree() and multiplayer.is_server():
		_fitting_source = source
		fitting_top = top
		fitting_bottom = bottom


func clear_fitting(source: Node) -> void:
	if is_inside_tree() and multiplayer.is_server() and _fitting_source == source:
		_fitting_source = null
		fitting_top = Vector2i(-1, -1)
		fitting_bottom = Vector2i(-1, -1)

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
	if owns(is_top, item) or not _begin_purchase([Vector3i(int(is_top), item.x, item.y)]):
		return
	if multiplayer.is_server():
		_purchase(is_top, item)
	else:
		_request_purchase.rpc_id(1, is_top, item)


func unowned_items(items: Array[Vector3i]) -> Array[Vector3i]:
	var result: Array[Vector3i] = []
	for item in items:
		if item not in result and not owns(item.x == 1, Vector2i(item.y, item.z)):
			result.append(item)
	return result


func basket_price(items: Array[Vector3i]) -> int:
	var total := 0
	for item in unowned_items(items):
		total += price(item.x == 1)
	return total


func buy_at_checkout(checkout: Interactable, paths: Array[NodePath], items: Array[Vector3i]) -> void:
	if checkout.can_use(player) and paths.size() == items.size() and _begin_purchase(items):
		checkout.purchase(player, paths, _pending_cost)


func _begin_purchase(items: Array[Vector3i]) -> bool:
	if not player.is_multiplayer_authority() or purchase_pending or items.is_empty() \
		or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return false
	for item in items:
		if item.x not in [0, 1] or not is_valid_item(item.x == 1, Vector2i(item.y, item.z)):
			return false
	var total := basket_price(items)
	if player.player_data.money < total:
		return false
	purchase_pending = true
	_pending_items = unowned_items(items)
	_pending_cost = total
	player.player_data.adjust_money(-total)
	changed.emit()
	return true

@rpc("any_peer", "reliable")
func _request_purchase(is_top: bool, item: Vector2i) -> void:
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() == int(player.name):
		_purchase(is_top, item)

func _purchase(is_top: bool, item: Vector2i) -> void:
	var items := player.owned_tops if is_top else player.owned_bottoms
	var accepted := is_valid_item(is_top, item) and item not in items
	if accepted:
		items.append(item)
	_purchase_result.rpc_id(int(player.name), accepted)

@rpc("authority", "call_local", "reliable")
func _purchase_result(accepted: bool) -> void:
	if not purchase_pending:
		return
	purchase_pending = false
	if accepted:
		for item in _pending_items:
			_receipts[item] = true
	else:
		player.player_data.adjust_money(_pending_cost)
	_pending_items.clear()
	_pending_cost = 0
	changed.emit()
	purchase_finished.emit(accepted)
