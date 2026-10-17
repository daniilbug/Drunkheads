class_name Phone
extends CanvasLayer

signal taxi_requested(destination: String)
signal closed

const WALLPAPERS := [
	preload("res://assets/sprites/phone/wallpaper_midnight.png"),
	preload("res://assets/sprites/phone/wallpaper_amber.png"),
	preload("res://assets/sprites/phone/wallpaper_sage.png"),
	preload("res://assets/sprites/phone/wallpaper_plum.png"),
]
const PLAY_ICON := preload("res://assets/sprites/phone/play_icon.png")
const PAUSE_ICON := preload("res://assets/sprites/phone/pause_icon.png")
@onready var _wallpaper: TextureRect = $Root/Screen/Wallpaper
@onready var _time_label: Label = $Root/Screen/StatusBar/Time
@onready var _launcher: Control = $Root/Screen/Launcher
@onready var _taxi_button: Button = $Root/Screen/Launcher/Apps/Taxi
@onready var _taxi_page: Control = $Root/Screen/TaxiDestinations
@onready var _destination_buttons: Array[Button] = [
	$Root/Screen/TaxiDestinations/Options/Bar,
	$Root/Screen/TaxiDestinations/Options/Cafe,
	$Root/Screen/TaxiDestinations/Options/Home,
]
@onready var _wallpapers_button: Button = $Root/Screen/Launcher/Apps/WallpapersButton
@onready var _music_button: Button = $Root/Screen/Launcher/Apps/MusicButton
@onready var _music_page: Control = $Root/Screen/MusicPlayer
@onready var _music_wave: PhoneMusicWave = $Root/Screen/MusicPlayer/Wave
@onready var _music_progress: ProgressBar = $Root/Screen/MusicPlayer/Progress
@onready var _previous_button: Button = $Root/Screen/MusicPlayer/Controls/Previous
@onready var _toggle_button: Button = $Root/Screen/MusicPlayer/Controls/Toggle
@onready var _toggle_glyph: TextureRect = $Root/Screen/MusicPlayer/Controls/Toggle/Glyph
@onready var _next_button: Button = $Root/Screen/MusicPlayer/Controls/Next
@onready var _picker: Control = $Root/Screen/WallpaperPicker
@onready var _preview_buttons: Array[Button] = [
	$Root/Screen/WallpaperPicker/Previews/Preview1,
	$Root/Screen/WallpaperPicker/Previews/Preview2,
	$Root/Screen/WallpaperPicker/Previews/Preview3,
	$Root/Screen/WallpaperPicker/Previews/Preview4,
]

var _settings: PlayerSettings
var _headphone_player: HeadphonePlayer
var _world_time: WorldTime
var _current_level := "bar"
var _taxi_available := true

func set_player_settings(settings: PlayerSettings) -> void:
	_settings = settings

func set_headphone_player(player: HeadphonePlayer) -> void:
	_headphone_player = player

func set_world_time(clock: WorldTime) -> void:
	if is_instance_valid(_world_time) and _world_time.time_changed.is_connected(_update_time):
		_world_time.time_changed.disconnect(_update_time)
	_world_time = clock
	if is_instance_valid(_world_time):
		_world_time.time_changed.connect(_update_time)
		_update_time(_world_time.get_hour())
	elif is_node_ready():
		_time_label.text = "--:--"

func _update_time(hour: float) -> void:
	if not is_node_ready():
		return
	# Float32 network snapshots can fall just below an exact minute boundary.
	var minutes := floori(hour * 60.0 + 0.0001) % 1440
	_time_label.text = "%02d:%02d" % [floori(minutes / 60.0), minutes % 60]

func _ready() -> void:
	if _settings == null:
		_settings = PlayerSettings.new()
	if is_instance_valid(_world_time):
		_update_time(_world_time.get_hour())
	_taxi_button.pressed.connect(_on_taxi_pressed)
	for i in _destination_buttons.size():
		_destination_buttons[i].pressed.connect(_order_taxi.bind(["bar", "cafe", "home"][i]))
	$Root/Screen/TaxiDestinations/Options/Back.pressed.connect(_show_launcher)
	_wallpapers_button.pressed.connect(_show_picker)
	_music_button.pressed.connect(_show_music)
	_music_button.disabled = _headphone_player == null
	if _headphone_player != null:
		_previous_button.pressed.connect(_headphone_player.select_relative.bind(-1))
		_toggle_button.pressed.connect(_headphone_player.toggle)
		_next_button.pressed.connect(_headphone_player.select_relative.bind(1))
		_headphone_player.changed.connect(_refresh_music)
		_refresh_music()
	for i in _preview_buttons.size():
		_preview_buttons[i].pressed.connect(_select_wallpaper.bind(i))
	_apply_wallpaper()
	_show_launcher()

func _process(_delta: float) -> void:
	if _music_page.visible:
		_update_music_visuals()

func set_taxi_available(available: bool) -> void:
	_taxi_available = available
	_refresh_destinations()
	_taxi_button.disabled = not available
	_taxi_button.modulate = Color.WHITE if available else Color(0.55, 0.55, 0.55)
	if _picker.visible or _music_page.visible or _taxi_page.visible:
		return
	if available:
		_taxi_button.grab_focus()
	else:
		_wallpapers_button.grab_focus()

func set_taxi_context(current_level: String) -> void:
	_current_level = current_level
	_refresh_destinations()

func _refresh_destinations() -> void:
	for i in _destination_buttons.size():
		_destination_buttons[i].disabled = not _taxi_available or ["bar", "cafe", "home"][i] == _current_level

func _apply_wallpaper() -> void:
	var index := clampi(_settings.phone_wallpaper_index, 0, WALLPAPERS.size() - 1)
	_wallpaper.texture = WALLPAPERS[index]
	for i in _preview_buttons.size():
		var selected := i == index
		var frame := StyleBoxFlat.new()
		frame.bg_color = Color(0.08, 0.12, 0.15)
		frame.border_color = Color(0.92, 0.76, 0.47) if selected else Color(0.28, 0.33, 0.34)
		frame.set_border_width_all(3)
		_preview_buttons[i].add_theme_stylebox_override("normal", frame)
		_preview_buttons[i].add_theme_stylebox_override("hover", frame)
		_preview_buttons[i].add_theme_stylebox_override("pressed", frame)

func _select_wallpaper(index: int) -> void:
	_settings.phone_wallpaper_index = index
	_apply_wallpaper()
	_show_launcher()

func _show_picker() -> void:
	_taxi_page.hide()
	_launcher.hide()
	_music_page.hide()
	_picker.show()
	_preview_buttons[clampi(_settings.phone_wallpaper_index, 0, _preview_buttons.size() - 1)].grab_focus()

func _show_music() -> void:
	_taxi_page.hide()
	_launcher.hide()
	_picker.hide()
	_music_page.show()
	_update_music_visuals()
	_toggle_button.grab_focus()

func _refresh_music() -> void:
	if _headphone_player == null:
		return
	_toggle_glyph.texture = PAUSE_ICON if _headphone_player.enabled else PLAY_ICON
	_update_music_visuals()

func _update_music_visuals() -> void:
	if _headphone_player == null:
		return
	var position := _headphone_player.get_playback_position()
	var playing := _headphone_player.enabled and _headphone_player.playing
	if playing:
		position += AudioServer.get_time_since_last_mix()
	var duration := _headphone_player.stream.get_length()
	_music_progress.value = clampf(position / duration, 0.0, 1.0) if duration > 0.0 else 0.0
	_music_wave.update_playback(position, playing)

func _show_launcher() -> void:
	_taxi_page.hide()
	_picker.hide()
	_music_page.hide()
	_launcher.show()
	if _taxi_button.disabled:
		_wallpapers_button.grab_focus()
	else:
		_taxi_button.grab_focus()

func _on_taxi_pressed() -> void:
	_launcher.hide()
	_picker.hide()
	_music_page.hide()
	_taxi_page.show()
	_refresh_destinations()
	for button in _destination_buttons:
		if not button.disabled:
			button.grab_focus()
			break

func _order_taxi(destination: String) -> void:
	if not _taxi_available or destination == _current_level:
		return
	set_taxi_available(false)
	taxi_requested.emit(destination)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("phone"):
		get_viewport().set_input_as_handled()
		closed.emit()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _picker.visible or _music_page.visible or _taxi_page.visible:
			_show_launcher()
		else:
			closed.emit()
	elif event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		var button := get_viewport().gui_get_focus_owner() as Button
		if button != null and not button.disabled and $Root.is_ancestor_of(button):
			button.pressed.emit()
