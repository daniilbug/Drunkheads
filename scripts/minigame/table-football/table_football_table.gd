@tool
class_name TableFootballTable
extends Node2D

@export var field_width: int = 330
@export var field_height: int = 560
@export var wall_thickness: int = 8
@export var goal_width: int = 50
@export var goal_depth: int = 16

@export var color_field: Color = Color("1e6530")
@export var color_field_line: Color = Color("2a7a40")
@export var color_wall_mid: Color = Color("7a5028")
@export var color_wall_dark: Color = Color("503215")
@export var color_wall_hi: Color = Color("9a6838")
@export var color_net: Color = Color(0.85, 0.85, 0.85, 0.35)

func _ready() -> void:
	for child in get_children():
		if child is StaticBody2D:
			var mt := PhysicsMaterial.new()
			mt.friction = 0.0
			mt.bounce = 1.0
			child.physics_material_override = mt

func _draw() -> void:
	var goal_l := (field_width - goal_width) * 0.5
	var goal_r := goal_l + goal_width
	var wt := float(wall_thickness)

	for x in range(int(goal_l), int(goal_l + goal_width), 8):
		draw_line(Vector2(x, -goal_depth), Vector2(x, 0.0), color_net, 0.5)
		draw_line(Vector2(x, field_height), Vector2(x, field_height + goal_depth), color_net, 0.5)

	draw_rect(Rect2(wt, wt, field_width - wt * 2.0, field_height - wt * 2.0), color_field)

	var ccr := minf(float(field_width) * 0.12, 22.0)
	draw_line(Vector2(wt, field_height * 0.5), Vector2(field_width - wt, field_height * 0.5), color_field_line, 1.0)
	_draw_circle_outline(Vector2(field_width * 0.5, field_height * 0.5), ccr, color_field_line)

	draw_rect(Rect2(0.0, 0.0, goal_l, wt), color_wall_mid)
	draw_rect(Rect2(0.0, 0.0, goal_l, 1.0), color_wall_hi)
	draw_rect(Rect2(goal_r, 0.0, field_width - goal_r, wt), color_wall_mid)
	draw_rect(Rect2(goal_r, 0.0, field_width - goal_r, 1.0), color_wall_hi)

	draw_rect(Rect2(0.0, field_height - wt, goal_l, wt), color_wall_mid)
	draw_rect(Rect2(0.0, field_height - wt, goal_l, 1.0), color_wall_hi)
	draw_rect(Rect2(goal_r, field_height - wt, field_width - goal_r, wt), color_wall_mid)
	draw_rect(Rect2(goal_r, field_height - wt, field_width - goal_r, 1.0), color_wall_hi)

	draw_rect(Rect2(0.0, 0.0, wt, field_height), color_wall_mid)
	draw_rect(Rect2(0.0, 0.0, 1.0, field_height), color_wall_hi)
	draw_rect(Rect2(field_width - wt, 0.0, wt, field_height), color_wall_dark)

func _draw_circle_outline(center: Vector2, radius: float, col: Color) -> void:
	var points := PackedVector2Array()
	for i in range(33):
		points.append(center + Vector2(cos(TAU * i / 32.0), sin(TAU * i / 32.0)) * radius)
	draw_polyline(points, col, 1.0)
