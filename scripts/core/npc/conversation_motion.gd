class_name NPCConversationMotion
extends Node

const Phase = NPCConversation.Phase
var _tween: Tween
var _player: Player

@onready var _npc: NPC = get_parent().get_parent()

static func idle_frame(actor: Player) -> int:
	var row := actor._dir_to_idle_row(actor.direction)
	if actor.is_sitting:
		row = Player.ROW_WALK_N if actor.direction.y < 0 else Player.ROW_SIT
	return row * 4

static func face(actor: Player, target: Player) -> void:
	if not actor.global_position.is_equal_approx(target.global_position):
		actor.direction = actor.global_position.direction_to(target.global_position)
	actor.sprite.frame = idle_frame(actor)

func apply(peer_id: int, phase: int, reaction: int) -> void:
	if not is_instance_valid(_npc) or not _npc.is_node_ready():
		return
	_stop()
	var level := Level.find_level_node(_npc)
	_player = level.get_player(peer_id) if level != null and peer_id > 0 else null
	if phase == Phase.SPEAK and is_instance_valid(_player) and _player.is_multiplayer_authority():
		_tween = create_tween()
		_tween.tween_property(_player.sprite, "position:y", -1.0, 0.12)
		_tween.tween_property(_player.sprite, "position:y", 0.0, 0.16)
	elif phase == Phase.REPLY:
		_tween = create_tween()
		var lean := _npc.direction if reaction > 0 else Vector2.ZERO
		_tween.tween_property(_npc.sprite, "position", lean + Vector2(0, -1), 0.14)
		_tween.tween_property(_npc.sprite, "position", lean, 0.14)
		if reaction > 0:
			_tween.tween_property(_npc.sprite, "position", lean + Vector2(0, -1), 0.14)
		_tween.tween_property(_npc.sprite, "position", Vector2.ZERO, 0.18)

func _stop() -> void:
	if _tween != null:
		_tween.kill()
	if is_instance_valid(_player) and _player.is_inside_tree() and _player.is_multiplayer_authority():
		_player.sprite.position = Vector2.ZERO
	if is_instance_valid(_npc) and _npc.is_node_ready():
		_npc.sprite.position = Vector2.ZERO

func _exit_tree() -> void:
	_stop()
