extends Level

@onready var _balcony: Room = $BalconyRoom
@onready var _street_ambience: AudioStreamPlayer = $StreetAmbience

func _physics_process(_delta: float) -> void:
	var on_balcony := false
	if is_instance_valid(local_player) and local_player.is_inside_tree() and is_visible_in_tree():
		# Use the player's origin (feet), so the sound cannot leak through the wall.
		var balcony_position := _balcony.to_local(local_player.global_position)
		on_balcony = Rect2(Vector2.ZERO, _balcony.room_size).has_point(balcony_position)
	if on_balcony and not _street_ambience.playing:
		_street_ambience.play()
	elif not on_balcony and _street_ambience.playing:
		_street_ambience.stop()
