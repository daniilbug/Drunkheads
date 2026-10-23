@tool
class_name Door
extends Node2D

@export var is_open: bool = false:
	set(value):
		var was_open = is_open
		is_open = value
		if is_node_ready():
			_apply_state(was_open)

@onready var _closed_sprite: Sprite2D = $ClosedSprite
@onready var _open_sprite: Sprite2D = $OpenSprite
@onready var _collision: CollisionShape2D = $Body/Shape
@onready var _audio: AudioStreamPlayer2D = $Audio
@onready var _npc_approach_zone: Area2D = $NPCApproachZone
@onready var _passage_zone: Area2D = $PassageZone

var _auto_close_timer := 0.0
var _opened_by_npc := false
var _npc_has_passed := false
var _npc_entry_sides: Dictionary = {}
const AUTO_CLOSE_DELAY := 2.0

func _enter_tree() -> void:
	add_to_group("saveable")
	set_multiplayer_authority(1, true)

func _ready() -> void:
	if multiplayer.is_server():
		_apply_state(false)
	if not Engine.is_editor_hint():
		_punch_wall_hole()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not multiplayer.is_server():
		return

	if not is_open:
		_cancel_npc_auto_close()
	for body in _npc_approach_zone.get_overlapping_bodies():
		var npc := body as NPC
		if npc == null or not _is_npc_approaching(npc):
			continue
		if not is_open:
			_opened_by_npc = true
			is_open = true
		if _opened_by_npc and not _npc_entry_sides.has(npc):
			var side := signf(_get_npc_position(npc).y)
			_npc_entry_sides[npc] = side if side != 0.0 else -signf(npc.nav_agent.velocity.y)

	if not _opened_by_npc:
		return
	_update_npc_passages()
	if not _npc_has_passed or not _npc_entry_sides.is_empty() or _is_passage_blocked():
		_auto_close_timer = 0.0
		return
	_auto_close_timer += delta
	if _auto_close_timer >= AUTO_CLOSE_DELAY:
		is_open = false
		_cancel_npc_auto_close()

func _get_npc_position(npc: NPC) -> Vector2:
	var body_shape := npc.get_node("Shape") as CollisionShape2D
	return to_local(body_shape.global_position) - to_local(_collision.global_position)

func _is_npc_approaching(npc: NPC) -> bool:
	if npc.is_sitting or npc.in_vehicle:
		return false
	# Requested navigation velocity remains nonzero when a closed door blocks motion.
	var motion := to_local(npc.global_position + npc.nav_agent.velocity) - to_local(npc.global_position)
	var position := _get_npc_position(npc)
	var destination := to_local(npc.nav_agent.target_position) - to_local(_collision.global_position)
	if is_zero_approx(motion.y) or position.y * motion.y > 0.0 or position.y * destination.y >= 0.0:
		return false
	var crossing_x := position.x - position.y * motion.x / motion.y
	return absf(crossing_x) <= (_collision.shape as RectangleShape2D).size.x * 0.5

func _update_npc_passages() -> void:
	for npc in _npc_entry_sides.keys():
		if not is_instance_valid(npc):
			_npc_entry_sides.erase(npc)
			continue
		var crossed := _get_npc_position(npc).y * float(_npc_entry_sides[npc]) < 0.0
		if _passage_zone.overlaps_body(npc):
			_npc_has_passed = _npc_has_passed or crossed
		elif crossed or not _npc_approach_zone.overlaps_body(npc) or not _is_npc_approaching(npc):
			_npc_entry_sides.erase(npc)

func _is_passage_blocked() -> bool:
	for body in _passage_zone.get_overlapping_bodies():
		if body is Player:
			return true
	return false

func _cancel_npc_auto_close() -> void:
	_opened_by_npc = false
	_npc_has_passed = false
	_auto_close_timer = 0.0
	_npc_entry_sides.clear()

func toggle() -> void:
	if multiplayer.is_server():
		_toggle_local()
	else:
		_toogle_remote.rpc_id(1)

@rpc("any_peer", "reliable")
func _toogle_remote() -> void:
	if not multiplayer.is_server():
		return
	var level := Level.find_level_node(self)
	var player := level.get_player(multiplayer.get_remote_sender_id()) if level != null else null
	if player == null or not $InteractionZone.overlaps_area(player.interaction_area):
		return
	_toggle_local()
	
func _toggle_local() -> void:
	_cancel_npc_auto_close()
	is_open = not is_open

func _apply_state(was_open: bool) -> void:
	_closed_sprite.visible = not is_open
	_open_sprite.visible = is_open
	_collision.disabled = is_open
	_make_sound(was_open)

func _punch_wall_hole() -> void:
	var room := get_parent() as Room
	if not room:
		return
	var walls := room.get_walls()
	if not walls:
		return

	var door_center := room.to_local(_collision.global_position)
	var door_shape := _collision.shape as RectangleShape2D
	if not door_shape:
		return
	var door_hw := door_shape.size.x * 0.5
	var door_hh := door_shape.size.y * 0.5

	for wall in walls:
		var shape_node := wall.find_child("*Shape") as CollisionShape2D
		if not shape_node:
			continue
		var wall_shape := shape_node.shape as RectangleShape2D
		if not wall_shape:
			continue
			
		var wall_center := wall.position
		var wall_hw := wall_shape.size.x * 0.5
		var wall_hh := wall_shape.size.y * 0.5

		if abs(door_center.x - wall_center.x) >= wall_hw + door_hw:
			continue
		if abs(door_center.y - wall_center.y) >= wall_hh + door_hh:
			continue

		shape_node.disabled = true

		if wall_hw >= wall_hh:
			_add_h_segment(wall, wall_center.x - wall_hw, door_center.x - door_hw, wall_hh * 2.0)
			_add_h_segment(wall, door_center.x + door_hw, wall_center.x + wall_hw, wall_hh * 2.0)
		else:
			_add_v_segment(wall, wall_center.y - wall_hh, door_center.y - door_hh, wall_hw * 2.0)
			_add_v_segment(wall, door_center.y + door_hh, wall_center.y + wall_hh, wall_hw * 2.0)
		break

func _add_h_segment(wall: StaticBody2D, x_from: float, x_to: float, height: float) -> void:
	var w := x_to - x_from
	if w <= 0.0:
		return
	var shape := RectangleShape2D.new()
	shape.size = Vector2(w, height)
	var col := CollisionShape2D.new()
	col.position = Vector2((x_from + x_to) * 0.5 - wall.position.x, 0.0)
	col.shape = shape
	wall.add_child(col)

func _add_v_segment(wall: StaticBody2D, y_from: float, y_to: float, width: float) -> void:
	var h := y_to - y_from
	if h <= 0.0:
		return
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, h)
	var col := CollisionShape2D.new()
	col.position = Vector2(0.0, (y_from + y_to) * 0.5 - wall.position.y)
	col.shape = shape
	wall.add_child(col)
	
func _make_sound(was_open: bool) -> void:
	if was_open and not is_open:
		_audio.stream = load("res://assets/audio/interactions/door_close.mp3")
		_audio.play()
	elif not was_open and is_open:
		_audio.stream = load("res://assets/audio/interactions/door_open.mp3")
		_audio.play()

func get_save_data() -> Dictionary:
	return SaveGraph.get_fields(self, ["is_open"])

func apply_save_data(data: Dictionary) -> void:
	SaveGraph.apply_fields(self, get_save_data().keys(), data)
