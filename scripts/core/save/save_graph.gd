class_name SaveGraph
extends RefCounted

## Saveable nodes expose get_save_data()/apply_save_data() and join "saveable".
## Tree ownership identifies objects; references are restored after all spawns.
const ITEM_SCHEMA := {"scene": "", "name": "", "path": NodePath(), "position": Vector2.ZERO, "sprite_position": Vector2.ZERO, "holder_peer_id": 0, "fields": {}}
static var _item_schemas: Dictionary = {}

static func nodes(root: Node) -> Array[Node]:
	var result: Array[Node] = []
	for child in root.get_children():
		if child.is_queued_for_deletion() or child is Player or child is Vehicle:
			continue
		if child.is_in_group("saveable"):
			result.append(child)
		if child is not Draggable:
			result.append_array(nodes(child))
	return result

static func capture(level: Node2D) -> Dictionary:
	var data := {"items": [], "objects": {}}
	for node in nodes(level):
		var state: Dictionary = node.get_save_data()
		if state.is_empty():
			continue
		if node is Draggable:
			data.items.append(state)
		else:
			data.objects[level.get_path_to(node)] = state
	return data

static func prepare_restore(level: Node2D, data: Dictionary) -> void:
	var paths: Array = data.items.map(func(item: Dictionary): return item.path)
	for node in nodes(level):
		if node is Draggable and level.get_path_to(node) not in paths:
			node.get_parent().remove_child(node)
			node.queue_free()
	for saved: Dictionary in data.items:
		if level.has_node(saved.path):
			continue
		var item := (load(saved.scene) as PackedScene).instantiate() as Draggable
		item.name = saved.name
		# Initialize replicated spawn values before entering the tree.
		item.position = saved.position
		item.get_node("Sprite").position = saved.sprite_position
		item.holder_peer_id = saved.holder_peer_id
		apply_fields(item, item.get_save_schema().keys(), saved.fields)
		var parent_path := str(saved.path).get_base_dir()
		var parent := level if parent_path.is_empty() else level.get_node(NodePath(parent_path))
		parent.add_child(item)

static func restore(level: Node2D, data: Dictionary) -> void:
	for saved: Dictionary in data.items:
		level.get_node(saved.path).apply_save_data(saved)
	for path: NodePath in data.objects:
		level.get_node(path).apply_save_data(data.objects[path])

static func can_restore(level: Node2D, data: Dictionary) -> bool:
	for saved: Dictionary in data.items:
		var parent_path := str(saved.path).get_base_dir()
		var parent := level if parent_path.is_empty() else level.get_node_or_null(NodePath(parent_path))
		var existing := level.get_node_or_null(saved.path)
		if parent == null or (existing != null and (existing is not Draggable or existing.scene_file_path != saved.scene)):
			return false
		if existing == null and not _can_spawn(level, parent, saved.scene):
			return false
		var item := existing as Draggable
		if item == null:
			item = (load(saved.scene) as PackedScene).instantiate() as Draggable
		var valid := item.can_restore_save_data(saved.fields, level)
		if existing == null:
			item.free()
		if not valid:
			return false
	for path in data.objects:
		var node := level.get_node_or_null(path)
		if node == null or not node.is_in_group("saveable") or node is Draggable:
			return false
		var valid: bool = node.can_restore_save_data(data.objects[path]) if node.has_method("can_restore_save_data") \
			else matches(data.objects[path], node.get_save_data())
		if not valid:
			return false
	return true

static func _can_spawn(level: Node, parent: Node, scene: String) -> bool:
	for spawner in level.find_children("*", "MultiplayerSpawner", true, false):
		if spawner.get_node(spawner.spawn_path) != parent:
			continue
		for index in spawner.get_spawnable_scene_count():
			if load(spawner.get_spawnable_scene(index)).resource_path == scene:
				return true
	return false

static func is_valid_level(data: Variant) -> bool:
	if not matches(data, {"items": [], "objects": {}}):
		return false
	var paths := {}
	for item in data.items:
		if not matches(item, ITEM_SCHEMA) or not safe_path(item.path) or not item.name.is_valid_identifier() \
			or str(item.path).get_file() != item.name or paths.has(item.path) or item.holder_peer_id not in [0, 1]:
			return false
		var schema: Variant = _item_schema(item.scene)
		if schema == null or not matches(item.fields, schema):
			return false
		paths[item.path] = true
	for path in data.objects:
		if not safe_path(path) or not data.objects[path] is Dictionary:
			return false
	return true

static func _item_schema(scene_path: String) -> Variant:
	if not _item_schemas.has(scene_path):
		if not scene_path.begins_with("res://scenes/") or scene_path.get_extension() != "tscn" or not ResourceLoader.exists(scene_path):
			return null
		var scene := load(scene_path) as PackedScene
		if scene == null:
			return null
		var node := scene.instantiate()
		var schema: Variant = node.get_save_schema() if node is Draggable else null
		node.free()
		_item_schemas[scene_path] = schema
	return _item_schemas[scene_path]

static func get_fields(object: Object, fields: Array) -> Dictionary:
	var data := {}
	for field in fields:
		data[field] = object.get(field)
	return data

static func apply_fields(object: Object, fields: Array, data: Dictionary) -> void:
	for field in fields:
		if data.has(field) and matches(data[field], object.get(field)):
			object.set(field, data[field])

static func safe_path(path: Variant) -> bool:
	return path is NodePath and not path.is_empty() and not path.is_absolute() and path.get_subname_count() == 0 and ".." not in str(path)

## Arrays enumerate values; Vector2i defines an inclusive integer range.
static func matches(value: Variant, template: Variant) -> bool:
	if template is Array and not template.is_empty():
		return typeof(value) == typeof(template[0]) and value in template
	if template is Vector2i:
		return value is int and value >= template.x and value <= template.y
	if typeof(value) != typeof(template):
		return false
	if template is Dictionary:
		for key in template:
			if not value.has(key) or not matches(value[key], template[key]):
				return false
	if value is float:
		return is_finite(value)
	if value is Vector2:
		return value.is_finite()
	return true
