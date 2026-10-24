@tool
extends Room

var _next_garment_id := 0


func init_room() -> void:
	if not multiplayer.is_server():
		return
	for slot: ClothingSlot in find_children("*", "ClothingSlot", true, false):
		if slot.generates_stock and slot.initial_item.x >= 0:
			_spawn_garment(slot, slot.initial_item, slot.is_top)
	restock()


func restock() -> void:
	if not multiplayer.is_server():
		return
	var tops: Array[Vector2i] = []
	var bottoms: Array[Vector2i] = []
	for style in CharacterSprite.TOP_TEXTURES.size():
		for color in CharacterSprite.CLOTHING_COLORS.size():
			tops.append(Vector2i(style, color))
	for style in CharacterSprite.PANTS_TEXTURES.size():
		for color in CharacterSprite.CLOTHING_COLORS.size():
			bottoms.append(Vector2i(style, color))
	for garment in Level.find_level_node(self).get_children():
		if garment is ShopGarment and not garment.is_queued_for_deletion():
			(tops if garment.is_top else bottoms).erase(garment.item)
	tops.shuffle()
	bottoms.shuffle()
	for slot: ClothingSlot in find_children("*", "ClothingSlot", true, false):
		if not slot.generates_stock or slot.get_garment() != null:
			continue
		var is_top := randf() < 0.5 if slot.allow_any_clothing else slot.is_top
		var available := tops if is_top else bottoms
		if not available.is_empty():
			_spawn_garment(slot, available.pop_back(), is_top)


func _spawn_garment(slot: ClothingSlot, item: Vector2i, is_top: bool) -> void:
	var level := Level.find_level_node(self)
	while level.has_node("ShopGarment%d" % _next_garment_id):
		_next_garment_id += 1
	var garment := load("res://scenes/room/clothing_store/garment.tscn").instantiate() as ShopGarment
	garment.name = "ShopGarment%d" % _next_garment_id
	_next_garment_id += 1
	garment.is_top = is_top
	garment.item = item
	garment.discount_percent = slot.stock_discount_percent
	garment.dock_path = slot.get_path()
	garment.position = level.to_local(slot.shape.global_position)
	level.add_child(garment)
