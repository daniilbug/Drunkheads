class_name NPCWalkRoute
extends NPCRoute

func start(actor: NPC) -> void:
	super.start(actor)
	npc._begin_exit()
