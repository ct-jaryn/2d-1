class_name StageManager
extends Node

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

@export var background: TextureRect

const NORMAL_BG: Texture2D = preload("res://assets/images/battle_bg.png")
const BOSS_BG: Texture2D = preload("res://assets/images/boss_arena.png")

var current_enemy_level: int = 1
var boss_unlock_level: int = BalanceConfig.BOSS_UNLOCK_LEVEL
var is_fighting_boss: bool = false

const ENEMY_NAMES: PackedStringArray = [
	"史莱姆", "哥布林", "蝙蝠", "骷髅兵", "史莱姆王",
	"兽人", "暗影狼", "石巨人", "幽灵", "恶魔犬",
	"黑暗骑士", "亡灵法师", "深渊触手", "熔岩怪", "虚空行者"
]

func _ready() -> void:
	Services.stage_manager = self
	## 敌人击杀由 BattleManager 直发，直接监听以推进关卡。
	if battle_manager:
		battle_manager.enemy_died.connect(_on_enemy_defeated)

func spawn_normal_enemy() -> void:
	is_fighting_boss = false
	var enemy: EnemyData = EnemyData.new(_get_enemy_name(current_enemy_level), current_enemy_level, false)
	battle_manager.start_battle(enemy)
	EventBus.enemy_spawned.emit(enemy)
	EventBus.message_logged.emit(tr("UI_STAGE_ENCOUNTER") % [enemy.level, tr("ENEMY_NAME_" + enemy.name)])
	_update_background(false)

func challenge_boss() -> bool:
	if current_enemy_level < boss_unlock_level:
		EventBus.message_logged.emit(tr("UI_STAGE_BOSS_UNLOCK_REQUIRED") % boss_unlock_level)
		return false
	if is_fighting_boss:
		EventBus.message_logged.emit(tr("UI_STAGE_ALREADY_FIGHTING_BOSS"))
		return false

	is_fighting_boss = true
	var enemy: EnemyData = EnemyData.new("恶龙", current_enemy_level, true)
	var mechanics: BossMechanics = BossMechanics.new(enemy)
	battle_manager.start_battle(enemy, mechanics)
	EventBus.enemy_spawned.emit(enemy)
	EventBus.message_logged.emit(tr("UI_STAGE_BOSS_CHALLENGE") % [enemy.level, tr("ENEMY_NAME_" + enemy.name)])
	_update_background(true)
	return true

func advance_stage() -> void:
	current_enemy_level += 1
	if player_data != null and current_enemy_level > player_data.highest_stage:
		player_data.highest_stage = current_enemy_level
	EventBus.stage_changed.emit(current_enemy_level)
	spawn_normal_enemy()

func get_stage_display() -> String:
	return tr("UI_STAGE_FORMAT") % current_enemy_level

func _on_enemy_defeated(enemy: EnemyData) -> void:
	if not enemy.is_boss:
		await get_tree().create_timer(0.5).timeout
		if player_data != null and player_data.is_alive():
			spawn_normal_enemy()
		return

	EventBus.message_logged.emit(tr("UI_STAGE_BOSS_DEFEATED"))
	advance_stage()

func _get_enemy_name(level: int) -> String:
	var index: int = wrapi(level - 1, 0, ENEMY_NAMES.size())
	return ENEMY_NAMES[index]

func _update_background(is_boss: bool) -> void:
	if background == null:
		return
	background.texture = BOSS_BG if is_boss else NORMAL_BG

func serialize() -> Dictionary:
	return {"level": current_enemy_level}

func deserialize(data: Dictionary) -> void:
	current_enemy_level = clampi(int(data.get("level", 1)), 1, BalanceConfig.MAX_STAGE)
