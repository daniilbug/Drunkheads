class_name NPCManager
extends Node2D

signal npc_added(npc: NPC)

const NPC_SCENE := preload("res://scenes/core/npc/npc.tscn")

@export_range(5, 32) var population_size := 12

var _spawn_interval := 0.0
var _spawn_timer := 0.0
var _max_npcs := 0
var _npc_count := 0
var _replace_on_exit := true
var _next_npc_id := -1
var _profiles: Array[NPCProfile] = []
@onready var _level: Level = Level.find_level_node(self)

func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_forget_guest)

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
	npc.profile = _assign_profile(npc)
	_next_npc_id -= 1
	npc.position = _level.to_local(route.spawn_position)
	_level._init_npc(npc)
	_level.add_child(npc)
	_npc_count += 1
	npc.tree_exited.connect(_on_npc_exited.bind(npc.profile), CONNECT_ONE_SHOT)
	npc_added.emit(npc)

func _on_npc_exited(profile: NPCProfile) -> void:
	profile.active = false
	_npc_count -= 1
	if _replace_on_exit and is_inside_tree() and not is_queued_for_deletion():
		call_deferred("_spawn_npc")

func _assign_profile(npc: NPC) -> NPCProfile:
	var available := _profiles.filter(func(profile: NPCProfile): return not profile.active)
	if _profiles.size() < maxi(population_size, _max_npcs):
		available.append(null)
	var profile: NPCProfile = available.pick_random()
	if profile == null:
		profile = NPCProfile.create(npc)
		_profiles.append(profile)
	else:
		profile.apply_appearance(npc)
	profile.active = true
	return profile

func _forget_guest(peer_id: int) -> void:
	for profile in _profiles:
		profile.forget_guest(peer_id)

func get_save_data() -> Dictionary:
	return {"profiles": _profiles.map(func(profile: NPCProfile): return profile.get_save_data())}

func can_restore_save_data(data: Dictionary) -> bool:
	if not SaveGraph.matches(data, {"profiles": []}) or data.profiles.size() > 32:
		return false
	return data.profiles.all(NPCProfile.is_valid_save)

func apply_save_data(data: Dictionary) -> void:
	if not multiplayer.is_server() or not can_restore_save_data(data):
		return
	# Existing instances are transient; newly spawned ones use the restored profiles.
	for child in _level.get_children():
		if child is NPC:
			if child.route != null:
				child.route.cleanup()
			child.queue_free()
	_profiles.clear()
	for saved: Dictionary in data.profiles:
		_profiles.append(NPCProfile.from_save(saved))
