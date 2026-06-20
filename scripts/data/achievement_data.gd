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
			return "击杀"
		Type.LEVEL:
			return "等级"
		Type.GOLD:
			return "金币"
		Type.BOSSES:
			return "Boss"
		Type.STAGE:
			return "关卡"
	return "未知"

func get_reward_text() -> String:
	var parts: PackedStringArray = []
	if reward_gold > 0:
		parts.append("金币 +%d" % reward_gold)
	if reward_attack > 0:
		parts.append("攻击 +%d" % reward_attack)
	if reward_defense > 0:
		parts.append("防御 +%d" % reward_defense)
	if parts.is_empty():
		return "无奖励"
	return "奖励：" + " ".join(parts)
