class_name WC
extends Room

@onready var lamp: Lamp = $Lamp
@onready var switch: Switch = $YSort/Switch

func _ready() -> void:
	switch.on_switch.connect(_invert_light)
	super._ready()

func _invert_light() -> void:
	lamp.visible = not lamp.visible
