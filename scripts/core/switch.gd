class_name Switch
extends Interactable

signal on_switch()

@onready var audio: AudioStreamPlayer2D = $Audio

func interact() -> void:
	on_switch.emit()
	audio.play()
