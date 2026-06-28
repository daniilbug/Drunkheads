class_name AnimationUtils
extends Object

const DRUNK_CAMERA_ANIM_DURATION = 0.3

static func drunk_camera_shake_tween(
	camera: Camera2D,
	speed: float,
	max_distance: float,
) -> Tween:
	var drunk_tween := camera.create_tween()
	drunk_tween.set_loops()

	drunk_tween.tween_property(camera, "drag_vertical_offset", -max_distance, speed)
	drunk_tween.tween_property(camera, "drag_horizontal_offset", -max_distance, speed)
	drunk_tween.tween_property(camera, "drag_vertical_offset", max_distance, speed)
	drunk_tween.tween_property(camera, "drag_horizontal_offset", max_distance, speed)

	drunk_tween.pause()

	return drunk_tween
	
static func drunk_camera_focus_change(camera: Camera2D, focus: float) -> Tween:
	var focus_tween = camera.create_tween()
	focus_tween.tween_property(camera, "zoom:x", focus, DRUNK_CAMERA_ANIM_DURATION)
	focus_tween.tween_property(camera, "zoom:y", focus, DRUNK_CAMERA_ANIM_DURATION)
	focus_tween.pause()
	return focus_tween
