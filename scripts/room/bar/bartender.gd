class_name Bartender
extends StaticBody2D

signal item_purchased(item: BarMenuItem)

@export var serves_coffee := false
@export var menu_scene: PackedScene

static var _drink_id := 0

@onready var sprite: Sprite2D = $Sprite

@onready var purchase_area: Area2D = $PurchaseArea
@onready var boombox_place: DropPlace = $DropPlaces/DropPlace1
@onready var dance_floor_controller_place: DropPlace = $DropPlaces/DropPlace7
@onready var order_place: DropPlace = $DropPlaces/OrderPlace

var _anim_t := 0.0
var _menu_open := false
var _purchase_pending := false
var _pending_cost := 0.0
var _pending_player: Player

func get_menu_items() -> Array[BarMenuItem]:
	return CafeMenu.coffee_menu if serves_coffee else BarMenu.get_all_items()

func order(player: Player) -> void:
	if _menu_open or _purchase_pending or player.is_world_input_blocked:
		return
	var menu := menu_scene.instantiate() as OrderMenu
	add_child(menu)
	_menu_open = true
	menu.open(player)
	menu.item_selected.connect(func(item: BarMenuItem): order_item(player, item))
	menu.closed.connect(func(): _on_menu_closed(menu))

func order_item(player: Player, item: BarMenuItem) -> bool:
	var index := get_menu_items().find(item)
	if index < 0 or player.player_data == null or player.player_data.money < item.cost:
		return false
	if player is NPC:
		if not multiplayer.is_server() or not _serve_for(int(player.name), index):
			return false
		player.player_data.adjust_money(-item.cost)
		return true
	if _purchase_pending:
		return false
	_purchase_pending = true
	_pending_cost = item.cost
	_pending_player = player
	player.player_data.adjust_money(-item.cost)
	if multiplayer.is_server():
		_purchase_result(_serve_for(int(player.name), index))
	else:
		_request_order.rpc_id(1, index)
	return true

@rpc("any_peer", "reliable")
func _request_order(index: int) -> void:
	if multiplayer.is_server():
		var peer_id := multiplayer.get_remote_sender_id()
		_purchase_result.rpc_id(peer_id, _serve_for(peer_id, index))

func _serve_for(peer_id: int, index: int) -> bool:
	var items := get_menu_items()
	if index < 0 or index >= items.size():
		return false
	var level := Level.find_level_node(self)
	var player := level.get_player(peer_id)
	if player == null or player.in_vehicle or not purchase_area.overlaps_area(player.interaction_area):
		return false
	# One collection point: do not stack orders or let visitors collect each other's cup.
	for child in level.get_children():
		var existing := child as Drink
		if existing != null and not existing.is_queued_for_deletion() and existing.holder_peer_id == 0:
			if order_place.to_local(existing.sprite.global_position).length() < 6.0:
				return false
	var item := items[index]
	var drink := load("res://scenes/room/bar/drink.tscn").instantiate() as Drink
	_drink_id += 1
	drink.name = "Drink%d" % _drink_id
	drink.drink_name = item.name
	drink.type = item.type
	drink.flavor = item.flavor
	drink.cost = item.cost
	drink.alcohol = item.alcohol
	drink.sprite_frame = item.sprite
	drink.max_parts = item.parts
	drink.customer_id = peer_id
	level.add_child(drink)
	drink.drop(null, order_place)
	item_purchased.emit(item)
	return true

@rpc("authority", "reliable")
func _purchase_result(accepted: bool) -> void:
	if not _purchase_pending:
		return
	if not accepted:
		if is_instance_valid(_pending_player):
			_pending_player.player_data.adjust_money(_pending_cost)
	_purchase_pending = false
	_pending_cost = 0.0
	_pending_player = null

func _ready() -> void:
	sprite.frame = 0

func _process(delta: float) -> void:
	_anim_t += delta
	var cycle := fmod(_anim_t, 3.0)
	sprite.frame = 1 if cycle < 0.4 else 0
	
func _on_menu_closed(menu: OrderMenu) -> void:
	_menu_open = false
	menu.queue_free()
