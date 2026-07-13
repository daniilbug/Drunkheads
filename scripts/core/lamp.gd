class_name Lamp
extends Node2D

@onready var _light: Light2D = $Light

@export var is_turned_on: bool = true:
	set(value):
		print("set ", value)
		if is_node_ready():
			_light.visible = value
		is_turned_on = value
