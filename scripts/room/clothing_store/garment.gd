class_name ShopGarment
extends Draggable

@export var is_top := true
@export var style_id := 0
@export var color_id := 0
@export_range(0, 100, 1) var discount_percent := 0:
	set(value):
		discount_percent = value
		if is_node_ready() and not dock_path.is_empty():
			var slot := get_node_or_null(dock_path) as ClothingSlot
			if slot != null:
				slot.contents_changed.emit()
var item: Vector2i:
	get:
		return Vector2i(style_id, color_id)
	set(value):
		style_id = value.x
		color_id = value.y
var _used_height := 0.0

@export var dock_path: NodePath:
	set(value):
		var previous := get_node_or_null(dock_path) if is_inside_tree() and not dock_path.is_empty() else null
		dock_path = value
		if is_node_ready():
			if previous is ClothingSlot:
				previous.contents_changed.emit()
			var slot := get_node_or_null(dock_path) if not dock_path.is_empty() else null
			if slot is ClothingSlot and slot != previous:
				slot.contents_changed.emit()


func _ready() -> void:
	var textures := CharacterSprite.TOP_TEXTURES if is_top else CharacterSprite.PANTS_TEXTURES
	sprite.texture = CharacterSprite.garment_icon(textures[item.x])
	var used := sprite.texture.get_image().get_used_rect()
	_used_height = used.size.y
	sprite.offset.y = sprite.texture.get_height() / 2.0 - used.position.y
	(sprite.material as ShaderMaterial).set_shader_parameter("clothing_color", CharacterSprite.CLOTHING_COLORS[item.y])
	if multiplayer.is_server() and not dock_path.is_empty():
		var slot := get_node_or_null(dock_path) as ClothingSlot
		if slot != null:
			super.drop(null, slot)
			slot.contents_changed.emit()


func _process(delta: float) -> void:
	super._process(delta)
	$Area.position = sprite.position + Vector2(0, _used_height * 0.5)


func can_pickup(player: Player) -> bool:
	return super.can_pickup(player) and player.level_id == _level.level_id and not player.in_vehicle


func _local_pickup(player_id: int) -> bool:
	if not super._local_pickup(player_id):
		return false
	dock_path = NodePath()
	return true


func place_nearby(player: Player, areas: Array[Area2D]) -> void:
	var nearest: ClothingSlot
	for area in areas:
		var slot := area.get_parent() as ClothingSlot
		if slot != null and slot.accepts(self) and (nearest == null or player.global_position.distance_squared_to(slot.shape.global_position) < player.global_position.distance_squared_to(nearest.shape.global_position)):
			nearest = slot
	if nearest != null:
		drop(player, nearest)


func drop(player: Player, place: DropPlace) -> void:
	if multiplayer.is_server():
		_dock_result(int(player.name), _dock(int(player.name), place.get_path()))
	else:
		_request_dock.rpc_id(1, place.get_path())


@rpc("any_peer", "reliable")
func _request_dock(path: NodePath) -> void:
	if multiplayer.is_server():
		var peer_id := multiplayer.get_remote_sender_id()
		_dock_result.rpc_id(peer_id, peer_id, _dock(peer_id, path))


func _dock(peer_id: int, path: NodePath) -> bool:
	var player := _level.get_player(peer_id)
	var slot := get_node_or_null(path) as ClothingSlot
	if player == null or holder_peer_id != peer_id or player.level_id != _level.level_id or player.in_vehicle:
		return false
	if slot == null or Level.find_level_node(slot) != _level or not slot.area.overlaps_area(player.interaction_area) or not slot.accepts(self):
		return false
	super.drop(player, slot)
	dock_path = slot.get_path()
	return true


@rpc("authority", "reliable")
func _dock_result(peer_id: int, accepted: bool) -> void:
	var player := _level.get_player(peer_id)
	if accepted and player != null and player._hands_item == self:
		player._hands_item = null


# Garments use the validated slot request, never client-supplied coordinates.
@rpc("any_peer", "reliable")
func _remote_drop(_player_id: int, _sort_pos: Vector2, _visual_pos: Vector2) -> void:
	pass


func _exit_tree() -> void:
	var slot := get_node_or_null(dock_path) if not dock_path.is_empty() else null
	if slot is ClothingSlot:
		slot.contents_changed.emit()


func get_save_schema() -> Dictionary:
	return {"is_top": true, "style_id": Vector2i(0, maxi(CharacterSprite.TOP_TEXTURES.size(), CharacterSprite.PANTS_TEXTURES.size()) - 1), "color_id": Vector2i(0, CharacterSprite.CLOTHING_COLORS.size() - 1), "dock_path": NodePath()}


func get_save_data() -> Dictionary:
	var data := super.get_save_data()
	if not data.is_empty():
		# Optional in older saves; validate it separately in can_restore_save_data().
		data.fields.discount_percent = discount_percent
		if not dock_path.is_empty():
			data.fields.dock_path = _level.get_path_to(get_node(dock_path))
	return data


func apply_save_data(data: Dictionary) -> void:
	var restored := data.duplicate(true)
	discount_percent = restored.fields.get("discount_percent", 0)
	if not restored.fields.dock_path.is_empty():
		restored.fields.dock_path = NodePath(str(_level.get_path()) + "/" + str(restored.fields.dock_path))
	super.apply_save_data(restored)


func can_restore_save_data(fields: Dictionary, saved_level: Node2D) -> bool:
	if not super.can_restore_save_data(fields, saved_level) or not SaveGraph.matches(fields.get("discount_percent", 0), Vector2i(0, 100)) \
		or not ClothingShop.is_valid_item(fields.is_top, Vector2i(fields.style_id, fields.color_id)):
		return false
	if fields.dock_path.is_empty():
		return true
	var slot := saved_level.get_node_or_null(fields.dock_path) as ClothingSlot if SaveGraph.safe_path(fields.dock_path) else null
	return slot != null and (slot.allow_any_clothing or slot.is_top == fields.is_top)
