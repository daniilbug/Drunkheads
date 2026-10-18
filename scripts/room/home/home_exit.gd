class_name HomeExit
extends Interactable

@export var arrival: Marker2D

@onready var area: Area2D = $Area

func interact(player: Player) -> void:
	if multiplayer.is_server():
		_try_exit(int(player.name))
	else:
		_request_exit.rpc_id(1)

@rpc("any_peer", "reliable")
func _request_exit() -> void:
	if multiplayer.is_server():
		_try_exit(multiplayer.get_remote_sender_id())

func _try_exit(peer_id: int) -> void:
	var home := Level.find_level_node(self)
	if home == null or not is_instance_valid(arrival):
		return
	var main := home.get_parent() as Main
	if main == null:
		return
	var player := main.get_player(peer_id)
	if player == null or player.level_id != home.level_id or player.in_vehicle \
		or player.is_sitting or not area.overlaps_area(player.interaction_area):
		return
	var destination := Level.find_level_node(arrival)
	main.transfer_player(peer_id, destination, arrival.global_position)
