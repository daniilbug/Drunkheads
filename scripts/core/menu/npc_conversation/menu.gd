extends CanvasLayer

const Phase = NPCConversation.Phase
var _player: Player
var _seated_direction := Vector2.DOWN
var _conversation: NPCConversation
var _token := 0
var _state: Dictionary = {}
var _waiting := true
var _pending_seconds := 0.0
var _closing := false
@onready var bubbles: Control = $Bubbles
@onready var panel: Control = $Bubbles/Panel
var buttons: Array[Button] = []

func _ready() -> void:
	for child: Button in panel.get_children():
		buttons.append(child)
		child.pressed.connect(_choose.bind(buttons.size() - 1))
	multiplayer.server_disconnected.connect(close.bind(false))

func open(player: Player, conversation: NPCConversation, token: int) -> void:
	_player = player
	_seated_direction = player.direction
	_conversation = conversation
	_token = token
	_player.is_world_input_blocked = true
	_player.velocity = Vector2.ZERO
	NPCConversationMotion.face(_player, conversation.npc)
	_player._animate_movement(0.0, Vector2.ZERO)
	_player.audio.stop()
	_player.tree_exiting.connect(close.bind(false), CONNECT_ONE_SHOT)
	_conversation.tree_exiting.connect(close.bind(false), CONNECT_ONE_SHOT)
	panel.hide()

func apply_state(data: Dictionary) -> void:
	_state = data
	_waiting = false
	_pending_seconds = 0.0
	bubbles.apply_state(data)
	panel.visible = data.phase == Phase.CHOOSE
	if not panel.visible:
		return
	for index in buttons.size():
		buttons[index].disabled = false
		(buttons[index].get_node("Icon") as TextureRect).texture = ConversationTopics.ICONS[data.choices[index]]
	buttons[0].grab_focus.call_deferred()

func _choose(index: int) -> void:
	if _waiting or _state.get("phase", Phase.CLOSED) != Phase.CHOOSE:
		return
	_waiting = true
	_pending_seconds = 0.0
	for button in buttons:
		button.disabled = true
	_conversation.choose(_token, _state.stage, _state.choices[index])

func _process(delta: float) -> void:
	if _closing or not is_instance_valid(_player) or not is_instance_valid(_conversation):
		close(false)
		return
	if _player.level_id != _conversation.npc.level_id or _player.in_vehicle:
		close()
		return
	if _waiting:
		_pending_seconds += delta
		if _pending_seconds > 8.0:
			close()
			return
	var player_transform := _player.get_global_transform_with_canvas()
	var npc_transform := _conversation.npc.get_global_transform_with_canvas()
	bubbles.player_point = player_transform * Vector2(0, -16)
	bubbles.npc_point = npc_transform * Vector2(0, -16)
	bubbles.actor_scale = player_transform.x.length()
	NPCConversationMotion.face(_player, _conversation.npc)

func _unhandled_input(event: InputEvent) -> void:
	if _closing or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif event.is_action_pressed("interact") or (_state.get("phase") == Phase.RESULT and event.is_action_pressed("ui_accept")):
		get_viewport().set_input_as_handled()
		if _state.get("phase") == Phase.RESULT:
			close()
		elif panel.visible and not _waiting:
			var focused := get_viewport().gui_get_focus_owner()
			if focused in buttons:
				_choose(buttons.find(focused))
	elif panel.visible and not _waiting:
		for action in ["left", "right"]:
			if event.is_action_pressed(action):
				var index := buttons.find(get_viewport().gui_get_focus_owner())
				var step := -1 if action == "left" else 1
				buttons[posmod(index + step, buttons.size())].grab_focus()
				get_viewport().set_input_as_handled()
				return

func close(notify := true) -> void:
	if _closing:
		return
	_closing = true
	hide()
	_release_player()
	if notify and is_instance_valid(_conversation) and _conversation.is_inside_tree():
		_conversation.close(_token)
	queue_free()

func _exit_tree() -> void:
	_release_player()

func _release_player() -> void:
	if is_instance_valid(_player):
		_player.is_world_input_blocked = false
		if _player.is_sitting:
			_player.direction = _seated_direction
			_player.sprite.frame = NPCConversationMotion.idle_frame(_player)
