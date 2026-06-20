class_name EquipmentData
extends Resource

enum Type {
	WEAPON,
	HELMET,
	ARMOR,
	BOOTS,
	RING
}

enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

const RARITY_COLORS: Dictionary = {
	Rarity.COMMON: Color.WHITE,
	Rarity.RARE: Color.CORNFLOWER_BLUE,
	Rarity.EPIC: Color.MEDIUM_PURPLE,
	Rarity.LEGENDARY: Color.GOLD
}

const RARITY_NAMES: Dictionary = {
	Rarity.COMMON: "普通",
	Rarity.RARE: "稀有",
	Rarity.EPIC: "史诗",
	Rarity.LEGENDARY: "传说"
}

const TYPE_NAMES: Dictionary = {
	Type.WEAPON: "武器",
	Type.HELMET: "头盔",
	Type.ARMOR: "护甲",
	Type.BOOTS: "鞋子",
	Type.RING: "戒指"
}

const TYPE_ICONS: Dictionary = {
	Type.WEAPON: "[武]",
	Type.HELMET: "[头]",
	Type.ARMOR: "[甲]",
	Type.BOOTS: "[鞋]",
	Type.RING: "[戒]"
}

var equip_name: String = ""
var type: Type = Type.WEAPON
var rarity: Rarity = Rarity.COMMON
var level: int = 1

## 基础属性加成
var attack_bonus: int = 0
var defense_bonus: int = 0
var max_hp_bonus: int = 0
var attack_speed_bonus: float = 0.0
var crit_rate_bonus: float = 0.0
var gold_bonus_percent: float = 0.0  ## 金币获取百分比加成
var exp_bonus_percent: float = 0.0   ## 经验获取百分比加成

func _init(p_name: String = "", p_type: Type = Type.WEAPON, p_rarity: Rarity = Rarity.COMMON, p_level: int = 1) -> void:
	equip_name = p_name
	type = p_type
	rarity = p_rarity
	level = p_level

func get_display_name() -> String:
	return "%s %s" % [RARITY_NAMES[rarity], equip_name]

func get_type_name() -> String:
	return TYPE_NAMES[type]

func get_rarity_color() -> Color:
	return RARITY_COLORS[rarity]

func get_stat_text() -> String:
	var lines: PackedStringArray = []
	if attack_bonus != 0:
		lines.append("攻击 +%d" % attack_bonus)
	if defense_bonus != 0:
		lines.append("防御 +%d" % defense_bonus)
	if max_hp_bonus != 0:
		lines.append("生命 +%d" % max_hp_bonus)
	if attack_speed_bonus != 0.0:
		lines.append("攻速 +%.2f" % attack_speed_bonus)
	if crit_rate_bonus != 0.0:
		lines.append("暴击 +%.1f%%" % (crit_rate_bonus * 100.0))
	if gold_bonus_percent != 0.0:
		lines.append("金币 +%.0f%%" % gold_bonus_percent)
	if exp_bonus_percent != 0.0:
		lines.append("经验 +%.0f%%" % exp_bonus_percent)
	return "\n".join(lines)

func get_upgrade_cost() -> int:
	return BalanceConfig.UPGRADE_COST_BASE * level

func get_power_score() -> int:
	"""战力评分：将生命、攻击、防御、攻速、暴击按权重汇总。"""
	return int(
		max_hp_bonus * BalanceConfig.POWER_WEIGHT_HP +
		attack_bonus * BalanceConfig.POWER_WEIGHT_ATK +
		defense_bonus * BalanceConfig.POWER_WEIGHT_DEF +
		attack_speed_bonus * BalanceConfig.POWER_WEIGHT_ASPD +
		crit_rate_bonus * BalanceConfig.POWER_WEIGHT_CRIT
	)

func upgrade() -> void:
	level += 1
	## 升级收益随等级成长，避免后期收益过低
	var mult: float = 1.0 + (level - 1) * 0.1
	match type:
		EquipmentData.Type.WEAPON:
			attack_bonus += int(2 * mult)
			attack_speed_bonus += snapped(randf_range(0.01, 0.03), 0.01)
			crit_rate_bonus += snapped(0.005, 0.001)
		EquipmentData.Type.HELMET:
			max_hp_bonus += int(4 * mult)
			defense_bonus += int(1 * mult)
		EquipmentData.Type.ARMOR:
			defense_bonus += int(2 * mult)
			max_hp_bonus += int(2 * mult)
		EquipmentData.Type.BOOTS:
			attack_speed_bonus += snapped(randf_range(0.02, 0.05), 0.01)
			defense_bonus += int(1 * mult)
		EquipmentData.Type.RING:
			if gold_bonus_percent > 0 or exp_bonus_percent > 0:
				gold_bonus_percent += randf_range(1.0, 3.0)
				exp_bonus_percent += randf_range(1.0, 3.0)
			else:
				attack_bonus += int(1 * mult)
				crit_rate_bonus += snapped(0.005, 0.001)

func get_summary_text() -> String:
	return "%s %s Lv.%d\n%s" % [TYPE_ICONS[type], get_display_name(), level, get_stat_text()]
