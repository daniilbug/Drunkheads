@tool
class_name CafeHall
extends Room

@onready var bartender: Bartender = $NavigationRegion/YSort/Bartender

func init_room() -> void:
	if not multiplayer.is_server():
		return
	var level := Level.find_level_node(self)
	for slot: CafeRecordSlot in $NavigationRegion/YSort/RecordTable/Slots.get_children():
		var record := load("res://scenes/room/cafe/record.tscn").instantiate() as CafeRecord
		record.name = "CafeRecord%d" % slot.record_id
		record.record_id = slot.record_id
		record.dock_path = slot.get_path()
		record.position = level.to_local(slot.shape.global_position)
		level.add_child(record)
