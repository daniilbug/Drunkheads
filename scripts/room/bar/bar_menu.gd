class_name BarMenu
extends CanvasLayer

signal item_selected(item: BarMenuItem)
signal closed

@onready var panel: PanelContainer = $Panel
@onready var list: VBoxContainer = $Panel/Margin/VBox/List
@onready var close_btn: Button = $Panel/Margin/VBox/CloseBtn

var _player_data: PlayerData

var _beer_menu: Array[BarMenuItem] = [
	BarMenuItem.new("Light Lager",  BarMenuItem.Type.BEER, "Crisp and watery. Goes down easy.",  8.0,  5, 0, 4),
	BarMenuItem.new("Pale Ale",     BarMenuItem.Type.BEER, "Hoppy with a citrus bite.",          12.0,  7, 1, 4),
	BarMenuItem.new("Dark Stout",   BarMenuItem.Type.BEER, "Thick and roasty. Almost a meal.",   14.0,  9, 2, 4),
	BarMenuItem.new("Strong IPA",   BarMenuItem.Type.BEER, "Bitter kick. Not for the faint.",    15.0, 10, 3, 4),
	BarMenuItem.new("Barleywine",   BarMenuItem.Type.BEER, "Dark and potent. Respect it.",       18.0, 13, 4, 4),
]

var _shots_menu: Array[BarMenuItem] = [
	BarMenuItem.new("Vodka",    BarMenuItem.Type.SHOT, "Clean. Cold. Ruthless.",          6.0,  8, 0, 1),
	BarMenuItem.new("Tequila",  BarMenuItem.Type.SHOT, "Salt, shot, lime. Classic.",      7.0,  9, 1, 1),
	BarMenuItem.new("Whiskey",  BarMenuItem.Type.SHOT, "Burns so good.",                  8.0, 10, 2, 1),
	BarMenuItem.new("Dark Rum", BarMenuItem.Type.SHOT, "Sweet on the way down.",          7.0,  9, 3, 1),
	BarMenuItem.new("Sambuca",  BarMenuItem.Type.SHOT, "Anise and fire. Bold choice.",    9.0, 12, 4, 1),
]

var _cocktails_menu: Array[BarMenuItem] = [
	BarMenuItem.new("Mojito",          BarMenuItem.Type.COCTAIL, "Mint, lime, rum. Refreshing.",       14.0,  8, 0, 5),
	BarMenuItem.new("Margarita",       BarMenuItem.Type.COCTAIL, "Tequila and citrus on the rocks.",   15.0,  9, 1, 5),
	BarMenuItem.new("Cosmopolitan",    BarMenuItem.Type.COCTAIL, "Pink and dangerous.",                16.0, 10, 2, 5),
	BarMenuItem.new("Blue Lagoon",     BarMenuItem.Type.COCTAIL, "Tropical blue. Deceptively strong.", 15.0,  9, 3, 5),
	BarMenuItem.new("Tequila Sunrise", BarMenuItem.Type.COCTAIL, "Pretty gradient, heavy punch.",      17.0, 11, 4, 5),
]

func _ready() -> void:
	close_btn.pressed.connect(_on_close)
	hide()

func open(player_data: PlayerData) -> void:
	_player_data = player_data
	_rebuild(_beer_menu)
	show()

func _on_buy(item: BarMenuItem) -> void:
	item_selected.emit(item)
	hide()
	
func _on_tabs_tab_changed(tab: int) -> void:
	match tab:
		0: _rebuild(_beer_menu)
		1: _rebuild(_shots_menu)
		2: _rebuild(_cocktails_menu)
	
func _on_close_btn_pressed() -> void:
	_on_close()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close()
		get_viewport().set_input_as_handled()

func _rebuild(items: Array[BarMenuItem]) -> void:
	for child in list.get_children():
		child.queue_free()
	for item in items:
		list.add_child(_make_row(item))

func _on_close() -> void:
	closed.emit()
	hide()
		
func _make_row(item: BarMenuItem) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl := Label.new()
	name_lbl.text = item.name
	name_lbl.add_theme_font_size_override("font_size", 20)

	var flavor_lbl := Label.new()
	flavor_lbl.text = item.flavor
	flavor_lbl.add_theme_font_size_override("font_size", 14)
	flavor_lbl.modulate = Color(0.75, 0.75, 0.75)

	info.add_child(name_lbl)
	info.add_child(flavor_lbl)

	var buy_btn := Button.new()
	buy_btn.text = "$%d" % int(item.cost)
	buy_btn.add_theme_font_size_override("font_size", 18)
	buy_btn.custom_minimum_size = Vector2(72, 0)
	var can_afford := _player_data != null and _player_data.money >= item.cost
	buy_btn.disabled = not can_afford
	buy_btn.pressed.connect(func(): _on_buy(item))

	row.add_child(info)
	row.add_child(buy_btn)
	return row
