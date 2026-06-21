class_name DrinkType
extends Resource

@export var drink_name: String = ""
@export var flavor: String = ""
@export var cost: float = 10.0
# 0.0 = non-alcoholic, 1.0 = maximum strength
@export var alcohol: float = 0.5
# Index into the drink.png sprite sheet (0–4)
@export var sprite_frame: int = 0

func get_respect_bonus() -> float:
	return 8.0 + alcohol * 14.0  # 8 – 22

func get_mind_penalty() -> float:
	return 5.0 + alcohol * 20.0  # 5 – 25
