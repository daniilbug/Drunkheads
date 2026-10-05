class_name NPCManager
extends Node2D

signal npc_added(npc: NPC)

const MAX_NPCS := 5
const SPAWN_INTERVAL := 10.0
const NPC_SCENE := preload("res://scenes/core/npc.tscn")

var _spawn_timer := 0.0
var _available_slots := MAX_NPCS
var _next_npc_id := -1
@onready var _level: Level = Level.find_level_node(self)
@onready var exit_point: Marker2D = $ExitPoint

func _ready() -> void:
	_spawn_timer = SPAWN_INTERVAL - 5.0

func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return

	_spawn_timer += delta
	if _spawn_timer >= SPAWN_INTERVAL:
		_spawn_timer = 0.0
		_spawn_npc()

func _spawn_npc() -> void:
	if not is_inside_tree() or not multiplayer.is_server() or not _level or _available_slots == 0:
		return

	var npc: NPC = NPC_SCENE.instantiate()
	npc.name = str(_next_npc_id)
	npc.randomize_appearance()
	_next_npc_id -= 1

	var spawn_point = _level.player_spawn
	npc.position = spawn_point.position

	_level.add_child(npc)
	_available_slots -= 1
	npc.tree_exited.connect(_on_npc_exited, CONNECT_ONE_SHOT)
	npc_added.emit(npc)

func _on_npc_exited() -> void:
	_available_slots = mini(_available_slots + 1, MAX_NPCS)
	if is_inside_tree() and not is_queued_for_deletion():
		call_deferred("_spawn_npc")
