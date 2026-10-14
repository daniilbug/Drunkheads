@tool
extends Node2D

@export_range(1.0, 4096.0, 1.0, "or_greater") var road_width := 240.0:
	set(value):
		road_width = maxf(value, 1.0)
		_update_layout()

@export_storage var right_lane_start_from_left := -65.0:
	set(value):
		right_lane_start_from_left = value
		_update_layout()

@export_storage var right_lane_end_from_right := 65.0:
	set(value):
		right_lane_end_from_right = value
		_update_layout()

@export_storage var left_lane_start_from_right := 65.0:
	set(value):
		left_lane_start_from_right = value
		_update_layout()

@export_storage var left_lane_end_from_left := -65.0:
	set(value):
		left_lane_end_from_left = value
		_update_layout()

func _ready() -> void:
	_update_layout()

func _update_layout() -> void:
	if not is_node_ready():
		return
	var road := $Road as Sprite2D
	var road_region := road.region_rect
	road_region.size.x = road_width
	road.region_rect = road_region
	$RightTrafficLane/Start.position.x = right_lane_start_from_left
	$RightTrafficLane/End.position.x = road_width + right_lane_end_from_right
	$LeftTrafficLane/Start.position.x = road_width + left_lane_start_from_right
	$LeftTrafficLane/End.position.x = left_lane_end_from_left
