class_name EquipmentManager
extends Node

const EQUIPMENT_NAMES: Dictionary = {
	EquipmentData.Type.WEAPON: ["短剑", "长剑", "精钢剑", "烈焰之刃", "屠龙刀", "圣光剑", "暗影匕首", "雷霆战斧", "传说神器"],
	EquipmentData.Type.HELMET: ["皮帽", "铁盔", "钢盔", "魔法帽", "龙鳞盔", "圣骑士头盔", "暗影面甲", "王者之冠"],
	EquipmentData.Type.ARMOR: ["皮甲", "铁甲", "钢甲", "魔法长袍", "龙鳞甲", "圣骑士铠甲", "暗影护甲", "王者战甲"],
	EquipmentData.Type.BOOTS: ["布鞋", "皮靴", "铁靴", "风行之靴", "龙鳞靴", "圣骑士战靴", "暗影短靴", "王者长靴"],
	EquipmentData.Type.RING: ["铜戒", "银戒", "金戒", "红宝石戒指", "蓝宝石戒指", "圣光指环", "暗影之戒", "王者戒指"]
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

## 已装备 {Type: EquipmentData}
var equipped: Dictionary = {}
## 背包
var inventory: Array[EquipmentData] = []
const MAX_INVENTORY: int = 50

func _ready() -> void:
	add_to_group("equipment_manager")

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

func equip_item(equip: EquipmentData) -> void:
	## 如果该部位已有装备，先放回背包
	if equipped.has(equip.type):
		var old: EquipmentData = equipped[equip.type]
		inventory.append(old)
	
	equipped[equip.type] = equip
	## 从背包移除
	var idx: int = inventory.find(equip)
	if idx >= 0:
		inventory.remove_at(idx)
	equipment_changed.emit()

func unequip_item(type: EquipmentData.Type) -> void:
	if not equipped.has(type):
		return
	var equip: EquipmentData = equipped[type]
	if inventory.size() < MAX_INVENTORY:
		inventory.append(equip)
	equipped.erase(type)
	equipment_changed.emit()

func sell_item(equip: EquipmentData) -> int:
	var idx: int = inventory.find(equip)
	if idx < 0:
		return 0
	inventory.remove_at(idx)
	var price: int = _calculate_sell_price(equip)
	equipment_changed.emit()
	return price

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
	var equip_name: String = names[name_index]
	
	var equip: EquipmentData = EquipmentData.new(equip_name, type, rarity, enemy_level)
	_generate_stats(equip, enemy_level, is_boss)
	return equip

func add_to_inventory(equip: EquipmentData) -> bool:
	if inventory.size() >= MAX_INVENTORY:
		return false
	inventory.append(equip)
	equipment_changed.emit()
	return true

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
	var rarity_mult: float = 1.0 + equip.rarity * 0.5
	var level_mult: float = 1.0 + (enemy_level - 1) * 0.12
	var boss_mult: float = 1.5 if is_boss else 1.0
	var mult: float = rarity_mult * level_mult * boss_mult
	
	## 根据装备类型生成主属性
	match equip.type:
		EquipmentData.Type.WEAPON:
			equip.attack_bonus = int(3 * mult)
			equip.attack_speed_bonus = snapped(randf_range(0.0, 0.15 * mult), 0.01)
			equip.crit_rate_bonus = snapped(randf_range(0.0, 0.03 * mult), 0.001)
		EquipmentData.Type.HELMET:
			equip.max_hp_bonus = int(8 * mult)
			equip.defense_bonus = int(1 * mult)
		EquipmentData.Type.ARMOR:
			equip.defense_bonus = int(3 * mult)
			equip.max_hp_bonus = int(5 * mult)
		EquipmentData.Type.BOOTS:
			equip.attack_speed_bonus = snapped(randf_range(0.05, 0.25 * mult), 0.01)
			equip.defense_bonus = int(1 * mult)
		EquipmentData.Type.RING:
			## 戒指随机为金币/经验加成或攻击/暴击加成
			if randf() < 0.5:
				equip.gold_bonus_percent = randf_range(2.0, 8.0 * mult)
				equip.exp_bonus_percent = randf_range(2.0, 8.0 * mult)
			else:
				equip.attack_bonus = int(2 * mult)
				equip.crit_rate_bonus = snapped(randf_range(0.01, 0.05 * mult), 0.001)
	
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
			equip.attack_bonus += int(2 * mult)
		1:
			equip.defense_bonus += int(1 * mult)
		2:
			equip.max_hp_bonus += int(4 * mult)
		3:
			equip.attack_speed_bonus += snapped(randf_range(0.02, 0.1 * mult), 0.01)
		4:
			equip.crit_rate_bonus += snapped(randf_range(0.01, 0.03 * mult), 0.001)
		5:
			equip.gold_bonus_percent += randf_range(1.0, 5.0 * mult)
		6:
			equip.exp_bonus_percent += randf_range(1.0, 5.0 * mult)

func _calculate_score(equip: EquipmentData) -> int:
	var score: int = 0
	score += equip.attack_bonus * 4
	score += equip.defense_bonus * 4
	score += equip.max_hp_bonus * 1
	score += int(equip.attack_speed_bonus * 50)
	score += int(equip.crit_rate_bonus * 200)
	score += int(equip.gold_bonus_percent * 3)
	score += int(equip.exp_bonus_percent * 3)
	score += equip.rarity * 20
	return score

func _calculate_sell_price(equip: EquipmentData) -> int:
	var base: int = 10 + equip.level * 2
	var rarity_mult: float = 1.0 + equip.rarity * 0.8
	return int(base * rarity_mult)
