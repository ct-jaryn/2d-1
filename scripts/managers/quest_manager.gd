class_name QuestManager
extends Node


const DAILY_QUEST_COUNT: int = 4
const REFRESH_COST: int = 100

var quests: Array[QuestData] = []
var last_refresh_day: int = -1
var free_refresh_used: bool = false

var _player_data: PlayerData
var player_data: PlayerData:
	get:
		if _player_data == null:
			_player_data = Services.player_data
		return _player_data
	set(v):
		_player_data = v

var _equipment_manager: EquipmentManager
var equipment_manager: EquipmentManager:
	get:
		if _equipment_manager == null:
			_equipment_manager = Services.equipment_manager
		return _equipment_manager
	set(v):
		_equipment_manager = v

var _stage_manager: StageManager
var stage_manager: StageManager:
	get:
		if _stage_manager == null:
			_stage_manager = Services.stage_manager
		return _stage_manager
	set(v):
		_stage_manager = v

func _ready() -> void:
	Services.quest_manager = self
	_connect_events()
	_ensure_daily_refresh()

func _connect_events() -> void:
	## 敌人击杀、技能施放由各自管理器直发，直接监听；升级/金币走 EventBus。
	if Services.battle_manager:
		Services.battle_manager.enemy_died.connect(_on_enemy_defeated)
	if Services.skill_manager:
		Services.skill_manager.skill_casted.connect(_on_skill_casted)
	EventBus.player_leveled_up.connect(_on_player_leveled_up)
	EventBus.gold_changed.connect(_on_gold_changed)

func _ensure_daily_refresh() -> void:
	var today: int = _get_today_index()
	if today != last_refresh_day:
		_generate_daily_quests(today)

func _get_today_index() -> int:
	var unix: int = Time.get_unix_time_from_system()
	return unix / 86400

func _generate_daily_quests(today: int) -> void:
	quests.clear()
	last_refresh_day = today
	free_refresh_used = false
	
	var templates: Array[Dictionary] = _get_quest_templates()
	templates.shuffle()
	
	for i: int in range(min(DAILY_QUEST_COUNT, templates.size())):
		var template: Dictionary = templates[i]
		var quest: QuestData = QuestData.new(template.id, template.type, template.title, template.description, template.target)
		quest.reward_gold = template.reward_gold
		quest.reward_exp = template.reward_exp
		quest.reward_equipment = template.reward_equipment
		quests.append(quest)
	
	EventBus.daily_quests_refreshed.emit()
	EventBus.message_logged.emit(tr("UI_QUEST_REFRESHED"))

func _get_quest_templates() -> Array[Dictionary]:
	return [
		{"id": "daily_kills_10", "type": QuestData.Type.KILL_ENEMIES, "title": "UI_QUEST_DAILY_KILLS_10_TITLE", "description": "UI_QUEST_DAILY_KILLS_10_DESC", "target": 10, "reward_gold": 100, "reward_exp": 50, "reward_equipment": false},
		{"id": "daily_kills_30", "type": QuestData.Type.KILL_ENEMIES, "title": "UI_QUEST_DAILY_KILLS_30_TITLE", "description": "UI_QUEST_DAILY_KILLS_30_DESC", "target": 30, "reward_gold": 300, "reward_exp": 150, "reward_equipment": false},
		{"id": "daily_boss_1", "type": QuestData.Type.DEFEAT_BOSSES, "title": "UI_QUEST_DAILY_BOSS_1_TITLE", "description": "UI_QUEST_DAILY_BOSS_1_DESC", "target": 1, "reward_gold": 500, "reward_exp": 300, "reward_equipment": true},
		{"id": "daily_boss_3", "type": QuestData.Type.DEFEAT_BOSSES, "title": "UI_QUEST_DAILY_BOSS_3_TITLE", "description": "UI_QUEST_DAILY_BOSS_3_DESC", "target": 3, "reward_gold": 1500, "reward_exp": 1000, "reward_equipment": true},
		{"id": "daily_gold_500", "type": QuestData.Type.EARN_GOLD, "title": "UI_QUEST_DAILY_GOLD_500_TITLE", "description": "UI_QUEST_DAILY_GOLD_500_DESC", "target": 500, "reward_gold": 200, "reward_exp": 100, "reward_equipment": false},
		{"id": "daily_gold_2000", "type": QuestData.Type.EARN_GOLD, "title": "UI_QUEST_DAILY_GOLD_2000_TITLE", "description": "UI_QUEST_DAILY_GOLD_2000_DESC", "target": 2000, "reward_gold": 800, "reward_exp": 400, "reward_equipment": false},
		{"id": "daily_level_2", "type": QuestData.Type.LEVEL_UP, "title": "UI_QUEST_DAILY_LEVEL_2_TITLE", "description": "UI_QUEST_DAILY_LEVEL_2_DESC", "target": 2, "reward_gold": 400, "reward_exp": 200, "reward_equipment": true},
		{"id": "daily_skills_10", "type": QuestData.Type.CAST_SKILLS, "title": "UI_QUEST_DAILY_SKILLS_10_TITLE", "description": "UI_QUEST_DAILY_SKILLS_10_DESC", "target": 10, "reward_gold": 300, "reward_exp": 150, "reward_equipment": false},
	]

func try_manual_refresh() -> bool:
	if player_data == null:
		return false
	
	if not free_refresh_used:
		free_refresh_used = true
		_generate_daily_quests(_get_today_index())
		EventBus.message_logged.emit(tr("UI_QUEST_REFRESH_FREE_DONE"))
		return true
	
	if not player_data.spend_gold(REFRESH_COST):
		EventBus.message_logged.emit(tr("UI_QUEST_REFRESH_NO_GOLD") % REFRESH_COST)
		return false
	
	_generate_daily_quests(_get_today_index())
	EventBus.message_logged.emit(tr("UI_QUEST_REFRESH_SPENT") % REFRESH_COST)
	return true

func claim_reward(quest: QuestData) -> bool:
	if not quest.completed or quest.claimed:
		return false
	
	quest.claimed = true
	
	if player_data != null:
		if quest.reward_gold > 0:
			player_data.add_gold(quest.reward_gold)
		if quest.reward_exp > 0:
			player_data.gain_exp(quest.reward_exp)
	
	if quest.reward_equipment and equipment_manager != null and stage_manager != null:
		var equip: EquipmentData = equipment_manager.generate_drop(stage_manager.current_enemy_level, false)
		if equipment_manager.add_to_inventory(equip):
			EventBus.equipment_dropped.emit(equip)
			EventBus.message_logged.emit(tr("UI_QUEST_REWARD_EQUIP_LOG") % equip.get_display_name())
		else:
			EventBus.message_logged.emit(tr("UI_QUEST_BAG_FULL_LOST"))
	
	EventBus.message_logged.emit(tr("UI_QUEST_REWARD_CLAIMED_LOG") % quest.get_reward_text())
	EventBus.quest_updated.emit(quest)
	return true

func _on_enemy_defeated(enemy: EnemyData) -> void:
	_update_quest_progress(QuestData.Type.KILL_ENEMIES, 1)
	if enemy.is_boss:
		_update_quest_progress(QuestData.Type.DEFEAT_BOSSES, 1)

func _on_player_leveled_up(_level: int) -> void:
	_update_quest_progress(QuestData.Type.LEVEL_UP, 1)

func _on_gold_changed(amount: int) -> void:
	if amount > 0:
		_update_quest_progress(QuestData.Type.EARN_GOLD, amount)

func _on_skill_casted(_skill: SkillData) -> void:
	_update_quest_progress(QuestData.Type.CAST_SKILLS, 1)

func _update_quest_progress(type: int, amount: int) -> void:
	var changed: bool = false
	for quest: QuestData in quests:
		if quest.type != type or quest.completed:
			continue
		if quest.add_progress(amount):
			EventBus.quest_completed.emit(quest)
			EventBus.message_logged.emit(tr("UI_QUEST_COMPLETED_LOG") % tr(quest.title))
		changed = true
		EventBus.quest_updated.emit(quest)
	
	if changed:
		EventBus.play_sfx.emit("coin")

func get_completed_count() -> int:
	var count: int = 0
	for quest: QuestData in quests:
		if quest.completed:
			count += 1
	return count

func get_total_count() -> int:
	return quests.size()

func serialize() -> Dictionary:
	var quest_data: Array = []
	for quest: QuestData in quests:
		quest_data.append(quest.serialize())
	return {
		"last_refresh_day": last_refresh_day,
		"free_refresh_used": free_refresh_used,
		"quests": quest_data
	}

func deserialize(data: Dictionary) -> void:
	last_refresh_day = data.get("last_refresh_day", -1)
	free_refresh_used = data.get("free_refresh_used", false)
	quests.clear()
	
	var today: int = _get_today_index()
	if today != last_refresh_day:
		_ensure_daily_refresh()
		return
	
	for q: Dictionary in data.get("quests", []):
		var quest: QuestData = QuestData.new(q.get("id", ""), q.get("type", 0), q.get("title", ""), q.get("description", ""), q.get("target", 1))
		quest.deserialize(q)
		quests.append(quest)
	
	EventBus.daily_quests_refreshed.emit()
