class_name PhoneController
extends Node

# Owns the local phone lifecycle; Main supplies dependencies and routes taxi requests.
signal taxi_requested(destination: String)

const PHONE_SCENE := preload("res://scenes/core/phone.tscn")

var _player: Player
var _headphone_player: HeadphonePlayer
var _world_time: WorldTime
var _destinations: Array[TransportDestination] = []
var _is_taxi_available: Callable
var _phone: Phone
var _opening := false

func configure(player: Player, headphone_player: HeadphonePlayer, world_time: WorldTime,
		destinations: Array[TransportDestination], is_taxi_available: Callable) -> void:
	close()
	_player = player
	_headphone_player = headphone_player
	_world_time = world_time
	_destinations = destinations
	_is_taxi_available = is_taxi_available

func _exit_tree() -> void:
	close()

func open(player: Player) -> void:
	if not is_instance_valid(_player) or player != _player or _phone != null or _opening:
		return
	_opening = true
	_player.is_world_input_blocked = true
	call_deferred("_open_phone")

func close() -> void:
	if not _opening and _phone == null:
		return
	_opening = false
	if is_instance_valid(_phone):
		_phone.queue_free()
	_phone = null
	if is_instance_valid(_player):
		_player.is_world_input_blocked = false

func refresh_taxi_context() -> void:
	if not is_instance_valid(_phone) or not is_instance_valid(_player):
		return
	_phone.set_taxi_context(_player.level_id)
	_phone.set_taxi_available(_is_taxi_available.call())

func _open_phone() -> void:
	if not _opening:
		return
	if not is_instance_valid(_player):
		close()
		return
	_phone = PHONE_SCENE.instantiate() as Phone
	_phone.set_player_settings(_player.settings)
	_phone.set_clothing_shop(_player.clothing_shop)
	_phone.set_headphone_player(_headphone_player)
	_phone.set_world_time(_world_time)
	_phone.set_transport_destinations(_destinations)
	_phone.taxi_requested.connect(_on_taxi_requested)
	_phone.closed.connect(close)
	add_child(_phone)
	_opening = false
	refresh_taxi_context()

func _on_taxi_requested(destination: String) -> void:
	close()
	taxi_requested.emit(destination)
