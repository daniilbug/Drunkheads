class_name WorldSave
extends Node

signal restored(player: Player)

## Coordinates host checkpoints. Levels and objects own their saved fields.
@onready var _world: Main = get_parent()
var _requested := false

func request_save() -> void:
	if multiplayer.is_server():
		_requested = true

func _process(_delta: float) -> void:
	if not _requested or not is_instance_valid(_world.local_player):
		return
	if not _world.transport.is_travel_complete(_world.local_player) or _world.local_player._smoking:
		return
	_requested = false
	var saved := SaveManager.write_snapshot(capture())
	$SaveStatus/Message.text = SaveManager.last_error
	$SaveStatus/Message.visible = not saved
	if not saved:
		push_warning(SaveManager.last_error)

func capture() -> Dictionary:
	var levels := {}
	for level in _world.get_levels():
		levels[level.level_id] = level.get_save_data()
	return {
		"player": _world.local_player.get_save_data(), "levels": levels,
		"clock": _world.world_time.get_save_data(), "headphones": _world.headphone_player.get_save_data(),
	}

func restore_world(snapshot: Dictionary) -> void:
	_world.world_time.apply_save_data(snapshot.clock)
	# Build every level first, then restore fields and references between objects.
	for level in _world.get_levels():
		level.prepare_save_restore(snapshot.levels[level.level_id])
	for level in _world.get_levels():
		level.apply_save_data(snapshot.levels[level.level_id])
	_world.headphone_player.apply_save_data(snapshot.headphones)
	restored.emit(_world.local_player)

func can_restore(snapshot: Dictionary) -> bool:
	if snapshot.levels.size() != _world.get_levels().size():
		return false
	for id in snapshot.levels:
		var level := _world.get_level(id)
		if level == null or not level.can_restore_save_data(snapshot.levels[id]):
			return false
	return true

static func is_valid_snapshot(snapshot: Dictionary) -> bool:
	if not SaveGraph.matches(snapshot, {
		"player": Player.SAVE_SCHEMA, "clock": WorldTime.SAVE_SCHEMA,
		"headphones": HeadphonePlayer.SAVE_SCHEMA, "levels": {},
	}):
		return false
	if snapshot.player.level_id not in snapshot.levels or snapshot.player.return_level_id not in snapshot.levels:
		return false
	for id in snapshot.levels:
		if not id is String or id.is_empty() or not SaveGraph.is_valid_level(snapshot.levels[id]):
			return false
	return true
