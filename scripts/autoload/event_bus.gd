extends Node

## 全局事件总线。仅承载跨子系统的全局事件。
##
## 战斗高频事件（player_attacked/enemy_attacked/enemy_died/player_died）由
## BattleManager 作为唯一真相源直接发射，消费方连接 BattleManager 信号，
## 不再在本总线重复定义，避免双轨制。

## 战斗事件
signal enemy_spawned(enemy: EnemyData)

## Boss 机制事件
signal boss_healed(amount: int)
signal boss_berserk(active: bool)

## 玩家成长事件
signal player_leveled_up(new_level: int)
signal stats_changed
signal gold_changed(amount: int)

## 游戏进度事件
signal stage_changed(stage: int)
signal equipment_dropped(equipment: EquipmentData)
signal achievement_unlocked(achievement: AchievementData)

## 每日任务事件
signal quest_updated(quest: QuestData)
signal quest_completed(quest: QuestData)
signal daily_quests_refreshed

## 通用消息与反馈
signal message_logged(text: String)
signal play_sfx(name: String)
