extends Level

func _ready() -> void:
	player_spawn = $PlayerSpawn
	super._ready()


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
	var restored := data.duplicate(true)
	# Browsing-only checkpoints predate the physical garments; seed their stock once.
	if not data.has("clothing_stock_version"):
		for child in get_children():
			if child is ShopGarment:
				restored.items.append(child.get_save_data())
	super.prepare_save_restore(restored)
