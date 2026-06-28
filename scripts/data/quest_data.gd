class_name QuestData
extends RefCounted

enum Type {
	KILL_ENEMIES,
	DEFEAT_BOSSES,
	EARN_GOLD,
	LEVEL_UP,
	CAST_SKILLS
}

const TYPE_NAMES: Dictionary = {
	Type.KILL_ENEMIES: "UI_QUEST_TYPE_KILL_ENEMIES",
	Type.DEFEAT_BOSSES: "UI_QUEST_TYPE_DEFEAT_BOSSES",
	Type.EARN_GOLD: "UI_QUEST_TYPE_EARN_GOLD",
	Type.LEVEL_UP: "UI_QUEST_TYPE_LEVEL_UP",
	Type.CAST_SKILLS: "UI_QUEST_TYPE_CAST_SKILLS"
}

var id: String
var type: int
var title: String
var description: String
var target: int
var progress: int = 0
var completed: bool = false
var claimed: bool = false
var reward_gold: int = 0
var reward_exp: int = 0
var reward_equipment: bool = false

func _init(p_id: String, p_type: int, p_title: String, p_desc: String, p_target: int) -> void:
	id = p_id
	type = p_type
	title = p_title
	description = p_desc
	target = p_target

func get_type_name() -> String:
	return tr(TYPE_NAMES.get(type, "UI_QUEST_UNKNOWN_TYPE"))

func add_progress(amount: int = 1) -> bool:
	if completed:
		return false
	progress = min(target, progress + amount)
	if progress >= target:
		completed = true
		return true
	return false

func get_progress_text() -> String:
	return "%d / %d" % [progress, target]

func get_progress_ratio() -> float:
	if target <= 0:
		return 0.0
	return float(progress) / float(target)

func get_reward_text() -> String:
	var parts: PackedStringArray = []
	if reward_gold > 0:
		parts.append(tr("UI_QUEST_REWARD_GOLD") % reward_gold)
	if reward_exp > 0:
		parts.append(tr("UI_QUEST_REWARD_EXP") % reward_exp)
	if reward_equipment:
		parts.append(tr("UI_QUEST_REWARD_EQUIPMENT"))
	if parts.is_empty():
		return tr("UI_QUEST_REWARD_NONE")
	return ", ".join(parts)

func serialize() -> Dictionary:
	return {
		"id": id,
		"type": type,
		"title": title,
		"description": description,
		"target": target,
		"progress": progress,
		"completed": completed,
		"claimed": claimed,
		"reward_gold": reward_gold,
		"reward_exp": reward_exp,
		"reward_equipment": reward_equipment
	}

func deserialize(data: Dictionary) -> void:
	id = data.get("id", id)
	type = data.get("type", type)
	title = data.get("title", title)
	description = data.get("description", description)
	target = data.get("target", target)
	progress = data.get("progress", 0)
	completed = data.get("completed", false)
	claimed = data.get("claimed", false)
	reward_gold = data.get("reward_gold", 0)
	reward_exp = data.get("reward_exp", 0)
	reward_equipment = data.get("reward_equipment", false)
