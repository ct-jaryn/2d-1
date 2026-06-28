class_name AchievementData
extends RefCounted

enum Type {
	KILLS,
	LEVEL,
	GOLD,
	BOSSES,
	STAGE
}

var id: String
var name: String
var description: String
var type: int
var target: int
var reward_gold: int = 0
var reward_attack: int = 0
var reward_defense: int = 0
var completed: bool = false

func _init(p_id: String, p_name: String, p_desc: String, p_type: int, p_target: int) -> void:
	id = p_id
	name = p_name
	description = p_desc
	type = p_type
	target = p_target

func get_type_name() -> String:
	match type:
		Type.KILLS:
			return tr("UI_ACHIEVEMENT_TYPE_KILLS")
		Type.LEVEL:
			return tr("UI_ACHIEVEMENT_TYPE_LEVEL")
		Type.GOLD:
			return tr("UI_ACHIEVEMENT_TYPE_GOLD")
		Type.BOSSES:
			return tr("UI_ACHIEVEMENT_TYPE_BOSSES")
		Type.STAGE:
			return tr("UI_ACHIEVEMENT_TYPE_STAGE")
	return tr("UI_ACHIEVEMENT_UNKNOWN_TYPE")

func get_reward_text() -> String:
	var parts: PackedStringArray = []
	if reward_gold > 0:
		parts.append(tr("UI_ACHIEVEMENT_REWARD_GOLD") % reward_gold)
	if reward_attack > 0:
		parts.append(tr("UI_ACHIEVEMENT_REWARD_ATTACK") % reward_attack)
	if reward_defense > 0:
		parts.append(tr("UI_ACHIEVEMENT_REWARD_DEFENSE") % reward_defense)
	if parts.is_empty():
		return tr("UI_ACHIEVEMENT_REWARD_NONE")
	return tr("UI_ACHIEVEMENT_REWARD_PREFIX") + " ".join(parts)
