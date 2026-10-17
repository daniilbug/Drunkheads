@tool
class_name BarHall
extends Room

const BOOMBOX_SCENE := preload("res://scenes/room/bar/boombox.tscn")
const DANCE_FLOOR_CONTROLLER := preload("res://scenes/room/bar/dance_floor_controller.tscn")

@onready var bartender: Bartender = $NavigationRegion/YSort/Bartender
@onready var dance_floor: DanceFloor = $FloorDecorations/DanceFloor

func init_room() -> void:
	var boombox: Boombox = BOOMBOX_SCENE.instantiate()
	var dance_floor_controller: DanceFloorController = DANCE_FLOOR_CONTROLLER.instantiate()
	y_sort.add_child(boombox)
	y_sort.add_child(dance_floor_controller)
	if multiplayer.is_server():
		boombox.drop(null, bartender.boombox_place)
		dance_floor_controller.on_mode_change.connect(func(mode: int): dance_floor.set_mode(mode))
		dance_floor_controller.drop(null, bartender.dance_floor_controller_place)
