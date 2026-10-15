@tool
class_name HomeToiletRoom
extends Room

## Render layer 3 isolates the toilet interior from the apartment's lights.
@export_flags_2d_render var interior_light_mask: int = 4

@onready var _lighting_zone: Area2D = $LightingZone

var _original_light_masks: Dictionary[int, int] = {}

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var active: Dictionary[int, bool] = {}
	var bounds := Rect2(Vector2.ZERO, room_size)
	for body in _lighting_zone.get_overlapping_bodies():
		if body is Player and bounds.has_point(to_local(body.global_position)):
			_mask_visuals(body, active)
	for area in _lighting_zone.get_overlapping_areas():
		var item := area.get_parent() as Draggable
		if item == null:
			continue
		var position := item.sprite.global_position
		if item.holder_peer_id != 0:
			var level := Level.find_level_node(item)
			var holder := level.get_player(item.holder_peer_id) if level != null else null
			if holder != null:
				position = holder.global_position
		if bounds.has_point(to_local(position)):
			_mask_visuals(item, active)
	for instance_id in _original_light_masks.keys():
		var target := instance_from_id(instance_id) as CanvasItem
		if target == null:
			_original_light_masks.erase(instance_id)
		elif not active.has(instance_id):
			target.light_mask = _original_light_masks[instance_id]
			_original_light_masks.erase(instance_id)

func _mask_visuals(node: Node, active: Dictionary[int, bool]) -> void:
	if node is CanvasItem:
		var target := node as CanvasItem
		var instance_id := target.get_instance_id()
		if not _original_light_masks.has(instance_id):
			_original_light_masks[instance_id] = target.light_mask
		target.light_mask = interior_light_mask
		active[instance_id] = true
	for child in node.get_children():
		_mask_visuals(child, active)

func _exit_tree() -> void:
	for instance_id in _original_light_masks:
		var target := instance_from_id(instance_id) as CanvasItem
		if target != null:
			target.light_mask = _original_light_masks[instance_id]
	_original_light_masks.clear()
