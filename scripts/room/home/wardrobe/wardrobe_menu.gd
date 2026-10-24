class_name WardrobeMenu
extends CanvasLayer

const CARD_SCENE := preload("res://scenes/room/home/wardrobe/card.tscn")
const CARD_STEP := 192
@onready var _overlay: Control = $Overlay
@onready var _preview: CharacterSprite = $Overlay/Panel/Preview/Character
@onready var _top_scroll: ScrollContainer = $Overlay/Panel/TopRow
@onready var _bottom_scroll: ScrollContainer = $Overlay/Panel/BottomRow
@onready var _tops: HBoxContainer = $Overlay/Panel/TopRow/Padding/Items
@onready var _bottoms: HBoxContainer = $Overlay/Panel/BottomRow/Padding/Items

var _player: Player
var _wardrobe: Wardrobe
var _top_items: Array[Vector2i] = []
var _bottom_items: Array[Vector2i] = []
var _selected_top := 0
var _selected_bottom := 0
var _closing := false

func _ready() -> void:
	hide()

func open(player: Player, wardrobe: Wardrobe) -> void:
	_player = player
	_wardrobe = wardrobe
	_top_items = _equipped_first(player.owned_tops, Vector2i(player.top_id, player.top_color_id))
	_bottom_items = _equipped_first(player.owned_bottoms, Vector2i(player.pants_id, player.pants_color_id))
	_player.is_world_input_blocked = true
	_player.appearance_changed.connect(_sync_equipped)
	_player.tree_exiting.connect(close)
	_build_row(_tops, _top_items, true)
	_build_row(_bottoms, _bottom_items, false)
	_configure_focus()
	for scroll in [_top_scroll, _bottom_scroll]:
		scroll.get_h_scroll_bar().step = CARD_STEP
	_sync_equipped()
	show()
	_focus_equipped.call_deferred()

func _equipped_first(items: Array[Vector2i], equipped: Vector2i) -> Array[Vector2i]:
	var ordered := items.duplicate()
	var index := ordered.find(equipped)
	if index > 0:
		ordered.remove_at(index)
		ordered.push_front(equipped)
	return ordered

func _focus_equipped() -> void:
	if not _closing:
		_top_scroll.scroll_horizontal = _selected_top * CARD_STEP
		_bottom_scroll.scroll_horizontal = _selected_bottom * CARD_STEP
		(_tops.get_child(_selected_top) as Button).grab_focus()

func _center_card(index: int, is_top: bool) -> void:
	# Keep the card under the pointer until a mouse click is released.
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	var scroll := _top_scroll if is_top else _bottom_scroll
	scroll.scroll_horizontal = index * CARD_STEP

func _process(_delta: float) -> void:
	if _player != null and not _closing and (not is_instance_valid(_player) or not _wardrobe.can_use(_player)):
		close()

func _exit_tree() -> void:
	close()

func close() -> void:
	if _closing:
		return
	_closing = true
	if is_instance_valid(_player):
		_player.is_world_input_blocked = false
		_player.appearance_changed.disconnect(_sync_equipped)
		_player.tree_exiting.disconnect(close)
	hide()
	queue_free()

func _build_row(row: HBoxContainer, items: Array[Vector2i], is_top: bool) -> void:
	var group := ButtonGroup.new()
	for index in items.size():
		var item := items[index]
		var card := CARD_SCENE.instantiate() as Button
		card.button_group = group
		row.add_child(card)
		var icon := card.get_node("Icon") as TextureRect
		var texture: Texture2D = CharacterSprite.TOP_TEXTURES[item.x] if is_top else CharacterSprite.PANTS_TEXTURES[item.x]
		icon.texture = CharacterSprite.garment_icon(texture)
		var dye := icon.material.duplicate() as ShaderMaterial
		dye.set_shader_parameter("clothing_color", CharacterSprite.CLOTHING_COLORS[item.y])
		icon.material = dye
		card.pressed.connect(_select.bind(index, is_top))
		card.focus_entered.connect(_center_card.bind(index, is_top))
		card.get_node("Hanger").visible = is_top

func _configure_focus() -> void:
	for row in [_tops, _bottoms]:
		var other_row := _bottoms if row == _tops else _tops
		for index in row.get_child_count():
			var card := row.get_child(index) as Button
			card.focus_neighbor_left = card.get_path_to(row.get_child(maxi(index - 1, 0)))
			card.focus_neighbor_right = card.get_path_to(row.get_child(mini(index + 1, row.get_child_count() - 1)))
			var across := card.get_path_to(other_row.get_child(mini(index, other_row.get_child_count() - 1)))
			card.focus_neighbor_top = across if row == _bottoms else NodePath(".")
			card.focus_neighbor_bottom = across if row == _tops else NodePath(".")

func _select(index: int, is_top: bool) -> void:
	if is_top:
		_selected_top = index
	else:
		_selected_bottom = index
	_refresh()
	var item := _top_items[index] if is_top else _bottom_items[index]
	_wardrobe.equip(_player, is_top, item)

func _input(event: InputEvent) -> void:
	if _closing or not visible:
		return
	var step := 0.0
	if event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT]:
			step = 1.0
		elif event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT]:
			step = -1.0
	if not is_zero_approx(step):
		for scroll in [_top_scroll, _bottom_scroll]:
			if scroll.get_global_rect().has_point(event.position):
				scroll.scroll_horizontal += int(step) * CARD_STEP
				get_viewport().set_input_as_handled()
				return

func _refresh() -> void:
	var top := _top_items[_selected_top]
	var bottom := _bottom_items[_selected_bottom]
	_preview.set_appearance(_player.hair_id, top.x, bottom.x, _player.hair_color_id, top.y, bottom.y)
	for row in [_tops, _bottoms]:
		var selected := _selected_top if row == _tops else _selected_bottom
		for index in row.get_child_count():
			var card := row.get_child(index) as Button
			card.set_pressed_no_signal(index == selected)

func _sync_equipped() -> void:
	var top := _top_items.find(Vector2i(_player.top_id, _player.top_color_id))
	var bottom := _bottom_items.find(Vector2i(_player.pants_id, _player.pants_color_id))
	if top >= 0:
		_selected_top = top
	if bottom >= 0:
		_selected_bottom = bottom
	_refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if _closing or not visible:
		return
	# Arrow keys and ui_accept use native Button navigation; also accept world WASD.
	var directions := {"left": SIDE_LEFT, "right": SIDE_RIGHT, "up": SIDE_TOP, "down": SIDE_BOTTOM}
	for action in directions:
		if event.is_action_pressed(action, true):
			var focused := get_viewport().gui_get_focus_owner()
			if focused != null:
				var target := focused.get_node(focused.get_focus_neighbor(directions[action])) as Control
				target.grab_focus()
			get_viewport().set_input_as_handled()
			return

func _unhandled_input(event: InputEvent) -> void:
	if _closing or not visible or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		var focused := get_viewport().gui_get_focus_owner() as Button
		if focused != null and _overlay.is_ancestor_of(focused):
			focused.pressed.emit()
		get_viewport().set_input_as_handled()
