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
	
	## Boss 每 6 秒恢复 8% 最大生命
	heal_timer += delta
	if heal_timer >= 6.0:
		heal_timer = 0.0
		var heal_amount: int = int(enemy.max_hp * 0.08)
		enemy.heal(heal_amount)
		EventBus.boss_healed.emit(heal_amount)
	
	## Boss 狂暴：每 12 秒触发一次，持续 4 秒，攻速翻倍
	if is_berserk:
		berserk_timer -= delta
		if berserk_timer <= 0.0:
			is_berserk = false
			enemy.attack_speed = base_attack_speed
			EventBus.boss_berserk.emit(false)
	else:
		berserk_cooldown += delta
		if berserk_cooldown >= 12.0:
			berserk_cooldown = 0.0
			is_berserk = true
			berserk_timer = 4.0
			enemy.attack_speed = base_attack_speed * 2.0
			EventBus.boss_berserk.emit(true)
