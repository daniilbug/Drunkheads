class_name Player
extends CharacterBody2D

static var local_setup: Dictionary = {"name": "Player"}

const SPEED := 350.0
const FPS_WALK := 8.0

const ROW_WALK_S  := 0
const ROW_WALK_N  := 1
const ROW_WALK_W  := 2
const ROW_WALK_E  := 3
const ROW_IDLE    := 4
const ROW_SIT     := 5
const ROW_DRINK   := 6
const ROW_DRINK_N := 7
const ROW_DANCE   := 8
const ROW_DANCE_N := 9

@export var player_data: PlayerData
@export var is_sitting := false
@export var seated_chair: Chair = null
@export var peer_id: int = 0

@export var in_vehicle := false:
	set(value):
		in_vehicle = value
		if is_node_ready():
			_apply_vehicle_state()

@export var riding_vehicle_name := ""

@export var hair_id: int = 0:
	set(value):
		hair_id = value
		_refresh_appearance()

@export var top_id: int = 0:
	set(value):
		top_id = value
		_refresh_appearance()

@export var pants_id: int = 0:
	set(value):
		pants_id = value
		_refresh_appearance()

var player_name: String = ""

@export var id: int = 0

@export var is_dancing := false:
	set(value):
		is_dancing = value
		if is_node_ready():
			if value:
				_start_dance_animation()
			else:
				_stop_dance_animation()

@export var direction := Vector2.DOWN:
	set(value):
		var old_value = direction
		direction = value
		if old_value != value:
			_on_direction_change(value)

@onready var sprite: CharacterSprite = $Sprite
@onready var hands: Node2D = $Hands
@onready var interaction_area: Area2D = $InteractionArea
@onready var camera: Camera2D = get_node_or_null("Camera")
@onready var audio: AudioStreamPlayer2D = $Audio

var _hands_item: Draggable = null
var _smoking := false
var is_world_input_blocked := false

var _anim_t := 0.0
var _anim_row := ROW_IDLE
var _is_walking := false
var _idle_tween: Tween
var _drunk_tween: Tween
var _dance_tween: Tween
var _last_position: Vector2

signal drink_action_requested(player_id: int, drink_name: String)
signal smoke_action_requested(player_id: int, pack_name: String)
signal phone_requested(player: Player)

func _enter_tree() -> void:
	set_multiplayer_authority(int(name), true)
	$AppearanceSynchronizer.set_multiplayer_authority(1)

func _ready() -> void:
	_refresh_appearance()
	_apply_vehicle_state()
	sprite.frame = ROW_IDLE * 4
	_start_idle_bob()
	set_notify_transform(true)
	call_deferred("_setup_authority")

func _apply_vehicle_state() -> void:
	visible = not in_vehicle
	is_world_input_blocked = in_vehicle
	$Shape.set_deferred("disabled", in_vehicle)
	var obstacle := get_node_or_null("NavigationObstacle") as NavigationObstacle2D
	if obstacle != null:
		obstacle.avoidance_enabled = multiplayer.is_server() and not in_vehicle

func randomize_appearance() -> void:
	hair_id = randi_range(0, CharacterSprite.HAIR_TEXTURES.size() - 1)
	top_id = randi_range(0, CharacterSprite.TOP_TEXTURES.size() - 1)
	pants_id = randi_range(0, CharacterSprite.PANTS_TEXTURES.size() - 1)

func _refresh_appearance() -> void:
	if is_node_ready():
		sprite.set_appearance(hair_id, top_id, pants_id)

func _setup_authority() -> void:
	if is_multiplayer_authority():
		player_data.stats_changed.connect(_on_stats_changed)
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
	var dir := Input.get_vector("left", "right", "up", "down")
	if is_world_input_blocked:
		velocity = Vector2.ZERO
		audio.stop()
		return
	if _smoking:
		velocity = Vector2.ZERO
		audio.stop()
		return
	if is_sitting:
		if dir != Vector2.ZERO:
			_stand_up()
		else:
			velocity = Vector2.ZERO
			audio.stop()
		return

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
		if not audio.playing: 
			audio.play()
	else:
		audio.stop()
	move_and_slide()

func _on_direction_change(direction: Vector2) -> void:
	if is_dancing:
		_stop_dance_animation()
		_start_dance_animation()

func _start_dance_animation() -> void:
	var dance_row := ROW_DANCE_N if direction.y < 0 else ROW_DANCE
	var sprite_row_start_frame = dance_row * sprite.hframes
	sprite.frame = sprite_row_start_frame
	_dance_tween = create_tween().set_loops()
	_dance_tween.tween_interval(0.5)
	_dance_tween.tween_callback(
		func(): sprite.frame = sprite_row_start_frame + (sprite.frame + 1) % sprite.hframes
	)
	
func _stop_dance_animation() -> void:
	if _dance_tween:
		_dance_tween.kill()
		_dance_tween = null
	_start_idle_bob()

func _dir_to_idle_row(d: Vector2) -> int:
	if absf(d.x) >= absf(d.y):
		return ROW_WALK_E if d.x > 0 else ROW_WALK_W
	return ROW_WALK_S if d.y > 0 else ROW_WALK_N

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("phone") and not event.is_echo():
		if not is_world_input_blocked and not _smoking:
			phone_requested.emit(self)
			get_viewport().set_input_as_handled()
		return
	if is_world_input_blocked:
		return
	if _smoking:
		return
	if event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("take"):
		_try_take_drop()

func _try_interact() -> void:
	if _hands_item != null:
		for area in interaction_area.get_overlapping_areas():
			var owner_node := area.get_parent()
			if owner_node is Trash:
				owner_node.interact(self)
				return
	for area in interaction_area.get_overlapping_areas():
		var owner_node := area.get_parent()
		if owner_node is Chair:
			var chair = owner_node as Chair
			if not chair.is_occupied:
				_sit_in(chair)
				return
		elif owner_node is Boombox:
			owner_node.switch()
			return
		elif owner_node is DanceFloorController:
			owner_node.next_mode()
			return
		elif owner_node is Door:
			owner_node.toggle()
			return
		elif owner_node is TableFootballInteract:
			owner_node.open_game(self)
			return
		elif owner_node is PokerSession:
			owner_node.open_game(self)
			return
		elif _hands_item != null:
			_hands_interact()
			return
		elif owner_node is Bartender:
			var bartender = owner_node as Bartender
			bartender.order(self)
			return
		elif owner_node is Interactable:
			owner_node.interact(self)
			return
	if _hands_item != null:
		_hands_interact()

func _try_take_drop() -> void:
	for area in interaction_area.get_overlapping_areas():
		var owner_node := area.get_parent()
		if owner_node is DropPlace and _hands_item != null:
			var place = owner_node as DropPlace
			_hands_item.drop(self, place)
			_hands_item = null
			return
		elif owner_node is Draggable and _hands_item == null:
			take_spawned_item(owner_node)
			_hands_item.pickup(self)
			return

func take_spawned_item(item: Draggable) -> void:
	if _hands_item != null:
		return
	_hands_item = item
	item.tree_exiting.connect(func():
		if _hands_item == item:
			_hands_item = null
	, CONNECT_ONE_SHOT)

func _sit_in(chair: Chair) -> void:
	if is_sitting:
		return
	chair.occupy(self)
	seated_chair = chair
	is_sitting = true
	global_position = chair.get_seat_position()
	_idle_tween.pause()
	sprite.frame = (ROW_WALK_N if chair.facing_north else ROW_SIT) * 4

func _stand_up() -> void:
	if seated_chair:
		seated_chair.vacate(self)
		seated_chair = null
	is_sitting = false
	_start_idle_bob()

func _hands_interact() -> void:
	if _hands_item == null:
		return
	elif _hands_item is Drink:
		var drink = _hands_item as Drink
		_drink(drink)
	elif _hands_item is CigarettePack:
		_smoke(_hands_item as CigarettePack)
	elif _hands_item is Boombox:
		_hands_item.switch()
	elif _hands_item is DanceFloorController:
		_hands_item.next_mode()

func _drink(drink: Drink) -> void:
	if drink.parts == 0:
		return
	player_data.apply_drink_part(drink)
	drink_action_requested.emit(int(name), drink.name)
	_rpc_show_drink_anim.rpc()

func _smoke(pack: CigarettePack) -> void:
	if _smoking or pack.cigarettes_left <= 0:
		return
	_smoking = true
	smoke_action_requested.emit(int(name), pack.name)
	_rpc_show_smoke_anim.rpc()

func on_cigarette_smoked() -> void:
	player_data.apply_cigarette()

@rpc("authority", "call_local", "reliable")
func _rpc_show_smoke_anim() -> void:
	var smoke_row := ROW_DRINK_N if direction.y < 0 else ROW_DRINK
	sprite.frame = smoke_row * 4
	var tween := create_tween()
	tween.tween_interval(CigarettePack.SMOKE_DURATION * 0.35)
	tween.tween_callback(func(): sprite.frame = smoke_row * 4 + 1)
	tween.tween_interval(CigarettePack.SMOKE_DURATION * 0.65)
	tween.tween_callback(func():
		sprite.frame = _dir_to_idle_row(direction) * 4
		_smoking = false
	)

@rpc("authority", "call_local", "reliable")
func _rpc_show_drink_anim() -> void:
	_animate_drink()

func _animate_drink() -> void:
	var drink_row := ROW_DRINK_N if direction.y < 0 else ROW_DRINK
	sprite.frame = drink_row * 4
	var tween := create_tween()
	tween.tween_property(sprite, "rotation_degrees", 12.0, 0.12)
	tween.tween_property(sprite, "rotation_degrees", -4.0, 0.1)
	tween.tween_property(sprite, "rotation_degrees", 0.0, 0.18).set_trans(Tween.TRANS_SPRING)
	var sit_row := ROW_WALK_N if seated_chair and seated_chair.facing_north else ROW_SIT
	tween.tween_callback(func(): sprite.frame = sit_row * 4)
	var frame_t := create_tween()
	frame_t.tween_interval(0.15)
	frame_t.tween_callback(func(): sprite.frame = drink_row * 4 + 1)
	
@rpc("any_peer", "call_local", "reliable")
func rpc_apply_player_setup(setup: Dictionary) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender != 0 and sender != 1:
		return
	if setup.has("name"):
		player_name = setup["name"]

func _on_stats_changed():
	var drunkness = player_data.get_drunkness()
	if drunkness > 0.75:
		AnimationUtils.drunk_camera_focus_change(camera, 1.25).play()
	else:
		AnimationUtils.drunk_camera_focus_change(camera, 1).play()
	if drunkness > 0.25:
		if _drunk_tween:
			_drunk_tween.kill()
		_drunk_tween = AnimationUtils.drunk_camera_shake_tween(
			camera,
			2 - drunkness + 0.25,
			drunkness,
		)
		_drunk_tween.play()
	
