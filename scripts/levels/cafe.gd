class_name Cafe
extends Level

@onready var taxi_stop: TaxiStop = $TrafficRoad/RightTrafficLane/TaxiStop
@onready var npc_manager: NPCManager = $NPCManager

func _ready() -> void:
	player_spawn = $PlayerSpawn
	npc_manager.npc_added.connect(_init_npc)
	$Darkness.enabled = get_parent() is not Main
	super._ready()
	$StreetNavigation.bake_navigation_polygon(false)

func _prepare_player_spawn(player: Player) -> void:
	player.level_id = "cafe"
	if get_parent() is Main:
		player.in_vehicle = true
		taxi_stop.queue_arrival(int(player.name))

func _cleanup_player(peer_id: int) -> void:
	taxi_stop.remove_passenger(peer_id)
	super._cleanup_player(peer_id)
