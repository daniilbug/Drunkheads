class_name PokerHandEvaluator

const HIGH_CARD       := 0
const ONE_PAIR        := 1
const TWO_PAIR        := 2
const THREE_OF_A_KIND := 3
const STRAIGHT        := 4
const FLUSH           := 5
const FULL_HOUSE      := 6
const FOUR_OF_A_KIND  := 7
const STRAIGHT_FLUSH  := 8

const HAND_NAMES := [
	"High Card",
	"Pair",
	"Two Pair",
	"Three of a Kind",
	"Straight",
	"Flush",
	"Full House",
	"Four of a Kind",
	"Straight Flush"
]

static func card_rank(c: int) -> int: return c / 4
static func card_suit(c: int) -> int: return c % 4

static func best_hand(cards: Array) -> Dictionary:
	if cards.size() < 5:
		return {}
	var best := {}
	for combo in _combos5(cards):
		var h := _eval5(combo)
		if best.is_empty() or _compare(h, best) > 0:
			best = h
	return best

static func compare_hands(a: Dictionary, b: Dictionary) -> int:
	return _compare(a, b)

static func _combos5(cards: Array) -> Array:
	var out := []
	var n := cards.size()
	for i in range(n - 4):
		for j in range(i + 1, n - 3):
			for k in range(j + 1, n - 2):
				for l in range(k + 1, n - 1):
					for m in range(l + 1, n):
						out.append([cards[i], cards[j], cards[k], cards[l], cards[m]])
	return out

static func _eval5(cards: Array) -> Dictionary:
	var ranks: Array = cards.map(func(c): return card_rank(c))
	var suits: Array = cards.map(func(c): return card_suit(c))
	ranks.sort()
	ranks.reverse()

	var is_flush := suits.count(suits[0]) == 5

	var is_straight := false
	var straight_high: int = ranks[0]
	if ranks[0] - ranks[4] == 4 and _unique(ranks) == 5:
		is_straight = true
	elif ranks == [12, 3, 2, 1, 0]:
		is_straight = true
		straight_high = 3

	var counts := {}
	for r in ranks:
		counts[r] = counts.get(r, 0) + 1

	var groups: Array = counts.values()
	groups.sort()
	groups.reverse()

	var tb: Array = _tiebreakers_by_count(counts)

	if is_straight and is_flush:
		return _h(STRAIGHT_FLUSH, [straight_high])
	if groups[0] == 4:
		return _h(FOUR_OF_A_KIND, tb)
	if groups[0] == 3 and groups[1] == 2:
		return _h(FULL_HOUSE, tb)
	if is_flush:
		return _h(FLUSH, ranks)
	if is_straight:
		return _h(STRAIGHT, [straight_high])
	if groups[0] == 3:
		return _h(THREE_OF_A_KIND, tb)
	if groups[0] == 2 and groups[1] == 2:
		return _h(TWO_PAIR, tb)
	if groups[0] == 2:
		return _h(ONE_PAIR, tb)
	return _h(HIGH_CARD, ranks)

static func _h(rank: int, tb: Array) -> Dictionary:
	return {"rank": rank, "name": HAND_NAMES[rank], "tiebreakers": tb}

static func _tiebreakers_by_count(counts: Dictionary) -> Array:
	var pairs := []
	for r in counts:
		pairs.append([counts[r], r])
	pairs.sort_custom(func(a, b): return a[0] > b[0] or (a[0] == b[0] and a[1] > b[1]))
	var out := []
	for p in pairs:
		out.append(p[1])
	return out

static func _unique(arr: Array) -> int:
	var s := {}
	for v in arr: s[v] = true
	return s.size()

static func _compare(a: Dictionary, b: Dictionary) -> int:
	if a.rank != b.rank:
		return 1 if a.rank > b.rank else -1
	for i in range(mini(a.tiebreakers.size(), b.tiebreakers.size())):
		if a.tiebreakers[i] != b.tiebreakers[i]:
			return 1 if a.tiebreakers[i] > b.tiebreakers[i] else -1
	return 0
