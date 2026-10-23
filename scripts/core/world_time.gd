class_name WorldTime
extends Node

## Main owns one clock for all loaded levels. A standalone Level owns its own
## instance of this scene. Authority remains with the server (peer 1).
signal time_changed(hour: float)
signal night_lighting_changed(strength: float)

const SAVE_SCHEMA := {"hours": 0.0, "day_duration": 0.0, "time_scale": 0.0, "paused": false}
const HOURS_PER_DAY := 24.0
const CORRECTION_SPEED := 6.0

@export_range(0.0, 24.0, 0.01) var initial_hour: float = 16.0
@export_range(1.0, 86400.0, 1.0, "or_greater", "suffix:s") var day_duration: float = 1800.0
@export_range(0.0, 100.0, 0.1, "or_greater") var time_scale: float = 1.0
@export var paused: bool = false
## RGB is subtracted from the world; alpha controls automatic night lights.
@export var lighting_profile: Gradient

# One snapshot keeps the time, rate and seek revision consistent on every peer.
# Hours remain unwrapped so correction across midnight follows the forward cycle.
var clock_snapshot: Vector3 = Vector3.ZERO:
	set(value):
		clock_snapshot = value
		if not is_node_ready() or is_multiplayer_authority():
			return
		_target_hours = value.x
		if not _has_snapshot or value.z != _seek_revision or value.y != _prediction_rate:
			_display_hours = value.x
		_prediction_rate = value.y
		_seek_revision = int(value.z)
		_has_snapshot = true
		_update_lighting()

@onready var _darkness: DirectionalLight2D = $Darkness

var _total_hours: float = 0.0
var _display_hours: float = 0.0
var _target_hours: float = 0.0
var _prediction_rate: float = 0.0
var _seek_revision: int = 0
var _has_snapshot: bool = false
var _night_strength: float = -1.0

func _ready() -> void:
	_total_hours = fposmod(initial_hour, HOURS_PER_DAY)
	_display_hours = _total_hours
	if is_multiplayer_authority():
		_publish_snapshot()
	_update_lighting()

func _process(delta: float) -> void:
	# Freeze a disconnected client's clock instead of querying an inactive peer.
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if is_multiplayer_authority():
		_total_hours += delta * _get_rate()
		_display_hours = _total_hours
		_publish_snapshot()
	elif _has_snapshot:
		_target_hours += delta * _prediction_rate
		_display_hours += delta * _prediction_rate
		_display_hours = lerpf(_display_hours, _target_hours, 1.0 - exp(-CORRECTION_SPEED * delta))
	_update_lighting()

func get_hour() -> float:
	return fposmod(_display_hours, HOURS_PER_DAY)

func get_save_data() -> Dictionary:
	return {"hours": _total_hours, "day_duration": day_duration, "time_scale": time_scale, "paused": paused}

func apply_save_data(data: Dictionary) -> void:
	if not is_multiplayer_authority():
		return
	_total_hours = maxf(0.0, float(data.get("hours", initial_hour)))
	_display_hours = _total_hours
	day_duration = maxf(1.0, float(data.get("day_duration", day_duration)))
	time_scale = maxf(0.0, float(data.get("time_scale", time_scale)))
	paused = data.get("paused", false)
	_seek_revision += 1
	_publish_snapshot()
	_update_lighting()

func get_night_light_strength() -> float:
	return _night_strength

## Local server/debug control. Clients cannot change the shared clock.
func set_time_of_day(hour: float) -> void:
	if not is_multiplayer_authority() or not is_finite(hour):
		return
	_total_hours = floorf(_total_hours / HOURS_PER_DAY) * HOURS_PER_DAY + fposmod(hour, HOURS_PER_DAY)
	_display_hours = _total_hours
	_seek_revision += 1
	_publish_snapshot()
	_update_lighting()

func _get_rate() -> float:
	return 0.0 if paused else HOURS_PER_DAY / maxf(day_duration, 1.0) * maxf(time_scale, 0.0)

func _publish_snapshot() -> void:
	clock_snapshot = Vector3(_total_hours, _get_rate(), _seek_revision)

func _update_lighting() -> void:
	var lighting := lighting_profile.sample(get_hour() / HOURS_PER_DAY) if lighting_profile != null else Color(0, 0, 0, 0)
	_darkness.color = Color(lighting.r, lighting.g, lighting.b, 1.0)
	_darkness.enabled = maxf(lighting.r, maxf(lighting.g, lighting.b)) > 0.0001
	var strength := clampf(lighting.a, 0.0, 1.0)
	if not is_equal_approx(strength, _night_strength):
		_night_strength = strength
		night_lighting_changed.emit(strength)
	time_changed.emit(get_hour())
