class_name Bartender
extends StaticBody2D

signal item_purchased(item: BarMenuItem)

@onready var sprite: Sprite2D = $Sprite

@onready var purchase_area: Area2D = $PurchaseArea
@onready var boombox_place: DropPlace = $DropPlaces/DropPlace1
@onready var dance_floor_controller_place: DropPlace = $DropPlaces/DropPlace7
@onready var order_place: DropPlace = $DropPlaces/OrderPlace

var _anim_t := 0.0
var _menu_open := false

func order(player: Player) -> void:
	if _menu_open or player.is_world_input_blocked:
		return
	var menu: BarMenu = preload("res://scenes/room/bar/bar_menu.tscn").instantiate()
	add_child(menu)
	_menu_open = true
	menu.open(player)
	menu.item_selected.connect(_on_menu_item_selected)
	menu.closed.connect(func(): _on_menu_closed(menu))

func order_item(player: Player, item: BarMenuItem) -> void:
	item_purchased.emit(item)

func _ready() -> void:
	sprite.frame = 0

func _process(delta: float) -> void:
	_anim_t += delta
	var cycle := fmod(_anim_t, 3.0)
	sprite.frame = 1 if cycle < 0.4 else 0
	
func _on_menu_item_selected(item: BarMenuItem) -> void:
	item_purchased.emit(item)
	
func _on_menu_closed(menu: BarMenu) -> void:
	_menu_open = false
	menu.queue_free()
