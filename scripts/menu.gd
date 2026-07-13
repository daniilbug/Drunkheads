extends Control

const HUB_SCENE := preload("res://scenes/main.tscn")
const DEFAULT_PORT := 7777
const MAX_PEERS := 16

@onready var name_input: LineEdit    = $VBoxContainer/NameInput
@onready var address_input: LineEdit = $VBoxContainer/AddressInput
@onready var port_input: LineEdit    = $VBoxContainer/PortInput
@onready var host_button: Button     = $VBoxContainer/HostButton
@onready var join_button: Button     = $VBoxContainer/JoinButton
@onready var status_label: Label     = $StatusLabel


func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)

	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func _on_host_pressed() -> void:
	var entered_name := name_input.text.strip_edges()
	Player.local_setup = {"name": entered_name if not entered_name.is_empty() else "Player"}
	var port := int(port_input.text) if port_input.text.is_valid_int() else DEFAULT_PORT

	var peer := ENetMultiplayerPeer.new()
	var err  := peer.create_server(port, MAX_PEERS)

	if err != OK:
		_set_status("Failed to create server (error %d)" % err, true)
		return

	multiplayer.multiplayer_peer = peer
	_set_status("Hosting on port %d …" % port)

	# Server loads the hub immediately.
	get_tree().change_scene_to_packed(HUB_SCENE)


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
	get_tree().change_scene_to_packed(HUB_SCENE)


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
	join_button.disabled = not enabled
