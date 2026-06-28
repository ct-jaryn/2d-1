class_name AchievementManager
extends Node


signal achievement_unlocked(achievement: AchievementData)

const ACHIEVEMENTS: Array[Dictionary] = [
	{"id": "first_blood", "name": "UI_ACHIEVEMENT_FIRST_BLOOD_NAME", "desc": "UI_ACHIEVEMENT_FIRST_BLOOD_DESC", "type": AchievementData.Type.KILLS, "target": 1, "reward_gold": 50, "reward_attack": 0, "reward_defense": 0},
	{"id": "seasoned", "name": "UI_ACHIEVEMENT_SEASONED_NAME", "desc": "UI_ACHIEVEMENT_SEASONED_DESC", "type": AchievementData.Type.KILLS, "target": 50, "reward_gold": 300, "reward_attack": 2, "reward_defense": 0},
	{"id": "slayer", "name": "UI_ACHIEVEMENT_SLAYER_NAME", "desc": "UI_ACHIEVEMENT_SLAYER_DESC", "type": AchievementData.Type.KILLS, "target": 200, "reward_gold": 1000, "reward_attack": 5, "reward_defense": 2},
	{"id": "novice", "name": "UI_ACHIEVEMENT_NOVICE_NAME", "desc": "UI_ACHIEVEMENT_NOVICE_DESC", "type": AchievementData.Type.LEVEL, "target": 10, "reward_gold": 200, "reward_attack": 1, "reward_defense": 1},
	{"id": "veteran", "name": "UI_ACHIEVEMENT_VETERAN_NAME", "desc": "UI_ACHIEVEMENT_VETERAN_DESC", "type": AchievementData.Type.LEVEL, "target": 30, "reward_gold": 800, "reward_attack": 3, "reward_defense": 3},
	{"id": "legend", "name": "UI_ACHIEVEMENT_LEGEND_NAME", "desc": "UI_ACHIEVEMENT_LEGEND_DESC", "type": AchievementData.Type.LEVEL, "target": 60, "reward_gold": 3000, "reward_attack": 10, "reward_defense": 5},
	{"id": "wealthy", "name": "UI_ACHIEVEMENT_WEALTHY_NAME", "desc": "UI_ACHIEVEMENT_WEALTHY_DESC", "type": AchievementData.Type.GOLD, "target": 1000, "reward_gold": 200, "reward_attack": 0, "reward_defense": 0},
	{"id": "rich", "name": "UI_ACHIEVEMENT_RICH_NAME", "desc": "UI_ACHIEVEMENT_RICH_DESC", "type": AchievementData.Type.GOLD, "target": 10000, "reward_gold": 1000, "reward_attack": 2, "reward_defense": 2},
	{"id": "boss_hunter", "name": "UI_ACHIEVEMENT_BOSS_HUNTER_NAME", "desc": "UI_ACHIEVEMENT_BOSS_HUNTER_DESC", "type": AchievementData.Type.BOSSES, "target": 5, "reward_gold": 1000, "reward_attack": 3, "reward_defense": 0},
	{"id": "boss_slayer", "name": "UI_ACHIEVEMENT_BOSS_SLAYER_NAME", "desc": "UI_ACHIEVEMENT_BOSS_SLAYER_DESC", "type": AchievementData.Type.BOSSES, "target": 20, "reward_gold": 5000, "reward_attack": 8, "reward_defense": 5},
	{"id": "deep_diver", "name": "UI_ACHIEVEMENT_DEEP_DIVER_NAME", "desc": "UI_ACHIEVEMENT_DEEP_DIVER_DESC", "type": AchievementData.Type.STAGE, "target": 20, "reward_gold": 1500, "reward_attack": 4, "reward_defense": 2},
	{"id": "immortal", "name": "UI_ACHIEVEMENT_IMMORTAL_NAME", "desc": "UI_ACHIEVEMENT_IMMORTAL_DESC", "type": AchievementData.Type.STAGE, "target": 50, "reward_gold": 8000, "reward_attack": 15, "reward_defense": 10}
]

var achievements: Array[AchievementData] = []
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
		var ach: AchievementData = AchievementData.new(data.id, data.name, data.desc, data.type, data.target)
		ach.reward_gold = data.reward_gold
		ach.reward_attack = data.reward_attack
		ach.reward_defense = data.reward_defense
		ach.completed = completed_ids.has(ach.id)
		achievements.append(ach)

func check_achievements(type: int, value: int) -> void:
	for ach: AchievementData in achievements:
		if ach.completed:
			continue
		if ach.type != type:
			continue
		if value >= ach.target:
			_unlock_achievement(ach)

func _unlock_achievement(ach: AchievementData) -> void:
	ach.completed = true
	completed_ids.append(ach.id)
	_apply_reward(ach)
	achievement_unlocked.emit(ach)
	EventBus.achievement_unlocked.emit(ach)
	EventBus.message_logged.emit(tr("UI_ACHIEVEMENT_UNLOCKED_LOG_FORMAT") % [tr(ach.name), ach.get_reward_text()])

func _apply_reward(ach: AchievementData) -> void:
	if player_data == null:
		return
	player_data.bonus_attack += ach.reward_attack
	player_data.bonus_defense += ach.reward_defense
	player_data.recalc_stats(false)
	player_data.add_gold(ach.reward_gold)

func _on_enemy_defeated(enemy: EnemyData) -> void:
	check_achievements(AchievementData.Type.KILLS, player_data.total_kills if player_data else 0)
	if enemy.is_boss:
		check_achievements(AchievementData.Type.BOSSES, player_data.bosses_defeated if player_data else 0)

func _on_level_up(_level: int) -> void:
	check_achievements(AchievementData.Type.LEVEL, player_data.level if player_data else 1)

func _on_stage_changed(stage: int) -> void:
	check_achievements(AchievementData.Type.STAGE, stage)

func _on_stats_changed() -> void:
	check_achievements(AchievementData.Type.GOLD, player_data.total_gold_earned if player_data else 0)

func get_completed_count() -> int:
	var count: int = 0
	for ach: AchievementData in achievements:
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
