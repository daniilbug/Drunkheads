class_name BarMenuItem
extends Resource

var name: String
var flavor: String
var cost: float
var alcohol: int
var sprite: int

func _init(name: String, flavor: String, cost: float, alcohol: int, sprite: int) -> void:
	self.name = name
	self.flavor = flavor
	self.cost = cost
	self.alcohol = alcohol
	self.sprite = sprite
