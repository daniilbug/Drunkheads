class_name CafeMenu
extends OrderMenu

static var coffee_menu: Array[BarMenuItem] = [
	BarMenuItem.new("Espresso", BarMenuItem.Type.COFFEE, "Small, rich and aromatic. Restores 8 Mind.", 6.0, 0, 0, 4),
	BarMenuItem.new("Americano", BarMenuItem.Type.COFFEE, "A long black coffee. Restores 8 Mind.", 8.0, 0, 1, 4),
	BarMenuItem.new("Cappuccino", BarMenuItem.Type.COFFEE, "Espresso with silky milk foam. Restores 8 Mind.", 10.0, 0, 2, 4),
]

func _get_initial_items() -> Array[BarMenuItem]:
	return coffee_menu
