class_name PlayerData
extends Resource

## 等级与经验
var level: int = 1
var exp: int = 0
var exp_to_next: int = 100

## 基础属性
var base_max_hp: int = 100
var base_attack: int = 10
var base_defense: int = 5
var base_attack_speed: float = BalanceConfig.BASE_ATTACK_SPEED  ## 每秒攻击次数
var base_crit_rate: float = 0.05
var crit_damage: float = 1.5

## 最终属性（基础 + 装备加成）
var max_hp: int = 100
var hp: int = 100
var attack: int = 10
var defense: int = 5
var attack_speed: float = 1.0
var crit_rate: float = 0.05

## 装备加成
var equip_max_hp_bonus: int = 0
var equip_attack_bonus: int = 0
var equip_defense_bonus: int = 0
var equip_attack_speed_bonus: float = 0.0
var equip_crit_rate_bonus: float = 0.0
var equip_gold_percent: float = 0.0
var equip_exp_percent: float = 0.0

var bonus_attack: int = 0
var bonus_defense: int = 0

## 运行时攻速倍率（由 SkillManager 注入，避免 PlayerData 反向引用 GameManager）
var attack_speed_multiplier: float = 1.0

var gold: int = 0
var total_kills: int = 0

## 统计
var total_gold_earned: int = 0
var total_damage_dealt: int = 0
var total_damage_taken: int = 0
var death_count: int = 0
var bosses_defeated: int = 0
var highest_stage: int = 1
var play_time_seconds: float = 0.0


signal leveled_up(new_level: int)
signal stats_changed
signal gold_changed(amount: int)

func _init() -> void:
	recalc_stats()

func recalc_stats(emit_signal: bool = true) -> void:
	base_max_hp = 100 + (level - 1) * BalanceConfig.HP_GROWTH
	base_attack = 10 + (level - 1) * BalanceConfig.ATK_GROWTH
	base_defense = 5 + (level - 1) * BalanceConfig.DEF_GROWTH
	exp_to_next = int(BalanceConfig.EXP_BASE * pow(BalanceConfig.EXP_GROWTH_RATE, level - 1))
	_apply_equipment_bonuses(emit_signal)

func _apply_equipment_bonuses(emit_signal: bool = true) -> void:
	max_hp = base_max_hp + equip_max_hp_bonus
	attack = base_attack + equip_attack_bonus + bonus_attack
	defense = base_defense + equip_defense_bonus + bonus_defense
	attack_speed = clamp((base_attack_speed + equip_attack_speed_bonus) * attack_speed_multiplier, 0.1, BalanceConfig.MAX_ATTACK_SPEED)
	crit_rate = clamp(base_crit_rate + equip_crit_rate_bonus, 0.0, 1.0)
	hp = min(hp, max_hp)
	if emit_signal:
		stats_changed.emit()

func set_equipment_bonuses(bonuses: Dictionary) -> void:
	equip_attack_bonus = bonuses.get("attack", 0)
	equip_defense_bonus = bonuses.get("defense", 0)
	equip_max_hp_bonus = bonuses.get("max_hp", 0)
	equip_attack_speed_bonus = bonuses.get("attack_speed", 0.0)
	equip_crit_rate_bonus = bonuses.get("crit_rate", 0.0)
	equip_gold_percent = bonuses.get("gold_percent", 0.0)
	equip_exp_percent = bonuses.get("exp_percent", 0.0)
	recalc_stats()

func gain_exp(amount: int) -> void:
	if level >= BalanceConfig.MAX_LEVEL:
		return
	exp += amount
	while exp >= exp_to_next and level < BalanceConfig.MAX_LEVEL:
		exp -= exp_to_next
		level_up()
	if level >= BalanceConfig.MAX_LEVEL:
		exp = 0
	stats_changed.emit()

func level_up() -> void:
	level += 1
	recalc_stats()
	leveled_up.emit(level)

func take_damage(damage: int) -> int:
	var actual: int = max(1, damage - defense)
	hp = max(0, hp - actual)
	stats_changed.emit()
	return actual

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)
	stats_changed.emit()

func is_alive() -> bool:
	return hp > 0

func get_attack_damage() -> Dictionary:
	var is_crit: bool = randf() < crit_rate
	var dmg: int = attack
	if is_crit:
		dmg = int(dmg * crit_damage)
	return {"damage": max(1, dmg), "is_crit": is_crit}

func add_gold(amount: int) -> void:
	gold += amount
	if amount > 0:
		total_gold_earned += amount
	gold_changed.emit(amount)
	stats_changed.emit()

func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(-amount)
	stats_changed.emit()
	return true

## 存档序列化：仅持久化字段，不触发改动信号。
func serialize() -> Dictionary:
	return {
		"level": level,
		"exp": exp,
		"gold": gold,
		"hp": hp,
		"bonus_attack": bonus_attack,
		"bonus_defense": bonus_defense,
		"total_kills": total_kills,
		"total_gold_earned": total_gold_earned,
		"total_damage_dealt": total_damage_dealt,
		"total_damage_taken": total_damage_taken,
		"death_count": death_count,
		"bosses_defeated": bosses_defeated,
		"highest_stage": highest_stage,
		"play_time_seconds": play_time_seconds
	}

## 存档反序列化：直接写字段，最后统一 recalc，避免加载过程中触发统计/任务信号。
func deserialize(data: Dictionary) -> void:
	level = int(data.get("level", 1))
	exp = int(data.get("exp", 0))
	gold = int(data.get("gold", 0))
	bonus_attack = int(data.get("bonus_attack", 0))
	bonus_defense = int(data.get("bonus_defense", 0))
	total_kills = int(data.get("total_kills", 0))
	total_gold_earned = int(data.get("total_gold_earned", 0))
	total_damage_dealt = int(data.get("total_damage_dealt", 0))
	total_damage_taken = int(data.get("total_damage_taken", 0))
	death_count = int(data.get("death_count", 0))
	bosses_defeated = int(data.get("bosses_defeated", 0))
	highest_stage = int(data.get("highest_stage", 1))
	play_time_seconds = float(data.get("play_time_seconds", 0.0))
	recalc_stats(false)
	hp = clampi(int(data.get("hp", max_hp)), 1, max_hp)
