class_name Player
extends CharacterBody2D

static var local_setup: Dictionary = {"name": "Player"}

const SPEED := 350.0
const FPS_WALK := 8.0
const SAVE_SCHEMA := {
	"player_name": "", "level_id": "", "return_level_id": "", "position": Vector2.ZERO,
	"direction": Vector2.ZERO, "wallpaper": 0, "stats": {"money": 0.0, "mind": 0.0, "respect": 0.0},
	"appearance": {"hair_id": 0, "hair_color_id": 0, "top_id": 0, "top_color_id": 0, "pants_id": 0, "pants_color_id": 0},
}
const SAVE_APPEARANCE: Array[String] = ["hair_id", "hair_color_id", "top_id", "top_color_id", "pants_id", "pants_color_id"]

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
var settings: PlayerSettings
@export var is_sitting := false
var seated_seat: Seat = null
@export var peer_id: int = 0

@export var in_vehicle := false:
	set(value):
		in_vehicle = value
		if is_node_ready():
			_apply_vehicle_state()

@export var riding_vehicle_name := ""
@export var level_id := "bar"
@export var return_level_id := "bar"

# A garment is its existing atlas style ID and fixed fabric color ID.
# These inventories, like appearance, are owned by the server.
@export var owned_tops: Array[Vector2i] = []
@export var owned_bottoms: Array[Vector2i] = []

@export var hair_id: int = 0:
	set(value):
		hair_id = value
		_refresh_appearance()

@export var hair_color_id: int = 2:
	set(value):
		hair_color_id = value
		_refresh_appearance()

@export var top_id: int = 0:
	set(value):
		top_id = value
		_refresh_appearance()

@export var top_color_id: int = 4:
	set(value):
		top_color_id = value
		_refresh_appearance()

@export var pants_id: int = 0:
	set(value):
		pants_id = value
		_refresh_appearance()

@export var pants_color_id: int = 3:
	set(value):
		pants_color_id = value
		_refresh_appearance()

@export var in_shower := false:
	set(value):
		in_shower = value
		if is_node_ready():
			sprite.set_in_shower(value)

@export var headphones_enabled := false:
	set(value):
		headphones_enabled = value
		if is_node_ready():
			sprite.set_headphones_enabled(value)

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
var _is_modal_input_blocked := false
var is_world_input_blocked: bool:
	get:
		return in_vehicle or _is_modal_input_blocked
	set(value):
		_is_modal_input_blocked = value

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
signal bus_exit_requested(player: Player)
signal appearance_changed

func _enter_tree() -> void:
	set_multiplayer_authority(int(name), true)
	$AppearanceSynchronizer.set_multiplayer_authority(1)

func _ready() -> void:
	_refresh_appearance()
	sprite.set_headphones_enabled(headphones_enabled)
	sprite.set_in_shower(in_shower)
	_apply_vehicle_state()
	_start_idle_bob()
	set_notify_transform(true)
	call_deferred("_setup_authority")

func _apply_vehicle_state() -> void:
	visible = not in_vehicle
	$Shape.set_deferred("disabled", in_vehicle)
	var obstacle := get_node_or_null("NavigationObstacle") as NavigationObstacle2D
	if obstacle != null:
		obstacle.avoidance_enabled = multiplayer.is_server() and not in_vehicle

func randomize_appearance() -> void:
	# All three slots use the same masculine/feminine ID ranges.
	var group_start := randi_range(0, 1) * CharacterSprite.STYLES_PER_GROUP
	hair_id = group_start + randi_range(0, CharacterSprite.STYLES_PER_GROUP - 1)
	hair_color_id = randi_range(0, CharacterSprite.HAIR_COLORS.size() - 1)
	top_id = group_start + randi_range(0, CharacterSprite.STYLES_PER_GROUP - 1)
	pants_id = group_start + randi_range(0, CharacterSprite.STYLES_PER_GROUP - 1)
	top_color_id = randi_range(0, CharacterSprite.CLOTHING_COLORS.size() - 1)
	pants_color_id = randi_range(0, CharacterSprite.CLOTHING_COLORS.size() - 1)

func _refresh_appearance() -> void:
	if is_node_ready():
		sprite.set_appearance(hair_id, top_id, pants_id, hair_color_id, top_color_id, pants_color_id)
		appearance_changed.emit()

func initialize_wardrobe() -> void:
	for is_top in [true, false]:
		var items := owned_tops if is_top else owned_bottoms
		if not items.is_empty():
			continue
		var current := Vector2i(top_id, top_color_id) if is_top else Vector2i(pants_id, pants_color_id)
		items.append(current)
		var group_start := (current.x / CharacterSprite.STYLES_PER_GROUP) * CharacterSprite.STYLES_PER_GROUP
		while items.size() < 3:
			var item := Vector2i(group_start + randi_range(0, CharacterSprite.STYLES_PER_GROUP - 1),
				randi_range(0, CharacterSprite.CLOTHING_COLORS.size() - 1))
			if item not in items:
				items.append(item)

static func is_valid_wardrobe(data: Variant) -> bool:
	if not SaveGraph.matches(data, {"tops": [], "bottoms": []}):
		return false
	for slot in ["tops", "bottoms"]:
		var count := CharacterSprite.TOP_TEXTURES.size() if slot == "tops" else CharacterSprite.PANTS_TEXTURES.size()
		var items: Array = data[slot]
		if items.is_empty() or items.size() > count * CharacterSprite.CLOTHING_COLORS.size():
			return false
		var seen := {}
		for item in items:
			if item is not Vector2i or item.x < 0 or item.x >= count \
				or item.y < 0 or item.y >= CharacterSprite.CLOTHING_COLORS.size() or seen.has(item):
				return false
			seen[item] = true
	return true

func _setup_authority() -> void:
	if is_multiplayer_authority():
		player_data.stats_changed.connect(_on_stats_changed)
		camera.make_current()
		_on_stats_changed()

func get_save_data() -> Dictionary:
	var world := get_parent() as Main
	var level := world.get_player_level(int(name)) if world != null else Level.find_level_node(self)
	var stats := player_data.get_save_data()
	if world != null:
		# Uncommitted poker chips are cashed out; session state is not persisted.
		for session in world.find_children("*", "PokerSession", true, false):
			stats.money = clampf(stats.money + session.get_cash_out(int(name)), PlayerData.MIN_STAT, PlayerData.MAX_STAT)
	return {
		"player_name": player_name, "level_id": level_id, "return_level_id": return_level_id,
		"position": level.to_local(level.get_transport_arrival_position() if in_vehicle else global_position), "direction": direction,
		"appearance": SaveGraph.get_fields(self, SAVE_APPEARANCE),
		"stats": stats, "wallpaper": settings.phone_wallpaper_index,
		"wardrobe": {"tops": owned_tops.duplicate(), "bottoms": owned_bottoms.duplicate()},
	}

func apply_save_data(data: Dictionary) -> void:
	player_name = data.player_name
	level_id = data.level_id
	return_level_id = data.get("return_level_id", "bar")
	direction = data.get("direction", Vector2.DOWN)
	SaveGraph.apply_fields(self, SAVE_APPEARANCE, data.get("appearance", {}))
	if data.has("wardrobe"):
		owned_tops.assign(data.wardrobe.tops)
		owned_bottoms.assign(data.wardrobe.bottoms)
	player_data = PlayerData.new()
	player_data.apply_save_data(data.stats)
	settings = PlayerSettings.new()
	settings.phone_wallpaper_index = maxi(0, int(data.get("wallpaper", 0)))

func _start_idle_bob() -> void:
	_anim_row = _dir_to_idle_row(direction)
	sprite.frame = _anim_row * 4
	_idle_tween = create_tween().set_loops()
	_idle_tween.tween_property(sprite, "scale:y", 0.95, 0.45).set_trans(Tween.TRANS_SINE)
	_idle_tween.tween_property(sprite, "scale:y", 1.0, 0.45).set_trans(Tween.TRANS_SINE)

func _process(_delta: float) -> void:
	if not in_vehicle or riding_vehicle_name.is_empty():
		return
	var main := get_parent() as Main
	var level := main.get_player_level(int(name)) if main != null else Level.find_level_node(self)
	if level == null:
		return
	var vehicle := level.get_node_or_null(NodePath(riding_vehicle_name)) as Vehicle
	if vehicle != null:
		global_position = vehicle.global_position + Vector2(0, -15)

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
	_animate_movement(delta, dir)
	if dir != Vector2.ZERO:
		if not audio.playing:
			audio.play()
	else:
		audio.stop()
	move_and_slide()

func _animate_movement(delta: float, dir: Vector2) -> void:
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
		if not _is_modal_input_blocked and not _smoking:
			phone_requested.emit(self)
			get_viewport().set_input_as_handled()
		return
	if is_world_input_blocked:
		if in_vehicle and not _is_modal_input_blocked and not _smoking and event.is_action_pressed("interact") and not event.is_echo():
			bus_exit_requested.emit(self)
			get_viewport().set_input_as_handled()
		return
	if _smoking:
		return
	if event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("take"):
		_try_take_drop()

func _try_interact() -> void:
	var areas := interaction_area.get_overlapping_areas()
	if _hands_item != null:
		for area in areas:
			var owner_node := area.get_parent()
			if owner_node is Trash:
				owner_node.interact(self)
				return
	var nearest_seat: Seat = null
	var nearest_distance := INF
	if not is_sitting:
		for area in areas:
			var candidate := area.get_parent() as Seat
			if candidate != null and not candidate.is_occupied and candidate.is_player_in_reach(self):
				var distance := global_position.distance_squared_to(candidate.global_position)
				if distance < nearest_distance:
					nearest_seat = candidate
					nearest_distance = distance
	if nearest_seat != null:
		_sit_in(nearest_seat)
		return
	var nearest_door: Door = null
	var nearest_door_distance := INF
	for area in areas:
		var owner_node := area.get_parent()
		if owner_node is Boombox:
			owner_node.switch()
			return
		elif owner_node is DanceFloorController:
			owner_node.next_mode()
			return
		elif owner_node is Door:
			var distance := global_position.distance_squared_to(owner_node.global_position)
			if distance < nearest_door_distance:
				nearest_door = owner_node
				nearest_door_distance = distance
	if nearest_door != null:
		nearest_door.toggle()
		return
	for area in areas:
		var owner_node := area.get_parent()
		if owner_node is TableFootballInteract:
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
		elif owner_node is Switch:
			# Adjacent switches can both overlap the player's interaction area.
			var nearest_switch := owner_node as Switch
			for switch_area in areas:
				var candidate := switch_area.get_parent() as Switch
				if candidate != null and global_position.distance_squared_to(candidate.global_position) < global_position.distance_squared_to(nearest_switch.global_position):
					nearest_switch = candidate
			nearest_switch.interact(self)
			return
		elif owner_node is Interactable:
			owner_node.interact(self)
			return
	if _hands_item != null:
		_hands_interact()

func _try_take_drop() -> void:
	var areas := interaction_area.get_overlapping_areas()
	if _hands_item is CafeRecord:
		(_hands_item as CafeRecord).place_nearby(self, areas)
		return
	# Q selects the closest record on the tabletop.
	if _hands_item == null:
		var nearest_record: CafeRecord
		for area in areas:
			var record := area.get_parent() as CafeRecord
			if record != null and record.can_pickup(self) and (nearest_record == null or global_position.distance_squared_to(area.global_position) < global_position.distance_squared_to(nearest_record.get_node("Area").global_position)):
				nearest_record = record
		if nearest_record != null:
			take_spawned_item(nearest_record)
			nearest_record.pickup(self)
			return
	for area in areas:
		var owner_node := area.get_parent()
		if owner_node is DropPlace and _hands_item != null:
			var place = owner_node as DropPlace
			if place is CafeRecordSlot:
				continue
			_hands_item.drop(self, place)
			_hands_item = null
			return
		elif owner_node is Draggable and _hands_item == null and owner_node.can_pickup(self):
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

func _sit_in(seat: Seat) -> void:
	if is_sitting or not seat.occupy(self):
		return
	seated_seat = seat
	is_sitting = true
	global_position = seat.get_seat_position()
	_idle_tween.pause()
	sprite.frame = (ROW_WALK_N if seat.facing_north else ROW_SIT) * 4

func _stand_up() -> void:
	if seated_seat:
		seated_seat.vacate(self)
		seated_seat = null
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
	tween.tween_callback(func():
		var idle_row := (ROW_WALK_N if direction.y < 0 else ROW_SIT) if is_sitting else _dir_to_idle_row(direction)
		sprite.frame = idle_row * 4
	)
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
	
