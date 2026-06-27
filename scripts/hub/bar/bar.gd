class_name Bar
extends Room

const BOOMBOX_SCENE := preload("res://scenes/hub/bar/boombox.tscn")
const DANCE_FLOOR_CONTROLLER := preload("res://scenes/hub/bar/dance_floor_controller.tscn")
const DRINK_SCENE  := preload("res://scenes/hub/drink.tscn")

@onready var bartender: Bartender = $YSort/Bartender
@onready var dance_floor: DanceFloor = $FloorDecorations/DanceFloor

func init_room() -> void:
	var boombox: Boombox = BOOMBOX_SCENE.instantiate()
	var dance_floor_controller: DanceFloorController = DANCE_FLOOR_CONTROLLER.instantiate()
	y_sort.add_child(boombox)
	y_sort.add_child(dance_floor_controller)
	if multiplayer.is_server():
		boombox.drop(bartender.boombox_place)
		dance_floor_controller.on_mode_change.connect(func(mode: int): dance_floor.set_mode(mode))
		dance_floor_controller.drop(bartender.dance_floor_controller_place)

func _on_bartender_item_purchased(item: BarMenuItem) -> void:
	if multiplayer.is_server():
		handle_drink_spawn(
			item.name, 
			item.type,
			item.flavor, 
			item.cost, 
			item.alcohol, 
			item.sprite,
			item.parts,
		)
	else:
		_spawn_drink.rpc_id(
			1, 
			item.name, 
			item.type,
			item.flavor, 
			item.cost, 
			item.alcohol, 
			item.sprite,
			item.parts,
		)

@rpc("any_peer", "reliable")
func _spawn_drink(
	drink_name: String,
	type: BarMenuItem.Type,
	flavor: String,
	cost: float,
	alcohol: float,
	sprite: int,
	parts: int,
) -> void:
	if not multiplayer.is_server():
		return
	handle_drink_spawn(drink_name, type, flavor, cost, alcohol, sprite, parts)
	
func handle_drink_spawn(
	drink_name: String,
	type: BarMenuItem.Type,
	flavor: String,
	cost: float,
	alcohol: float,
	sprite: int,
	parts: int,
) -> void:
	var drink: Drink = DRINK_SCENE.instantiate()
	drink.drink_name = drink_name
	drink.type = type
	drink.flavor = flavor
	drink.cost = cost
	drink.alcohol = alcohol
	drink.sprite_frame = sprite
	drink.max_parts = parts
	y_sort.add_child(drink)
	drink.drop(bartender.order_place)
