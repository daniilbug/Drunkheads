@tool
extends StaticBody2D

@export var display_tops := true:
	set(value):
		display_tops = value
		_update_garments()
## Store assortment: catalog style and fabric color, independent of ownership.
@export var garments: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 3), Vector2i(2, 4), Vector2i(3, 5)]:
	set(value):
		garments = value
		_update_garments()


func _ready() -> void:
	_update_garments()


func _update_garments() -> void:
	if not is_node_ready():
		return
	var textures := CharacterSprite.TOP_TEXTURES if display_tops else CharacterSprite.PANTS_TEXTURES
	for index in $Garments.get_child_count():
		var slot := $Garments.get_child(index) as ClothingSlot
		slot.is_top = display_tops
		slot.generates_stock = index < garments.size()
		slot.initial_item = garments[index] if index < garments.size() else Vector2i(-1, -1)
		var sprite := slot.get_node("Preview") as Sprite2D
		sprite.visible = Engine.is_editor_hint() and index < garments.size()
		if index >= garments.size():
			continue
		var item := garments[index]
		sprite.texture = CharacterSprite.garment_icon(textures[clampi(item.x, 0, textures.size() - 1)])
		sprite.offset.y = sprite.texture.get_height() / 2.0 - sprite.texture.get_image().get_used_rect().position.y
		(sprite.material as ShaderMaterial).set_shader_parameter(
			"clothing_color", CharacterSprite.CLOTHING_COLORS[clampi(item.y, 0, CharacterSprite.CLOTHING_COLORS.size() - 1)]
		)
