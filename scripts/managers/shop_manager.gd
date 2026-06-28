class_name ShopManager
extends Node

signal item_purchased(item_id: String, price: int)
signal purchase_failed(reason: String)

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

const ITEMS: Dictionary = {
	"health_potion": {
		"name": "UI_SHOP_ITEM_NAME_HEALTH_POTION",
		"desc": "UI_SHOP_ITEM_DESC_HEALTH_POTION",
		"price": 50,
		"icon": "res://assets/images/equipment_helmet.png"
	},
	"attack_boost": {
		"name": "UI_SHOP_ITEM_NAME_ATTACK_BOOST",
		"desc": "UI_SHOP_ITEM_DESC_ATTACK_BOOST",
		"price": 200,
		"icon": "res://assets/images/equipment_weapon.png"
	},
	"defense_boost": {
		"name": "UI_SHOP_ITEM_NAME_DEFENSE_BOOST",
		"desc": "UI_SHOP_ITEM_DESC_DEFENSE_BOOST",
		"price": 200,
		"icon": "res://assets/images/equipment_armor.png"
	},
	"exp_potion": {
		"name": "UI_SHOP_ITEM_NAME_EXP_POTION",
		"desc": "UI_SHOP_ITEM_DESC_EXP_POTION",
		"price": 150,
		"icon": "res://assets/images/equipment_ring.png"
	},
	"equipment_box": {
		"name": "UI_SHOP_ITEM_NAME_EQUIPMENT_BOX",
		"desc": "UI_SHOP_ITEM_DESC_EQUIPMENT_BOX",
		"price": 300,
		"icon": "res://assets/images/equipment_boots.png"
	}
}

var exp_potion_charges: int = 0

func _ready() -> void:
	Services.shop_manager = self

func get_item(id: String) -> Dictionary:
	var item: Dictionary = ITEMS.get(id, {})
	if item.is_empty():
		return {}
	return {
		"name": tr(item.name),
		"desc": tr(item.desc),
		"price": item.price,
		"icon": item.icon
	}

func can_afford(id: String) -> bool:
	var item: Dictionary = ITEMS.get(id, {})
	if item.is_empty() or player_data == null:
		return false
	return player_data.gold >= item.price

func purchase(id: String) -> bool:
	if not can_afford(id):
		purchase_failed.emit(tr("UI_SHOP_NOT_ENOUGH_GOLD"))
		return false
	
	var item: Dictionary = ITEMS.get(id, {})
	var price: int = item.price
	
	## 第一阶段：校验所有前置条件，避免扣款后才发现无法生效
	match id:
		"health_potion":
			if player_data.hp >= player_data.max_hp:
				purchase_failed.emit(tr("UI_SHOP_HP_FULL"))
				return false
		"attack_boost":
			if player_data.bonus_attack >= BalanceConfig.MAX_BONUS_ATTACK:
				purchase_failed.emit(tr("UI_SHOP_ATTACK_MAX"))
				return false
		"defense_boost":
			if player_data.bonus_defense >= BalanceConfig.MAX_BONUS_DEFENSE:
				purchase_failed.emit(tr("UI_SHOP_DEFENSE_MAX"))
				return false
		"exp_potion":
			if exp_potion_charges >= BalanceConfig.MAX_EXP_POTION_CHARGES:
				purchase_failed.emit(tr("UI_SHOP_EXP_POTION_MAX"))
				return false
		"equipment_box":
			if equipment_manager == null or stage_manager == null:
				purchase_failed.emit(tr("UI_SHOP_SYSTEM_NOT_READY"))
				return false
		_:
			purchase_failed.emit(tr("UI_SHOP_UNKNOWN_ITEM"))
			return false
	
	## 第二阶段：扣款。校验已通过，此处不应失败；若失败则保持状态一致
	if not player_data.spend_gold(price):
		purchase_failed.emit(tr("UI_SHOP_NOT_ENOUGH_GOLD"))
		return false
	
	## 第三阶段：发放效果
	match id:
		"health_potion":
			var heal: int = int(player_data.max_hp * 0.5)
			player_data.heal(heal)
			EventBus.message_logged.emit(tr("UI_SHOP_HEAL_LOG") % heal)
		"attack_boost":
			player_data.bonus_attack += 2
			player_data.recalc_stats()
			EventBus.message_logged.emit(tr("UI_SHOP_ATTACK_BOOST_LOG"))
		"defense_boost":
			player_data.bonus_defense += 2
			player_data.recalc_stats()
			EventBus.message_logged.emit(tr("UI_SHOP_DEFENSE_BOOST_LOG"))
		"exp_potion":
			exp_potion_charges = min(BalanceConfig.MAX_EXP_POTION_CHARGES, exp_potion_charges + BalanceConfig.EXP_POTION_BUY_AMOUNT)
			EventBus.message_logged.emit(tr("UI_SHOP_EXP_POTION_LOG") % [exp_potion_charges, (BalanceConfig.EXP_POTION_MULTIPLIER - 1.0) * 100.0])
		"equipment_box":
			var equip: EquipmentData = equipment_manager.generate_drop(stage_manager.current_enemy_level, false)
			if equipment_manager.add_to_inventory(equip):
				EventBus.equipment_dropped.emit(equip)
				EventBus.message_logged.emit(tr("UI_SHOP_EQUIPMENT_DROP_LOG") % equip.get_display_name())
			else:
				## 背包已满时退款，避免玩家花钱却拿不到东西
				player_data.add_gold(price)
				purchase_failed.emit(tr("UI_SHOP_INVENTORY_FULL"))
				return false
	
	item_purchased.emit(id, price)
	return true

func apply_exp_bonus(exp: int) -> int:
	if exp_potion_charges > 0:
		exp_potion_charges -= 1
		return int(exp * BalanceConfig.EXP_POTION_MULTIPLIER)
	return exp

func serialize() -> Dictionary:
	return {"exp_potion_charges": exp_potion_charges}

func deserialize(data: Dictionary) -> void:
	exp_potion_charges = clampi(int(data.get("exp_potion_charges", 0)), 0, BalanceConfig.MAX_EXP_POTION_CHARGES)
