class_name AchievementManager
extends Node

const AchievementDataGD = preload("res://scripts/data/achievement_data.gd")

signal achievement_unlocked(achievement: AchievementDataGD)

const ACHIEVEMENTS: Array[Dictionary] = [
	{"id": "first_blood", "name": "首杀", "desc": "击败第一个敌人", "type": AchievementDataGD.Type.KILLS, "target": 1, "reward_gold": 50, "reward_attack": 0, "reward_defense": 0},
	{"id": "seasoned", "name": "身经百战", "desc": "累计击败 50 个敌人", "type": AchievementDataGD.Type.KILLS, "target": 50, "reward_gold": 300, "reward_attack": 2, "reward_defense": 0},
	{"id": "slayer", "name": "杀戮机器", "desc": "累计击败 200 个敌人", "type": AchievementDataGD.Type.KILLS, "target": 200, "reward_gold": 1000, "reward_attack": 5, "reward_defense": 2},
	{"id": "novice", "name": "初出茅庐", "desc": "角色达到 Lv.10", "type": AchievementDataGD.Type.LEVEL, "target": 10, "reward_gold": 200, "reward_attack": 1, "reward_defense": 1},
	{"id": "veteran", "name": "资深勇者", "desc": "角色达到 Lv.30", "type": AchievementDataGD.Type.LEVEL, "target": 30, "reward_gold": 800, "reward_attack": 3, "reward_defense": 3},
	{"id": "legend", "name": "传说勇者", "desc": "角色达到 Lv.60", "type": AchievementDataGD.Type.LEVEL, "target": 60, "reward_gold": 3000, "reward_attack": 10, "reward_defense": 5},
	{"id": "wealthy", "name": "小有积蓄", "desc": "累计获得 1000 金币", "type": AchievementDataGD.Type.GOLD, "target": 1000, "reward_gold": 200, "reward_attack": 0, "reward_defense": 0},
	{"id": "rich", "name": "富甲一方", "desc": "累计获得 10000 金币", "type": AchievementDataGD.Type.GOLD, "target": 10000, "reward_gold": 1000, "reward_attack": 2, "reward_defense": 2},
	{"id": "boss_hunter", "name": "Boss 猎手", "desc": "累计击败 5 个 Boss", "type": AchievementDataGD.Type.BOSSES, "target": 5, "reward_gold": 1000, "reward_attack": 3, "reward_defense": 0},
	{"id": "boss_slayer", "name": "Boss 克星", "desc": "累计击败 20 个 Boss", "type": AchievementDataGD.Type.BOSSES, "target": 20, "reward_gold": 5000, "reward_attack": 8, "reward_defense": 5},
	{"id": "deep_diver", "name": "深渊行者", "desc": "到达第 20 关", "type": AchievementDataGD.Type.STAGE, "target": 20, "reward_gold": 1500, "reward_attack": 4, "reward_defense": 2},
	{"id": "immortal", "name": "不朽传说", "desc": "到达第 50 关", "type": AchievementDataGD.Type.STAGE, "target": 50, "reward_gold": 8000, "reward_attack": 15, "reward_defense": 10}
]

var achievements: Array[AchievementDataGD] = []
var completed_ids: Array[String] = []

var _player_data: PlayerData
var player_data: PlayerData:
	get:
		if _player_data == null:
			_player_data = Services.player_data
		return _player_data
	set(v):
		_player_data = v

func _ready() -> void:
	Services.achievement_manager = self
	_init_achievements()

	## 敌人击杀由 BattleManager 直发，直接监听。
	if Services.battle_manager:
		Services.battle_manager.enemy_died.connect(_on_enemy_defeated)
	EventBus.stage_changed.connect(_on_stage_changed)
	if player_data:
		player_data.leveled_up.connect(_on_level_up)
		player_data.stats_changed.connect(_on_stats_changed)

func _init_achievements() -> void:
	achievements.clear()
	for data: Dictionary in ACHIEVEMENTS:
		var ach: AchievementDataGD = AchievementDataGD.new(data.id, data.name, data.desc, data.type, data.target)
		ach.reward_gold = data.reward_gold
		ach.reward_attack = data.reward_attack
		ach.reward_defense = data.reward_defense
		ach.completed = completed_ids.has(ach.id)
		achievements.append(ach)

func check_achievements(type: int, value: int) -> void:
	for ach: AchievementDataGD in achievements:
		if ach.completed:
			continue
		if ach.type != type:
			continue
		if value >= ach.target:
			_unlock_achievement(ach)

func _unlock_achievement(ach: AchievementDataGD) -> void:
	ach.completed = true
	completed_ids.append(ach.id)
	_apply_reward(ach)
	achievement_unlocked.emit(ach)
	EventBus.achievement_unlocked.emit(ach)
	EventBus.message_logged.emit("成就解锁：%s！%s" % [ach.name, ach.get_reward_text()])

func _apply_reward(ach: AchievementDataGD) -> void:
	if player_data == null:
		return
	player_data.bonus_attack += ach.reward_attack
	player_data.bonus_defense += ach.reward_defense
	player_data.recalc_stats(false)
	player_data.add_gold(ach.reward_gold)

func _on_enemy_defeated(enemy: EnemyData) -> void:
	check_achievements(AchievementDataGD.Type.KILLS, player_data.total_kills if player_data else 0)
	if enemy.is_boss:
		check_achievements(AchievementDataGD.Type.BOSSES, player_data.bosses_defeated if player_data else 0)

func _on_level_up(_level: int) -> void:
	check_achievements(AchievementDataGD.Type.LEVEL, player_data.level if player_data else 1)

func _on_stage_changed(stage: int) -> void:
	check_achievements(AchievementDataGD.Type.STAGE, stage)

func _on_stats_changed() -> void:
	check_achievements(AchievementDataGD.Type.GOLD, player_data.total_gold_earned if player_data else 0)

func get_completed_count() -> int:
	var count: int = 0
	for ach: AchievementDataGD in achievements:
		if ach.completed:
			count += 1
	return count

func get_total_count() -> int:
	return achievements.size()

func serialize() -> Dictionary:
	return {"completed": completed_ids.duplicate()}

func deserialize(data: Dictionary) -> void:
	var raw: Array = data.get("completed", [])
	completed_ids.assign(raw)
	_init_achievements()
