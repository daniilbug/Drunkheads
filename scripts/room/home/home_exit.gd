class_name HomeExit
extends Interactable

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
	if home == null:
		return
	var main := home.get_parent() as Main
	if main == null or not main.is_player_home(peer_id):
		return
	var player := main.bar.get_node_or_null(str(peer_id)) as Player
	if player == null or not area.overlaps_area(player.interaction_area):
		return
	main.return_from_home(peer_id)
