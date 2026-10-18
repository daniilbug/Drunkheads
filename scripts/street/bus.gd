class_name Bus
extends Vehicle

enum ServiceState { APPROACHING, BOARDING, LEAVING }
const DESTINATION_FADE_SECONDS := 0.5

@export var destination_id := "":
	set(value):
		if destination_id == value:
			return
		destination_id = value
		if is_node_ready():
			_refresh_destination(true)

@export var service_state: ServiceState = ServiceState.APPROACHING

@onready var _destination_icon: Sprite2D = $Visuals/DestinationIcon

var _destination_tween: Tween

# The server keeps the manifest; peers observe passengers through Player's
# existing server-owned in_vehicle, level_id and riding_vehicle_name fields.
var passenger_ids: Array[int] = []

func _ready() -> void:
	super._ready()
	_refresh_destination()

func _refresh_destination(animate := false) -> void:
	var level := Level.find_level_node(self)
	var main := level.get_parent() as Main if level != null else null
	var destination := main.transport.get_destination(destination_id) if main != null else null
	var texture := destination.icon if destination != null else null
	if _destination_tween != null:
		_destination_tween.kill()
	if not animate or texture == null or _destination_icon.texture == null or _destination_icon.texture == texture:
		_set_destination_icon(texture)
		_destination_icon.modulate.a = 1.0
		return
	_destination_tween = create_tween()
	_destination_tween.tween_property(_destination_icon, "modulate:a", 0.0, DESTINATION_FADE_SECONDS)
	_destination_tween.tween_callback(_set_destination_icon.bind(texture))
	_destination_tween.tween_property(_destination_icon, "modulate:a", 1.0, DESTINATION_FADE_SECONDS)

func _set_destination_icon(texture: Texture2D) -> void:
	_destination_icon.texture = texture
	_destination_icon.visible = texture != null
