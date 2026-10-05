class_name CigaretteMachine
extends Interactable

const PACK_SCENE := preload("res://scenes/street/cigarette_pack.tscn")
const PRICE := 10.0

static var _next_pack_id := 0
var _purchase_pending := false

@onready var purchase_area: Area2D = $Area
@onready var audio: AudioStreamPlayer2D = $Audio

func interact(player: Player) -> void:
	if player._hands_item != null or _purchase_pending:
		return
	if player.player_data.money < PRICE:
		return
	_purchase_pending = true
	player.player_data.adjust_money(-PRICE)
	if multiplayer.is_server():
		_buy_for(int(player.name))
	else:
		_request_purchase.rpc_id(1)

@rpc("any_peer", "reliable")
func _request_purchase() -> void:
	if multiplayer.is_server():
		_buy_for(multiplayer.get_remote_sender_id())

func _buy_for(peer_id: int) -> void:
	var level := Level.find_level_node(self)
	var player := level.get_node_or_null(str(peer_id)) as Player
	if player == null or not purchase_area.overlaps_area(player.interaction_area):
		_purchase_result.rpc_id(peer_id, false)
		return
	for child in level.get_children():
		if child is Draggable and (child as Draggable).holder_peer_id == peer_id:
			_purchase_result.rpc_id(peer_id, false)
			return
	_next_pack_id += 1
	var pack := PACK_SCENE.instantiate() as CigarettePack
	pack.name = "CigarettePack%d" % _next_pack_id
	pack.holder_peer_id = peer_id
	level.add_child(pack)
	pack.global_position = player.hands.global_position
	if player == level.local_player:
		player.take_spawned_item(pack)
	_purchase_result.rpc_id(peer_id, true)
	_play_dispense_sound.rpc()

@rpc("authority", "call_local", "reliable")
func _play_dispense_sound() -> void:
	audio.play()

@rpc("authority", "call_local", "reliable")
func _purchase_result(accepted: bool) -> void:
	_purchase_pending = false
	if not accepted:
		var level := Level.find_level_node(self)
		if level.local_player != null:
			level.local_player.player_data.adjust_money(PRICE)
