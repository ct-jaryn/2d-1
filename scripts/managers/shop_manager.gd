class_name ShopManager
extends Node

signal item_purchased(item_id: String, price: int)
signal purchase_failed(reason: String)

@export var game_manager: GameManager

const ITEMS: Dictionary = {
	"health_potion": {
		"name": "生命药水",
		"desc": "立即恢复 50% 最大生命值",
		"price": 50,
		"icon": "res://assets/images/equipment_helmet.png"
	},
	"attack_boost": {
		"name": "攻击卷轴",
		"desc": "永久提升基础攻击 +2",
		"price": 200,
		"icon": "res://assets/images/equipment_weapon.png"
	},
	"defense_boost": {
		"name": "防御卷轴",
		"desc": "永久提升基础防御 +2",
		"price": 200,
		"icon": "res://assets/images/equipment_armor.png"
	},
	"exp_potion": {
		"name": "经验药水",
		"desc": "接下来 5 场战斗经验 +50%",
		"price": 150,
		"icon": "res://assets/images/equipment_ring.png"
	},
	"equipment_box": {
		"name": "装备宝箱",
		"desc": "随机获得一件装备",
		"price": 300,
		"icon": "res://assets/images/equipment_boots.png"
	}
}

var exp_potion_charges: int = 0

func _ready() -> void:
	add_to_group("shop_manager")

func get_item(id: String) -> Dictionary:
	return ITEMS.get(id, {})

func can_afford(id: String) -> bool:
	var item: Dictionary = ITEMS.get(id, {})
	if item.is_empty() or game_manager == null or game_manager.player_data == null:
		return false
	return game_manager.player_data.gold >= item.price

func purchase(id: String) -> bool:
	if not can_afford(id):
		purchase_failed.emit("金币不足")
		return false
	
	var item: Dictionary = ITEMS.get(id, {})
	var price: int = item.price
	
	match id:
		"health_potion":
			if game_manager.player_data.hp >= game_manager.player_data.max_hp:
				purchase_failed.emit("生命值已满")
				return false
			var heal: int = int(game_manager.player_data.max_hp * 0.5)
			game_manager.player_data.heal(heal)
			EventBus.message_logged.emit("生命药水恢复 %d 点生命" % heal)
		"attack_boost":
			if game_manager.player_data.bonus_attack >= BalanceConfig.MAX_BONUS_ATTACK:
				purchase_failed.emit("攻击卷轴已达购买上限")
				return false
			game_manager.player_data.bonus_attack += 2
			game_manager.player_data.recalc_stats()
			EventBus.message_logged.emit("攻击卷轴：攻击 +2")
		"defense_boost":
			if game_manager.player_data.bonus_defense >= BalanceConfig.MAX_BONUS_DEFENSE:
				purchase_failed.emit("防御卷轴已达购买上限")
				return false
			game_manager.player_data.bonus_defense += 2
			game_manager.player_data.recalc_stats()
			EventBus.message_logged.emit("防御卷轴：防御 +2")
		"exp_potion":
			if exp_potion_charges >= BalanceConfig.MAX_EXP_POTION_CHARGES:
				purchase_failed.emit("经验药水层数已达上限")
				return false
			exp_potion_charges = min(BalanceConfig.MAX_EXP_POTION_CHARGES, exp_potion_charges + BalanceConfig.EXP_POTION_BUY_AMOUNT)
			EventBus.message_logged.emit("经验药水生效：剩余 %d 场战斗经验 +%.0f%%" % [exp_potion_charges, (BalanceConfig.EXP_POTION_MULTIPLIER - 1.0) * 100.0])
		"equipment_box":
			if game_manager.equipment_manager == null or game_manager.stage_manager == null:
				purchase_failed.emit("装备系统未初始化")
				return false
			var equip: EquipmentData = game_manager.equipment_manager.generate_drop(game_manager.stage_manager.current_enemy_level, false)
			if game_manager.equipment_manager.add_to_inventory(equip):
				EventBus.message_logged.emit("获得装备：%s" % equip.get_display_name())
				EventBus.equipment_dropped.emit(equip)
			else:
				purchase_failed.emit("背包已满")
				return false
		_:
			purchase_failed.emit("未知商品")
			return false
	
	game_manager.player_data.gold -= price
	game_manager.player_data.stats_changed.emit()
	item_purchased.emit(id, price)
	return true

func apply_exp_bonus(exp: int) -> int:
	if exp_potion_charges > 0:
		exp_potion_charges -= 1
		return int(exp * BalanceConfig.EXP_POTION_MULTIPLIER)
	return exp
