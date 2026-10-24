extends Level

var _has_players := false


func _ready() -> void:
	player_spawn = $PlayerSpawn
	super._ready()
	set_physics_process(multiplayer.is_server())


func _physics_process(_delta: float) -> void:
	var occupied := get_players().any(func(player: Player):
		return player.level_id == level_id and not player.is_queued_for_deletion())
	if occupied and not _has_players and $Store.restock_empty_slots() > 0:
		var main := get_parent() as Main
		if main != null:
			main.world_save.request_save()
	_has_players = occupied


func get_save_data() -> Dictionary:
	var data := super.get_save_data()
	data.clothing_stock_version = 1
	return data


func prepare_save_restore(data: Dictionary) -> void:
	var restored := data.duplicate(true)
	# Browsing-only checkpoints predate the physical garments; seed their stock once.
	if not data.has("clothing_stock_version"):
		for child in get_children():
			if child is ShopGarment:
				restored.items.append(child.get_save_data())
	super.prepare_save_restore(restored)
