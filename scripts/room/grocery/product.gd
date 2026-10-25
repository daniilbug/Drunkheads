@tool
class_name GroceryProduct
extends Node2D

@export var product_name: String


func get_display_width() -> int:
	return ($Sprite as Sprite2D).texture.get_width()
