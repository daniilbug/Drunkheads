class_name Phone
extends CanvasLayer

signal taxi_requested
signal closed

@onready var _taxi_button: Button = $Root/Screen/TaxiButton

func _ready() -> void:
	_taxi_button.pressed.connect(_on_taxi_pressed)

func set_taxi_available(available: bool) -> void:
	_taxi_button.disabled = not available
	if not _taxi_button.disabled:
		_taxi_button.grab_focus()

func _on_taxi_pressed() -> void:
	_taxi_button.disabled = true
	taxi_requested.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("phone") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()
	elif event.is_action_pressed("interact") and not _taxi_button.disabled:
		get_viewport().set_input_as_handled()
		_on_taxi_pressed()
