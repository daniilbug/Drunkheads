class_name NPCRoute
extends RefCounted

var npc: NPC
var spawn_position: Vector2
var exit_position: Vector2

func _init(start: Vector2, finish: Vector2) -> void:
	spawn_position = start
	exit_position = finish

func start(actor: NPC) -> void:
	npc = actor

## False defers movement until a changed state has selected its destination.
func update(_delta: float) -> bool:
	if npc.state == NPC.State.EXITING and npc.nav_agent.is_target_reached():
		npc.queue_free()
	return true

func is_navigating() -> bool:
	return npc.state == NPC.State.EXITING

func move_direct(_delta: float) -> bool:
	return false

func cleanup() -> void:
	pass
