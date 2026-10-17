@tool
class_name HomeToiletDoor
extends Door

@export var light_source: Lamp

@onready var _spill_light: PointLight2D = $Light
@onready var _lighting: LightSource = $Lighting
@onready var _source_light: Light2D = light_source.get_node("Light") if light_source != null else null

func _ready() -> void:
	super._ready()
	if _source_light != null:
		_source_light.visibility_changed.connect(_update_light)
	_update_light()

func _apply_state(was_open: bool) -> void:
	super._apply_state(was_open)
	_update_light()

func _update_light() -> void:
	var active := is_open and is_instance_valid(_source_light) and _source_light.is_visible_in_tree()
	if Engine.is_editor_hint():
		_spill_light.enabled = active
	else:
		_lighting.is_turned_on = active
