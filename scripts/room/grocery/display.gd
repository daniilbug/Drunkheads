@tool
class_name GroceryDisplay
extends StaticBody2D

## Decorative stock is built identically on every peer from scene resources.
## Taking products and changing stock during play require a separate server flow.
@export var stock: GroceryDisplayStock:
	set(value):
		if stock != null and stock.changed.is_connected(_update_stock):
			stock.changed.disconnect(_update_stock)
		stock = value
		if stock != null and not stock.changed.is_connected(_update_stock):
			stock.changed.connect(_update_stock)
		_update_stock()


func _ready() -> void:
	_update_stock()


func _update_stock() -> void:
	if not is_node_ready():
		return
	for child in $Products.get_children():
		child.free()
	if stock == null:
		return
	for row_index in stock.rows.size():
		var row := stock.rows[row_index]
		if row == null or row.products.is_empty():
			continue
		var x := 0
		var index := 0
		while x < row.width:
			var scene := row.products[index % row.products.size()]
			if scene == null:
				break
			var instance := scene.instantiate()
			var product := instance as GroceryProduct
			if product == null:
				instance.free()
				push_warning("Grocery display requires a GroceryProduct scene.")
				break
			var product_width := product.get_display_width()
			if product_width <= 0 or x + product_width > row.width:
				product.free()
				break
			product.name = "Row%dProduct%d" % [row_index, index]
			product.position = Vector2(row.baseline) + Vector2(x, 0)
			$Products.add_child(product)
			x += product_width + row.gap
			index += 1
			if not row.repeat_to_fill and index >= row.products.size():
				break
