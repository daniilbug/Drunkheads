class_name OrderMenu
extends CanvasLayer

signal item_selected(item: BarMenuItem)
signal closed

@export var row_scene: PackedScene

@onready var list: VBoxContainer = $Panel/Margin/VBox/Scroll/List
@onready var panel: PanelContainer = $Panel
@onready var tabs: HBoxContainer = $Panel/Margin/VBox/Tabs

var _player: Player

func _ready() -> void:
	hide()

func open(player: Player) -> void:
	_player = player
	_player.is_world_input_blocked = true
	_rebuild(_get_initial_items())
	show()
	# The interaction that opens the menu must not also confirm an order.
	call_deferred("_focus_first_available")

func _get_initial_items() -> Array[BarMenuItem]:
	return []

func _on_buy(item: BarMenuItem) -> void:
	if _player.player_data.money < item.cost:
		return
	item_selected.emit(item)
	_on_close()
	
func _unhandled_input(event: InputEvent) -> void:
	if not visible or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_close()
	elif event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		var button := get_viewport().gui_get_focus_owner() as Button
		if button != null and not button.disabled and panel.is_ancestor_of(button):
			if button.toggle_mode:
				button.button_pressed = true
			button.pressed.emit()

func _rebuild(items: Array[BarMenuItem]) -> void:
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	for item in items:
		var row := row_scene.instantiate() as OrderMenuRow
		list.add_child(row)
		row.configure(item, _player.player_data.money >= item.cost)
		row.button.pressed.connect(_on_buy.bind(item))
	_update_focus_navigation()

func _focus_first_available() -> void:
	if not visible:
		return
	for row: OrderMenuRow in list.get_children():
		if not row.button.disabled:
			row.button.grab_focus()
			return
	if tabs.visible:
		tabs.get_child(0).grab_focus()
	else:
		panel.grab_focus()

func _update_focus_navigation() -> void:
	var categories: Array[Button] = []
	var active_category: Button
	if tabs.visible:
		for button: Button in tabs.get_children():
			categories.append(button)
			if button.button_pressed:
				active_category = button
	var rows: Array[Button] = []
	for row: OrderMenuRow in list.get_children():
		if not row.button.disabled:
			rows.append(row.button)
	if not rows.is_empty():
		var previous: Button = active_category if active_category != null else rows[-1]
		for row in rows:
			row.focus_neighbor_top = row.get_path_to(previous)
			previous.focus_neighbor_bottom = previous.get_path_to(row)
			previous = row
		previous.focus_neighbor_bottom = previous.get_path_to(active_category if active_category != null else rows[0])
	for button in categories:
		button.focus_neighbor_bottom = button.get_path_to(rows[0] if not rows.is_empty() else button)
	var buttons: Array[Button] = categories + rows
	var first: Control = buttons[0] if not buttons.is_empty() else panel
	panel.focus_next = panel.get_path_to(first)
	panel.focus_previous = panel.get_path_to(buttons[-1] if not buttons.is_empty() else panel)
	panel.focus_neighbor_top = panel.focus_next
	panel.focus_neighbor_bottom = panel.focus_next
	for i in buttons.size():
		var button := buttons[i]
		button.focus_previous = button.get_path_to(buttons[posmod(i - 1, buttons.size())])
		button.focus_next = button.get_path_to(buttons[(i + 1) % buttons.size()])

func _on_close() -> void:
	if not visible:
		return
	hide()
	if is_instance_valid(_player):
		_player.is_world_input_blocked = false
	closed.emit()
