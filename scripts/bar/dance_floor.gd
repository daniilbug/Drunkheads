class_name DanceFloor
extends Node2D

@onready var sprite: Sprite2D = $Sprite
@onready var area: Area2D = $Area
@onready var light: PointLight2D = $Light
@onready var _light_texture: GradientTexture2D = light.texture

@export var mode: int = 0:
	set(value):
		mode = value
		_update_collision()
		_update_animation()
		_update_light()

var _tween: Tween

func _enter_tree() -> void:
	set_multiplayer_authority(1, true)

func set_mode(mode: int) -> void:
	if multiplayer.is_server():
		self.mode = mode
	else:
		_remote_set_mode(mode)

@rpc("any_peer", "reliable")
func _remote_set_mode(mode: int) -> void:
	if not multiplayer.is_server():
		return
	self.mode = mode

func _update_collision():
	if mode > 0:
		area.collision_mask = 1
	else:
		area.collision_mask = 0

func _update_animation():
	if _tween:
		_tween.kill()
	if mode > 0:
		sprite.frame = 1
		_tween = create_tween().set_loops()
		_tween.tween_interval(0.5 / mode)
		_tween.tween_callback(
			func(): 
				sprite.frame = max(1, (sprite.frame + 1) % sprite.hframes)
				match sprite.frame:
					1: _light_texture.gradient.set_color(0, Color.from_string("#fe33cc", Color.WHITE))
					2: _light_texture.gradient.set_color(0, Color.from_string("#67ccfe", Color.WHITE))
					3: _light_texture.gradient.set_color(0, Color.from_string("#65fe98", Color.WHITE))
					4: _light_texture.gradient.set_color(0, Color.from_string("#fefe00", Color.WHITE))
		)
	else:
		sprite.frame = 0

func _update_light():
	if mode > 0:
		light.enabled = true
	else:
		light.enabled = false

func _on_area_body_entered(body: Node2D) -> void:
	if body is Player:
		body.is_dancing = true

func _on_area_body_exited(body: Node2D) -> void:
	if body is Player:
		body.is_dancing = false
