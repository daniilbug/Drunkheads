@tool
class_name GroceryDisplayStock
extends Resource

@export var rows: Array[GroceryDisplayRow] = []:
	set(value):
		for row in rows:
			if row != null and row.changed.is_connected(emit_changed):
				row.changed.disconnect(emit_changed)
		rows = value
		for row in rows:
			if row != null and not row.changed.is_connected(emit_changed):
				row.changed.connect(emit_changed)
		emit_changed()
