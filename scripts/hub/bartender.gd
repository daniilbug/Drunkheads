class_name Bartender
extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite

var _anim_t := 0.0

var menu: Array[DrinkType] = []

func _ready() -> void:
	sprite.frame = 0
	_build_menu()

func _build_menu() -> void:
	var light_lager := DrinkType.new()
	light_lager.drink_name = "Light Lager"
	light_lager.flavor = "Crisp and watery. Goes down easy."
	light_lager.cost = 8.0
	light_lager.alcohol = 0.15
	light_lager.sprite_frame = 0

	var pale_ale := DrinkType.new()
	pale_ale.drink_name = "Pale Ale"
	pale_ale.flavor = "Hoppy with a citrus bite."
	pale_ale.cost = 12.0
	pale_ale.alcohol = 0.40
	pale_ale.sprite_frame = 1

	var dark_stout := DrinkType.new()
	dark_stout.drink_name = "Dark Stout"
	dark_stout.flavor = "Roasted malt, bitter finish."
	dark_stout.cost = 14.0
	dark_stout.alcohol = 0.60
	dark_stout.sprite_frame = 2

	var strong_ipa := DrinkType.new()
	strong_ipa.drink_name = "Strong IPA"
	strong_ipa.flavor = "Resinous hops, serious kick."
	strong_ipa.cost = 16.0
	strong_ipa.alcohol = 0.78
	strong_ipa.sprite_frame = 3

	var barleywine := DrinkType.new()
	barleywine.drink_name = "Barleywine"
	barleywine.flavor = "Sweet and potent. You'll feel it."
	barleywine.cost = 20.0
	barleywine.alcohol = 1.0
	barleywine.sprite_frame = 4

	menu = [light_lager, pale_ale, dark_stout, strong_ipa, barleywine]

func _process(delta: float) -> void:
	_anim_t += delta
	var cycle := fmod(_anim_t, 3.0)
	sprite.frame = 1 if cycle < 0.4 else 0
