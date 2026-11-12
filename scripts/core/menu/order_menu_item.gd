class_name OrderMenuItem
extends Resource

var name: String
var flavor: String
var cost: float
var sprite: int
var parts: int

func _init(
	name: String,
	flavor: String, 
	cost: float, 
	sprite: int,
	parts: int,
) -> void:
	self.name = name
	self.flavor = flavor
	self.cost = cost
	self.sprite = sprite
	self.parts = parts
