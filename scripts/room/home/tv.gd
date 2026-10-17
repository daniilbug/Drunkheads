@tool
extends Switch

const MIN_COLOR_HOLD_SECONDS := 1.0
const MAX_COLOR_HOLD_SECONDS := 3.0

@export var broadcast_colors: Gradient

@export var is_turned_on := false:
	set(value):
		is_turned_on = value
		if is_node_ready():
			_update_power()

## Only the server advances the palette; late joiners receive the current color.
@export var color_index := 0:
	set(value):
		color_index = value
		if is_node_ready():
			_update_color()

@onready var _light: PointLight2D = $Light
@onready var _power_led: Sprite2D = $PowerLED
@onready var _area: Area2D = $Area
@onready var _color_timer: Timer = $ColorTimer

func _ready() -> void:
	_color_timer.timeout.connect(_on_color_timeout)
	_update_power()
	_update_color()

func _on_color_timeout() -> void:
	if not multiplayer.is_server() or not is_turned_on:
		return
	if broadcast_colors != null:
		color_index = (color_index + 1) % broadcast_colors.get_point_count()
	_start_color_timer()

func _start_color_timer() -> void:
	_color_timer.start(randf_range(MIN_COLOR_HOLD_SECONDS, MAX_COLOR_HOLD_SECONDS))

func interact(player: Player) -> void:
	if multiplayer.is_server():
		_toggle_for(int(player.name))
	else:
		_request_toggle.rpc_id(1)

@rpc("any_peer", "reliable")
func _request_toggle() -> void:
	if multiplayer.is_server():
		_toggle_for(multiplayer.get_remote_sender_id())

func _toggle_for(peer_id: int) -> void:
	var level := Level.find_level_node(self)
	var player := level.get_player(peer_id) if level != null else null
	if player == null or player.is_world_input_blocked or not _area.overlaps_area(player.interaction_area):
		return
	is_turned_on = not is_turned_on
	_play_switch_sound.rpc()

@rpc("authority", "call_local", "reliable")
func _play_switch_sound() -> void:
	on_switch.emit()
	audio.play()

func _update_power() -> void:
	_light.visible = is_turned_on
	_power_led.self_modulate = Color("91cbb0") if is_turned_on else Color("80564f")
	if not Engine.is_editor_hint() and multiplayer.is_server():
		_color_timer.paused = not is_turned_on
		if is_turned_on and _color_timer.is_stopped():
			_start_color_timer()

func _update_color() -> void:
	if broadcast_colors != null:
		_light.color = broadcast_colors.get_color(wrapi(color_index, 0, broadcast_colors.get_point_count()))
