extends Node2D

@onready var player: Player = $YSort/Player
@onready var respect_label: Label = $HUD/Stats/RespectLabel
@onready var mind_label: Label = $HUD/Stats/MindLabel
@onready var money_label: Label = $HUD/Stats/MoneyLabel
@onready var hint_label: Label = $HUD/HintLabel

func _ready() -> void:
	player.player_data = PlayerData.new()
	player.player_data.stats_changed.connect(_update_stats)
	player.player_data.stat_changed.connect(_on_stat_changed)
	_update_stats()

func _process(_delta: float) -> void:
	hint_label.text = player.get_interaction_hint()

func _update_stats() -> void:
	var d := player.player_data
	respect_label.text = "Respect  %d" % int(d.respect)
	mind_label.text    = "Mind     %d" % int(d.mind)
	money_label.text   = "Money   $%d" % int(d.money)

func _on_stat_changed(stat: String, delta: float) -> void:
	var color := Color(0.4, 0.9, 0.4) if delta > 0.0 else Color(1.0, 0.4, 0.4)
	var prefix := "+" if delta > 0.0 else ""
	FloatingText.spawn(self, player.global_position, "%s%d %s" % [prefix, int(delta), stat.capitalize()], color)
