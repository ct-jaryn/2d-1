class_name SkillData
extends Resource

enum Type {
	HEAL,       ## 治疗
	HEAVY_HIT,  ## 重击
	BERSERK     ## 狂暴
}

var skill_name: String = ""
var type: Type = Type.HEAL
var description: String = ""
var cooldown: float = 10.0  ## 冷却时间（秒）
var energy_cost: int = 0
var power: float = 1.0      ## 技能倍率
var duration: float = 0.0   ## 持续效果时间（秒）

func _init(p_name: String, p_type: Type, p_desc: String, p_cooldown: float, p_cost: int, p_power: float, p_duration: float = 0.0) -> void:
	skill_name = p_name
	type = p_type
	description = p_desc
	cooldown = p_cooldown
	energy_cost = p_cost
	power = p_power
	duration = p_duration
