@tool
class_name BarDoor
extends Door

@onready var light: Light2D = $Light
@onready var _lighting: LightSource = $Lighting

func _apply_state(was_open: bool) -> void:
	super._apply_state(was_open)
	_update_light()
	
func _update_light() -> void:
	if Engine.is_editor_hint():
		light.enabled = is_open
	else:
		_lighting.is_turned_on = is_open
