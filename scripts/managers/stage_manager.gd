class_name StageManager
extends Node

@export var game_manager: GameManager
@export var battle_manager: BattleManager
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
	add_to_group("stage_manager")
	EventBus.enemy_defeated.connect(_on_enemy_defeated)

func spawn_normal_enemy() -> void:
	is_fighting_boss = false
	var enemy: EnemyData = EnemyData.new(_get_enemy_name(current_enemy_level), current_enemy_level, false)
	battle_manager.start_battle(enemy)
	EventBus.enemy_spawned.emit(enemy)
	EventBus.message_logged.emit("遭遇了 Lv.%d %s！" % [enemy.level, enemy.name])
	_update_background(false)

func challenge_boss() -> bool:
	if current_enemy_level < boss_unlock_level:
		EventBus.message_logged.emit("需要通关到第 %d 关才能挑战 Boss！" % boss_unlock_level)
		return false
	if is_fighting_boss:
		EventBus.message_logged.emit("已经在挑战 Boss 了！")
		return false

	is_fighting_boss = true
	var enemy: EnemyData = EnemyData.new("恶龙", current_enemy_level, true)
	var mechanics: BossMechanics = BossMechanics.new(enemy)
	battle_manager.start_battle(enemy, mechanics)
	EventBus.enemy_spawned.emit(enemy)
	EventBus.message_logged.emit("挑战 Boss：Lv.%d %s！" % [enemy.level, enemy.name])
	_update_background(true)
	return true

func advance_stage() -> void:
	current_enemy_level += 1
	if game_manager and game_manager.player_data:
		if current_enemy_level > game_manager.player_data.highest_stage:
			game_manager.player_data.highest_stage = current_enemy_level
	EventBus.stage_changed.emit(current_enemy_level)
	spawn_normal_enemy()

func get_stage_display() -> String:
	return "第 %d 关" % current_enemy_level

func _on_enemy_defeated(enemy: EnemyData) -> void:
	if not enemy.is_boss:
		await get_tree().create_timer(0.5).timeout
		if game_manager and game_manager.player_data and game_manager.player_data.is_alive():
			spawn_normal_enemy()
		return

	EventBus.message_logged.emit("Boss 讨伐成功！进入下一区域！")
	advance_stage()

func _get_enemy_name(level: int) -> String:
	var index: int = wrapi(level - 1, 0, ENEMY_NAMES.size())
	return ENEMY_NAMES[index]

func _update_background(is_boss: bool) -> void:
	if background == null:
		return
	background.texture = BOSS_BG if is_boss else NORMAL_BG
