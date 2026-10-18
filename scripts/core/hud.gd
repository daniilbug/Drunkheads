class_name HUD
extends CanvasLayer

# Main owns the signal connection; HUD only displays the supplied PlayerData.
@onready var _respect_label: Label = $Stats/RespectLabel
@onready var _mind_label: Label = $Stats/MindLabel
@onready var _money_label: Label = $Stats/MoneyLabel

func update_stats(data: PlayerData) -> void:
	_respect_label.text = "Respect  %d" % int(data.respect)
	_mind_label.text = "Mind     %d" % int(data.mind)
	_money_label.text = "Money   $%d" % int(data.money)
