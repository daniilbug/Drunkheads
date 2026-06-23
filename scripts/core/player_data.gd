class_name PlayerData
extends Resource

const MAX_STAT := 100.0
const MIN_STAT := 0.0

@export var respect: float = 50.0
@export var mind: float = 50.0
@export var money: float = 50.0

signal stats_changed
signal stat_changed(stat: String, delta: float)

func buy_drink(drink: Drink) -> bool:
	if money < drink.cost:
		return false
	_apply("money", -drink.cost)
	stats_changed.emit()
	return true

func apply_drink_effects(drink: Drink) -> void:
	_apply("respect", drink.get_respect_bonus())
	_apply("mind", -drink.get_mind_penalty())
	stats_changed.emit()

func apply_drink_part(drink: Drink) -> void:
	_apply("respect", drink.get_respect_bonus() / 4.0)
	_apply("mind", -drink.get_mind_penalty() / 4.0)
	stats_changed.emit()

func _apply(stat: String, delta: float) -> void:
	var current: float = get(stat)
	var next := clampf(current + delta, MIN_STAT, MAX_STAT)
	var actual := next - current
	set(stat, next)
	if not is_zero_approx(actual):
		stat_changed.emit(stat, actual)
