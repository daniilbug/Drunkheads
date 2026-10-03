class_name VehicleInteraction
extends Interactable

@onready var area: Area2D = $Area

func interact(player: Player) -> void:
	var vehicle := get_parent() as Vehicle
	if vehicle != null:
		vehicle.request_interaction(player)
