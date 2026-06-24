@tool
class_name Drink
extends Node2D

const FRAMES := 5

@export var drink_name: String = ""
@export var type: BarMenuItem.Type = BarMenuItem.Type.BEER
@export var flavor: String = ""
@export var cost: float = 10.0
@export var alcohol: float = 5.0
@export var sprite_frame: int = 0

@export
var max_parts: int = 4:
	set(value):
		max_parts = value
		parts = value
		if is_node_ready():
			_update_drink_sprite()

var _log := Log.new("Drink")

@onready var glass_sprite: Sprite2D = $GlassSprite
@onready var drink_sprite: Sprite2D = $GlassSprite/DrinkSprite
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

var parts: int = max_parts:
	set(value):
		parts = value
		if is_node_ready():
			_update_drink_sprite()

var holder_peer_id: int = 0

func _enter_tree() -> void:
	$MultiplayerSynchronizer.set_multiplayer_authority(get_multiplayer_authority())

func _ready() -> void:
	_update_drink_sprite()

func get_respect_bonus() -> float:
	return 5.0 + alcohol

func get_mind_penalty() -> float:
	return 5.0 + alcohol

func _update_drink_sprite() -> void:
	match type:
		BarMenuItem.Type.BEER:
			glass_sprite.texture = load("res://assets/sprites/drinks/beer_glass.png")
			drink_sprite.texture = load("res://assets/sprites/drinks/beer.png")
		BarMenuItem.Type.SHOT:
			glass_sprite.texture = load("res://assets/sprites/drinks/shot_glass.png")
			drink_sprite.texture = load("res://assets/sprites/drinks/shot.png")
		BarMenuItem.Type.COCTAIL:
			glass_sprite.texture = load("res://assets/sprites/drinks/cocktail_glass.png")
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
