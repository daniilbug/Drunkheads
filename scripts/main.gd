class_name Main
extends Node2D

@onready var bar: Bar = $Bar
@onready var home: Level = $Home
@onready var taxi_stop: TaxiStop = $Bar/RightTrafficLane/TaxiStop
@onready var taxi_return: Marker2D = $Bar/TaxiReturn
@onready var respect_label: Label = $HUD/Stats/RespectLabel
@onready var mind_label: Label = $HUD/Stats/MindLabel
@onready var money_label: Label = $HUD/Stats/MoneyLabel

var _players_at_home: Dictionary = {}

func _ready() -> void:
	bar.local_player_initialized.connect(_init_hud)
	if bar.local_player != null:
		_init_hud(bar.local_player)
	taxi_stop.boarding_requested.connect(_on_taxi_boarding_requested)
	taxi_stop.passenger_arrived.connect(_on_taxi_passenger_arrived)
	taxi_stop.passenger_departed.connect(_on_taxi_passenger_departed)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _init_hud(player: Player) -> void:
	player.player_data.stats_changed.connect(_update_stats)
	_update_stats()

func _update_stats() -> void:
	if bar.local_player == null:
		return
	var data := bar.local_player.player_data
	respect_label.text = "Respect  %d" % int(data.respect)
	mind_label.text = "Mind     %d" % int(data.mind)
	money_label.text = "Money   $%d" % int(data.money)

func _on_taxi_passenger_arrived(peer_id: int) -> void:
	_apply_trip.rpc(peer_id, false)

func _on_taxi_passenger_departed(peer_id: int) -> void:
	_apply_trip.rpc(peer_id, true)

func _on_taxi_boarding_requested(player: Player) -> void:
	if not _players_at_home.has(int(player.name)):
		taxi_stop.board_player(player)

func return_from_home(peer_id: int) -> void:
	if not multiplayer.is_server() or not _players_at_home.has(peer_id):
		return
	_begin_arrival.rpc(peer_id)
	taxi_stop.queue_arrival(peer_id)

@rpc("authority", "call_local", "reliable")
func _begin_arrival(peer_id: int) -> void:
	_players_at_home.erase(peer_id)
	var player := bar.get_node_or_null(str(peer_id)) as Player
	if player == null:
		return
	player.in_vehicle = true
	player.riding_vehicle_name = ""
	player.velocity = Vector2.ZERO
	player.global_position = taxi_return.global_position
	if player == bar.local_player:
		home.local_player = null
		_set_camera_bounds(player, bar.get_world_bounds())

func is_player_home(peer_id: int) -> bool:
	return _players_at_home.has(peer_id)

@rpc("authority", "call_local", "reliable")
func _apply_trip(peer_id: int, to_home: bool) -> void:
	var player := bar.get_node_or_null(str(peer_id)) as Player
	if player == null:
		return
	player.in_vehicle = false
	player.riding_vehicle_name = ""
	if to_home:
		_players_at_home[peer_id] = true
	else:
		_players_at_home.erase(peer_id)
	var destination := home.get_node("PlayerSpawn") as Marker2D if to_home else taxi_return
	player.velocity = Vector2.ZERO
	player.global_position = destination.global_position
	if player != bar.local_player:
		return
	home.local_player = player if to_home else null
	_set_camera_bounds(player, home.get_world_bounds() if to_home else bar.get_world_bounds())

func _set_camera_bounds(player: Player, bounds: Rect2) -> void:
	player.camera.limit_left = floori(bounds.position.x)
	player.camera.limit_top = floori(bounds.position.y)
	player.camera.limit_right = ceili(bounds.end.x)
	player.camera.limit_bottom = ceili(bounds.end.y)
	player.camera.reset_smoothing()

func _on_peer_disconnected(peer_id: int) -> void:
	_players_at_home.erase(peer_id)
