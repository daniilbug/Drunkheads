class_name Car
extends Vehicle

@export var body_textures: Array[Texture2D] = [
	preload("res://assets/sprites/street/car_body.png"),
	preload("res://assets/sprites/street/car_body_estate.png"),
]

@export var paint_colors: Array[Color] = []

@export var body_type := 0:
	set(value):
		body_type = value
		_refresh_appearance()

@export var paint_id := 0:
	set(value):
		paint_id = value
		_refresh_appearance()

@onready var _body: Sprite2D = $Visuals/Body

func _ready() -> void:
	super._ready()
	# Scene resources are shared by instances; each car needs its own uniform.
	_body.material = _body.material.duplicate()
	_refresh_appearance()

func randomize_appearance() -> void:
	if paint_colors.is_empty():
		return
	if not body_textures.is_empty():
		body_type = randi_range(0, body_textures.size() - 1)
	paint_id = randi_range(0, paint_colors.size() - 1)

func _refresh_appearance() -> void:
	if not is_node_ready() or paint_colors.is_empty():
		return
	if not body_textures.is_empty():
		_body.texture = body_textures[clampi(body_type, 0, body_textures.size() - 1)]
	(_body.material as ShaderMaterial).set_shader_parameter(
		"paint_color", paint_colors[clampi(paint_id, 0, paint_colors.size() - 1)]
	)
