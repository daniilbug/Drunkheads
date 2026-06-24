class_name AnimationUtils
extends Object

const DRUNK_ANIM_DURATION = 0.3

static func drunk_camera_shake_tween(camera: Camera2D) -> Tween:
	var drunk_tween = camera.create_tween().set_loops()
	drunk_tween.tween_interval(0)
	drunk_tween.tween_property(camera, "drag_vertical_offset", 0.5, DRUNK_ANIM_DURATION)
	drunk_tween.tween_property(camera, "drag_horizontal_offset", 0.5, DRUNK_ANIM_DURATION)
	drunk_tween.tween_property(camera, "drag_vertical_offset", -0.5, DRUNK_ANIM_DURATION)
	drunk_tween.tween_property(camera, "drag_horizontal_offset", -0.5, DRUNK_ANIM_DURATION)
	drunk_tween.tween_property(camera, "drag_horizontal_offset", 0, DRUNK_ANIM_DURATION)
	drunk_tween.tween_property(camera, "drag_vertical_offset", 0, DRUNK_ANIM_DURATION)
	drunk_tween.pause()
	return drunk_tween
	
static func drunk_camera_focus_change(camera: Camera2D, focus: float) -> Tween:
	var focus_tween = camera.create_tween()
	focus_tween.tween_property(camera, "zoom:x", focus, DRUNK_ANIM_DURATION)
	focus_tween.tween_property(camera, "zoom:y", focus, DRUNK_ANIM_DURATION)
	focus_tween.pause()
	return focus_tween
