class_name SkillManager
extends Node

signal skill_casted(skill: SkillData)
signal energy_changed(current: int, maximum: int)
signal cooldown_updated(skill_type: int, remaining: float)

var _player_data: PlayerData
var player_data: PlayerData:
	get:
		if _player_data == null:
			_player_data = Services.player_data
		return _player_data
	set(v):
		_player_data = v

var _battle_manager: BattleManager
var battle_manager: BattleManager:
	get:
		if _battle_manager == null:
			_battle_manager = Services.battle_manager
		return _battle_manager
	set(v):
		_battle_manager = v

var skills: Array[SkillData] = []
var cooldowns: Dictionary = {}  ## {SkillData.Type: remaining_time}
var energy: int = 0
var max_energy: int = BalanceConfig.MAX_ENERGY
var _energy_regen_accumulator: float = 0.0

## 狂暴技能计时
var berserk_timer: float = 0.0
var berserk_multiplier: float = 1.0

func _ready() -> void:
	Services.skill_manager = self
	_init_default_skills()
	## 能量收益：直接监听战斗击杀事件，不再经 EventBus.energy_gained 中转。
	if battle_manager:
		battle_manager.enemy_died.connect(_on_enemy_died)

func _init_default_skills() -> void:
	skills.append(SkillData.new("UI_SKILL_NAME_HEAL", SkillData.Type.HEAL, tr("UI_SKILL_DESC_HEAL") % (BalanceConfig.SKILL_HEAL_PERCENT * 100.0), 15.0, 20, BalanceConfig.SKILL_HEAL_PERCENT))
	skills.append(SkillData.new("UI_SKILL_NAME_HEAVY_HIT", SkillData.Type.HEAVY_HIT, tr("UI_SKILL_DESC_HEAVY_HIT") % (BalanceConfig.SKILL_HEAVY_HIT_POWER * 100.0), 10.0, 15, BalanceConfig.SKILL_HEAVY_HIT_POWER))
	skills.append(SkillData.new("UI_SKILL_NAME_BERSERK", SkillData.Type.BERSERK, tr("UI_SKILL_DESC_BERSERK") % BalanceConfig.SKILL_BERSERK_DURATION, 30.0, 30, BalanceConfig.SKILL_BERSERK_MULTIPLIER, BalanceConfig.SKILL_BERSERK_DURATION))

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
	return true

func add_energy(amount: int) -> void:
	energy = min(max_energy, energy + amount)
	energy_changed.emit(energy, max_energy)

func _on_enemy_died(enemy: EnemyData) -> void:
	add_energy(10 if enemy.is_boss else 3)

func _cast_heal(skill: SkillData) -> void:
	if player_data == null:
		return
	var heal_amount: int = int(player_data.max_hp * skill.power)
	player_data.heal(heal_amount)
	var ftm: FloatingTextManager = Services.floating_text_manager
	if ftm:
		var player: Node2D = Services.player_node
		if player:
			ftm.show_heal(player.global_position + Vector2(0, -40), heal_amount)
	EventBus.message_logged.emit(tr("UI_SKILL_HEAL_LOG") % heal_amount)

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

	var ftm: FloatingTextManager = Services.floating_text_manager
	if ftm:
		var enemy: Node2D = Services.enemy_node
		if enemy:
			ftm.show_damage(enemy.global_position + Vector2(0, -40), actual, true, true)
	EventBus.message_logged.emit(tr("UI_SKILL_HEAVY_HIT_LOG") % actual)

func _cast_berserk(skill: SkillData) -> void:
	if player_data == null:
		return
	berserk_timer = skill.duration
	berserk_multiplier = skill.power
	player_data.attack_speed_multiplier = berserk_multiplier
	player_data.recalc_stats()
	EventBus.message_logged.emit(tr("UI_SKILL_BERSERK_START"))

func _end_berserk() -> void:
	if player_data == null:
		return
	berserk_multiplier = 1.0
	player_data.attack_speed_multiplier = berserk_multiplier
	player_data.recalc_stats()
	EventBus.message_logged.emit(tr("UI_SKILL_BERSERK_END"))

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

func serialize() -> Dictionary:
	return {
		"energy": energy,
		"cooldowns": cooldowns.duplicate(),
		"berserk_timer": berserk_timer,
		"berserk_multiplier": berserk_multiplier
	}

func deserialize(data: Dictionary) -> void:
	energy = clampi(int(data.get("energy", 0)), 0, max_energy)
	berserk_timer = maxf(0.0, float(data.get("berserk_timer", 0.0)))
	berserk_multiplier = maxf(1.0, float(data.get("berserk_multiplier", 1.0)))
	set_cooldowns(data.get("cooldowns", {}))
	## 过滤掉负值冷却
	for type: int in cooldowns.keys():
		if cooldowns[type] < 0.0:
			cooldowns.erase(type)
	## 狂暴倍率由 SkillManager 拥有，加载后同步回 PlayerData 的运行时攻速倍率。
	if player_data != null:
		player_data.attack_speed_multiplier = berserk_multiplier
		player_data.recalc_stats(false)
	energy_changed.emit(energy, max_energy)
