class_name SaveManager
extends Node

## 存档编排器：仅负责组装 JSON、原子写入与版本迁移。
## 各管理器内部状态由其自身的 serialize()/deserialize() 负责，本类不再触碰任何
## 管理器的私有字段。

const SAVE_PATH: String = "user://savegame.json"
const TEMP_PATH: String = "user://savegame.json.tmp"
const BACKUP_PATH: String = "user://savegame.json.bak"
const CURRENT_VERSION: int = BalanceConfig.SAVE_VERSION

signal save_completed
signal load_completed

var _last_save_time: int = 0

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func get_last_save_time() -> int:
	return _last_save_time

func save_game(player_data: PlayerData, equipment_manager: EquipmentManager, stage_manager: StageManager, achievement_manager: AchievementManager = null, quest_manager: Node = null, skill_manager: SkillManager = null, shop_manager: ShopManager = null) -> bool:
	if player_data == null or equipment_manager == null:
		return false

	var data: Dictionary = {
		"version": CURRENT_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"player": player_data.serialize(),
		"stage": stage_manager.serialize() if stage_manager != null else {"level": 1},
		"equipment": equipment_manager.serialize(),
		"skill": skill_manager.serialize() if skill_manager != null else {},
		"shop": shop_manager.serialize() if shop_manager != null else {},
		"achievements": achievement_manager.serialize() if achievement_manager != null and achievement_manager.has_method("serialize") else {},
		"quests": quest_manager.serialize() if quest_manager != null and quest_manager.has_method("serialize") else {}
	}

	## 原子写入：先写临时文件，再重命名为正式存档；成功后保留一份备份
	var file: FileAccess = FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("无法打开存档临时文件，错误码：%d" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data))
	file.close()

	if FileAccess.file_exists(SAVE_PATH):
		var dir_bak: DirAccess = DirAccess.open("user://")
		if dir_bak != null:
			dir_bak.copy(SAVE_PATH, BACKUP_PATH)

	var dir: DirAccess = DirAccess.open("user://")
	if dir == null or dir.rename(TEMP_PATH, SAVE_PATH) != OK:
		push_error("存档重命名失败")
		return false

	save_completed.emit()
	return true

func load_game(player_data: PlayerData, equipment_manager: EquipmentManager, stage_manager: StageManager = null, achievement_manager: AchievementManager = null, quest_manager: Node = null, skill_manager: SkillManager = null, shop_manager: ShopManager = null) -> bool:
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
		push_error("存档缺少版本字段")
		return false
	var save_version: int = data.get("version", 0)
	if save_version > CURRENT_VERSION:
		push_error("存档版本 %d 高于当前支持版本 %d，无法加载" % [save_version, CURRENT_VERSION])
		return false

	## 版本迁移
	data = _migrate_data(data, save_version)

	_last_save_time = data.get("timestamp", 0)

	## 各管理器自行反序列化
	player_data.deserialize(data.get("player", {}))
	if stage_manager != null:
		stage_manager.deserialize(data.get("stage", {}))
	equipment_manager.deserialize(data.get("equipment", {}))
	if skill_manager != null:
		skill_manager.deserialize(data.get("skill", {}))
	if shop_manager != null:
		shop_manager.deserialize(data.get("shop", {}))
	if achievement_manager != null and achievement_manager.has_method("deserialize"):
		achievement_manager.deserialize(data.get("achievements", {}))
	if quest_manager != null and quest_manager.has_method("deserialize"):
		quest_manager.deserialize(data.get("quests", {}))

	## 装备加载完成后触发一次重算，同步玩家属性与 UI
	equipment_manager.equipment_changed.emit()
	load_completed.emit()
	return true

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

func _migrate_data(data: Dictionary, from_version: int) -> Dictionary:
	## 按版本链式迁移，未来新增版本在这里追加。
	while from_version < CURRENT_VERSION:
		from_version += 1
		match from_version:
			4:
				## v3 → v4：equipped/inventory 从顶层合并到 "equipment" 下；
				## stage 由裸 int 包装为 {"level": int}，交给 StageManager.deserialize。
				var equipped: Dictionary = data.get("equipped", {})
				var inventory: Array = data.get("inventory", [])
				data["equipment"] = {"equipped": equipped, "inventory": inventory}
				data.erase("equipped")
				data.erase("inventory")
				data["stage"] = {"level": int(data.get("stage", 1))}
			_:
				pass
	data["version"] = CURRENT_VERSION
	return data
