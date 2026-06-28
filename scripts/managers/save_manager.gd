class_name SaveManager
extends RefCounted

## 存档编排器：仅负责组装 JSON、原子写入与版本迁移。
## 各管理器内部状态由其自身的 serialize()/deserialize() 负责，本类不再触碰任何
## 管理器的私有字段。

const SAVE_PATH: String = "user://savegame.json"
const TEMP_PATH: String = "user://savegame.json.tmp"
const BACKUP_PATHS: PackedStringArray = [
	"user://savegame.json.bak",
	"user://savegame.json.bak1",
	"user://savegame.json.bak2"
]
const MAX_BACKUP_COUNT: int = 3
const CURRENT_VERSION: int = BalanceConfig.SAVE_VERSION

## 存档加密：防止普通文本篡改，密钥/IV 固定即可满足单机反 casual 修改需求
const ENCRYPTION_MARKER: String = "ENC:"
const ENCRYPTION_KEY_PHRASE: String = "PixelIdleHeroSaveKey"
const ENCRYPTION_IV_PHRASE: String = "PixelIdleHeroSaveIV"

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
	data["checksum"] = _compute_checksum(data)

	## 原子写入：先写临时文件，再重命名为正式存档；成功后保留一份备份
	var json_text: String = JSON.stringify(data)
	var encrypted: String = ENCRYPTION_MARKER + _encrypt(json_text)

	var file: FileAccess = FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("无法打开存档临时文件，错误码：%d" % FileAccess.get_open_error())
		return false
	file.store_string(encrypted)
	file.close()

	if FileAccess.file_exists(SAVE_PATH):
		var dir_bak: DirAccess = DirAccess.open("user://")
		if dir_bak != null:
			_rotate_backups()
			dir_bak.copy(SAVE_PATH, BACKUP_PATHS[0])

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
	var file_content: String = file.get_as_text()
	file.close()

	## 兼容旧版本未加密存档：带 ENCRYPTION_MARKER 则解密，否则按明文 JSON 处理
	var json_text: String
	if file_content.begins_with(ENCRYPTION_MARKER):
		json_text = _decrypt(file_content.substr(ENCRYPTION_MARKER.length()))
		if json_text.is_empty():
			push_error("存档解密失败")
			return false
	else:
		json_text = file_content

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

	## 校验和检查：可检测存档损坏或简单篡改
	var stored_checksum: String = data.get("checksum", "")
	if stored_checksum != "" and stored_checksum != _compute_checksum(data):
		push_warning("存档校验和不匹配，可能已损坏或被修改")

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

func _rotate_backups() -> void:
	## 保留最近 MAX_BACKUP_COUNT 份备份：bak2 <- bak1 <- bak <- 当前存档
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	for i: int in range(MAX_BACKUP_COUNT - 1, 0, -1):
		var older: String = BACKUP_PATHS[i]
		if FileAccess.file_exists(older):
			DirAccess.remove_absolute(older)
		var newer: String = BACKUP_PATHS[i - 1]
		if FileAccess.file_exists(newer):
			dir.rename(newer, older)

func _compute_checksum(data: Dictionary) -> String:
	var data_without_checksum: Dictionary = data.duplicate()
	data_without_checksum.erase("checksum")
	return JSON.stringify(data_without_checksum).sha256_text()

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

func _encrypt(plain_text: String) -> String:
	var data: PackedByteArray = _pkcs7_pad(plain_text.to_utf8_buffer())
	var aes: AESContext = AESContext.new()
	aes.start(AESContext.MODE_CBC_ENCRYPT, _get_key(), _get_iv())
	var encrypted: PackedByteArray = aes.update(data)
	return Marshalls.raw_to_base64(encrypted)

func _decrypt(cipher_text: String) -> String:
	var data: PackedByteArray = Marshalls.base64_to_raw(cipher_text)
	if data.is_empty():
		return ""
	var aes: AESContext = AESContext.new()
	aes.start(AESContext.MODE_CBC_DECRYPT, _get_key(), _get_iv())
	var decrypted: PackedByteArray = aes.update(data)
	return _pkcs7_unpad(decrypted).get_string_from_utf8()

func _get_key() -> PackedByteArray:
	return _hex_to_bytes(ENCRYPTION_KEY_PHRASE.sha256_text())

func _get_iv() -> PackedByteArray:
	## IV 取密钥派生串的前 32 个十六进制字符，即 16 字节
	return _hex_to_bytes(ENCRYPTION_IV_PHRASE.sha256_text().substr(0, 32))

func _hex_to_bytes(hex: String) -> PackedByteArray:
	var bytes: PackedByteArray = PackedByteArray()
	for i: int in range(0, hex.length(), 2):
		bytes.append(hex.substr(i, 2).hex_to_int())
	return bytes

func _pkcs7_pad(data: PackedByteArray) -> PackedByteArray:
	var block_size: int = 16
	var pad_len: int = block_size - (data.size() % block_size)
	var padded: PackedByteArray = data.duplicate()
	for i: int in range(pad_len):
		padded.append(pad_len)
	return padded

func _pkcs7_unpad(data: PackedByteArray) -> PackedByteArray:
	if data.is_empty():
		return data
	var pad_len: int = data[data.size() - 1]
	if pad_len < 1 or pad_len > 16:
		return data
	return data.slice(0, data.size() - pad_len)
