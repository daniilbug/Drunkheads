extends Node2D

var _players: Array[Player] = []
@onready var _level := Level.find_level_node(self)


func _ready() -> void:
	set_physics_process(multiplayer.is_server())
	if not multiplayer.is_server():
		return
	$InsideArea.body_entered.connect(_on_entered)
	$InsideArea.body_exited.connect(_on_exited)
	for slot: ClothingSlot in $Table/Slots.get_children():
		slot.contents_changed.connect(_refresh)


func _on_entered(body: Node2D) -> void:
	if body is Player and body not in _players:
		_players.append(body)
		_refresh()


func _on_exited(body: Node2D) -> void:
	if body is Player:
		_players.erase(body)
		body.clothing_shop.clear_fitting(self)


func _physics_process(_delta: float) -> void:
	for player in _players.duplicate():
		if not is_instance_valid(player):
			_players.erase(player)
		elif player.in_vehicle or player.level_id != _level.level_id:
			_on_exited(player)


func _refresh() -> void:
	var top: ShopGarment = $Table/Slots/Top.get_garment()
	var bottom: ShopGarment = $Table/Slots/Bottom.get_garment()
	for player in _players:
		if is_instance_valid(player):
			player.clothing_shop.preview_fitting(self, top.item if top != null else Vector2i(-1, -1), bottom.item if bottom != null else Vector2i(-1, -1))


func _exit_tree() -> void:
	for player in _players:
		if is_instance_valid(player):
			player.clothing_shop.clear_fitting(self)
