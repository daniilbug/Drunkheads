extends Control

const Layout = preload("res://scripts/core/menu/npc_conversation/layout.gd")
const Phase = NPCConversation.Phase
const PAPER := Color("e6dfcd")
const MUTED := Color("d6d9c7")
const PLUS = preload("res://assets/sprites/social/ui/affinity_plus.png")
const MINUS = preload("res://assets/sprites/social/ui/affinity_minus.png")
var player_point := Vector2.ZERO
var npc_point := Vector2.ZERO
var actor_scale := 4.0
var _state: Dictionary = {}
var _elapsed := 0.0
var _clock := 0.0
@onready var panel: Control = $Panel
@onready var player_bubble: NPCConversationBubble = $PlayerBubble
@onready var npc_bubble: NPCConversationBubble = $NPCBubble
@onready var player_topic: TextureRect = $PlayerTopic
@onready var npc_topic: TextureRect = $NPCTopic
@onready var heart: TextureRect = $Heart
@onready var thinking: Control = $Thinking
@onready var voice: Sprite2D = $Voice
@onready var spark: TextureRect = $Spark
@onready var result_mark: TextureRect = $ResultMark

func apply_state(data: Dictionary) -> void:
	_state = data
	_elapsed = 0.0
	_refresh()

func _process(delta: float) -> void:
	_elapsed += delta
	_clock += delta
	_refresh()

func _place(is_player: bool, extent: Vector2, occupied := Rect2()) -> Rect2:
	var head := player_point if is_player else npc_point
	var other := npc_point if is_player else player_point
	return Layout.place(head, other, extent, size, is_player, actor_scale, occupied)

func _refresh() -> void:
	for item in [player_bubble, npc_bubble, player_topic, npc_topic, heart, thinking, voice, spark, result_mark]:
		item.hide()
	if _state.is_empty() or player_point == Vector2.ZERO:
		return
	var phase: int = _state.phase
	if phase == Phase.CHOOSE:
		panel.position = _place(true, Vector2(248, 104)).position
		var choices := Rect2(panel.position, panel.size)
		player_bubble.show_at(choices, player_point, PAPER)
		var waiting := _place(false, Vector2(72, 56), choices)
		npc_bubble.show_at(waiting, npc_point, MUTED)
		_dots(waiting.position + Vector2(22, 24), false)
		return
	if phase == Phase.RESULT:
		_result()
		return
	var speech := _place(true, Vector2(80, 72))
	player_bubble.show_at(speech, player_point, PAPER)
	_icon(player_topic, ConversationTopics.ICONS[_state.topic], speech.position + Vector2(16, 10), 48)
	if phase == Phase.SPEAK:
		_voice(player_point + Vector2(24, -4))
	elif phase == Phase.LISTEN:
		var waiting := _place(false, Vector2(72, 56), speech)
		npc_bubble.show_at(waiting, npc_point, MUTED)
		_dots(waiting.position + Vector2(22, 24), true)
	elif phase == Phase.REPLY:
		var interested: bool = _state.matched
		var reply := _place(false, Vector2(112, 80) if interested else Vector2(80, 72), speech)
		npc_bubble.show_at(reply, npc_point, PAPER if interested else MUTED)
		if interested:
			_icon(npc_topic, ConversationTopics.ICONS[_state.topic], reply.position + Vector2(12, 18), 40)
			_icon(heart, ConversationTopics.HEART, reply.position + Vector2(60, 16 - roundf(sin(_elapsed * 9) * 2)), 40)
			spark.position = reply.position + Vector2(102, -6)
			spark.show()
			_voice(npc_point + Vector2(24, -4))
		else:
			_icon(npc_topic, ConversationTopics.NEUTRAL, reply.position + Vector2(16, 12), 48)

func _result() -> void:
	var delta: float = _state.delta
	var rect := _place(false, Vector2(56 if delta == 0 else 80, 56))
	npc_bubble.show_at(rect, npc_point, PAPER)
	# The 48px icon includes 8px transparent margins around its visible 32px glyph.
	_icon(npc_topic, ConversationTopics.NEUTRAL if delta == 0 else ConversationTopics.HEART, rect.position + Vector2(4, 4), 48)
	if delta != 0:
		result_mark.texture = PLUS if delta > 0 else MINUS
		result_mark.position = rect.position + Vector2(52, 20)
		result_mark.show()

func _icon(view: TextureRect, texture: Texture2D, origin: Vector2, extent: float) -> void:
	view.texture = texture
	view.position = origin.round()
	view.size = Vector2.ONE * extent
	view.show()

func _dots(origin: Vector2, animated: bool) -> void:
	thinking.position = origin
	for index in thinking.get_child_count():
		var bob := -4.0 if animated and int(_clock * 6) % 3 == index else 0.0
		thinking.get_child(index).position = Vector2(index * 12, bob)
	thinking.show()

func _voice(origin: Vector2) -> void:
	voice.frame = int(_clock * 8) % 2
	voice.position = (origin + Vector2(0, -2)).round()
	voice.show()
