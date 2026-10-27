extends RefCounted

## Head coordinates are already in viewport space; UI stays at its native scale.
static func place(head: Vector2, other: Vector2, extent: Vector2, viewport: Vector2,
		is_player: bool, actor_scale: float, occupied := Rect2()) -> Rect2:
	var side := -1.0 if is_player else 1.0
	var vertical := absf(head.x - other.x) < 96.0
	var gap := maxf(40.0, actor_scale * 8.0)
	var above := head + Vector2(-extent.x + 40 if head.x < other.x else -40, -extent.y - 40)
	var left := head + Vector2(-extent.x - gap, -extent.y / 2)
	var right := head + Vector2(gap, -extent.y / 2)
	var candidates: Array[Vector2] = [left if side < 0 else right, above, right if side < 0 else left]
	if not vertical:
		candidates = [above, candidates[0], candidates[2]]
	var best := Rect2()
	var best_score := INF
	for candidate in candidates:
		var origin := candidate.clamp(Vector2(16, 16), viewport - extent - Vector2(16, 16)).round()
		var rect := Rect2(origin, extent)
		var score := origin.distance_to(candidate)
		for actor in [head, other]:
			var body := Rect2(actor - Vector2(8, 5) * actor_scale, Vector2(16, 25) * actor_scale)
			score += rect.intersection(body).get_area() * 10.0
		if occupied.has_area():
			score += rect.intersection(occupied.grow(12)).get_area() * 20.0
		if score < best_score:
			best = rect
			best_score = score
	return best
