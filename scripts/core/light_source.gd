class_name LightSource
extends Node2D

## Shared lighting for lamps, signs and multi-light scenery. The server owns
## switch state and schedule settings; peers derive smooth visuals from WorldTime.
@export_group("Lighting")
@export var lighting_enabled: bool = true:
	set(value):
		lighting_enabled = value
		_refresh_settings()
@export var is_turned_on: bool = true:
	set(value):
		is_turned_on = value
		if is_node_ready():
			_apply_light_state()
@export var automatic_lighting: bool = false:
	set(value):
		automatic_lighting = value
		_refresh_settings()
@export_range(0.0, 24.0, 0.25) var switch_on_hour: float = 18.0:
	set(value):
		switch_on_hour = value
		_refresh_settings()
## Equal on/off hours mean all day. An end before the start crosses midnight.
@export_range(0.0, 24.0, 0.25) var switch_off_hour: float = 8.0:
	set(value):
		switch_off_hour = value
		_refresh_settings()
## Set to zero for an immediate switch at the configured hours.
@export_range(0.0, 12.0, 0.25) var fade_duration_hours: float = 2.0:
	set(value):
		fade_duration_hours = value
		_refresh_settings()

@export_group("Lighting visuals")
@export var light_sources: Array[Light2D] = []
## Optional emissive visuals, including scenes with no Light2D nodes.
@export var glow_sprites: Array[CanvasItem] = []
@export_range(0.0, 1.0) var unlit_brightness: float = 0.35

var _world_time: WorldTime
var _schedule_strength: float = 1.0
var _flicker_strength: float = 1.0
var _lights: Array[Light2D] = []
var _base_energies: Array[float] = []
var _base_enabled: Array[bool] = []
var _glows: Array[CanvasItem] = []
var _glow_colors: Array[Color] = []

func _ready() -> void:
	for light in light_sources:
		if light != null:
			_lights.append(light)
			_base_energies.append(light.energy)
			_base_enabled.append(light.enabled)
	for glow in glow_sprites:
		if glow != null:
			_glows.append(glow)
			_glow_colors.append(glow.self_modulate)
	_apply_light_state()
	var level := Level.find_level_node(self)
	if level == null:
		return
	if level.world_time != null:
		_bind_world_time(level.world_time)
	else:
		level.world_time_ready.connect(_bind_world_time, CONNECT_ONE_SHOT)

func _exit_tree() -> void:
	if is_instance_valid(_world_time) and _world_time.time_changed.is_connected(_on_time_changed):
		_world_time.time_changed.disconnect(_on_time_changed)
	_world_time = null

func _bind_world_time(clock: WorldTime) -> void:
	_world_time = clock
	clock.time_changed.connect(_on_time_changed)
	_on_time_changed(clock.get_hour())

func _refresh_settings() -> void:
	if not is_node_ready():
		return
	if automatic_lighting and is_instance_valid(_world_time):
		_on_time_changed(_world_time.get_hour())
	else:
		_apply_light_state()

func _on_time_changed(hour: float) -> void:
	if not is_inside_tree() or not automatic_lighting:
		return
	_schedule_strength = get_schedule_strength(hour)
	if multiplayer.is_server():
		var scheduled_on := lighting_enabled and _schedule_strength > 0.001
		if is_turned_on != scheduled_on:
			is_turned_on = scheduled_on
	_apply_light_state()

func get_schedule_strength(hour: float) -> float:
	var duration := fposmod(switch_off_hour - switch_on_hour, WorldTime.HOURS_PER_DAY)
	if is_zero_approx(duration):
		return 1.0
	var elapsed := fposmod(hour - switch_on_hour, WorldTime.HOURS_PER_DAY)
	if elapsed >= duration:
		return 0.0
	var fade := clampf(fade_duration_hours, 0.0, duration * 0.5)
	if is_zero_approx(fade):
		return 1.0
	return minf(minf(elapsed, duration - elapsed) / fade, 1.0)

func is_light_active() -> bool:
	if not lighting_enabled:
		return false
	# Scheduled visuals use the clock, so an earlier switch-state packet cannot
	# briefly override the displayed time during a server seek or late join.
	if automatic_lighting and is_instance_valid(_world_time):
		return _schedule_strength > 0.001
	return is_turned_on

func set_flicker_strength(strength: float) -> void:
	_flicker_strength = strength
	_apply_light_state()

func _apply_light_state() -> void:
	var active := is_light_active()
	var strength := _flicker_strength if active else 0.0
	if automatic_lighting and is_instance_valid(_world_time):
		strength *= _schedule_strength
	for i in _lights.size():
		var light := _lights[i]
		if is_instance_valid(light):
			light.visible = active
			light.enabled = _base_enabled[i] and active
			light.energy = _base_energies[i] * strength
	var brightness := lerpf(unlit_brightness, 1.0, clampf(strength, 0.0, 1.0))
	for i in _glows.size():
		if is_instance_valid(_glows[i]):
			_glows[i].self_modulate = _glow_colors[i] * Color(brightness, brightness, brightness, 1.0)

func _enter_tree() -> void:
	add_to_group("saveable")

func get_save_data() -> Dictionary:
	return SaveGraph.get_fields(self, ["is_turned_on", "lighting_enabled", "automatic_lighting", "switch_on_hour", "switch_off_hour", "fade_duration_hours"])

func apply_save_data(data: Dictionary) -> void:
	SaveGraph.apply_fields(self, get_save_data().keys(), data)
