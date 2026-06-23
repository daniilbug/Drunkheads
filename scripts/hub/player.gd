class_name Player
extends CharacterBody2D

const SPEED := 200.0
const FPS_WALK := 8.0

const ROW_WALK_S := 0
const ROW_WALK_N := 1
const ROW_WALK_W := 2
const ROW_WALK_E := 3
const ROW_IDLE   := 4
const ROW_SIT    := 5
const ROW_DRINK  := 6

const HANDS_EMPTY_CHILD_COUNT = 1
const HANDS_ITEM_INDEX = 1

@export var player_data: PlayerData
@export var is_sitting := false
@export var seated_chair: Chair = null
@export var peer_id: int = 0

@onready var sprite: Sprite2D = $Sprite
@onready var hands: Node2D = $Hands
@onready var interaction_area: Area2D = $InteractionArea
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var camera: Camera2D = $Camera
var direction := Vector2.DOWN

var _log = Log.new("Player")

var _hands_item: Node2D = null

var _anim_t := 0.0
var _anim_row := ROW_IDLE
var _is_walking := false
var _idle_tween: Tween

signal pickup_requested(drink_name: String)
signal drop_requested(drink_name: String, sort_pos: Vector2, visual_pos: Vector2)
signal drink_action_requested(drink_name: String)

func _enter_tree() -> void:
	set_multiplayer_authority(get_multiplayer_authority(), true)

func _ready() -> void:
	sprite.frame = ROW_IDLE * 4
	_start_idle_bob()
	call_deferred("_setup_authority")

func _setup_authority() -> void:
	if is_multiplayer_authority():
		camera.make_current()

func _start_idle_bob() -> void:
	_anim_row = ROW_IDLE
	sprite.frame = ROW_IDLE * 4
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(sprite, "scale:y", 0.95, 0.45).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(sprite, "scale:y", 1.0, 0.45).set_trans(Tween.TRANS_SINE)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if is_sitting:
		velocity = Vector2.ZERO
		return

	var dir := Input.get_vector("left", "right", "up", "down")
	velocity = dir * SPEED

	var walking := dir != Vector2.ZERO
	if walking != _is_walking:
		_is_walking = walking
		if walking:
			_idle_tween.pause()
			sprite.scale.y = 1.0
			_anim_t = 0.0
		else:
			sprite.position.y = 0.0
			_idle_tween.play()
			_anim_row = _dir_to_idle_row(direction)
			sprite.frame = _anim_row * 4

	if walking:
		direction = dir
		_anim_t += delta
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
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("take"):
		_try_take_drop()

func _try_interact() -> void:
	if is_sitting:
		if _hands_item != null:
			_hands_interact()
		else:
			_stand_up()
		return
	for area in interaction_area.get_overlapping_areas():
		var owner_node := area.get_parent()
		if owner_node is Bartender:
			var bartender = owner_node as Bartender
			bartender.order(self)
			return
		elif owner_node is Chair:
			var chair = owner_node as Chair
			if not chair.is_occupied:
				_sit_in(chair)
				return
	_hands_interact()

func _get_top_ysort_anchor(node: Node) -> Node2D:
	var result: Node2D = null
	var current := node
	while current.get_parent() != null:
		var parent := current.get_parent()
		if parent is Node2D and (parent as Node2D).y_sort_enabled:
			result = current as Node2D
		current = parent
	return result

func _try_take_drop() -> void:
	for area in interaction_area.get_overlapping_areas():
		var owner_node := area.get_parent()
		if owner_node is DropPlace and _hands_item != null:
			var drop_place := owner_node as DropPlace
			var visual_pos := drop_place.shape.global_position
			var anchor := _get_top_ysort_anchor(drop_place)
			var sort_y := visual_pos.y
			if anchor != null:
				sort_y = maxf(visual_pos.y, anchor.global_position.y + 1.0)
			drop_requested.emit(_hands_item.name, Vector2(visual_pos.x, sort_y), visual_pos)
			_hands_item = null
			return
		elif owner_node is Drink and _hands_item == null:
			_hands_item = owner_node
			owner_node.tree_exiting.connect(func(): _hands_item = null, CONNECT_ONE_SHOT)
			pickup_requested.emit(owner_node.name)
			return

func _sit_in(chair: Chair) -> void:
	chair.occupy(self)
	seated_chair = chair
	is_sitting = true
	global_position = chair.get_seat_position()
	_idle_tween.pause()
	sprite.frame = (ROW_WALK_N if chair.facing_north else ROW_SIT) * 4

func _stand_up() -> void:
	if seated_chair:
		seated_chair.vacate()
		seated_chair = null
	is_sitting = false
	_start_idle_bob()

func _hands_interact() -> void:
	if _hands_item == null:
		return
	elif _hands_item is Drink:
		var drink = _hands_item as Drink
		_drink(drink)

func _drink(drink: Drink) -> void:
	if drink.parts == 0:
		return
	player_data.apply_drink_part(drink)
	drink_action_requested.emit(drink.name)
	_rpc_show_drink_anim.rpc()

@rpc("authority", "call_local", "reliable")
func _rpc_show_drink_anim() -> void:
	_animate_drink()

func _animate_drink() -> void:
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
