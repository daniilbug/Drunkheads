class_name WcCabin
extends Interactable

@onready var audio: AudioStreamPlayer2D = $Audio

@export var is_being_used: bool = false:
	set(value):
		is_being_used = value
		if is_node_ready():
			if value:
				audio.play()
			else:
				audio.stop()

func interact() -> void:
	if not is_being_used:
		use()

func use() -> void:
	if multiplayer.is_server():
		_local_use()
	else:
		_remote_use.rpc()

@rpc("any_peer", "reliable")
func _remote_use() -> void:
	if not multiplayer.is_server():
		return
	_local_use()

func _local_use() -> void:
	is_being_used = true
	var tween = create_tween()
	tween.tween_interval(3.0) 
	tween.tween_callback(_local_release)
	
func _local_release() -> void:
	is_being_used = false
