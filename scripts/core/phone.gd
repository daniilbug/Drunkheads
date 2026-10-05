class_name Phone
extends CanvasLayer

signal taxi_requested
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
@onready var _launcher: Control = $Root/Screen/Launcher
@onready var _taxi_button: Button = $Root/Screen/Launcher/Apps/Taxi
@onready var _wallpapers_button: Button = $Root/Screen/Launcher/Apps/WallpapersButton
@onready var _music_button: Button = $Root/Screen/Launcher/Apps/MusicButton
@onready var _music_page: Control = $Root/Screen/MusicPlayer
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

func set_player_settings(settings: PlayerSettings) -> void:
	_settings = settings

func set_headphone_player(player: HeadphonePlayer) -> void:
	_headphone_player = player

func _ready() -> void:
	if _settings == null:
		_settings = PlayerSettings.new()
	_taxi_button.pressed.connect(_on_taxi_pressed)
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

func set_taxi_available(available: bool) -> void:
	_taxi_button.disabled = not available
	_taxi_button.modulate = Color.WHITE if available else Color(0.55, 0.55, 0.55)
	if _picker.visible or _music_page.visible:
		return
	if available:
		_taxi_button.grab_focus()
	else:
		_wallpapers_button.grab_focus()

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
	_launcher.hide()
	_music_page.hide()
	_picker.show()
	_preview_buttons[clampi(_settings.phone_wallpaper_index, 0, _preview_buttons.size() - 1)].grab_focus()

func _show_music() -> void:
	_launcher.hide()
	_picker.hide()
	_music_page.show()
	_toggle_button.grab_focus()

func _refresh_music() -> void:
	if _headphone_player == null:
		return
	_toggle_glyph.texture = PAUSE_ICON if _headphone_player.enabled else PLAY_ICON

func _show_launcher() -> void:
	_picker.hide()
	_music_page.hide()
	_launcher.show()
	if _taxi_button.disabled:
		_wallpapers_button.grab_focus()
	else:
		_taxi_button.grab_focus()

func _on_taxi_pressed() -> void:
	_taxi_button.disabled = true
	_taxi_button.modulate = Color(0.55, 0.55, 0.55)
	taxi_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("phone"):
		get_viewport().set_input_as_handled()
		closed.emit()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _picker.visible or _music_page.visible:
			_show_launcher()
		else:
			closed.emit()
	elif event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		var button := get_viewport().gui_get_focus_owner() as Button
		if button != null and not button.disabled and $Root.is_ancestor_of(button):
			button.pressed.emit()
