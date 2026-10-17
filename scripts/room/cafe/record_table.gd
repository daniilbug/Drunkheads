extends StaticBody2D

func _process(_delta: float) -> void:
	for slot: CafeRecordSlot in $Slots.get_children():
		slot.get_node("Cover").visible = slot.get_record() != null
