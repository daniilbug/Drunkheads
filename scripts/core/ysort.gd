class_name YSort
extends Object

static func _get_top_ysort_anchor(node: Node) -> Node2D:
	var result: Node2D = null
	var current := node
	while current.get_parent() != null:
		var parent := current.get_parent()
		if parent is Node2D and (parent as Node2D).y_sort_enabled:
			result = current as Node2D
		current = parent
	return result
