extends Level

func _ready() -> void:
	player_spawn = $PlayerSpawn
	$NPCManager.configure(10.0, false)
	super._ready()
	$StreetNavigation.bake_navigation_polygon(false)

func create_npc_route() -> NPCRoute:
	var start: Vector2 = $NPCPath/Left.global_position
	var finish: Vector2 = $NPCPath/Right.global_position
	if randf() < 0.5:
		return NPCWalkRoute.new(start, finish)
	return NPCWalkRoute.new(finish, start)
