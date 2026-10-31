class_name CafeMenu
extends OrderMenu

static var coffee_menu: Array[CafeMenuItem] = [
	CafeMenuItem.new("Espresso", "Small, rich and aromatic. Restores 8 Mind.", 6.0, 0, 4),
	CafeMenuItem.new("Americano", "A long black coffee. Restores 8 Mind.", 8.0, 1, 4),
	CafeMenuItem.new("Cappuccino", "Espresso with silky milk foam. Restores 8 Mind.", 10.0, 2, 4),
]

func _get_initial_items() -> Array[OrderMenuItem]:
	var items: Array[OrderMenuItem] = []
	items.assign(coffee_menu)
	return items
