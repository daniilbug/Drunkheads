class_name Main
extends Level

@onready var bar: Bar = $Bar
@onready var npc_manager: NPCManager = $NPCManager

@onready var respect_label: Label = $HUD/Stats/RespectLabel
@onready var mind_label: Label = $HUD/Stats/MindLabel
@onready var money_label: Label = $HUD/Stats/MoneyLabel

func _ready() -> void:
	player_spawn = $PlayerSpawn
	npc_manager.npc_added.connect(_init_npc)
	$CigaretteSpawner.spawned.connect(_on_cigarette_spawned)
	super._ready()

func _init_npc(npc: NPC) -> void:
	super._init_npc(npc)
	npc.player_data.stats_changed.connect(_update_stats)
	npc.drink_action_requested.connect(_on_drink_action_requested)

func _init_local_player(player: Player) -> void:
	super._init_local_player(player)
	player.player_data.stats_changed.connect(_update_stats)
	player.drink_action_requested.connect(_on_drink_action_requested)
	player.smoke_action_requested.connect(_on_smoke_action_requested)
	_update_stats()

func _on_cigarette_spawned(node: Node) -> void:
	if node is CigarettePack and local_player != null:
		var pack := node as CigarettePack
		if pack.holder_peer_id == int(local_player.name):
			local_player.take_spawned_item(pack)

func _update_stats() -> void:
	if not local_player:
		return
	var d := local_player.player_data
	respect_label.text = "Respect  %d" % int(d.respect)
	mind_label.text    = "Mind     %d" % int(d.mind)
	money_label.text   = "Money   $%d" % int(d.money)
		
func _on_drink_action_requested(player_id: int, drink_name: String) -> void:
	if multiplayer.is_server():
		_handle_drink_action(player_id, drink_name)
	else:
		_request_drink_action.rpc_id(1, player_id, drink_name)

@rpc("any_peer", "reliable")
func _request_drink_action(player_id: int, drink_name: String) -> void:
	if not multiplayer.is_server() or player_id != multiplayer.get_remote_sender_id():
		return
	_handle_drink_action(player_id, drink_name)
	
func _handle_drink_action(player_id: int, drink_name: String) -> void:
	var drink := get_node_or_null(drink_name) as Drink
	if drink == null or drink.holder_peer_id != player_id:
		return
	if drink.parts == 0:
		return
	drink.parts -= 1
	if drink.parts == 0:
		drink.holder_peer_id = 0
		drink.queue_free()

func _on_smoke_action_requested(player_id: int, pack_name: String) -> void:
	if multiplayer.is_server():
		_handle_smoke_action(player_id, pack_name)
	else:
		_request_smoke_action.rpc_id(1, player_id, pack_name)

@rpc("any_peer", "reliable")
func _request_smoke_action(player_id: int, pack_name: String) -> void:
	if not multiplayer.is_server() or player_id != multiplayer.get_remote_sender_id():
		return
	_handle_smoke_action(player_id, pack_name)

func _handle_smoke_action(player_id: int, pack_name: String) -> void:
	var pack := get_node_or_null(pack_name) as CigarettePack
	if pack == null or pack.holder_peer_id != player_id:
		return
	if pack.cigarettes_left <= 0 or pack.is_smoking:
		return
	pack.is_smoking = true
	pack.play_smoke.rpc()
	_finish_smoking(pack, player_id)

func _finish_smoking(pack: CigarettePack, player_id: int) -> void:
	await get_tree().create_timer(CigarettePack.SMOKE_DURATION).timeout
	if not is_instance_valid(pack):
		return
	pack.is_smoking = false
	if pack.holder_peer_id != player_id or pack.cigarettes_left <= 0:
		return
	pack.cigarettes_left -= 1
	_smoke_finished.rpc_id(player_id)
	if pack.cigarettes_left == 0:
		pack.holder_peer_id = 0
		pack.queue_free()

@rpc("authority", "call_local", "reliable")
func _smoke_finished() -> void:
	if local_player != null:
		local_player.on_cigarette_smoked()
