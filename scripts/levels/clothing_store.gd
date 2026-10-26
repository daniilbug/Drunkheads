extends Level

func _ready() -> void:
	player_spawn = $PlayerSpawn
	$NPCManager.configure(10.0, false)
	super._ready()
	$StreetNavigation.bake_navigation_polygon(false)


func create_npc_route() -> NPCRoute:
	var start: Vector2 = $NPCPath/Left.global_position
	var finish: Vector2 = $NPCPath/Right.global_position
	if randf() < 0.5:
		return NPCWalkRoute.new(start, finish)
	return NPCWalkRoute.new(finish, start)


func cleanup() -> void:
	if not multiplayer.is_server():
		return
	for child in get_children():
		if child is ShopGarment:
			child.queue_free()
	$Store.restock()


func get_save_data() -> Dictionary:
	var data := super.get_save_data()
	data.clothing_stock_version = 1
	return data


func prepare_save_restore(data: Dictionary) -> void:
	var restored := _migrate_save(data)
	# Browsing-only checkpoints predate the physical garments; seed their stock once.
	if not data.has("clothing_stock_version"):
		for child in get_children():
			if child is ShopGarment:
				restored.items.append(child.get_save_data())
	super.prepare_save_restore(restored)


func apply_save_data(data: Dictionary) -> void:
	super.apply_save_data(_migrate_save(data))


func can_restore_save_data(data: Dictionary) -> bool:
	return super.can_restore_save_data(_migrate_save(data))


func _migrate_save(data: Dictionary) -> Dictionary:
	var restored := data.duplicate(true)
	# The removed barber sink may still be present in earlier checkpoints.
	restored.objects.erase(^"BarberRoom/NavigationRegion/YSort/Sink")
	return restored
