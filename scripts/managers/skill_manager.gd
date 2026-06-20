class_name SkillManager
extends Node

signal skill_casted(skill: SkillData)
signal energy_changed(current: int, maximum: int)
signal cooldown_updated(skill_type: int, remaining: float)

@export var player_data: PlayerData
@export var battle_manager: BattleManager

var skills: Array[SkillData] = []
var cooldowns: Dictionary = {}  ## {SkillData.Type: remaining_time}
var energy: int = 0
var max_energy: int = BalanceConfig.MAX_ENERGY
var _energy_regen_accumulator: float = 0.0

## 狂暴技能计时
var berserk_timer: float = 0.0
var berserk_multiplier: float = 1.0

func _ready() -> void:
	add_to_group("skill_manager")
	_init_default_skills()
	EventBus.energy_gained.connect(add_energy)

func _init_default_skills() -> void:
	skills.append(SkillData.new("治愈术", SkillData.Type.HEAL, "恢复 %.0f%% 最大生命值" % (BalanceConfig.SKILL_HEAL_PERCENT * 100.0), 15.0, 20, BalanceConfig.SKILL_HEAL_PERCENT))
	skills.append(SkillData.new("重击", SkillData.Type.HEAVY_HIT, "造成 %.0f%% 攻击伤害" % (BalanceConfig.SKILL_HEAVY_HIT_POWER * 100.0), 10.0, 15, BalanceConfig.SKILL_HEAVY_HIT_POWER))
	skills.append(SkillData.new("狂暴", SkillData.Type.BERSERK, "%.0f 秒内攻速翻倍" % BalanceConfig.SKILL_BERSERK_DURATION, 30.0, 30, BalanceConfig.SKILL_BERSERK_MULTIPLIER, BalanceConfig.SKILL_BERSERK_DURATION))

func _process(delta: float) -> void:
	## 更新技能冷却
	var expired_types: Array[int] = []
	for type: int in cooldowns.keys():
		var old_remaining: float = cooldowns[type]
		cooldowns[type] = max(0.0, cooldowns[type] - delta)
		## 每 0.1 秒或冷却结束时发射一次更新信号，避免每帧都发
		if old_remaining > 0.0 and (cooldowns[type] <= 0.001 or int(old_remaining * 10.0) != int(cooldowns[type] * 10.0)):
			cooldown_updated.emit(type, cooldowns[type])
		if cooldowns[type] <= 0.001:
			expired_types.append(type)
	for type: int in expired_types:
		cooldowns.erase(type)
		cooldown_updated.emit(type, 0.0)
	
	## 能量自然回复（累加小数避免高帧率下回复为 0）
	if energy < max_energy:
		_energy_regen_accumulator += delta * BalanceConfig.ENERGY_REGEN_PER_SECOND
		var whole: int = int(_energy_regen_accumulator)
		if whole > 0:
			_energy_regen_accumulator -= whole
			energy = min(max_energy, energy + whole)
			energy_changed.emit(energy, max_energy)
	
	## 狂暴状态倒计时
	if berserk_timer > 0.0:
		berserk_timer -= delta
		if berserk_timer <= 0.0:
			_end_berserk()

func can_cast(skill: SkillData) -> bool:
	return energy >= skill.energy_cost and not cooldowns.has(skill.type)

func cast_skill(skill: SkillData) -> bool:
	if not can_cast(skill):
		return false
	## 治疗/狂暴不依赖敌人；重击需要敌人目标
	match skill.type:
		SkillData.Type.HEAVY_HIT:
			if battle_manager == null or battle_manager.enemy_data == null:
				return false
		SkillData.Type.HEAL, SkillData.Type.BERSERK:
			if player_data == null:
				return false
		_:
			return false
	
	energy -= skill.energy_cost
	energy_changed.emit(energy, max_energy)
	cooldowns[skill.type] = skill.cooldown
	
	match skill.type:
		SkillData.Type.HEAL:
			_cast_heal(skill)
		SkillData.Type.HEAVY_HIT:
			_cast_heavy_hit(skill)
		SkillData.Type.BERSERK:
			_cast_berserk(skill)
	
	skill_casted.emit(skill)
	EventBus.skill_casted.emit(skill)
	return true

func add_energy(amount: int) -> void:
	energy = min(max_energy, energy + amount)
	energy_changed.emit(energy, max_energy)

func _cast_heal(skill: SkillData) -> void:
	if player_data == null:
		return
	var heal_amount: int = int(player_data.max_hp * skill.power)
	player_data.heal(heal_amount)
	var ftm: FloatingTextManager = get_tree().get_first_node_in_group("floating_text_manager") as FloatingTextManager
	if ftm:
		var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
		if player:
			ftm.show_heal(player.global_position + Vector2(0, -40), heal_amount)
	EventBus.message_logged.emit("治愈术恢复 %d 点生命" % heal_amount)

func _cast_heavy_hit(skill: SkillData) -> void:
	if battle_manager == null or battle_manager.enemy_data == null or player_data == null:
		return
	var damage: int = int(player_data.attack * skill.power)
	## 抑制 player_attacked 信号，避免普通攻击飘字与重击飘字重叠
	var actual: int = battle_manager.deal_damage_to_enemy(damage, true, false)
	
	EventBus.play_sfx.emit("attack")
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(BalanceConfig.SKILL_HEAVY_HIT_SHAKE)
	
	var ftm: FloatingTextManager = get_tree().get_first_node_in_group("floating_text_manager") as FloatingTextManager
	if ftm:
		var enemy: Node2D = get_tree().get_first_node_in_group("enemy") as Node2D
		if enemy:
			ftm.show_damage(enemy.global_position + Vector2(0, -40), actual, true, true)
	EventBus.message_logged.emit("重击造成 %d 点伤害" % actual)

func _cast_berserk(skill: SkillData) -> void:
	if player_data == null:
		return
	berserk_timer = skill.duration
	berserk_multiplier = skill.power
	player_data.attack_speed_multiplier = berserk_multiplier
	player_data.recalc_stats()
	EventBus.message_logged.emit("狂暴开启！攻击速度翻倍")

func _end_berserk() -> void:
	if player_data == null:
		return
	berserk_multiplier = 1.0
	player_data.attack_speed_multiplier = berserk_multiplier
	player_data.recalc_stats()
	EventBus.message_logged.emit("狂暴效果结束")

func get_attack_speed_multiplier() -> float:
	return berserk_multiplier

func get_remaining_cooldown(type: int) -> float:
	return cooldowns.get(type, 0.0)

func get_cooldowns() -> Dictionary:
	return cooldowns

func set_cooldowns(data: Dictionary) -> void:
	cooldowns.clear()
	for type_str: String in data.keys():
		cooldowns[int(type_str)] = float(data[type_str])
