class_name BattleManager
extends Node

## 战斗系统：持有当前敌人数据，驱动玩家/敌人攻击循环。
## 战斗事件（player_attacked/enemy_attacked/enemy_died/player_died）的唯一真相源，
## 消费方直接连接本类的信号。

var _player_data: PlayerData
var player_data: PlayerData:
	get:
		if _player_data == null:
			_player_data = Services.player_data
		return _player_data
	set(v):
		_player_data = v

var enemy_data: EnemyData

var player_attack_timer: float = 0.0
var enemy_attack_timer: float = 0.0
var boss_mechanics: BossMechanics = null

## 单帧攻击结算最大次数，防止低帧率/极高速下出现卡顿或异常Burst
const MAX_ATTACK_ITERATIONS: int = 5

signal enemy_died(enemy: EnemyData)
signal player_died
signal player_attacked(damage: int, is_crit: bool)
signal enemy_attacked(damage: int, is_crit: bool)
signal battle_started(enemy: EnemyData)

func _ready() -> void:
	Services.battle_manager = self

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if Services.battle_manager == self:
			Services.battle_manager = null

func start_battle(p_enemy: EnemyData, p_boss_mechanics: BossMechanics = null) -> void:
	enemy_data = p_enemy
	boss_mechanics = p_boss_mechanics
	player_attack_timer = 0.0
	enemy_attack_timer = 0.0
	battle_started.emit(enemy_data)

func reset() -> void:
	enemy_data = null
	boss_mechanics = null
	player_attack_timer = 0.0
	enemy_attack_timer = 0.0

func _process(delta: float) -> void:
	if enemy_data == null or not enemy_data.is_alive() or not player_data.is_alive():
		return

	if boss_mechanics != null:
		boss_mechanics.update(delta)

	player_attack_timer += delta
	enemy_attack_timer += delta

	var player_interval: float = 1.0 / maxf(player_data.attack_speed, 0.001)
	var player_iterations: int = 0
	while player_attack_timer >= player_interval and player_iterations < MAX_ATTACK_ITERATIONS:
		player_attack_timer -= player_interval
		_player_attack()
		player_iterations += 1

	var enemy_interval: float = 1.0 / maxf(enemy_data.attack_speed, 0.001)
	var enemy_iterations: int = 0
	while enemy_attack_timer >= enemy_interval and enemy_iterations < MAX_ATTACK_ITERATIONS:
		enemy_attack_timer -= enemy_interval
		_enemy_attack()
		enemy_iterations += 1

func deal_damage_to_enemy(damage: int, is_crit: bool = false, emit_feedback: bool = true) -> int:
	"""供技能调用，统一结算对敌人伤害并分发事件。"""
	if enemy_data == null:
		return 0
	var actual: int = enemy_data.take_damage(damage)
	player_data.total_damage_dealt += actual
	if emit_feedback:
		player_attacked.emit(actual, is_crit)
	if not enemy_data.is_alive():
		_shake(BalanceConfig.DEATH_SHAKE)
		enemy_died.emit(enemy_data)
	return actual

func _player_attack() -> void:
	if enemy_data == null:
		return
	EventBus.play_sfx.emit("attack")
	var result: Dictionary = player_data.get_attack_damage()
	if result.is_crit:
		_shake(BalanceConfig.PLAYER_CRIT_SHAKE)
	deal_damage_to_enemy(result.damage, result.is_crit)

func _enemy_attack() -> void:
	if enemy_data == null:
		return
	EventBus.play_sfx.emit("hit")
	var result: Dictionary = enemy_data.get_attack_damage()
	var damage: int = result.damage
	var is_crit: bool = result.is_crit
	if is_crit:
		_shake(BalanceConfig.ENEMY_CRIT_SHAKE)
	var actual: int = player_data.take_damage(damage)
	player_data.total_damage_taken += actual
	enemy_attacked.emit(actual, is_crit)
	if not player_data.is_alive():
		_shake(BalanceConfig.DEATH_SHAKE)
		player_died.emit()

func _shake(amount: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(amount)
