class_name Bar
extends Level

const DRINK_SCENE  := preload("res://scenes/hub/drink.tscn")

@onready var menu_item_spawn: Node2D = $MenuItemSpawn
@onready var bartender: Bartender = $YSort/Bartender
@onready var boombox: Boombox = $YSort/Boombox
@onready var respect_label: Label = $HUD/Stats/RespectLabel
@onready var mind_label: Label = $HUD/Stats/MindLabel
@onready var money_label: Label = $HUD/Stats/MoneyLabel
@onready var hint_label: Label = $HUD/HintLabel

func _ready() -> void:
	y_sort = $YSort
	spawner = $Spawner
	player_spawn = $WelcomeZone
	super._ready()
	spawner.spawned.connect(_on_spawned)

	if multiplayer.is_server():
		boombox.drop(bartender.boombox_place)

func _init_local_player(player: Player) -> void:
	super._init_local_player(player)
	player.player_data.stats_changed.connect(_update_stats)
	player.drink_action_requested.connect(_on_drink_action_requested)
	_update_stats()

func _update_stats() -> void:
	if not local_player:
		return
	var d := local_player.player_data
	respect_label.text = "Respect  %d" % int(d.respect)
	mind_label.text    = "Mind     %d" % int(d.mind)
	money_label.text   = "Money   $%d" % int(d.money)

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
		
func _on_drink_action_requested(drink_name: String) -> void:
	if multiplayer.is_server():
		_handle_drink_action(multiplayer.get_unique_id(), drink_name)
	else:
		_request_drink_action.rpc_id(1, drink_name)

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

@rpc("any_peer", "reliable")
func _request_drink_action(drink_name: String) -> void:
	if not multiplayer.is_server():
		return
	_handle_drink_action(multiplayer.get_remote_sender_id(), drink_name)

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
	y_sort.add_child(drink, true)
	drink.drop(bartender.order_place)
	
func _handle_drink_action(peer_id: int, drink_name: String) -> void:
	var drink := y_sort.get_node_or_null(drink_name) as Drink
	if drink == null or drink.holder_peer_id != peer_id:
		return
	if drink.parts == 0:
		return
	drink.parts -= 1
	if drink.parts == 0:
		drink.holder_peer_id = 0
		drink.queue_free()
