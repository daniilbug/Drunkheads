@tool
class_name Seat
extends Node2D

signal occupancy_changed

@export var facing_north := false
@export var available_to_npc := true
@export var seat_position_offset := Vector2.ZERO

@export var occupant_name := "":
	set(value):
		if occupant_name == value:
			return
		occupant_name = value
		if is_node_ready():
			occupancy_changed.emit()

var is_occupied: bool:
	get: return not occupant_name.is_empty()

func get_seat_position() -> Vector2:
	return to_global(seat_position_offset)

func occupy(player: Player) -> bool:
	if player == null or (is_occupied and occupant_name != player.name):
		return false
	occupant_name = player.name
	player.direction = Vector2.UP if facing_north else Vector2.DOWN
	if not multiplayer.is_server() and player.is_multiplayer_authority():
		_request_occupy.rpc_id(1)
	return true

func vacate(player: Player = null) -> void:
	if player != null and occupant_name != player.name:
		return
	if player == null and not multiplayer.is_server():
		return
	occupant_name = ""
	if player != null and not multiplayer.is_server() and player.is_multiplayer_authority():
		_request_vacate.rpc_id(1)

@rpc("any_peer", "reliable")
func _request_occupy() -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	var level := Level.find_level_node(self)
	var player := level.get_node_or_null(str(peer_id)) as Player if level else null
	if player == null or player is NPC:
		return
	if (is_occupied and occupant_name != player.name) or player.global_position.distance_to(global_position) > 32.0:
		_reject_occupy.rpc_id(peer_id)
		return
	occupy(player)

@rpc("any_peer", "reliable")
func _request_vacate() -> void:
	if not multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	if occupant_name == str(peer_id):
		vacate()

@rpc("authority", "reliable")
func _reject_occupy() -> void:
	var level := Level.find_level_node(self)
	if level and level.local_player and level.local_player.seated_seat == self:
		level.local_player._stand_up()
