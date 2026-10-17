@tool
class_name CafeHall
extends Room

@onready var bartender: Bartender = $NavigationRegion/YSort/Bartender

func init_room() -> void:
	var boombox := load("res://scenes/room/bar/boombox.tscn").instantiate() as Boombox
	boombox.name = "Boombox"
	y_sort.add_child(boombox)
	if multiplayer.is_server():
		boombox.drop(null, bartender.boombox_place)
