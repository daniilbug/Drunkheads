class_name BarWC
extends Room

@onready var lamp: Lamp = $Lamp
@onready var switch: Switch = $NavigationRegion/YSort/Switch

func _ready() -> void:
	switch.on_switch.connect(_invert_light)
	lamp.is_turned_on = true
	super._ready()

func _invert_light() -> void:
	lamp.is_turned_on = not lamp.is_turned_on
