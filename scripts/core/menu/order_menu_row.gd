class_name OrderMenuRow
extends MarginContainer

@onready var button: Button = $Button
@onready var name_label: Label = $Content/HBox/Info/Name
@onready var description_label: Label = $Content/HBox/Info/Description
@onready var price_label: Label = $Content/HBox/Price
@onready var availability: AnimationPlayer = $Availability

func configure(item: BarMenuItem, can_afford: bool) -> void:
	name_label.text = item.name
	description_label.text = item.flavor
	price_label.text = "$%d" % int(item.cost)
	button.disabled = not can_afford
	availability.play("RESET" if can_afford else "unavailable")
