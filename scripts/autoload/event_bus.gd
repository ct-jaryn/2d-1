extends Node

## 战斗事件
signal enemy_spawned(enemy: EnemyData)
signal enemy_defeated(enemy: EnemyData)
signal player_died
signal player_attacked(damage: int, is_crit: bool)
signal enemy_attacked(damage: int, is_crit: bool)

## Boss 机制事件
signal boss_healed(amount: int)
signal boss_berserk(active: bool)

## 玩家成长事件
signal player_leveled_up(new_level: int)
signal stats_changed
signal gold_changed(amount: int)
signal energy_gained(amount: int)
signal skill_casted(skill: SkillData)

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
