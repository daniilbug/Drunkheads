class_name BarMenuItem
extends Resource

enum Type { BEER, SHOT, COCTAIL }

var name: String
var type: Type
var flavor: String
var cost: float
var alcohol: int
var sprite: int
var parts: int

func _init(
	name: String,
	type: Type,
	flavor: String, 
	cost: float, 
	alcohol: int, 
	sprite: int,
	parts: int,
) -> void:
	self.name = name
	self.type = type
	self.flavor = flavor
	self.cost = cost
	self.alcohol = alcohol
	self.sprite = sprite
	self.parts = parts
