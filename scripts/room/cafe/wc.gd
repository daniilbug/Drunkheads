@tool
class_name CafeWC
extends Room

@onready var lamp: Lamp = $Lamp
@onready var light_switch: Switch = $NavigationRegion/YSort/Switch

func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		light_switch.on_switch.connect(_on_switch)

func _on_switch() -> void:
	lamp.is_turned_on = not lamp.is_turned_on
