class_name Bar
extends Level

@onready var taxi_stop: TaxiStop = get_taxi_stop()
@onready var npc_manager: NPCManager = $NPCManager

func _ready() -> void:
	player_spawn = $PlayerSpawn
	npc_manager.configure(10.0)
	$CigaretteSpawner.spawned.connect(_on_cigarette_spawned)
	super._ready()
	$StreetNavigation.bake_navigation_polygon(false)

func create_npc_route() -> NPCRoute:
	return NPCVisitRoute.new($BarHall, $BarWC, $Bench,
		$PlayerSpawn.global_position, $NPCManager/ExitPoint.global_position)

func _prepare_player_spawn(player: Player) -> void:
	if get_parent() is Main:
		player.in_vehicle = true
		taxi_stop.queue_arrival(int(player.name))
