extends LightSource


func _bind_world_time(clock: WorldTime) -> void:
	super._bind_world_time(clock)
	clock.night_lighting_changed.connect(_on_night_lighting_changed)
	_apply_light_state()


func _on_night_lighting_changed(_strength: float) -> void:
	_apply_light_state()


func _exit_tree() -> void:
	if is_instance_valid(_world_time) and _world_time.night_lighting_changed.is_connected(_on_night_lighting_changed):
		_world_time.night_lighting_changed.disconnect(_on_night_lighting_changed)
	super._exit_tree()


func _apply_light_state() -> void:
	super._apply_light_state()
	if not is_instance_valid(_world_time):
		return
	# The shop stays lit at night without bleaching the floor in daylight.
	for light in _lights:
		light.energy *= lerpf(0.08, 1.0, _world_time.get_night_light_strength())
