class_name HomeElevator
extends Interactable

@export var ding_scene: PackedScene

@onready var area: Area2D = $Area

func interact(player: Player) -> void:
	if multiplayer.is_server():
		_try_enter(int(player.name))
	else:
		_request_enter.rpc_id(1)

@rpc("any_peer", "reliable")
func _request_enter() -> void:
	if multiplayer.is_server():
		_try_enter(multiplayer.get_remote_sender_id())

func _try_enter(peer_id: int) -> void:
	var level := Level.find_level_node(self)
	if level == null:
		return
	var main := level.get_parent() as Main
	var player := level.get_player(peer_id)
	if main == null or player == null or player.level_id != level.level_id:
		return
	var room := get_parent().get_parent().get_parent() as Room
	if room == null or not Rect2(Vector2.ZERO, room.room_size).has_point(room.to_local(player.global_position)):
		return
	if not area.overlaps_area(player.interaction_area):
		return
	main.enter_home(peer_id)
	if player.level_id == main.home.level_id:
		_play_ding.rpc(peer_id)

@rpc("authority", "call_local", "reliable")
func _play_ding(peer_id: int) -> void:
	var level := Level.find_level_node(self)
	var player := level.get_player(peer_id) if level != null else null
	if player == null or ding_scene == null:
		return
	var audio := ding_scene.instantiate() as AudioStreamPlayer2D
	var is_rider := peer_id == multiplayer.get_unique_id()
	var emitter: Node2D = player if is_rider else self
	if is_rider:
		# Keep the cue audible across the trip, including at camera limits.
		audio.max_distance = player.get_viewport_rect().size.length() / minf(player.camera.zoom.x, player.camera.zoom.y)
		audio.attenuation = 0.0
		audio.panning_strength = 0.0
	emitter.add_child(audio)
	audio.play()
