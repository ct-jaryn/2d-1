extends Node

## 全局服务注册表（autoload 单例）。
##
## 管理器与数据对象在 _ready 时把自身注册到这里，消费方通过本单例解析协作者，
## 取代散落在各处的 get_first_node_in_group / get_node_or_null("../X") 查找，
## 统一依赖解析入口并消除 _ready 时序竞争。
##
## 约定：
## - 管理器/数据/服务（player_data、各 Manager、floating_text_manager、audio_manager）
##   统一通过 Services 解析。
## - 场景表现节点（player/enemy 演员、sub_ui 面板组）仍按 Godot 惯例用组查找。

var player_data: PlayerData
var game_manager: GameManager
var battle_manager: BattleManager
var stage_manager: StageManager
var equipment_manager: EquipmentManager
var shop_manager: ShopManager
var skill_manager: SkillManager
var achievement_manager: AchievementManager
var quest_manager: QuestManager
var reward_manager: RewardManager
var save_manager: SaveManager
var floating_text_manager: FloatingTextManager
var audio_manager: AudioManager

## 场景表现节点（演员）注册点，供特效、技能、复活逻辑直接解析。
var player_node: Node2D
var enemy_node: Node2D
