class_name Main
extends Level

@onready var bar: Bar = $Bar

@onready var respect_label: Label = $HUD/Stats/RespectLabel
@onready var mind_label: Label = $HUD/Stats/MindLabel
@onready var money_label: Label = $HUD/Stats/MoneyLabel
@onready var hint_label: Label = $HUD/HintLabel

func _ready() -> void:
	player_spawn = $PlayerSpawn
	super._ready()

func _init_local_player(player: Player) -> void:
	super._init_local_player(player)
	player.player_data.stats_changed.connect(_update_stats)
	player.drink_action_requested.connect(_on_drink_action_requested)
	_update_stats()

func _update_stats() -> void:
	if not local_player:
		return
	var d := local_player.player_data
	respect_label.text = "Respect  %d" % int(d.respect)
	mind_label.text    = "Mind     %d" % int(d.mind)
	money_label.text   = "Money   $%d" % int(d.money)
		
func _on_drink_action_requested(drink_name: String) -> void:
	if multiplayer.is_server():
		_handle_drink_action(multiplayer.get_unique_id(), drink_name)
	else:
		_request_drink_action.rpc_id(1, drink_name)

@rpc("any_peer", "reliable")
func _request_drink_action(drink_name: String) -> void:
	if not multiplayer.is_server():
		return
	_handle_drink_action(multiplayer.get_remote_sender_id(), drink_name)
	
func _handle_drink_action(peer_id: int, drink_name: String) -> void:
	var drink := get_node_or_null(drink_name) as Drink
	if drink == null or drink.holder_peer_id != peer_id:
		return
	if drink.parts == 0:
		return
	drink.parts -= 1
	if drink.parts == 0:
		drink.holder_peer_id = 0
		drink.queue_free()
