class_name BarMenu
extends OrderMenu

static var beer_menu: Array[BarMenuItem] = [
	BarMenuItem.new("Light Lager",  BarMenuItem.Type.BEER, "Crisp and watery. Goes down easy.",  8.0,  5, 0, 4),
	BarMenuItem.new("Pale Ale",     BarMenuItem.Type.BEER, "Hoppy with a citrus bite.",          12.0,  7, 1, 4),
	BarMenuItem.new("Dark Stout",   BarMenuItem.Type.BEER, "Thick and roasty. Almost a meal.",   14.0,  9, 2, 4),
	BarMenuItem.new("Strong IPA",   BarMenuItem.Type.BEER, "Bitter kick. Not for the faint.",    15.0, 10, 3, 4),
	BarMenuItem.new("Barleywine",   BarMenuItem.Type.BEER, "Dark and potent. Respect it.",       18.0, 13, 4, 4),
]

static var shots_menu: Array[BarMenuItem] = [
	BarMenuItem.new("Vodka",    BarMenuItem.Type.SHOT, "Clean. Cold. Ruthless.",          6.0,  8, 0, 1),
	BarMenuItem.new("Tequila",  BarMenuItem.Type.SHOT, "Salt, shot, lime. Classic.",      7.0,  9, 1, 1),
	BarMenuItem.new("Whiskey",  BarMenuItem.Type.SHOT, "Burns so good.",                  8.0, 10, 2, 1),
	BarMenuItem.new("Dark Rum", BarMenuItem.Type.SHOT, "Sweet on the way down.",          7.0,  9, 3, 1),
	BarMenuItem.new("Sambuca",  BarMenuItem.Type.SHOT, "Anise and fire. Bold choice.",    9.0, 12, 4, 1),
]

static var cocktails_menu: Array[BarMenuItem] = [
	BarMenuItem.new("Mojito",          BarMenuItem.Type.COCTAIL, "Mint, lime, rum. Refreshing.",       14.0,  8, 0, 5),
	BarMenuItem.new("Margarita",       BarMenuItem.Type.COCTAIL, "Tequila and citrus on the rocks.",   15.0,  9, 1, 5),
	BarMenuItem.new("Cosmopolitan",    BarMenuItem.Type.COCTAIL, "Pink and dangerous.",                16.0, 10, 2, 5),
	BarMenuItem.new("Blue Lagoon",     BarMenuItem.Type.COCTAIL, "Tropical blue. Deceptively strong.", 15.0,  9, 3, 5),
	BarMenuItem.new("Tequila Sunrise", BarMenuItem.Type.COCTAIL, "Pretty gradient, heavy punch.",      17.0, 11, 4, 5),
]

static func get_all_items() -> Array[BarMenuItem]:
	return beer_menu + shots_menu + cocktails_menu

func open(player: Player) -> void:
	$Panel/Margin/VBox/Tabs/Beer.set_pressed_no_signal(true)
	super.open(player)

func _get_initial_items() -> Array[BarMenuItem]:
	return beer_menu

func _on_tabs_tab_changed(tab: int) -> void:
	match tab:
		0: _rebuild(beer_menu)
		1: _rebuild(shots_menu)
		2: _rebuild(cocktails_menu)
