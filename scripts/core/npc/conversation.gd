class_name NPCConversation
extends Node

enum Phase { CLOSED = -1, CHOOSE, SPEAK, LISTEN, REPLY, RESULT }

const PHASE_SECONDS := {Phase.SPEAK: 0.55, Phase.LISTEN: 0.6, Phase.REPLY: 1.15, Phase.RESULT: 3.0}
const CHOICE_TIMEOUT := 45.0

@export var menu_scene: PackedScene
## Atomic server snapshot: participant peer ID, phase, topic ID, reaction.
@export var presentation := Vector4i(0, Phase.CLOSED, -1, 0):
	set(value):
		if presentation == value:
			return
		presentation = value
		if is_node_ready():
			$Motion.apply(peer_id, phase, reaction)

var peer_id: int:
	get: return presentation.x

var phase: int:
	get: return presentation.y

var topic_id: int:
	get: return presentation.z

var reaction: int:
	get: return presentation.w

var _token := 0
var _local_token := 0
var _rounds: Array[PackedInt32Array] = []
var _stage := 0
var _hits := 0
var _elapsed := 0.0
var _delta := 0.0
var _menu: CanvasLayer

@onready var npc: NPC = get_parent()

func _ready() -> void:
	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	$Motion.apply.call_deferred(peer_id, phase, reaction)

func participant() -> Player:
	var level := Level.find_level_node(npc)
	return level.get_player(peer_id) if level != null and peer_id > 0 else null

func interact(player: Player) -> void:
	if not player.is_multiplayer_authority() or player.is_world_input_blocked or peer_id != 0 \
		or is_instance_valid(_menu) or not can_talk_to(player):
		return
	_local_token += 1
	_menu = menu_scene.instantiate()
	add_child(_menu)
	_menu.open(player, self, _local_token)
	get_viewport().set_input_as_handled()
	if multiplayer.is_server():
		_begin(int(player.name), _local_token)
	else:
		_request_begin.rpc_id(1, _local_token)

func choose(token: int, stage: int, topic: int) -> void:
	if multiplayer.is_server():
		_choose(multiplayer.get_unique_id(), token, stage, topic)
	else:
		_request_choice.rpc_id(1, token, stage, topic)

func close(token: int) -> void:
	if multiplayer.is_server():
		_cancel(multiplayer.get_unique_id(), token)
	elif multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		_request_close.rpc_id(1, token)

@rpc("any_peer", "reliable")
func _request_begin(token: int) -> void:
	if multiplayer.is_server():
		_begin(multiplayer.get_remote_sender_id(), token)

@rpc("any_peer", "reliable")
func _request_choice(token: int, stage: int, topic: int) -> void:
	if multiplayer.is_server():
		_choose(multiplayer.get_remote_sender_id(), token, stage, topic)

@rpc("any_peer", "reliable")
func _request_close(token: int) -> void:
	if multiplayer.is_server():
		_cancel(multiplayer.get_remote_sender_id(), token)

func _begin(sender: int, token: int) -> void:
	var level := Level.find_level_node(npc)
	var player := level.get_player(sender) if level != null else null
	if peer_id != 0 or npc.profile == null or not can_talk_to(player):
		_send(sender, token, {"closed": true})
		return
	for other in level.get_children():
		if other is NPC and other.conversation.peer_id == sender:
			_send(sender, token, {"closed": true})
			return
	_token = token
	_stage = 0
	_hits = 0
	_delta = 0.0
	_rounds = ConversationTopics.new_rounds(npc.profile.interests)
	npc.pause_for_conversation()
	presentation = Vector4i(sender, Phase.CHOOSE, -1, 0)
	_elapsed = 0.0
	_publish()

func _choose(sender: int, token: int, stage: int, topic: int) -> void:
	if sender != peer_id or token != _token or phase != Phase.CHOOSE or stage != _stage:
		return
	if not can_talk_to(participant(), true):
		_end()
		return
	if topic not in _rounds[_stage]:
		return
	var matched := topic in npc.profile.interests
	_hits += int(matched)
	_set_phase(Phase.SPEAK, topic, int(matched))

func _physics_process(delta: float) -> void:
	if peer_id == 0 or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED or not multiplayer.is_server():
		return
	if not can_talk_to(participant(), true):
		_end()
		return
	_elapsed += delta
	var duration: float = CHOICE_TIMEOUT if phase == Phase.CHOOSE else PHASE_SECONDS[phase]
	if _elapsed < duration:
		return
	match phase:
		Phase.CHOOSE, Phase.RESULT:
			_end()
		Phase.SPEAK:
			_set_phase(Phase.LISTEN, topic_id, reaction)
		Phase.LISTEN:
			_set_phase(Phase.REPLY, topic_id, reaction)
		Phase.REPLY:
			_stage += 1
			if _stage < ConversationTopics.ROUND_COUNT:
				_set_phase(Phase.CHOOSE)
			else:
				_delta = npc.profile.finish_conversation(peer_id, _hits)
				var main := Level.find_level_node(npc).get_parent() as Main
				if main != null:
					main.world_save.request_save()
				_set_phase(Phase.RESULT, -1, int(signf(_delta)))

func _set_phase(new_phase: int, new_topic := -1, new_reaction := 0) -> void:
	presentation = Vector4i(peer_id, new_phase, new_topic, new_reaction)
	_elapsed = 0.0
	_publish()

func _publish() -> void:
	_send(peer_id, _token, {
		"phase": phase, "stage": _stage, "topic": topic_id,
		"matched": reaction > 0, "delta": _delta,
		"choices": _rounds[_stage] if _stage < _rounds.size() else PackedInt32Array(),
	})

func _send(receiver: int, token: int, data: Dictionary) -> void:
	if receiver == multiplayer.get_unique_id() or receiver in multiplayer.get_peers():
		_receive_state.rpc_id(receiver, token, data)

@rpc("authority", "call_local", "reliable")
func _receive_state(token: int, data: Dictionary) -> void:
	if token != _local_token or not is_instance_valid(_menu) or _menu.is_queued_for_deletion():
		return
	if data.get("closed", false):
		_menu.close(false)
	else:
		_menu.apply_state(data)

func _cancel(sender: int, token: int) -> void:
	if sender == peer_id and token == _token:
		_end()

func _on_peer_disconnected(sender: int) -> void:
	if sender == peer_id:
		_end()

func _end() -> void:
	var receiver := peer_id
	if receiver == 0:
		return
	npc.resume_after_conversation()
	presentation = Vector4i(0, Phase.CLOSED, -1, 0)
	_rounds.clear()
	_send(receiver, _token, {"closed": true})

func _exit_tree() -> void:
	if is_instance_valid(_menu):
		_menu.close(false)

func can_talk_to(player: Player, ongoing := false) -> bool:
	if not is_instance_valid(player) or player is NPC or player.is_queued_for_deletion() \
		or player.level_id != npc.level_id or player.in_vehicle or player.in_shower or player._smoking \
		or npc.in_shower or npc.in_vehicle or npc.is_queued_for_deletion():
		return false
	if multiplayer.is_server() and not ongoing and npc.state not in [NPC.State.ARRIVING, NPC.State.GOING_TO_BENCH,
		NPC.State.SITTING_ON_BENCH, NPC.State.LOOKING_FOR_SEAT, NPC.State.SITTING, NPC.State.GOING_TO_BARTENDER,
		NPC.State.WAITING_TO_ORDER, NPC.State.WAITING_FOR_DRINK, NPC.State.DRINKING, NPC.State.EXITING]:
		return false
	if not npc.interaction_area.overlaps_area(player.interaction_area):
		return false
	var excluded: Array[RID] = [npc.get_rid(), player.get_rid()]
	# A seated actor's own table is below their head, not a wall between speakers.
	for actor: Player in [npc, player]:
		if not actor.is_sitting:
			continue
		var seat := actor.seated_seat
		# Remote actors replicate seat ownership, not their local node reference.
		if not is_instance_valid(seat):
			for candidate: Seat in Level.find_level_node(npc).find_children("*", "Seat", true, false):
				if candidate.occupant_name == actor.name:
					seat = candidate
					break
		if not is_instance_valid(seat):
			continue
		var chair := seat.get_parent() as Chair
		if chair != null:
			for body in chair.get_parent().get_children():
				if body is StaticBody2D:
					excluded.append(body.get_rid())
	var offset := Vector2(0, -4) * npc._world_scale
	var ray := PhysicsRayQueryParameters2D.create(npc.global_position + offset, player.global_position + offset, 1, excluded)
	return npc.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

static func nearest(player: Player, areas: Array[Area2D]) -> NPCConversation:
	var nearest: NPC
	for area in areas:
		var npc := area.get_parent() as NPC
		if npc == null or npc.conversation.peer_id != 0 or not npc.conversation.can_talk_to(player):
			continue
		if nearest == null or player.global_position.distance_squared_to(npc.global_position) < player.global_position.distance_squared_to(nearest.global_position):
			nearest = npc
	return nearest.conversation if nearest != null else null
