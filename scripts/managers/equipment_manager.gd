class_name EquipmentManager
extends Node

const EQUIPMENT_NAMES: Dictionary = {
	EquipmentData.Type.WEAPON: ["UI_EQUIPMENT_NAME_WEAPON_0", "UI_EQUIPMENT_NAME_WEAPON_1", "UI_EQUIPMENT_NAME_WEAPON_2", "UI_EQUIPMENT_NAME_WEAPON_3", "UI_EQUIPMENT_NAME_WEAPON_4", "UI_EQUIPMENT_NAME_WEAPON_5", "UI_EQUIPMENT_NAME_WEAPON_6", "UI_EQUIPMENT_NAME_WEAPON_7", "UI_EQUIPMENT_NAME_WEAPON_8"],
	EquipmentData.Type.HELMET: ["UI_EQUIPMENT_NAME_HELMET_0", "UI_EQUIPMENT_NAME_HELMET_1", "UI_EQUIPMENT_NAME_HELMET_2", "UI_EQUIPMENT_NAME_HELMET_3", "UI_EQUIPMENT_NAME_HELMET_4", "UI_EQUIPMENT_NAME_HELMET_5", "UI_EQUIPMENT_NAME_HELMET_6", "UI_EQUIPMENT_NAME_HELMET_7"],
	EquipmentData.Type.ARMOR: ["UI_EQUIPMENT_NAME_ARMOR_0", "UI_EQUIPMENT_NAME_ARMOR_1", "UI_EQUIPMENT_NAME_ARMOR_2", "UI_EQUIPMENT_NAME_ARMOR_3", "UI_EQUIPMENT_NAME_ARMOR_4", "UI_EQUIPMENT_NAME_ARMOR_5", "UI_EQUIPMENT_NAME_ARMOR_6", "UI_EQUIPMENT_NAME_ARMOR_7"],
	EquipmentData.Type.BOOTS: ["UI_EQUIPMENT_NAME_BOOTS_0", "UI_EQUIPMENT_NAME_BOOTS_1", "UI_EQUIPMENT_NAME_BOOTS_2", "UI_EQUIPMENT_NAME_BOOTS_3", "UI_EQUIPMENT_NAME_BOOTS_4", "UI_EQUIPMENT_NAME_BOOTS_5", "UI_EQUIPMENT_NAME_BOOTS_6", "UI_EQUIPMENT_NAME_BOOTS_7"],
	EquipmentData.Type.RING: ["UI_EQUIPMENT_NAME_RING_0", "UI_EQUIPMENT_NAME_RING_1", "UI_EQUIPMENT_NAME_RING_2", "UI_EQUIPMENT_NAME_RING_3", "UI_EQUIPMENT_NAME_RING_4", "UI_EQUIPMENT_NAME_RING_5", "UI_EQUIPMENT_NAME_RING_6", "UI_EQUIPMENT_NAME_RING_7"]
}

const RARITY_DROP_WEIGHTS: Dictionary = {
	EquipmentData.Rarity.COMMON: 60,
	EquipmentData.Rarity.RARE: 25,
	EquipmentData.Rarity.EPIC: 12,
	EquipmentData.Rarity.LEGENDARY: 3
}

## Boss 稀有度加成
const BOSS_RARITY_BONUS: Dictionary = {
	EquipmentData.Rarity.COMMON: -20,
	EquipmentData.Rarity.RARE: 10,
	EquipmentData.Rarity.EPIC: 8,
	EquipmentData.Rarity.LEGENDARY: 2
}

signal equipment_changed
signal equipment_dropped(equipment: EquipmentData)

enum UnequipResult { SUCCESS, INVENTORY_FULL }

## 已装备 {Type: EquipmentData}
var equipped: Dictionary = {}
## 背包
var inventory: Array[EquipmentData] = []
const MAX_INVENTORY: int = 50

func _ready() -> void:
	Services.equipment_manager = self

func get_equipment_bonuses() -> Dictionary:
	var bonuses: Dictionary = {
		"attack": 0,
		"defense": 0,
		"max_hp": 0,
		"attack_speed": 0.0,
		"crit_rate": 0.0,
		"gold_percent": 0.0,
		"exp_percent": 0.0
	}
	for equip: EquipmentData in equipped.values():
		bonuses.attack += equip.attack_bonus
		bonuses.defense += equip.defense_bonus
		bonuses.max_hp += equip.max_hp_bonus
		bonuses.attack_speed += equip.attack_speed_bonus
		bonuses.crit_rate += equip.crit_rate_bonus
		bonuses.gold_percent += equip.gold_bonus_percent
		bonuses.exp_percent += equip.exp_bonus_percent
	return bonuses

func get_equipped(type: EquipmentData.Type) -> EquipmentData:
	return equipped.get(type, null) as EquipmentData

func get_equipped_dict() -> Dictionary:
	return equipped

func equip_item(equip: EquipmentData) -> bool:
	## 如果该部位已有装备，先放回背包
	if equipped.has(equip.type):
		var old: EquipmentData = equipped[equip.type]
		if inventory.size() >= MAX_INVENTORY:
			## 背包已满，无法替换：保留原装备，不装备新装备
			return false
		inventory.append(old)
	
	equipped[equip.type] = equip
	## 从背包移除
	var idx: int = inventory.find(equip)
	if idx >= 0:
		inventory.remove_at(idx)
	equipment_changed.emit()
	return true

func unequip_item(type: EquipmentData.Type) -> UnequipResult:
	if not equipped.has(type):
		return UnequipResult.SUCCESS
	var equip: EquipmentData = equipped[type]
	if inventory.size() >= MAX_INVENTORY:
		return UnequipResult.INVENTORY_FULL
	inventory.append(equip)
	equipped.erase(type)
	equipment_changed.emit()
	return UnequipResult.SUCCESS

func sell_item(equip: EquipmentData) -> Dictionary:
	var idx: int = inventory.find(equip)
	if idx < 0:
		return {"ok": false, "price": 0, "reason": tr("UI_EQUIPMENT_NOT_FOUND")}
	inventory.remove_at(idx)
	var price: int = _calculate_sell_price(equip)
	equipment_changed.emit()
	return {"ok": true, "price": price, "reason": ""}

func auto_equip_best() -> void:
	## 按部位分组并选择评分最高
	var by_type: Dictionary = {}
	for equip: EquipmentData in inventory:
		if not by_type.has(equip.type):
			by_type[equip.type] = []
		by_type[equip.type].append(equip)
	
	for type: int in by_type.keys():
		var best: EquipmentData = null
		var best_score: int = -1
		for equip: EquipmentData in by_type[type]:
			var score: int = _calculate_score(equip)
			if score > best_score:
				best_score = score
				best = equip
		if best != null:
			equip_item(best)

func generate_drop(enemy_level: int, is_boss: bool = false) -> EquipmentData:
	var rarity: int = _roll_rarity(is_boss)
	var type: int = randi() % EquipmentData.Type.size()
	var names: Array = EQUIPMENT_NAMES[type]
	var name_index: int = clampi(rarity, 0, names.size() - 1)
	var equip_name: String = tr(names[name_index])
	
	var equip: EquipmentData = EquipmentData.new(equip_name, type, rarity, enemy_level)
	_generate_stats(equip, enemy_level, is_boss)
	return equip

func add_to_inventory(equip: EquipmentData) -> bool:
	if inventory.size() >= MAX_INVENTORY:
		return false
	inventory.append(equip)
	equipment_changed.emit()
	return true

func load_equipment(p_equipped: Dictionary, p_inventory: Array[EquipmentData]) -> void:
	## 仅用于存档加载，不触发信号，避免加载过程中重复刷新 UI
	equipped.clear()
	for type: int in p_equipped.keys():
		var equip: EquipmentData = p_equipped[type] as EquipmentData
		if equip != null:
			equipped[type] = equip
	inventory.assign(p_inventory)

## 存档序列化：已装备 + 背包。
func serialize() -> Dictionary:
	var equipped_data: Dictionary = {}
	for type: int in equipped.keys():
		equipped_data[str(type)] = _serialize_equipment(equipped[type])
	var inventory_data: Array = []
	for equip: EquipmentData in inventory:
		inventory_data.append(_serialize_equipment(equip))
	return {"equipped": equipped_data, "inventory": inventory_data}

## 存档反序列化：重建装备对象，不触发信号。
func deserialize(data: Dictionary) -> void:
	var loaded_equipped: Dictionary = {}
	for type_str: String in data.get("equipped", {}).keys():
		var equip: EquipmentData = _deserialize_equipment(data["equipped"][type_str])
		if equip != null:
			loaded_equipped[int(type_str)] = equip
	var loaded_inventory: Array[EquipmentData] = []
	for item: Dictionary in data.get("inventory", []):
		var equip: EquipmentData = _deserialize_equipment(item)
		if equip != null:
			loaded_inventory.append(equip)
	load_equipment(loaded_equipped, loaded_inventory)

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
	var type_count: int = EquipmentData.Type.size()
	var rarity_count: int = EquipmentData.Rarity.size()
	var type: int = _clamp_int(data.get("type", EquipmentData.Type.WEAPON), 0, type_count - 1, EquipmentData.Type.WEAPON)
	var rarity: int = _clamp_int(data.get("rarity", EquipmentData.Rarity.COMMON), 0, rarity_count - 1, EquipmentData.Rarity.COMMON)
	var level: int = maxi(1, _clamp_int(data.get("level", 1), 0, 999999, 1))

	var equip: EquipmentData = EquipmentData.new(
		data.get("name", ""),
		type,
		rarity,
		level
	)
	equip.attack_bonus = maxi(0, _clamp_int(data.get("attack", 0), -999999, 999999, 0))
	equip.defense_bonus = maxi(0, _clamp_int(data.get("defense", 0), -999999, 999999, 0))
	equip.max_hp_bonus = maxi(0, _clamp_int(data.get("max_hp", 0), -999999, 999999, 0))
	equip.attack_speed_bonus = maxf(0.0, float(data.get("attack_speed", 0.0)))
	equip.crit_rate_bonus = maxf(0.0, float(data.get("crit_rate", 0.0)))
	equip.gold_bonus_percent = maxf(0.0, float(data.get("gold_percent", 0.0)))
	equip.exp_bonus_percent = maxf(0.0, float(data.get("exp_percent", 0.0)))
	return equip

func _clamp_int(value: Variant, min_value: int, max_value: int, default: int) -> int:
	if value == null or typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return default
	return clampi(int(value), min_value, max_value)

func has_drop_chance(is_boss: bool) -> bool:
	var base_chance: float = BalanceConfig.BOSS_DROP_CHANCE if is_boss else BalanceConfig.NORMAL_DROP_CHANCE
	return randf() < base_chance

func _roll_rarity(is_boss: bool) -> int:
	var weights: Dictionary = RARITY_DROP_WEIGHTS.duplicate()
	if is_boss:
		for r: int in BOSS_RARITY_BONUS.keys():
			weights[r] = max(1, weights[r] + BOSS_RARITY_BONUS[r])
	
	var total: int = 0
	for w: int in weights.values():
		total += w
	
	var roll: int = randi() % total
	var cumulative: int = 0
	for r: int in weights.keys():
		cumulative += weights[r]
		if roll < cumulative:
			return r
	return EquipmentData.Rarity.COMMON

func _generate_stats(equip: EquipmentData, enemy_level: int, is_boss: bool) -> void:
	var rarity_mult: float = BalanceConfig.EQUIPMENT_RARITY_MULT_BASE + equip.rarity * BalanceConfig.EQUIPMENT_RARITY_MULT_STEP
	var level_mult: float = 1.0 + (enemy_level - 1) * BalanceConfig.EQUIPMENT_LEVEL_MULT
	var boss_mult: float = BalanceConfig.EQUIPMENT_BOSS_MULT if is_boss else 1.0
	var mult: float = rarity_mult * level_mult * boss_mult
	
	## 根据装备类型生成主属性
	match equip.type:
		EquipmentData.Type.WEAPON:
			equip.attack_bonus = int(BalanceConfig.EQUIPMENT_WEAPON_ATK_BASE * mult)
			equip.attack_speed_bonus = snapped(randf_range(0.0, BalanceConfig.EQUIPMENT_WEAPON_ASPD_MAX * mult), 0.01)
			equip.crit_rate_bonus = snapped(randf_range(0.0, BalanceConfig.EQUIPMENT_WEAPON_CRIT_MAX * mult), 0.001)
		EquipmentData.Type.HELMET:
			equip.max_hp_bonus = int(BalanceConfig.EQUIPMENT_HELMET_HP_BASE * mult)
			equip.defense_bonus = int(BalanceConfig.EQUIPMENT_HELMET_DEF_BASE * mult)
		EquipmentData.Type.ARMOR:
			equip.defense_bonus = int(BalanceConfig.EQUIPMENT_ARMOR_DEF_BASE * mult)
			equip.max_hp_bonus = int(BalanceConfig.EQUIPMENT_ARMOR_HP_BASE * mult)
		EquipmentData.Type.BOOTS:
			equip.attack_speed_bonus = snapped(randf_range(BalanceConfig.EQUIPMENT_BOOTS_ASPD_MIN, BalanceConfig.EQUIPMENT_BOOTS_ASPD_MAX * mult), 0.01)
			equip.defense_bonus = int(BalanceConfig.EQUIPMENT_BOOTS_DEF_BASE * mult)
		EquipmentData.Type.RING:
			## 戒指随机为金币/经验加成或攻击/暴击加成
			if randf() < BalanceConfig.EQUIPMENT_RING_BRANCH_CHANCE:
				equip.gold_bonus_percent = randf_range(BalanceConfig.EQUIPMENT_RING_GOLD_MIN, BalanceConfig.EQUIPMENT_RING_GOLD_MAX * mult)
				equip.exp_bonus_percent = randf_range(BalanceConfig.EQUIPMENT_RING_EXP_MIN, BalanceConfig.EQUIPMENT_RING_EXP_MAX * mult)
			else:
				equip.attack_bonus = int(BalanceConfig.EQUIPMENT_RING_ATK_BASE * mult)
				equip.crit_rate_bonus = snapped(randf_range(BalanceConfig.EQUIPMENT_RING_CRIT_MIN, BalanceConfig.EQUIPMENT_RING_CRIT_MAX * mult), 0.001)
	
	## 稀有度越高，额外随机属性越多
	if equip.rarity >= EquipmentData.Rarity.RARE:
		_add_random_bonus(equip, mult)
	if equip.rarity >= EquipmentData.Rarity.EPIC:
		_add_random_bonus(equip, mult)
	if equip.rarity >= EquipmentData.Rarity.LEGENDARY:
		_add_random_bonus(equip, mult)
		_add_random_bonus(equip, mult)

func _add_random_bonus(equip: EquipmentData, mult: float) -> void:
	var bonus_type: int = randi() % 7
	match bonus_type:
		0:
			equip.attack_bonus += int(BalanceConfig.EQUIPMENT_RANDOM_BONUS_ATK * mult)
		1:
			equip.defense_bonus += int(BalanceConfig.EQUIPMENT_RANDOM_BONUS_DEF * mult)
		2:
			equip.max_hp_bonus += int(BalanceConfig.EQUIPMENT_RANDOM_BONUS_HP * mult)
		3:
			equip.attack_speed_bonus += snapped(randf_range(BalanceConfig.EQUIPMENT_RANDOM_BONUS_ASPD_MIN, BalanceConfig.EQUIPMENT_RANDOM_BONUS_ASPD_MAX * mult), 0.01)
		4:
			equip.crit_rate_bonus += snapped(randf_range(BalanceConfig.EQUIPMENT_RANDOM_BONUS_CRIT_MIN, BalanceConfig.EQUIPMENT_RANDOM_BONUS_CRIT_MAX * mult), 0.001)
		5:
			equip.gold_bonus_percent += randf_range(BalanceConfig.EQUIPMENT_RANDOM_BONUS_GOLD_MIN, BalanceConfig.EQUIPMENT_RANDOM_BONUS_GOLD_MAX * mult)
		6:
			equip.exp_bonus_percent += randf_range(BalanceConfig.EQUIPMENT_RANDOM_BONUS_EXP_MIN, BalanceConfig.EQUIPMENT_RANDOM_BONUS_EXP_MAX * mult)

func _calculate_score(equip: EquipmentData) -> int:
	var score: int = 0
	score += equip.attack_bonus * BalanceConfig.EQUIPMENT_SCORE_WEIGHT_ATK
	score += equip.defense_bonus * BalanceConfig.EQUIPMENT_SCORE_WEIGHT_DEF
	score += equip.max_hp_bonus * BalanceConfig.EQUIPMENT_SCORE_WEIGHT_HP
	score += int(equip.attack_speed_bonus * BalanceConfig.EQUIPMENT_SCORE_WEIGHT_ASPD)
	score += int(equip.crit_rate_bonus * BalanceConfig.EQUIPMENT_SCORE_WEIGHT_CRIT)
	score += int(equip.gold_bonus_percent * BalanceConfig.EQUIPMENT_SCORE_WEIGHT_GOLD)
	score += int(equip.exp_bonus_percent * BalanceConfig.EQUIPMENT_SCORE_WEIGHT_EXP)
	score += equip.rarity * BalanceConfig.EQUIPMENT_SCORE_RARITY
	return score

func _calculate_sell_price(equip: EquipmentData) -> int:
	var base: int = BalanceConfig.EQUIPMENT_SELL_BASE + equip.level * BalanceConfig.EQUIPMENT_SELL_LEVEL
	var rarity_mult: float = 1.0 + equip.rarity * BalanceConfig.EQUIPMENT_SELL_RARITY_MULT
	return int(base * rarity_mult)
