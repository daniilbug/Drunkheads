@tool
class_name GroceryDisplayRow
extends Resource

## Left edge and surface height, relative to the furniture's origin at its feet.
@export var baseline := Vector2i.ZERO:
	set(value):
		baseline = value
		emit_changed()
@export_range(1, 256) var width := 30:
	set(value):
		width = value
		emit_changed()
@export_range(0, 16) var gap := 1:
	set(value):
		gap = value
		emit_changed()
@export var repeat_to_fill := true:
	set(value):
		repeat_to_fill = value
		emit_changed()
@export var products: Array[PackedScene] = []:
	set(value):
		products = value
		emit_changed()
