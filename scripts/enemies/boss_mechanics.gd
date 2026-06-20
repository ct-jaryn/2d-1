class_name BossMechanics
extends RefCounted

var enemy: EnemyData
var base_attack_speed: float = 0.8

var heal_timer: float = 0.0
var berserk_timer: float = 0.0
var berserk_cooldown: float = 0.0
var is_berserk: bool = false

func _init(p_enemy: EnemyData) -> void:
	enemy = p_enemy
	base_attack_speed = enemy.attack_speed

func update(delta: float) -> void:
	if enemy == null or not enemy.is_alive():
		return
	
	## Boss 周期性恢复生命
	heal_timer += delta
	if heal_timer >= BalanceConfig.BOSS_HEAL_INTERVAL:
		heal_timer = 0.0
		var heal_amount: int = int(enemy.max_hp * BalanceConfig.BOSS_HEAL_PERCENT)
		enemy.heal(heal_amount)
		EventBus.boss_healed.emit(heal_amount)
	
	## Boss 周期性狂暴
	if is_berserk:
		berserk_timer -= delta
		if berserk_timer <= 0.0:
			is_berserk = false
			enemy.attack_speed = base_attack_speed
			EventBus.boss_berserk.emit(false)
	else:
		berserk_cooldown += delta
		if berserk_cooldown >= BalanceConfig.BOSS_BERSERK_COOLDOWN:
			berserk_cooldown = 0.0
			is_berserk = true
			berserk_timer = BalanceConfig.BOSS_BERSERK_DURATION
			enemy.attack_speed = base_attack_speed * BalanceConfig.BOSS_BERSERK_ATK_SPEED_MULTIPLIER
			EventBus.boss_berserk.emit(true)
