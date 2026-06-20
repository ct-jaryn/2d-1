class_name GameManager
extends Node

@export var player_data: PlayerData
@export var battle_manager: BattleManager
@export var equipment_manager: EquipmentManager
@export var skill_manager: SkillManager
@export var shop_manager: ShopManager
@export var achievement_manager: AchievementManager
@export var stage_manager: StageManager
@export var reward_manager: RewardManager
@export var quest_manager: QuestManager

@onready var background: TextureRect = $"../Background"

var save_manager: SaveManager = null
const SAVE_INTERVAL: float = BalanceConfig.SAVE_INTERVAL
var save_timer: float = 0.0

func _ready() -> void:
	add_to_group("game_manager")
	_init_subsystems()
	_connect_events()
	_load_save()

	if stage_manager:
		stage_manager.spawn_normal_enemy()

func _init_subsystems() -> void:
	if player_data == null:
		player_data = PlayerData.new()

	battle_manager = _ensure_manager(battle_manager, BattleManager)
	equipment_manager = _ensure_manager(equipment_manager, EquipmentManager)
	skill_manager = _ensure_manager(skill_manager, SkillManager)
	shop_manager = _ensure_manager(shop_manager, ShopManager)
	reward_manager = _ensure_manager(reward_manager, RewardManager)
	achievement_manager = _ensure_manager(achievement_manager, AchievementManager)
	stage_manager = _ensure_manager(stage_manager, StageManager)
	quest_manager = _ensure_manager(quest_manager, QuestManager)

	battle_manager.player_data = player_data

	equipment_manager.equipment_changed.connect(_on_equipment_changed)

	skill_manager.player_data = player_data
	skill_manager.battle_manager = battle_manager

	shop_manager.player_data = player_data
	shop_manager.equipment_manager = equipment_manager
	shop_manager.stage_manager = stage_manager

	reward_manager.player_data = player_data
	reward_manager.equipment_manager = equipment_manager
	reward_manager.shop_manager = shop_manager
	reward_manager.stage_manager = stage_manager

	achievement_manager.player_data = player_data

	stage_manager.player_data = player_data
	stage_manager.battle_manager = battle_manager
	stage_manager.background = background

	quest_manager.player_data = player_data
	quest_manager.equipment_manager = equipment_manager
	quest_manager.stage_manager = stage_manager

	save_manager = SaveManager.new()

func _ensure_manager(current: Node, script_class: GDScript) -> Node:
	if current != null:
		return current
	var instance: Node = script_class.new()
	add_child(instance)
	return instance

func _connect_events() -> void:
	if player_data:
		player_data.leveled_up.connect(_on_player_leveled_up)
		player_data.stats_changed.connect(_on_player_stats_changed)
	if battle_manager:
		battle_manager.player_died.connect(_on_battle_player_died)
		battle_manager.enemy_died.connect(_on_battle_enemy_died)
	EventBus.player_died.connect(_on_player_died)
	EventBus.boss_healed.connect(_on_boss_healed)
	EventBus.boss_berserk.connect(_on_boss_berserk)

func _on_player_leveled_up(new_level: int) -> void:
	EventBus.player_leveled_up.emit(new_level)

func _on_player_stats_changed() -> void:
	EventBus.stats_changed.emit()

func _on_battle_player_died() -> void:
	EventBus.player_died.emit()

func _on_battle_enemy_died(enemy: EnemyData) -> void:
	EventBus.enemy_defeated.emit(enemy)

func _load_save() -> void:
	if save_manager == null:
		return
	if save_manager.has_save():
		if save_manager.load_game(player_data, equipment_manager, self, achievement_manager, quest_manager):
			EventBus.message_logged.emit("已加载存档")
			reward_manager.apply_offline_rewards(save_manager.get_last_save_time())
		else:
			EventBus.message_logged.emit("存档加载失败，开始新游戏")

func _process(delta: float) -> void:
	save_timer += delta
	if save_timer >= SAVE_INTERVAL:
		save_timer = 0.0
		_save_game()

	if player_data:
		player_data.play_time_seconds += delta

func _save_game() -> void:
	if save_manager == null or player_data == null or equipment_manager == null or stage_manager == null or quest_manager == null:
		return
	save_manager.save_game(player_data, equipment_manager, stage_manager.current_enemy_level, achievement_manager, quest_manager, self)

func challenge_boss() -> bool:
	if stage_manager:
		return stage_manager.challenge_boss()
	return false

func _on_equipment_changed() -> void:
	var bonuses: Dictionary = equipment_manager.get_equipment_bonuses()
	player_data.set_equipment_bonuses(bonuses)

func _on_player_died() -> void:
	player_data.death_count += 1
	EventBus.message_logged.emit("勇者倒下了！正在复活...")
	await get_tree().create_timer(BalanceConfig.REVIVE_DELAY).timeout
	if not is_instance_valid(self) or player_data == null or stage_manager == null:
		return
	player_data.heal(player_data.max_hp)
	if battle_manager:
		battle_manager.player_attack_timer = 0.0
		battle_manager.enemy_attack_timer = 0.0
	stage_manager.spawn_normal_enemy()
	var player_node = get_tree().get_first_node_in_group("player") as Node2D
	if player_node and player_node.has_method("revive"):
		player_node.revive()

func _on_boss_healed(amount: int) -> void:
	EventBus.message_logged.emit("Boss 恢复了 %d 点生命！" % amount)

func _on_boss_berserk(active: bool) -> void:
	if active:
		EventBus.message_logged.emit("Boss 进入狂暴状态！攻速翻倍！")
	else:
		EventBus.message_logged.emit("Boss 狂暴结束")
