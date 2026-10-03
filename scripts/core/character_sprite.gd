class_name CharacterSprite
extends Sprite2D

# Every texture uses the same 4 x 10 atlas and the same 12 x 20 frame origin.
const HAIR_TEXTURES = [
	# 0-5: masculine silhouettes. 6-11: feminine silhouettes.
	preload("res://assets/sprites/characters/hair_0.png"),
	preload("res://assets/sprites/characters/hair_1.png"),
	preload("res://assets/sprites/characters/hair_2.png"),
	preload("res://assets/sprites/characters/hair_3.png"),
	preload("res://assets/sprites/characters/hair_4.png"),
	preload("res://assets/sprites/characters/hair_5.png"),
	preload("res://assets/sprites/characters/hair_6.png"),
	preload("res://assets/sprites/characters/hair_7.png"),
	preload("res://assets/sprites/characters/hair_8.png"),
	preload("res://assets/sprites/characters/hair_9.png"),
	preload("res://assets/sprites/characters/hair_10.png"),
	preload("res://assets/sprites/characters/hair_11.png"),
]
const TOP_TEXTURES = [
	preload("res://assets/sprites/characters/top_0.png"),
	preload("res://assets/sprites/characters/top_1.png"),
	preload("res://assets/sprites/characters/top_2.png"),
	preload("res://assets/sprites/characters/top_3.png"),
	preload("res://assets/sprites/characters/top_4.png"),
	preload("res://assets/sprites/characters/top_5.png"),
]
const PANTS_TEXTURES = [
	preload("res://assets/sprites/characters/pants_0.png"),
	preload("res://assets/sprites/characters/pants_1.png"),
	preload("res://assets/sprites/characters/pants_2.png"),
	preload("res://assets/sprites/characters/pants_3.png"),
	preload("res://assets/sprites/characters/pants_4.png"),
	preload("res://assets/sprites/characters/pants_5.png"),
]

@onready var _hair: Sprite2D = $Hair
@onready var _top: Sprite2D = $Top
@onready var _pants: Sprite2D = $Pants

func _ready() -> void:
	frame_changed.connect(_sync_layer_frames)
	_sync_layer_frames()

func set_appearance(hair_id: int, top_id: int, pants_id: int) -> void:
	_hair.texture = HAIR_TEXTURES[clampi(hair_id, 0, HAIR_TEXTURES.size() - 1)]
	_top.texture = TOP_TEXTURES[clampi(top_id, 0, TOP_TEXTURES.size() - 1)]
	_pants.texture = PANTS_TEXTURES[clampi(pants_id, 0, PANTS_TEXTURES.size() - 1)]
	_sync_layer_frames()

func _sync_layer_frames() -> void:
	_hair.frame = frame
	_top.frame = frame
	_pants.frame = frame
