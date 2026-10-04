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
const SETTINGS_PATH := "user://phone_settings.cfg"

@onready var _wallpaper: TextureRect = $Root/Screen/Wallpaper
@onready var _launcher: Control = $Root/Screen/Launcher
@onready var _taxi_button: Button = $Root/Screen/Launcher/Taxi
@onready var _wallpapers_button: Button = $Root/Screen/Launcher/WallpapersButton
@onready var _picker: Control = $Root/Screen/WallpaperPicker
@onready var _preview_buttons: Array[Button] = [
	$Root/Screen/WallpaperPicker/Preview1,
	$Root/Screen/WallpaperPicker/Preview2,
	$Root/Screen/WallpaperPicker/Preview3,
	$Root/Screen/WallpaperPicker/Preview4,
]

var _wallpaper_index := 0

func _ready() -> void:
	_taxi_button.pressed.connect(_on_taxi_pressed)
	_wallpapers_button.pressed.connect(_show_picker)
	for i in _preview_buttons.size():
		_preview_buttons[i].pressed.connect(_select_wallpaper.bind(i))
	_load_wallpaper()
	_apply_wallpaper()
	_show_launcher()

func set_taxi_available(available: bool) -> void:
	_taxi_button.disabled = not available
	_taxi_button.modulate = Color.WHITE if available else Color(0.55, 0.55, 0.55)
	if _picker.visible:
		return
	if available:
		_taxi_button.grab_focus()
	else:
		_wallpapers_button.grab_focus()

func _load_wallpaper() -> void:
	var settings := ConfigFile.new()
	if settings.load(SETTINGS_PATH) != OK:
		return
	var saved_index: Variant = settings.get_value("phone", "wallpaper", 0)
	if typeof(saved_index) == TYPE_INT and saved_index >= 0 and saved_index < WALLPAPERS.size():
		_wallpaper_index = saved_index

func _apply_wallpaper() -> void:
	_wallpaper.texture = WALLPAPERS[_wallpaper_index]
	for i in _preview_buttons.size():
		var selected := i == _wallpaper_index
		var frame := StyleBoxFlat.new()
		frame.bg_color = Color(0.08, 0.12, 0.15)
		frame.border_color = Color(0.92, 0.76, 0.47) if selected else Color(0.28, 0.33, 0.34)
		frame.set_border_width_all(3)
		_preview_buttons[i].add_theme_stylebox_override("normal", frame)
		_preview_buttons[i].add_theme_stylebox_override("hover", frame)
		_preview_buttons[i].add_theme_stylebox_override("pressed", frame)

func _select_wallpaper(index: int) -> void:
	_wallpaper_index = index
	_apply_wallpaper()
	var settings := ConfigFile.new()
	settings.set_value("phone", "wallpaper", index)
	var error := settings.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Could not save phone wallpaper: %s" % error_string(error))
	_show_launcher()

func _show_picker() -> void:
	_launcher.hide()
	_picker.show()
	_preview_buttons[_wallpaper_index].grab_focus()

func _show_launcher() -> void:
	_picker.hide()
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
		if _picker.visible:
			_show_launcher()
		else:
			closed.emit()
	elif event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _picker.visible:
			for i in _preview_buttons.size():
				if _preview_buttons[i].has_focus():
					_select_wallpaper(i)
					return
		elif _wallpapers_button.has_focus():
			_show_picker()
		elif not _taxi_button.disabled:
			_on_taxi_pressed()
