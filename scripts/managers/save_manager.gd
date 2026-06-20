class_name SaveManager
extends Node

const SAVE_PATH: String = "user://savegame.json"
const CURRENT_VERSION: int = BalanceConfig.SAVE_VERSION

signal save_completed
signal load_completed

var _last_save_time: int = 0

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func get_last_save_time() -> int:
	return _last_save_time

func save_game(player_data: PlayerData, equipment_manager: EquipmentManager, current_stage: int, achievement_manager: Node = null, quest_manager: Node = null, game_manager: GameManager = null) -> bool:
	if player_data == null or equipment_manager == null:
		return false

	var ach_data: Dictionary = {}
	if achievement_manager != null and achievement_manager.has_method("serialize"):
		ach_data = achievement_manager.serialize()

	var quest_data: Dictionary = {}
	if quest_manager != null and quest_manager.has_method("serialize"):
		quest_data = quest_manager.serialize()

	var skill_manager: SkillManager = null
	var shop_manager: ShopManager = null
	if game_manager != null:
		skill_manager = game_manager.skill_manager
		shop_manager = game_manager.shop_manager

	var skill_data: Dictionary = {
		"energy": skill_manager.energy if skill_manager else 0,
		"cooldowns": skill_manager.cooldowns.duplicate() if skill_manager else {},
		"berserk_timer": skill_manager.berserk_timer if skill_manager else 0.0,
		"berserk_multiplier": skill_manager.berserk_multiplier if skill_manager else 1.0
	}

	var shop_data: Dictionary = {
		"exp_potion_charges": shop_manager.exp_potion_charges if shop_manager else 0
	}

	var data: Dictionary = {
		"version": CURRENT_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"achievements": ach_data,
		"quests": quest_data,
		"player": {
			"level": player_data.level,
			"exp": player_data.exp,
			"gold": player_data.gold,
			"hp": player_data.hp,
			"bonus_attack": player_data.bonus_attack,
			"bonus_defense": player_data.bonus_defense,
			"total_kills": player_data.total_kills,
			"total_gold_earned": player_data.total_gold_earned,
			"total_damage_dealt": player_data.total_damage_dealt,
			"total_damage_taken": player_data.total_damage_taken,
			"death_count": player_data.death_count,
			"bosses_defeated": player_data.bosses_defeated,
			"highest_stage": player_data.highest_stage,
			"play_time_seconds": player_data.play_time_seconds
		},
		"stage": current_stage,
		"equipped": _serialize_equipment_dict(equipment_manager.equipped),
		"inventory": _serialize_equipment_array(equipment_manager.inventory),
		"skill": skill_data,
		"shop": shop_data
	}

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("无法打开存档文件，错误码：%d" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data))
	file.close()
	save_completed.emit()
	return true

func load_game(player_data: PlayerData, equipment_manager: EquipmentManager, game_manager: GameManager, achievement_manager: Node = null, quest_manager: Node = null) -> bool:
	if not has_save():
		return false

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var err: int = json.parse(json_text)
	if err != OK:
		push_error("存档 JSON 解析失败")
		return false

	var data: Dictionary = json.data
	if not data.has("version"):
		return false
	if data.get("version", 0) > CURRENT_VERSION:
		push_error("存档版本 %d 高于当前支持版本 %d，无法加载" % [data.get("version", 0), CURRENT_VERSION])
		return false

	_last_save_time = data.get("timestamp", 0)

	## 读取玩家数据
	var p: Dictionary = data.get("player", {})
	player_data.level = p.get("level", 1)
	player_data.exp = p.get("exp", 0)
	player_data.gold = p.get("gold", 0)
	player_data.hp = p.get("hp", player_data.max_hp)
	player_data.bonus_attack = p.get("bonus_attack", 0)
	player_data.bonus_defense = p.get("bonus_defense", 0)
	player_data.total_kills = p.get("total_kills", 0)
	player_data.total_gold_earned = p.get("total_gold_earned", 0)
	player_data.total_damage_dealt = p.get("total_damage_dealt", 0)
	player_data.total_damage_taken = p.get("total_damage_taken", 0)
	player_data.death_count = p.get("death_count", 0)
	player_data.bosses_defeated = p.get("bosses_defeated", 0)
	player_data.highest_stage = p.get("highest_stage", 1)
	player_data.play_time_seconds = p.get("play_time_seconds", 0.0)

	## 恢复关卡进度
	if game_manager != null and game_manager.stage_manager != null:
		game_manager.stage_manager.current_enemy_level = data.get("stage", 1)

	## 清空当前装备数据
	equipment_manager.equipped.clear()
	equipment_manager.inventory.clear()

	var equipped_data: Dictionary = data.get("equipped", {})
	for type_str: String in equipped_data.keys():
		var type: int = int(type_str)
		var equip: EquipmentData = _deserialize_equipment(equipped_data[type_str])
		if equip != null:
			equipment_manager.equipped[type] = equip

	var inventory_data: Array = data.get("inventory", [])
	for item: Dictionary in inventory_data:
		var equip: EquipmentData = _deserialize_equipment(item)
		if equip != null:
			equipment_manager.inventory.append(equip)

	## 读取技能状态（v3 新增，旧存档兼容）
	if game_manager != null and game_manager.skill_manager != null:
		var skill_data: Dictionary = data.get("skill", {})
		var sm: SkillManager = game_manager.skill_manager
		sm.energy = skill_data.get("energy", 0)
		sm.berserk_timer = skill_data.get("berserk_timer", 0.0)
		sm.berserk_multiplier = skill_data.get("berserk_multiplier", 1.0)
		var raw_cooldowns: Dictionary = skill_data.get("cooldowns", {})
		sm.cooldowns.clear()
		for type_str: String in raw_cooldowns.keys():
			sm.cooldowns[int(type_str)] = float(raw_cooldowns[type_str])

	## 读取商店状态（v3 新增，旧存档兼容）
	if game_manager != null and game_manager.shop_manager != null:
		var shop_data: Dictionary = data.get("shop", {})
		game_manager.shop_manager.exp_potion_charges = shop_data.get("exp_potion_charges", 0)

	## 读取成就数据
	if achievement_manager != null and achievement_manager.has_method("deserialize"):
		var ach_data: Dictionary = data.get("achievements", {})
		achievement_manager.deserialize(ach_data)

	## 读取任务数据（旧存档可能没有）
	if quest_manager != null and quest_manager.has_method("deserialize"):
		var q_data: Dictionary = data.get("quests", {})
		quest_manager.deserialize(q_data)

	player_data.recalc_stats()
	equipment_manager.equipment_changed.emit()
	load_completed.emit()
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

func _serialize_equipment_dict(dict: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for type: int in dict.keys():
		var equip: EquipmentData = dict[type]
		result[str(type)] = _serialize_equipment(equip)
	return result

func _serialize_equipment_array(arr: Array[EquipmentData]) -> Array:
	var result: Array = []
	for equip: EquipmentData in arr:
		result.append(_serialize_equipment(equip))
	return result

func _serialize_equipment(equip: EquipmentData) -> Dictionary:
	return {
		"name": equip.equip_name,
		"type": equip.type,
		"rarity": equip.rarity,
		"level": equip.level,
		"attack": equip.attack_bonus,
		"defense": equip.defense_bonus,
		"max_hp": equip.max_hp_bonus,
		"attack_speed": equip.attack_speed_bonus,
		"crit_rate": equip.crit_rate_bonus,
		"gold_percent": equip.gold_bonus_percent,
		"exp_percent": equip.exp_bonus_percent
	}

func _deserialize_equipment(data: Dictionary) -> EquipmentData:
	var equip: EquipmentData = EquipmentData.new(
		data.get("name", ""),
		data.get("type", EquipmentData.Type.WEAPON),
		data.get("rarity", EquipmentData.Rarity.COMMON),
		data.get("level", 1)
	)
	equip.attack_bonus = data.get("attack", 0)
	equip.defense_bonus = data.get("defense", 0)
	equip.max_hp_bonus = data.get("max_hp", 0)
	equip.attack_speed_bonus = data.get("attack_speed", 0.0)
	equip.crit_rate_bonus = data.get("crit_rate", 0.0)
	equip.gold_bonus_percent = data.get("gold_percent", 0.0)
	equip.exp_bonus_percent = data.get("exp_percent", 0.0)
	return equip
