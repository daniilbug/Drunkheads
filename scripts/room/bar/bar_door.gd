@tool
class_name BarDoor
extends Door

@onready var light: Light2D = $Light

func _apply_state(was_open: bool) -> void:
	super._apply_state(was_open)
	_update_light()
	
func _update_light() -> void:
	if is_open:
		light.enabled = true
	else:
		light.enabled = false
