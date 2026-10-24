class_name PhoneMarketplace
extends Control

const CARD_SCENE := preload("res://scenes/core/phone_clothing_card.tscn")

@onready var _scroll: ScrollContainer = $Scroll
@onready var _grid: GridContainer = $Scroll/Items

var _shop: ClothingShop
var _items: Array[Vector3i] = []
var _pointer_scroll := false

func set_shop(shop: ClothingShop) -> void:
	_shop = shop
	_shop.changed.connect(_refresh)
	_shop.player.player_data.stats_changed.connect(_refresh)

func _exit_tree() -> void:
	if is_instance_valid(_shop):
		_shop.changed.disconnect(_refresh)
		_shop.player.player_data.stats_changed.disconnect(_refresh)

func open() -> void:
	if _shop == null:
		return
	if _items.is_empty():
		_build_catalog()
	_refresh()
	show()
	(_grid.get_child(0) as Button).grab_focus()
	_scroll.scroll_vertical = 0

func _build_catalog() -> void:
	var icons: Dictionary = {}
	for color in CharacterSprite.CLOTHING_COLORS.size():
		for style in maxi(CharacterSprite.TOP_TEXTURES.size(), CharacterSprite.PANTS_TEXTURES.size()):
			var color_id := (color + style) % CharacterSprite.CLOTHING_COLORS.size()
			for is_top in [true, false]:
				var textures: Array = CharacterSprite.TOP_TEXTURES if is_top else CharacterSprite.PANTS_TEXTURES
				if style >= textures.size():
					continue
				var key := Vector2i(int(is_top), style)
				if not icons.has(key):
					icons[key] = CharacterSprite.garment_icon(textures[style])
				var index := _items.size()
				_items.append(Vector3i(int(is_top), style, color_id))
				var card := CARD_SCENE.instantiate() as Button
				_grid.add_child(card)
				var icon := card.get_node("Icon") as TextureRect
				icon.texture = icons[key]
				var dye := icon.material.duplicate() as ShaderMaterial
				dye.set_shader_parameter("clothing_color", CharacterSprite.CLOTHING_COLORS[color_id])
				icon.material = dye
				(card.get_node("Price") as Label).text = str(ClothingShop.price(is_top))
				card.pressed.connect(_buy.bind(index))
				card.focus_entered.connect(_scroll.ensure_control_visible.bind(card))
	for index in _items.size():
		var card := _grid.get_child(index) as Button
		var column := index % _grid.columns
		card.focus_neighbor_left = card.get_path_to(_grid.get_child(index - 1 if column > 0 else index))
		card.focus_neighbor_right = card.get_path_to(_grid.get_child(index + 1 if column < _grid.columns - 1 and index + 1 < _items.size() else index))
		card.focus_neighbor_top = card.get_path_to(_grid.get_child(index - _grid.columns if index >= _grid.columns else index))
		card.focus_neighbor_bottom = card.get_path_to(_grid.get_child(index + _grid.columns if index + _grid.columns < _items.size() else index))

func _buy(index: int) -> void:
	var item := _items[index]
	_shop.buy(item.x == 1, Vector2i(item.y, item.z))
	_refresh()

func _refresh() -> void:
	for index in _items.size():
		var item := _items[index]
		var card := _grid.get_child(index) as Button
		var owned := _shop.owns(item.x == 1, Vector2i(item.y, item.z))
		card.set_pressed_no_signal(owned)
		card.modulate = Color(1, 1, 1, 0.5) if owned else Color.WHITE
		card.get_node("Price").modulate = Color(1, 1, 1, 0.4) \
			if _shop.purchase_pending or _shop.player.player_data.money < ClothingShop.price(item.x == 1) else Color.WHITE

func _input(event: InputEvent) -> void:
	if is_visible_in_tree():
		if event is InputEventMouseMotion:
			_pointer_scroll = true
		elif event is InputEventKey:
			_pointer_scroll = false

func _process(delta: float) -> void:
	if not is_visible_in_tree() or not _pointer_scroll or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	var point := _scroll.get_local_mouse_position()
	if not Rect2(Vector2.ZERO, _scroll.size).has_point(point):
		return
	var direction := 1 if point.y > _scroll.size.y - 24 else (-1 if point.y < 24 else 0)
	_scroll.scroll_vertical += roundi(direction * 240.0 * delta)

func _unhandled_key_input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var directions := {"left": SIDE_LEFT, "right": SIDE_RIGHT, "up": SIDE_TOP, "down": SIDE_BOTTOM}
	for action in directions:
		if event.is_action_pressed(action, true):
			var focused := get_viewport().gui_get_focus_owner()
			if focused != null and _grid.is_ancestor_of(focused):
				var target := focused.get_node(focused.get_focus_neighbor(directions[action])) as Control
				target.grab_focus()
			get_viewport().set_input_as_handled()
			return
