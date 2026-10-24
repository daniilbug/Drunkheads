@tool
extends Room

var _next_garment_id := 0


func init_room() -> void:
	if not multiplayer.is_server():
		return
	for slot: ClothingSlot in find_children("*", "ClothingSlot", true, false):
		if slot.initial_item.x >= 0:
			_spawn_garment(slot, slot.initial_item)


func restock_empty_slots() -> int:
	if not multiplayer.is_server():
		return 0
	var tops: Array[Vector2i] = []
	var bottoms: Array[Vector2i] = []
	for style in CharacterSprite.TOP_TEXTURES.size():
		for color in CharacterSprite.CLOTHING_COLORS.size():
			tops.append(Vector2i(style, color))
	for style in CharacterSprite.PANTS_TEXTURES.size():
		for color in CharacterSprite.CLOTHING_COLORS.size():
			bottoms.append(Vector2i(style, color))
	# Include garments in hands, fitting rooms and at checkout to avoid repeating them.
	var level := Level.find_level_node(self)
	for child in level.get_children():
		if child is ShopGarment and not child.is_queued_for_deletion():
			(tops if child.is_top else bottoms).erase(child.item)
	tops.shuffle()
	bottoms.shuffle()
	var added := 0
	for slot: ClothingSlot in find_children("*", "ClothingSlot", true, false):
		# Only trade displays have initial stock; checkout and fitting slots stay empty.
		if slot.initial_item.x < 0 or slot.get_garment() != null:
			continue
		var available := tops if slot.is_top else bottoms
		if not available.is_empty():
			_spawn_garment(slot, available.pop_back())
			added += 1
	return added


func _spawn_garment(slot: ClothingSlot, item: Vector2i) -> void:
	var level := Level.find_level_node(self)
	while level.has_node("ShopGarment%d" % _next_garment_id):
		_next_garment_id += 1
	var garment := load("res://scenes/room/clothing_store/garment.tscn").instantiate() as ShopGarment
	garment.name = "ShopGarment%d" % _next_garment_id
	_next_garment_id += 1
	garment.is_top = slot.is_top
	garment.item = item
	garment.dock_path = slot.get_path()
	garment.position = level.to_local(slot.shape.global_position)
	level.add_child(garment)
