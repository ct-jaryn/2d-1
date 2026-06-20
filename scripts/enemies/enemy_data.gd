class_name EnemyData
extends Resource

## 敌人基础属性
var name: String = "Slime"
var level: int = 1
var max_hp: int = 50
var hp: int = 50
var attack: int = 5
var defense: int = 2
var attack_speed: float = 0.8
var exp_reward: int = 20
var gold_reward: int = 10
var is_boss: bool = false

## 外观
var color: Color = Color.GREEN_YELLOW
var size_scale: float = 1.0

func _init(p_name: String, p_level: int, p_is_boss: bool = false) -> void:
	name = p_name
	level = p_level
	is_boss = p_is_boss
	generate_stats()

func generate_stats() -> void:
	var level_multiplier: float = 1.0 + (level - 1) * BalanceConfig.ENEMY_ATK_MULTIPLIER
	var boss_multiplier: float = BalanceConfig.BOSS_HP_MULTIPLIER if is_boss else 1.0

	max_hp = int(50 * level_multiplier * boss_multiplier)
	hp = max_hp
	attack = int((5 + level * 0.8) * level_multiplier * (BalanceConfig.BOSS_ATK_MULTIPLIER if is_boss else 1.0))
	defense = int((2 + level * 0.3) * level_multiplier * (1.5 if is_boss else 1.0))
	attack_speed = min(2.0, 0.8 * (1.0 + level * 0.03))

	exp_reward = int(20 * level_multiplier * boss_multiplier * (2.0 if is_boss else 1.0))
	gold_reward = int(10 * level_multiplier * boss_multiplier * (2.5 if is_boss else 1.0))

	if is_boss:
		color = Color.CRIMSON
		size_scale = BalanceConfig.ENEMY_SIZE_SCALE_MAX
	else:
		## 普通怪随等级变色
		var hue: float = fmod(level * 0.08, 1.0)
		color = Color.from_hsv(hue, 0.7, 0.9)
		size_scale = clamp(BalanceConfig.ENEMY_SIZE_SCALE_MIN + (level - 1) * 0.02, BalanceConfig.ENEMY_SIZE_SCALE_MIN, BalanceConfig.ENEMY_SIZE_SCALE_MAX)

func take_damage(damage: int) -> int:
	var actual: int = max(1, damage - defense)
	hp = max(0, hp - actual)
	return actual

func is_alive() -> bool:
	return hp > 0

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)

func get_attack_damage() -> Dictionary:
	var is_crit: bool = is_boss and randf() < BalanceConfig.BOSS_CRIT_CHANCE
	var damage: int = attack
	if is_crit:
		damage = int(damage * BalanceConfig.BOSS_CRIT_DAMAGE)
	return {"damage": damage, "is_crit": is_crit}

func get_reward_text() -> String:
	return "EXP +%d  Gold +%d" % [exp_reward, gold_reward]
