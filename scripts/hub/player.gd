class_name Player
extends CharacterBody2D

const SPEED := 200.0
const FPS_WALK := 8.0

# Sprite sheet row indices
const ROW_WALK_S := 0
const ROW_WALK_N := 1
const ROW_WALK_W := 2
const ROW_WALK_E := 3
const ROW_IDLE    := 4
const ROW_SIT     := 5
const ROW_DRINK   := 6

@export var player_data: PlayerData

@onready var sprite: Sprite2D = $Sprite
@onready var drink_indicator: Sprite2D = $DrinkIndicator
@onready var drink_fill: Sprite2D = $DrinkIndicator/DrinkFill
@onready var interaction_area: Area2D = $InteractionArea

var drink_parts: int = 0
var held_drink: DrinkType = null
var is_sitting := false
var seated_chair: Chair = null

var _walk_t := 0.0
var _anim_t := 0.0
var _anim_row := ROW_IDLE
var _is_walking := false
var _idle_tween: Tween
var _last_dir := Vector2.DOWN
var _menu_open := false
var _drink_default_pos := Vector2(0, -10)

func _ready() -> void:
	sprite.frame = ROW_IDLE * 4
	_start_idle_bob()

func _start_idle_bob() -> void:
	_anim_row = ROW_IDLE
	sprite.frame = ROW_IDLE * 4
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(sprite, "scale:y", 0.96, 0.45).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(sprite, "scale:y", 1.0, 0.45).set_trans(Tween.TRANS_SINE)

func _physics_process(delta: float) -> void:
	# Update drink visibility based on state
	if is_sitting:
		drink_indicator.visible = drink_parts > 0
	elif not _menu_open:
		drink_indicator.visible = drink_parts > 0 and _anim_row != ROW_WALK_N

	if is_sitting or _menu_open:
		velocity = Vector2.ZERO
		return

	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = dir * SPEED

	var walking := dir != Vector2.ZERO
	if walking != _is_walking:
		_is_walking = walking
		if walking:
			_idle_tween.pause()
			sprite.scale.y = 1.0
			_anim_t = 0.0
		else:
			_walk_t = 0.0
			sprite.position.y = 0.0
			_idle_tween.play()
			_anim_row = _dir_to_idle_row(_last_dir)
			sprite.frame = _anim_row * 4

	if walking:
		_last_dir = dir
		_walk_t += delta
		_anim_t += delta
		var bounce := sin(_walk_t * TAU * 2.8)
		sprite.position.y = bounce * 1.2
		sprite.scale.y = 1.0 - absf(bounce) * 0.04
		if not is_zero_approx(dir.x):
			_anim_row = ROW_WALK_E if dir.x > 0 else ROW_WALK_W
		elif not is_zero_approx(dir.y):
			_anim_row = ROW_WALK_S if dir.y > 0 else ROW_WALK_N
		sprite.frame = _anim_row * 4 + (int(_anim_t * FPS_WALK) % 4)

	move_and_slide()

func _dir_to_idle_row(d: Vector2) -> int:
	if absf(d.x) >= absf(d.y):
		return ROW_WALK_E if d.x > 0 else ROW_WALK_W
	return ROW_WALK_S if d.y > 0 else ROW_WALK_N

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()

func get_interaction_hint() -> String:
	if is_sitting:
		return "E: Drink" if drink_parts > 0 else "E: Stand up"
	for area in interaction_area.get_overlapping_areas():
		var owner_node := area.get_parent()
		if owner_node is Bartender:
			if drink_parts > 0:
				return "Already carrying a drink"
			return "E: Order drink"
		if owner_node is Chair and not (owner_node as Chair).is_occupied:
			return "E: Sit down"
	return ""

func _try_interact() -> void:
	if is_sitting:
		if drink_parts > 0:
			_drink()
		else:
			_stand_up()
		return
	for area in interaction_area.get_overlapping_areas():
		var owner_node := area.get_parent()
		if owner_node is Bartender:
			_open_menu(owner_node as Bartender)
			return
		if owner_node is Chair and not (owner_node as Chair).is_occupied:
			_sit_in(owner_node as Chair)
			return

func _open_menu(bartender: Bartender) -> void:
	if drink_parts > 0 or player_data == null:
		return
	var menu: DrinkMenu = preload("res://scenes/hub/drink_menu.tscn").instantiate()
	add_child(menu)
	_menu_open = true
	menu.open(bartender.menu, player_data)
	menu.drink_selected.connect(func(drink: DrinkType): _on_drink_selected(drink, menu))
	menu.closed.connect(func(): _on_menu_closed(menu))

func _on_drink_selected(drink: DrinkType, menu: DrinkMenu) -> void:
	if player_data.buy_drink(drink):
		held_drink = drink
		drink_parts = 4
		drink_indicator.position = _drink_default_pos
		_update_drink_sprite()
		drink_indicator.visible = true
	_on_menu_closed(menu)

func _update_drink_sprite() -> void:
	if drink_parts == 0 or held_drink == null:
		return
	# Liquid: cropped from the top to show only the remaining fill
	var fill := drink_parts / 4.0
	var frame_h := drink_fill.texture.get_height()
	var visible_h := frame_h * fill
	drink_fill.frame = held_drink.sprite_frame
	drink_fill.region_enabled = true
	drink_fill.region_rect = Rect2(0, frame_h - visible_h, drink_fill.texture.get_width(), visible_h)
	# Shift down in local space to keep the liquid bottom anchored to the glass bottom
	drink_fill.position.y = frame_h * (1.0 - fill) / 2.0
	drink_fill.visible = true

func _on_menu_closed(menu: DrinkMenu) -> void:
	_menu_open = false
	menu.queue_free()

func _sit_in(chair: Chair) -> void:
	chair.occupy(self)
	seated_chair = chair
	is_sitting = true
	global_position = chair.get_seat_position()
	_idle_tween.pause()
	sprite.frame = (ROW_WALK_N if chair.facing_north else ROW_SIT) * 4
	if drink_parts > 0:
		var offset = -20 if chair.facing_north else 5
		drink_indicator.position = Vector2(0.0, float(offset))
		_update_drink_sprite()
		drink_indicator.visible = true

func _stand_up() -> void:
	if seated_chair:
		seated_chair.vacate()
		seated_chair = null
	is_sitting = false
	if drink_parts > 0:
		drink_indicator.position = _drink_default_pos
		_update_drink_sprite()
	_start_idle_bob()


func _drink() -> void:
	drink_parts -= 1
	if player_data and held_drink:
		player_data.apply_drink_part(held_drink)

	if drink_parts == 0:
		held_drink = null
		drink_fill.visible = false
		drink_indicator.visible = false
	else:
		_update_drink_sprite()

	sprite.frame = ROW_DRINK * 4
	var t := create_tween()
	t.tween_property(sprite, "rotation_degrees", 12.0, 0.12)
	t.tween_property(sprite, "rotation_degrees", -4.0, 0.1)
	t.tween_property(sprite, "rotation_degrees", 0.0, 0.18).set_trans(Tween.TRANS_SPRING)
	var sit_row := ROW_WALK_N if seated_chair and seated_chair.facing_north else ROW_SIT
	t.tween_callback(func(): sprite.frame = sit_row * 4)
	var frame_t := create_tween()
	frame_t.tween_interval(0.12)
	frame_t.tween_callback(func(): sprite.frame = ROW_DRINK * 4 + 1)
