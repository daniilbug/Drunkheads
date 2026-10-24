@tool
class_name ClothingSlot
extends DropPlace

signal contents_changed

@export var is_top := true
@export var allow_any_clothing := false
@export var generates_stock := false
@export_range(0, 100, 1) var stock_discount_percent := 0
var initial_item := Vector2i(-1, -1)


func get_garment() -> ShopGarment:
	var level := Level.find_level_node(self)
	if level != null:
		for child in level.get_children():
			if child is ShopGarment and child.is_inside_tree() and not child.is_queued_for_deletion() and child.dock_path == get_path() and child.holder_peer_id == 0:
				return child
	return null


func accepts(garment: ShopGarment) -> bool:
	return (allow_any_clothing or garment.is_top == is_top) and get_garment() == null
