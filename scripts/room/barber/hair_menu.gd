extends CanvasLayer

const CARD_SCENE := preload("res://scenes/room/barber/hair_card.tscn")

@onready var _grid: GridContainer = $Overlay/Panel/Choices
@onready var _preview: CharacterSprite = $Overlay/Panel/Preview/Character
@onready var _apply: Button = $Overlay/Panel/Apply

var _player: Player
var _barber: Barber
var _selected := 0
var _closing := false


func open(player: Player, barber: Barber) -> void:
	_player = player
	_barber = barber
	_selected = player.hair_id
	_player.is_world_input_blocked = true
	_player.tree_exiting.connect(close)
	_player.appearance_changed.connect(_refresh)
	_player.player_data.stats_changed.connect(_refresh)
	_barber.purchase_finished.connect(_on_purchase_finished)
	var group := ButtonGroup.new()
	for index in CharacterSprite.HAIR_TEXTURES.size():
		var card := CARD_SCENE.instantiate() as Button
		card.button_group = group
		_grid.add_child(card)
		var hair := AtlasTexture.new()
		hair.atlas = CharacterSprite.HAIR_TEXTURES[index]
		hair.region = Rect2(0, Player.ROW_IDLE * 20, 12, 10)
		(card.get_node("Hair") as TextureRect).texture = hair
		card.pressed.connect(_select.bind(index))
	_configure_focus()
	_apply.pressed.connect(_confirm)
	_select(_selected)
	(_grid.get_child(_selected) as Button).grab_focus.call_deferred()


func _configure_focus() -> void:
	for index in _grid.get_child_count():
		var card := _grid.get_child(index) as Button
		card.focus_neighbor_left = card.get_path_to(_grid.get_child(index - 1 if index % _grid.columns > 0 else index))
		card.focus_neighbor_right = card.get_path_to(_grid.get_child(index + 1 if index % _grid.columns < _grid.columns - 1 else index))
		card.focus_neighbor_top = card.get_path_to(_grid.get_child(maxi(index - _grid.columns, index % _grid.columns)))
		card.focus_neighbor_bottom = card.get_path_to(_grid.get_child(index + _grid.columns) if index + _grid.columns < _grid.get_child_count() else _apply)
		card.focus_next = card.get_path_to(_apply)


func _select(index: int) -> void:
	_selected = index
	var path := _apply.get_path_to(_grid.get_child(index))
	_apply.focus_neighbor_top = path
	_apply.focus_previous = path
	_apply.focus_next = path
	_refresh()


func _refresh() -> void:
	if _closing:
		return
	_preview.set_appearance(_selected, _player.top_id, _player.pants_id, _player.hair_color_id, _player.top_color_id, _player.pants_color_id)
	($Overlay/Panel/Apply/Contents/Price as Label).text = str(Barber.PRICE)
	_apply.disabled = _barber.purchase_pending or _selected == _player.hair_id or _player.player_data.money < Barber.PRICE
	_apply.modulate.a = 0.45 if _apply.disabled else 1.0
	for index in _grid.get_child_count():
		var card := _grid.get_child(index) as Button
		card.set_pressed_no_signal(index == _selected)
		(card.get_node("Hair").material as ShaderMaterial).set_shader_parameter("hair_color", CharacterSprite.HAIR_COLORS[_player.hair_color_id])


func _confirm() -> void:
	if not _closing and not _apply.disabled:
		_barber.buy_hair(_player, _selected)


func _on_purchase_finished(accepted: bool) -> void:
	if accepted:
		close()
	else:
		_refresh()


func _process(_delta: float) -> void:
	if not _closing and _player != null and (not is_instance_valid(_player) or not is_instance_valid(_barber) or not _barber.can_use(_player)):
		close()


func close() -> void:
	if _closing:
		return
	_closing = true
	if is_instance_valid(_player):
		_player.is_world_input_blocked = false
		_player.tree_exiting.disconnect(close)
		_player.appearance_changed.disconnect(_refresh)
		_player.player_data.stats_changed.disconnect(_refresh)
	if is_instance_valid(_barber):
		_barber.purchase_finished.disconnect(_on_purchase_finished)
	hide()
	queue_free()


func _exit_tree() -> void:
	close()


func _unhandled_key_input(event: InputEvent) -> void:
	var directions := {"left": SIDE_LEFT, "right": SIDE_RIGHT, "up": SIDE_TOP, "down": SIDE_BOTTOM}
	for action in directions:
		if not _closing and event.is_action_pressed(action, true):
			var focused := get_viewport().gui_get_focus_owner()
			if focused != null and $Overlay.is_ancestor_of(focused):
				var target := focused.find_valid_focus_neighbor(directions[action])
				if target != null and not (target is BaseButton and target.disabled):
					target.grab_focus()
			get_viewport().set_input_as_handled()
			return


func _unhandled_input(event: InputEvent) -> void:
	if _closing or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		var focused := get_viewport().gui_get_focus_owner() as Button
		if focused != null and $Overlay.is_ancestor_of(focused):
			focused.pressed.emit()
		get_viewport().set_input_as_handled()
