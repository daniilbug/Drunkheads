class_name DrinkMenu
extends CanvasLayer

signal drink_selected(drink: DrinkType)
signal closed

@onready var panel: PanelContainer = $Panel
@onready var list: VBoxContainer = $Panel/Margin/VBox/List
@onready var close_btn: Button = $Panel/Margin/VBox/CloseBtn

var _player_data: PlayerData

func _ready() -> void:
	close_btn.pressed.connect(_on_close)
	hide()

func open(drinks: Array[DrinkType], player_data: PlayerData) -> void:
	_player_data = player_data
	_rebuild(drinks)
	show()

func _rebuild(drinks: Array[DrinkType]) -> void:
	for child in list.get_children():
		child.queue_free()
	for drink in drinks:
		list.add_child(_make_row(drink))

func _make_row(drink: DrinkType) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl := Label.new()
	name_lbl.text = drink.drink_name
	name_lbl.add_theme_font_size_override("font_size", 20)

	var flavor_lbl := Label.new()
	flavor_lbl.text = drink.flavor
	flavor_lbl.add_theme_font_size_override("font_size", 14)
	flavor_lbl.modulate = Color(0.75, 0.75, 0.75)

	var stats_lbl := Label.new()
	var pct := int(drink.alcohol * 100)
	stats_lbl.text = "+%d Respect  -%d Mind  (%d%% alc)" % [
		int(drink.get_respect_bonus()),
		int(drink.get_mind_penalty()),
		pct
	]
	stats_lbl.add_theme_font_size_override("font_size", 13)
	stats_lbl.modulate = Color(0.9, 0.85, 0.6)

	info.add_child(name_lbl)
	info.add_child(flavor_lbl)
	info.add_child(stats_lbl)

	var buy_btn := Button.new()
	buy_btn.text = "$%d" % int(drink.cost)
	buy_btn.add_theme_font_size_override("font_size", 18)
	buy_btn.custom_minimum_size = Vector2(72, 0)
	var can_afford := _player_data != null and _player_data.money >= drink.cost
	buy_btn.disabled = not can_afford
	buy_btn.pressed.connect(func(): _on_buy(drink))

	row.add_child(info)
	row.add_child(buy_btn)
	return row

func _on_buy(drink: DrinkType) -> void:
	drink_selected.emit(drink)
	hide()

func _on_close() -> void:
	closed.emit()
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close()
		get_viewport().set_input_as_handled()
