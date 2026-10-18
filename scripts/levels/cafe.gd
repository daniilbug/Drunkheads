class_name Cafe
extends Level

@onready var taxi_stop: TaxiStop = get_taxi_stop()
@onready var npc_manager: NPCManager = $NPCManager

func _ready() -> void:
	player_spawn = $PlayerSpawn
	npc_manager.npc_added.connect(_init_npc)
	super._ready()
	$StreetNavigation.bake_navigation_polygon(false)

func _prepare_player_spawn(player: Player) -> void:
	player.level_id = level_id
	if get_parent() is Main:
		player.in_vehicle = true
		taxi_stop.queue_arrival(int(player.name))
