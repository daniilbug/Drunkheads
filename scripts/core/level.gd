class_name Level
extends Node2D

const PLAYER_SCENE := preload("res://scenes/core/player.tscn")

static func find_level_node(node: Node2D) -> Level:
	var result: Node2D = null
	var current := node
	while current.get_parent() != null:
		var parent := current.get_parent()
		if parent is not Level:
			current = parent
		else:
			return parent
	return null

@onready var spawner: MultiplayerSpawner = $Spawner
var player_spawn: Node2D

var local_player: Player = null
var _name_registry: Dictionary = {}  # peer_id -> final display name (server only)

func _ready() -> void:
	spawner.spawned.connect(_on_spawned)
	child_entered_tree.connect(_on_child_entered_tree)
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_remove_player)
		_spawn_player(multiplayer.get_unique_id())
		_init_local_player(get_node(str(multiplayer.get_unique_id())) as Player)
		_register_player_setup(multiplayer.get_unique_id(), Player.local_setup)
	for child in get_children():
		if child is Room:
			child.init_room()

func _on_child_entered_tree(node: Node) -> void:
	if node is Draggable:
		node.pickup_requested.connect(_on_pickup_requested)
		node.drop_requested.connect(_on_drop_requested)
		node.set_multiplayer_authority(1)

func _on_peer_connected(peer_id: int) -> void:
	_spawn_player(peer_id)

func _spawn_player(peer_id: int) -> void:
	var player: Player = PLAYER_SCENE.instantiate()
	player.name = str(peer_id)
	player.set_multiplayer_authority(peer_id)
	add_child(player)
	player.global_position = player_spawn.global_position

func _on_spawned(node: Node) -> void:
	if node is Player:
		var pid := int(node.name)
		node.set_multiplayer_authority(pid)
		if pid == multiplayer.get_unique_id():
			node.global_position = player_spawn.global_position
			_init_local_player(node)
			_request_player_setup.rpc_id(1, Player.local_setup)

func _remove_player(peer_id: int) -> void:
	_name_registry.erase(peer_id)
	var player := get_node_or_null(str(peer_id))
	if player:
		player.queue_free()
	for child in get_children():
		if child is Draggable and (child as Draggable).holder_peer_id == peer_id:
			child.holder_peer_id = 0

func _init_local_player(player: Player) -> void:
	if local_player != null:
		return
	player.player_data = PlayerData.new()
	local_player = player

func _process(_delta: float) -> void:
	if not multiplayer.is_server():
		return
	for child in get_children():
		if not child is Draggable:
			continue
		var draggable := child as Draggable
		if draggable.holder_peer_id == 0:
			continue
		var holder := get_node_or_null(str(draggable.holder_peer_id)) as Player
		if holder == null:
			draggable.holder_peer_id = 0
			continue
		var hands_pos := holder.hands.global_position
		if holder.direction.y < 0:
			draggable.global_position = hands_pos
			draggable.sprite.position = Vector2.ZERO
		else:
			draggable.global_position = Vector2(hands_pos.x, holder.global_position.y + 5.0)
			draggable.sprite.position = draggable.to_local(hands_pos)

func _on_pickup_requested(name: String) -> void:
	if multiplayer.is_server():
		_handle_pickup(multiplayer.get_unique_id(), name)
	else:
		_request_pickup.rpc_id(1, name)

func _on_drop_requested(name: String, sort_pos: Vector2, visual_pos: Vector2) -> void:
	if multiplayer.is_server():
		_handle_drop(multiplayer.get_unique_id(), name, sort_pos, visual_pos)
	else:
		_request_drop.rpc_id(1, name, sort_pos, visual_pos)

@rpc("any_peer", "reliable")
func _request_pickup(name: String) -> void:
	if not multiplayer.is_server():
		return
	_handle_pickup(multiplayer.get_remote_sender_id(), name)

@rpc("any_peer", "reliable")
func _request_drop(name: String, sort_pos: Vector2, visual_pos: Vector2) -> void:
	if not multiplayer.is_server():
		return
	_handle_drop(multiplayer.get_remote_sender_id(), name, sort_pos, visual_pos)

func _handle_pickup(peer_id: int, name: String) -> void:
	var draggable := get_node_or_null(name) as Draggable
	if draggable == null or draggable.holder_peer_id != 0:
		return
	draggable.sprite.position = Vector2.ZERO
	draggable.holder_peer_id = peer_id

func _handle_drop(peer_id: int, name: String, sort_pos: Vector2, visual_pos: Vector2) -> void:
	var draggable := get_node_or_null(name) as Draggable
	if draggable == null:
		return
	draggable.holder_peer_id = 0
	draggable.global_position = sort_pos
	draggable.sprite.position = draggable.to_local(visual_pos)

func _resolve_name(desired: String, exclude_peer: int) -> String:
	var base := desired.strip_edges()
	if base.is_empty():
		base = "Player"
	var taken: Array[String] = []
	for pid in _name_registry:
		if pid != exclude_peer:
			taken.append(_name_registry[pid])
	if base not in taken:
		return base
	var idx := 2
	while ("%s %d" % [base, idx]) in taken:
		idx += 1
	return "%s %d" % [base, idx]

func _register_player_setup(peer_id: int, setup: Dictionary) -> void:
	var final_name := _resolve_name(setup.get("name", "Player"), peer_id)
	_name_registry[peer_id] = final_name
	var final_setup := setup.duplicate()
	final_setup["name"] = final_name
	var player := get_node_or_null(str(peer_id)) as Player
	if player:
		player.rpc_apply_player_setup.rpc(final_setup)

@rpc("any_peer", "reliable")
func _request_player_setup(setup: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	_register_player_setup(multiplayer.get_remote_sender_id(), setup)
