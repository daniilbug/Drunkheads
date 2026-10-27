class_name NPCProfile
extends Resource

const AFFINITY_LIMIT := 20.0
const AFFINITY_DELTAS := [-0.5, 0.0, 0.5, 1.0]
const APPEARANCE_CATALOGS := {
	"hair_id": CharacterSprite.HAIR_TEXTURES, "top_id": CharacterSprite.TOP_TEXTURES,
	"pants_id": CharacterSprite.PANTS_TEXTURES, "hair_color_id": CharacterSprite.HAIR_COLORS,
	"top_color_id": CharacterSprite.CLOTHING_COLORS, "pants_color_id": CharacterSprite.CLOTHING_COLORS,
}

var appearance: Dictionary = {}
var interests := PackedInt32Array()
var active := false
var _affinities: Dictionary[int, float] = {}

static func create(npc: NPC) -> NPCProfile:
	var profile := NPCProfile.new()
	npc.randomize_appearance()
	profile.appearance = SaveGraph.get_fields(npc, Player.SAVE_APPEARANCE)
	profile.interests = ConversationTopics.new_interests()
	return profile

func apply_appearance(npc: NPC) -> void:
	SaveGraph.apply_fields(npc, Player.SAVE_APPEARANCE, appearance)

func affinity(peer_id: int) -> float:
	return _affinities.get(peer_id, 0.0)

func finish_conversation(peer_id: int, hits: int) -> float:
	var previous := affinity(peer_id)
	var value := clampf(previous + AFFINITY_DELTAS[hits], -AFFINITY_LIMIT, AFFINITY_LIMIT)
	_affinities[peer_id] = value
	return value - previous

func forget_guest(peer_id: int) -> void:
	_affinities.erase(peer_id)

func get_save_data() -> Dictionary:
	# Guest characters follow the existing rule: they do not survive a loaded game.
	return {"appearance": appearance.duplicate(), "interests": interests, "affinity": affinity(1)}

static func from_save(data: Dictionary) -> NPCProfile:
	var profile := NPCProfile.new()
	profile.appearance = data.appearance.duplicate()
	profile.interests = data.interests.duplicate()
	profile._affinities[1] = data.affinity
	return profile

static func is_valid_save(data: Variant) -> bool:
	if not SaveGraph.matches(data, {"appearance": {}, "interests": PackedInt32Array(), "affinity": 0.0}):
		return false
	if absf(data.affinity) > AFFINITY_LIMIT:
		return false
	for field in APPEARANCE_CATALOGS:
		var limit: int = APPEARANCE_CATALOGS[field].size()
		if not data.appearance.has(field) or not SaveGraph.matches(data.appearance[field], Vector2i(0, limit - 1)):
			return false
	if data.interests.size() != ConversationTopics.INTEREST_COUNT:
		return false
	var seen: Array[int] = []
	for topic: int in data.interests:
		if topic < 0 or topic >= ConversationTopics.ICONS.size() or topic in seen:
			return false
		seen.append(topic)
	return true
