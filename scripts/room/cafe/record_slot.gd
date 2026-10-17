class_name CafeRecordSlot
extends DropPlace

## -1 is the turntable; the table's four places each accept their own record.
@export_range(-1, 3) var record_id := -1

func get_record() -> CafeRecord:
	var level := Level.find_level_node(self)
	for child in level.get_children():
		if child is CafeRecord and child.dock_path == get_path():
			return child
	return null

func accepts(record: CafeRecord) -> bool:
	return (record_id == -1 or record_id == record.record_id) and get_record() == null
