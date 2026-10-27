class_name ConversationTopics
extends RefCounted

# Topic IDs are saved in NPC profiles: append new topics without reordering.
const ICONS: Array[Texture2D] = [
	preload("res://assets/sprites/social/music.png"),
	preload("res://assets/sprites/social/reading.png"),
	preload("res://assets/sprites/social/sport.png"),
	preload("res://assets/sprites/social/cooking.png"),
	preload("res://assets/sprites/social/games.png"),
	preload("res://assets/sprites/social/travel.png"),
	preload("res://assets/sprites/social/animals.png"),
	preload("res://assets/sprites/social/gardening.png"),
	preload("res://assets/sprites/social/cinema.png"),
	preload("res://assets/sprites/social/photography.png"),
	preload("res://assets/sprites/social/drawing.png"),
	preload("res://assets/sprites/social/fishing.png"),
	preload("res://assets/sprites/social/cars.png"),
	preload("res://assets/sprites/social/astronomy.png"),
	preload("res://assets/sprites/social/science.png"),
	preload("res://assets/sprites/social/fashion.png"),
	preload("res://assets/sprites/social/board_games.png"),
	preload("res://assets/sprites/social/coffee.png"),
]
const HEART: Texture2D = preload("res://assets/sprites/social/heart.png")
const NEUTRAL: Texture2D = preload("res://assets/sprites/social/neutral.png")
const INTEREST_COUNT := 6
const ROUND_COUNT := 3

static func new_interests() -> PackedInt32Array:
	var topics := range(ICONS.size())
	topics.shuffle()
	return PackedInt32Array(topics.slice(0, INTEREST_COUNT))

## Nine distinct topics per conversation; each trio contains exactly one NPC interest.
static func new_rounds(interests: PackedInt32Array) -> Array[PackedInt32Array]:
	var liked: Array = Array(interests)
	liked.shuffle()
	var others := range(ICONS.size()).filter(func(topic: int): return topic not in interests)
	others.shuffle()
	var rounds: Array[PackedInt32Array] = []
	for index in ROUND_COUNT:
		var choices: Array = [liked[index], others[index * 2], others[index * 2 + 1]]
		choices.shuffle()
		rounds.append(PackedInt32Array(choices))
	return rounds
