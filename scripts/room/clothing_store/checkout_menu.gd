extends CanvasLayer

const CARD_SCENE := preload("res://scenes/room/clothing_store/checkout_card.tscn")

@onready var _cards: HBoxContainer = $Overlay/Panel/Content/Items
@onready var _buy: Button = $Overlay/Panel/Content/Buy
@onready var _total: Label = $Overlay/Panel/Content/Buy/Contents/Price

var _player: Player
var _checkout: ClothingCheckout
var _paths: Array[NodePath] = []
var _items: Array[Vector3i] = []
var _discounts: Array[int] = []
var _closing := false


func open(player: Player, checkout: ClothingCheckout) -> void:
	_player = player
	_checkout = checkout
	_player.is_world_input_blocked = true
	_player.tree_exiting.connect(close)
	_player.clothing_shop.changed.connect(_refresh)
	_player.clothing_shop.purchase_finished.connect(_on_purchase_finished)
	_player.player_data.stats_changed.connect(_refresh)
	for slot: ClothingSlot in checkout.get_node("CheckoutSlots").get_children():
		_cards.add_child(CARD_SCENE.instantiate())
		slot.contents_changed.connect(_refresh)
	_buy.pressed.connect(_on_buy)
	_refresh()


func _refresh() -> void:
	if _closing:
		return
	var basket := _checkout.get_basket()
	if basket.is_empty():
		close()
		return
	_paths.assign(basket.map(func(garment: ShopGarment): return garment.get_path()))
	_items.assign(basket.map(func(garment: ShopGarment): return Vector3i(int(garment.is_top), garment.style_id, garment.color_id)))
	_discounts.assign(basket.map(func(garment: ShopGarment): return garment.discount_percent))
	var prices := _player.clothing_shop.basket_prices(_items, _discounts)
	var total := 0
	for index in _cards.get_child_count():
		var card := _cards.get_child(index) as Control
		card.visible = index < basket.size()
		if not card.visible:
			continue
		var garment := basket[index]
		var icon: TextureRect = card.get_node("Icon")
		icon.texture = garment.sprite.texture
		icon.material = garment.sprite.material
		var price := prices[index]
		total += price
		(card.get_node("Price") as Label).text = str(price)
		card.modulate.a = 0.55 if price == 0 else 1.0
	_total.text = str(total)
	_buy.disabled = _player.clothing_shop.purchase_pending or _player.player_data.money < total
	_buy.modulate.a = 0.45 if _buy.disabled else 1.0
	if not _buy.disabled:
		_buy.grab_focus()


func _on_buy() -> void:
	if not _closing and not _buy.disabled:
		_player.clothing_shop.buy_at_checkout(_checkout, _paths.duplicate(), _items.duplicate(), _discounts.duplicate())


func _on_purchase_finished(accepted: bool) -> void:
	if accepted:
		close()
	else:
		_refresh()


func _process(_delta: float) -> void:
	if not _closing and (not is_instance_valid(_player) or not _checkout.can_use(_player)):
		close()


func _exit_tree() -> void:
	close()


func close() -> void:
	if _closing:
		return
	_closing = true
	if is_instance_valid(_player):
		_player.is_world_input_blocked = false
		_player.tree_exiting.disconnect(close)
		if is_instance_valid(_player.clothing_shop):
			_player.clothing_shop.changed.disconnect(_refresh)
			_player.clothing_shop.purchase_finished.disconnect(_on_purchase_finished)
		_player.player_data.stats_changed.disconnect(_refresh)
	hide()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if _closing or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		_on_buy()
		get_viewport().set_input_as_handled()
