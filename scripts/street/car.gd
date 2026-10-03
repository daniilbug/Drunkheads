class_name Car
extends Vehicle

const BODY_TEXTURES = [
	preload("res://assets/sprites/street/car_body.png"),
	preload("res://assets/sprites/street/car_body_estate.png"),
]

const PAINT_COLORS = [
	Color("#46878c"), # Teal
	Color("#a75d5a"), # Brick red
	Color("#ad884b"), # Ochre
	Color("#586f96"), # Slate blue
	Color("#71885a"), # Olive
	Color("#8c709a"), # Lavender
]

@export_enum("Compact", "Estate") var body_type := 0:
	set(value):
		body_type = value
		_refresh_appearance()

@export_enum("Teal", "Brick Red", "Ochre", "Slate Blue", "Olive", "Lavender") var paint_id := 0:
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
	body_type = randi_range(0, BODY_TEXTURES.size() - 1)
	paint_id = randi_range(0, PAINT_COLORS.size() - 1)

func _refresh_appearance() -> void:
	if not is_node_ready():
		return
	_body.texture = BODY_TEXTURES[clampi(body_type, 0, BODY_TEXTURES.size() - 1)]
	(_body.material as ShaderMaterial).set_shader_parameter(
		"paint_color", PAINT_COLORS[clampi(paint_id, 0, PAINT_COLORS.size() - 1)]
	)
