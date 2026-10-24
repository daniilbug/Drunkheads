class_name ClothingCheckout
extends Interactable

@export var menu_scene: PackedScene

@onready var area: Area2D = $InteractionArea
var _menu: CanvasLayer


func can_use(player: Player) -> bool:
	var level := Level.find_level_node(self)
	return is_instance_valid(player) and player.is_inside_tree() and level != null \
		and player.level_id == level.level_id and not player.in_vehicle and not player.is_sitting \
		and area.overlaps_area(player.interaction_area)


func get_basket() -> Array[ShopGarment]:
	var basket: Array[ShopGarment] = []
	for slot: ClothingSlot in $CheckoutSlots.get_children():
		var garment := slot.get_garment()
		if garment != null:
			basket.append(garment)
	return basket


func interact(player: Player) -> void:
	if not player.is_multiplayer_authority() or player.is_world_input_blocked or not can_use(player) \
		or get_basket().is_empty() or player.clothing_shop.purchase_pending or is_instance_valid(_menu):
		return
	_menu = menu_scene.instantiate()
	add_child(_menu)
	_menu.open(player, self)
	get_viewport().set_input_as_handled()


func purchase(player: Player, paths: Array[NodePath], total: int) -> void:
	if multiplayer.is_server():
		_finish_purchase(int(player.name), paths, total)
	else:
		_request_purchase.rpc_id(1, paths, total)


@rpc("any_peer", "reliable")
func _request_purchase(paths: Array[NodePath], total: int) -> void:
	if multiplayer.is_server():
		_finish_purchase(multiplayer.get_remote_sender_id(), paths, total)


func _finish_purchase(peer_id: int, paths: Array[NodePath], total: int) -> void:
	var level := Level.find_level_node(self)
	var player := level.get_player(peer_id)
	if player == null:
		return
	var accepted := _commit_purchase(player, paths, total)
	player.clothing_shop._purchase_result.rpc_id(peer_id, accepted)


func _commit_purchase(player: Player, paths: Array[NodePath], total: int) -> bool:
	if not can_use(player):
		return false
	var basket := get_basket()
	if basket.is_empty() or basket.size() != paths.size():
		return false
	var items: Array[Vector3i] = []
	for index in basket.size():
		var garment := basket[index]
		if garment.get_path() != paths[index]:
			return false
		items.append(Vector3i(int(garment.is_top), garment.style_id, garment.color_id))
	if total != player.clothing_shop.basket_price(items):
		return false
	for item in player.clothing_shop.unowned_items(items):
		var wardrobe := player.owned_tops if item.x == 1 else player.owned_bottoms
		wardrobe.append(Vector2i(item.y, item.z))
	for garment in basket:
		garment.dock_path = NodePath()
		garment.queue_free()
	var world := Level.find_level_node(self).get_parent() as Main
	if world != null:
		world.world_save.request_save()
	return true
