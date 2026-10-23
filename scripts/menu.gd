extends Control

const HUB_SCENE := preload("res://scenes/levels/main.tscn")
const DEFAULT_PORT := 7777
const MAX_PEERS := 16

var _starting_game := false

@onready var name_input: LineEdit    = $VBoxContainer/NameInput
@onready var address_input: LineEdit = $VBoxContainer/AddressInput
@onready var port_input: LineEdit    = $VBoxContainer/PortInput
@onready var host_button: Button     = $VBoxContainer/HostButton
@onready var load_button: Button     = $VBoxContainer/LoadButton
@onready var join_button: Button     = $VBoxContainer/JoinButton
@onready var status_label: Label     = $StatusLabel
@onready var save_panel: PanelContainer = $SavePanel
@onready var save_list: ItemList = $SavePanel/Margin/VBox/SaveList
@onready var save_message: Label = $SavePanel/Margin/VBox/Message


func _ready() -> void:
	if not SaveManager.last_error.is_empty():
		_set_status(SaveManager.last_error, true)
	host_button.pressed.connect(_start_host)
	load_button.pressed.connect(_show_saves)
	join_button.pressed.connect(_on_join_pressed)
	$SavePanel/Margin/VBox/BackButton.pressed.connect(func():
		save_panel.hide()
		$VBoxContainer.show()
		load_button.grab_focus()
	)
	save_list.item_clicked.connect(func(index: int, _position: Vector2, button: int):
		if button == MOUSE_BUTTON_LEFT:
			_load_save(index)
	)
	save_list.item_activated.connect(_load_save)

	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _show_saves() -> void:
	save_list.clear()
	for save in SaveManager.list_saves():
		var title: String
		if not save.error.is_empty():
			title = "%s — %s" % [save.file_name, save.error]
		else:
			var date := Time.get_datetime_string_from_unix_time(int(save.saved_at / 1000000)).replace("T", " ")
			var names := {"bar": "Бар", "cafe": "Кафе", "apartment": "Квартира", "home": "Подъезд"}
			title = "%s UTC · %s · %s · $%.2f" % [date, save.name, names.get(save.level, save.level), save.money]
		var index := save_list.add_item(title)
		save_list.set_item_metadata(index, save.file_name)
		save_list.set_item_tooltip(index, title)
		save_list.set_item_disabled(index, not save.error.is_empty())
	save_message.text = "Сохранений пока нет." if save_list.item_count == 0 else "Выберите сохранение. В каждом прохождении хранятся три последние точки."
	$VBoxContainer.hide()
	save_panel.show()
	save_list.grab_focus()


func _load_save(index: int) -> void:
	if not save_list.is_item_disabled(index):
		_start_host(save_list.get_item_metadata(index))


func _start_host(file_name := "") -> void:
	if _starting_game:
		return
	if not file_name.is_empty() and not SaveManager.prepare_load(file_name):
		save_message.text = SaveManager.last_error
		return
	var entered_name := name_input.text.strip_edges()
	Player.local_setup = {"name": entered_name if not entered_name.is_empty() else "Player"}
	var port := int(port_input.text) if port_input.text.is_valid_int() else DEFAULT_PORT

	var peer := ENetMultiplayerPeer.new()
	var err  := peer.create_server(port, MAX_PEERS)

	if err != OK:
		_set_status("Failed to create server (error %d)" % err, true)
		if save_panel.visible:
			save_message.text = "Не удалось запустить игру: порт занят или недоступен."
		return

	multiplayer.multiplayer_peer = peer
	_starting_game = true
	if file_name.is_empty():
		SaveManager.new_game()
	_set_status("Hosting on port %d …" % port)

	# Server loads the hub immediately.
	err = get_tree().change_scene_to_packed(HUB_SCENE)
	if err != OK:
		_starting_game = false
		peer.close()
		multiplayer.multiplayer_peer = null
		_set_status("Не удалось открыть игровой мир (ошибка %d)." % err, true)


func _on_join_pressed() -> void:
	var entered_name := name_input.text.strip_edges()
	Player.local_setup = {"name": entered_name if not entered_name.is_empty() else "Player"}
	var address := address_input.text.strip_edges()
	var port    := int(port_input.text) if port_input.text.is_valid_int() else DEFAULT_PORT

	if address.is_empty():
		address = "127.0.0.1"

	var peer := ENetMultiplayerPeer.new()
	var err  := peer.create_client(address, port)

	if err != OK:
		_set_status("Failed to connect (error %d)" % err, true)
		return

	multiplayer.multiplayer_peer = peer
	_set_status("Connecting to %s:%d …" % [address, port])
	_set_buttons_enabled(false)


func _on_connected() -> void:
	_set_status("Connected!")
	var scene := HUB_SCENE.instantiate()
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	queue_free()


func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	_set_status("Connection failed.", true)
	_set_buttons_enabled(true)


func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	_set_status("Server disconnected.", true)
	_set_buttons_enabled(true)


func _set_status(msg: String, is_error := false) -> void:
	status_label.text = msg
	status_label.modulate = Color(1.0, 0.4, 0.4) if is_error else Color(1, 1, 1)


func _set_buttons_enabled(enabled: bool) -> void:
	host_button.disabled = not enabled
	load_button.disabled = not enabled
	join_button.disabled = not enabled
