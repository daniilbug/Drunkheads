class_name Bar
extends Level

signal local_player_initialized(player: Player)

@onready var taxi_stop: TaxiStop = $RightTrafficLane/TaxiStop
@onready var npc_manager: NPCManager = $NPCManager

func _ready() -> void:
	player_spawn = $PlayerSpawn
	npc_manager.npc_added.connect(_init_npc)
	$CigaretteSpawner.spawned.connect(_on_cigarette_spawned)
	super._ready()

func _prepare_player_spawn(player: Player) -> void:
	player.in_vehicle = true
	taxi_stop.queue_arrival(int(player.name))

func _remove_player(peer_id: int) -> void:
	taxi_stop.remove_passenger(peer_id)
	super._remove_player(peer_id)

func _init_npc(npc: NPC) -> void:
	super._init_npc(npc)
	npc.drink_action_requested.connect(_on_drink_action_requested)

func _init_local_player(player: Player) -> void:
	super._init_local_player(player)
	player.drink_action_requested.connect(_on_drink_action_requested)
	player.smoke_action_requested.connect(_on_smoke_action_requested)
	local_player_initialized.emit(player)

func _on_cigarette_spawned(node: Node) -> void:
	if node is CigarettePack and local_player != null:
		var pack := node as CigarettePack
		if pack.holder_peer_id == int(local_player.name):
			local_player.take_spawned_item(pack)

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
