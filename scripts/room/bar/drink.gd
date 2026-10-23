@tool
class_name Drink
extends Draggable

const FRAMES := 5

@export var drink_name: String = ""
@export var type: BarMenuItem.Type = BarMenuItem.Type.BEER:
	set(value):
		type = value
		if is_node_ready():
			_update_drink_sprite()
@export var flavor: String = ""
@export var cost: float = 10.0
@export var alcohol: float = 5.0
@export var sprite_frame: int = 0:
	set(value):
		sprite_frame = value
		if is_node_ready():
			_update_drink_sprite()
## Reserves an uncollected order for its customer. 0 is an unreserved drink.
@export var customer_id: int = 0

@export
var max_parts: int = 4:
	set(value):
		max_parts = value
		parts = value
		if is_node_ready():
			_update_drink_sprite()

@onready var drink_sprite: Sprite2D = $Sprite/Drink
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

@export
var parts: int = max_parts:
	set(value):
		parts = value
		if is_node_ready():
			_update_drink_sprite()

func _ready() -> void:
	_update_drink_sprite()

func can_pickup(player: Player) -> bool:
	return super.can_pickup(player) and customer_id in [0, int(player.name)]

func _local_pickup(player_id: int) -> bool:
	if not super._local_pickup(player_id):
		return false
	customer_id = 0
	return true

func get_respect_bonus() -> float:
	if type == BarMenuItem.Type.COFFEE:
		return 0.0
	return 5.0 + alcohol

func get_mind_penalty() -> float:
	if type == BarMenuItem.Type.COFFEE:
		return -8.0
	return 5.0 + alcohol

func _update_drink_sprite() -> void:
	if type == BarMenuItem.Type.COFFEE:
		sprite.texture = preload("res://assets/sprites/cafe/coffee_cup.png")
		drink_sprite.texture = preload("res://assets/sprites/cafe/coffee.png")
		drink_sprite.region_enabled = true
		var frame_size := sprite.texture.get_size()
		drink_sprite.region_rect = Rect2(Vector2(sprite_frame, clampi(max_parts - parts, 0, 4)) * frame_size, frame_size)
		return
	match type:
		BarMenuItem.Type.BEER:
			sprite.texture = load("res://assets/sprites/drinks/beer_glass.png")
			drink_sprite.texture = load("res://assets/sprites/drinks/beer.png")
		BarMenuItem.Type.SHOT:
			sprite.texture = load("res://assets/sprites/drinks/shot_glass.png")
			drink_sprite.texture = load("res://assets/sprites/drinks/shot.png")
		BarMenuItem.Type.COCTAIL:
			sprite.texture = load("res://assets/sprites/drinks/cocktail_glass.png")
			drink_sprite.texture = load("res://assets/sprites/drinks/cocktail.png")
	
	var frame_w := drink_sprite.texture.get_width()
	var visible_w := float(frame_w) / FRAMES
	var frame_h := drink_sprite.texture.get_height()
	var visible_h := float(frame_h) / max_parts
	drink_sprite.region_enabled = true
	drink_sprite.region_rect = Rect2(
		visible_w * sprite_frame,
		visible_h * (max_parts - parts),
		visible_w,
		visible_h,
	)

func get_save_schema() -> Dictionary:
	return {
		"drink_name": "", "type": [0, 1, 2, 3], "flavor": "", "cost": 0.0, "alcohol": 0.0,
		"sprite_frame": [0, 1, 2, 3, 4], "max_parts": Vector2i(1, 64), "parts": Vector2i(1, 64), "customer_id": [0, 1],
	}

func get_save_data() -> Dictionary:
	if customer_id < 0:
		return {}
	var data := super.get_save_data()
	if not data.is_empty() and customer_id > 1:
		data.fields.customer_id = 0
	return data

func apply_save_data(data: Dictionary) -> void:
	super.apply_save_data(data)
	Bartender._drink_id = maxi(Bartender._drink_id, str(name).trim_prefix("Drink").to_int())

func can_restore_save_data(fields: Dictionary, saved_level: Node2D) -> bool:
	return super.can_restore_save_data(fields, saved_level) and fields.parts <= fields.max_parts and fields.cost >= 0 and fields.alcohol >= 0
