class_name Bartender
extends StaticBody2D

signal item_purchased(item: BarMenuItem)

@onready var sprite: Sprite2D = $Sprite
@onready var menu_item_area: Area2D = $MenuItemArea

var _anim_t := 0.0
var _menu_open := false

func order(player: Player) -> void:
	var menu: BarMenu = preload("res://scenes/hub/bar/bar_menu.tscn").instantiate()
	add_child(menu)
	_menu_open = true
	menu.open(player.player_data)
	menu.item_selected.connect(func(item: BarMenuItem): _on_menu_item_selected(item, menu))
	menu.closed.connect(func(): _on_menu_closed(menu))

func _ready() -> void:
	sprite.frame = 0

func _process(delta: float) -> void:
	_anim_t += delta
	var cycle := fmod(_anim_t, 3.0)
	sprite.frame = 1 if cycle < 0.4 else 0
	
func _on_menu_item_selected(item: BarMenuItem, menu: BarMenu) -> void:
	item_purchased.emit(item)
	
func _on_menu_closed(menu: BarMenu) -> void:
	_menu_open = false
	menu.queue_free()
