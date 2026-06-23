class_name Bar
extends Node2D

const PLAYER_SCENE := preload("res://scenes/hub/player.tscn")
const DRINK_SCENE  := preload("res://scenes/hub/drink.tscn")

@onready var log = Log.new("Bar")

@onready var y_sort: Node2D = $YSort
@onready var items: Node2D = $Items
@onready var menu_item_spawn: Node2D = $MenuItemSpawn
@onready var respect_label: Label = $HUD/Stats/RespectLabel
@onready var mind_label: Label = $HUD/Stats/MindLabel
@onready var money_label: Label = $HUD/Stats/MoneyLabel
@onready var hint_label: Label = $HUD/HintLabel

var local_player: Player = null

func _ready() -> void:
	var player_spawner: MultiplayerSpawner = $PlayerSpawner
	player_spawner.spawned.connect(_on_player_spawned)

	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_remove_player)
		_spawn_player(multiplayer.get_unique_id())
		_init_local_player(y_sort.get_node(str(multiplayer.get_unique_id())) as Player)
	else:
		pass

func _process(_delta: float) -> void:
	if not multiplayer.is_server():
		return
	for child in items.get_children():
		if not child is Drink:
			continue
		var drink := child as Drink
		if drink.holder_peer_id == 0:
			continue
		var holder := y_sort.get_node_or_null(str(drink.holder_peer_id)) as Player
		if holder == null:
			drink.holder_peer_id = 0
			continue
		drink.global_position = holder.hands.global_position

func _on_peer_connected(peer_id: int) -> void:
	_spawn_player(peer_id)

func _spawn_player(peer_id: int) -> void:
	var player: Player = PLAYER_SCENE.instantiate()
	player.peer_id = peer_id
	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id)

	var spawn_pos := Vector2(100, 100)

	player.position = spawn_pos
	y_sort.add_child(player)

	_set_player_position.rpc_id(peer_id, spawn_pos)

var _next_spawn_index := 0

@rpc("authority", "reliable")
func _set_player_position(pos: Vector2) -> void:
	var my_id := str(multiplayer.get_unique_id())
	var player := y_sort.get_node_or_null(my_id)
	if player:
		player.global_position = pos
	else:
		await get_tree().process_frame
		player = y_sort.get_node_or_null(my_id)
		if player:
			player.global_position = pos

func _remove_player(peer_id: int) -> void:
	var player := y_sort.get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
	for child in get_children():
		if child is Drink and (child as Drink).holder_peer_id == peer_id:
			(child as Drink).holder_peer_id = 0

func _on_player_spawned(node: Node) -> void:
	print("_on_player_spawned fired for: ", node.name)
	var pid := int(node.name)
	node.set_multiplayer_authority(pid)
	if pid == multiplayer.get_unique_id():
		_init_local_player(node as Player)

func _init_local_player(player: Player) -> void:
	if local_player != null:
		return

	print("Initializing local player for peer: ", multiplayer.get_unique_id())
	local_player = player
	local_player.player_data = PlayerData.new()
	local_player.player_data.stats_changed.connect(_update_stats)
	local_player.pickup_requested.connect(_on_pickup_requested)
	local_player.drop_requested.connect(_on_drop_requested)
	local_player.drink_action_requested.connect(_on_drink_action_requested)
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
		handle_drink_spawn(item.name, item.flavor, item.cost, item.alcohol, item.sprite)
	else:
		_spawn_drink.rpc_id(1, item.name, item.flavor, item.cost, item.alcohol, item.sprite)

func _on_pickup_requested(drink_name: String) -> void:
	if multiplayer.is_server():
		_handle_pickup(multiplayer.get_unique_id(), drink_name)
	else:
		_request_pickup.rpc_id(1, drink_name)

func _on_drop_requested(
	drink_name: String, 
	drop_pos: Vector2, 
	z_index: int,
) -> void:
	if multiplayer.is_server():
		_handle_drop(multiplayer.get_unique_id(), drink_name, drop_pos, z_index)
	else:
		_request_drop.rpc_id(1, drink_name, drop_pos, z_index)

func _on_drink_action_requested(drink_name: String) -> void:
	if multiplayer.is_server():
		_handle_drink_action(multiplayer.get_unique_id(), drink_name)
	else:
		_request_drink_action.rpc_id(1, drink_name)

@rpc("any_peer", "reliable")
func _spawn_drink(
	drink_name: String,
	flavor: String,
	cost: float,
	alcohol: float,
	sprite: int,
) -> void:
	if not multiplayer.is_server():
		return
	handle_drink_spawn(drink_name, flavor, cost, alcohol, sprite)

@rpc("any_peer", "reliable")
func _request_pickup(drink_name: String) -> void:
	if not multiplayer.is_server():
		return
	_handle_pickup(multiplayer.get_remote_sender_id(), drink_name)

@rpc("any_peer", "reliable")
func _request_drop(drink_name: String, drop_pos: Vector2, z_index: int) -> void:
	if not multiplayer.is_server():
		return
	_handle_drop(multiplayer.get_remote_sender_id(), drink_name, drop_pos, z_index)

@rpc("any_peer", "reliable")
func _request_drink_action(drink_name: String) -> void:
	if not multiplayer.is_server():
		return
	_handle_drink_action(multiplayer.get_remote_sender_id(), drink_name)

func handle_drink_spawn(
	drink_name: String,
	flavor: String,
	cost: float,
	alcohol: float,
	sprite: int,
) -> void:
	var drink: Drink = DRINK_SCENE.instantiate()
	drink.drink_name = drink_name
	drink.flavor = flavor
	drink.cost = cost
	drink.alcohol = alcohol
	drink.sprite_frame = sprite
	drink.position = menu_item_spawn.position
	drink.set_multiplayer_authority(1)
	items.add_child(drink, true)

func _handle_pickup(peer_id: int, drink_name: String) -> void:
	var drink := items.get_node_or_null(drink_name) as Drink
	if drink == null or drink.holder_peer_id != 0:
		return
	drink.holder_peer_id = peer_id

func _handle_drop(
	peer_id: int, 
	drink_name: String, 
	drop_pos: Vector2, 
	z_index: int,
) -> void:
	var drink := items.get_node_or_null(drink_name) as Drink
	if drink == null or drink.holder_peer_id != peer_id:
		return
	drink.holder_peer_id = 0
	drink.global_position = drop_pos
	print(z_index)
	drink.z_index = z_index

func _handle_drink_action(peer_id: int, drink_name: String) -> void:
	var drink := items.get_node_or_null(drink_name) as Drink
	if drink == null or drink.holder_peer_id != peer_id:
		return
	if drink.parts == 0:
		return
	drink.parts -= 1
	if drink.parts == 0:
		drink.holder_peer_id = 0
		drink.queue_free()
