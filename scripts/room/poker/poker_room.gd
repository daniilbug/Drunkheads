@tool
class_name BarPokerRoom
extends Room

@onready var lamp: Lamp = $Lamp

func _on_switch() -> void:
	lamp.is_turned_on = not lamp.is_turned_on
