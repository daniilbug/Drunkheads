class_name BarMenuItem
extends OrderMenuItem

var type: Drink.Type
var alcohol: int

func _init(
	name: String,
	type: Drink.Type,
	flavor: String,
	cost: float,
	alcohol: int,
	sprite: int,
	parts: int,
) -> void:
	super(name, flavor, cost, sprite, parts)
	assert(type in [Drink.Type.BEER, Drink.Type.SHOT, Drink.Type.COCTAIL])
	self.type = type
	self.alcohol = alcohol
