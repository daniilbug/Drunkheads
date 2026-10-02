@tool
class_name Chair
extends Node2D

@export var facing_north := false

@export var occupant_name := "":
	set(value):
		occupant_name = value
		if is_node_ready():
			_update_sprite()

var is_occupied: bool:
	get: return not occupant_name.is_empty()

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	_update_sprite()

func get_seat_position() -> Vector2:
	return global_position + (Vector2(0, -8) if facing_north else Vector2(0, 8))

func get_occupant() -> Player:
	if occupant_name.is_empty():
		return null
	var level := Level.find_level_node(self)
	return level.get_node_or_null(occupant_name) as Player if level else null

func occupy(player: Player) -> void:
	if player == null or (is_occupied and occupant_name != player.name):
		return
	occupant_name = player.name
	player.direction = Vector2.UP if facing_north else Vector2.DOWN
	if not multiplayer.is_server() and player.is_multiplayer_authority():
		_request_occupy.rpc_id(1)

func vacate(player: Player = null) -> void:
	if player != null and occupant_name != player.name:
		return
	if player == null and not multiplayer.is_server():
		return
	occupant_name = ""
	if player != null and not multiplayer.is_server() and player.is_multiplayer_authority():
		_request_vacate.rpc_id(1)

func _update_sprite() -> void:
	sprite.frame = (3 if is_occupied else 2) if facing_north else (1 if is_occupied else 0)

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
		vacate(get_occupant())

@rpc("authority", "reliable")
func _reject_occupy() -> void:
	var level := Level.find_level_node(self)
	if level and level.local_player and level.local_player.seated_chair == self:
		level.local_player._stand_up()
