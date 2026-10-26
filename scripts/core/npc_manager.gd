class_name NPCManager
extends Node2D

signal npc_added(npc: NPC)

const NPC_SCENE := preload("res://scenes/core/npc.tscn")

var _spawn_interval := 0.0
var _spawn_timer := 0.0
var _max_npcs := 0
var _npc_count := 0
var _replace_on_exit := true
var _next_npc_id := -1
@onready var _level: Level = Level.find_level_node(self)

func configure(interval: float, replace_on_exit: bool = true, initial_delay: float = 5.0, max_npcs: int = 5) -> void:
	_spawn_interval = interval
	_spawn_timer = interval - initial_delay
	_max_npcs = max_npcs
	_replace_on_exit = replace_on_exit

func _process(delta: float) -> void:
	if not multiplayer.is_server() or _spawn_interval <= 0.0:
		return

	_spawn_timer += delta
	if _spawn_timer >= _spawn_interval:
		_spawn_timer = 0.0
		_spawn_npc()

func _spawn_npc() -> void:
	if not is_inside_tree() or is_queued_for_deletion() or not multiplayer.is_server() or not _level or _level.is_queued_for_deletion() or _npc_count >= _max_npcs:
		return

	var route := _level.create_npc_route()
	if route == null:
		return
	var npc: NPC = NPC_SCENE.instantiate()
	npc.name = str(_next_npc_id)
	npc.route = route
	npc.level_id = _level.level_id
	npc.randomize_appearance()
	_next_npc_id -= 1
	npc.position = _level.to_local(route.spawn_position)
	_level._init_npc(npc)
	_level.add_child(npc)
	_npc_count += 1
	npc.tree_exited.connect(_on_npc_exited, CONNECT_ONE_SHOT)
	npc_added.emit(npc)

func _on_npc_exited() -> void:
	_npc_count -= 1
	if _replace_on_exit and is_inside_tree() and not is_queued_for_deletion():
		call_deferred("_spawn_npc")
