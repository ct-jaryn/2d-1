class_name BalanceConfig
extends RefCounted

## 玩家成长
const MAX_LEVEL: int = 100
const HP_GROWTH: int = 20
const ATK_GROWTH: int = 4
const DEF_GROWTH: int = 2
const EXP_BASE: int = 100
const EXP_GROWTH_RATE: float = 1.25
const BASE_ATTACK_SPEED: float = 1.0
const MAX_ATTACK_SPEED: float = 3.0
const BASE_CRIT_RATE: float = 0.05

## 敌人
const ENEMY_BASE_HP: int = 50
const ENEMY_BASE_ATK: int = 5
const ENEMY_BASE_DEF: int = 2
const ENEMY_BASE_ATK_SPEED: float = 0.8
const ENEMY_ATK_SPEED_LEVEL_GROWTH: float = 0.03
const ENEMY_ATK_SPEED_CAP: float = 2.0
const ENEMY_BASE_EXP: int = 20
const ENEMY_BASE_GOLD: int = 10
const ENEMY_HP_MULTIPLIER: float = 1.12
const ENEMY_ATK_MULTIPLIER: float = 1.10
const ENEMY_DEF_MULTIPLIER: float = 1.08
const ENEMY_SIZE_SCALE_MIN: float = 0.8
const ENEMY_SIZE_SCALE_MAX: float = 1.4
const BOSS_HP_MULTIPLIER: float = 3.0
const BOSS_ATK_MULTIPLIER: float = 1.3
const BOSS_DEF_MULTIPLIER: float = 1.5
const BOSS_EXP_MULTIPLIER: float = 2.0
const BOSS_GOLD_MULTIPLIER: float = 2.5
const BOSS_CRIT_CHANCE: float = 0.2
const BOSS_CRIT_DAMAGE: float = 1.5

## Boss 机制
const BOSS_HEAL_INTERVAL: float = 6.0
const BOSS_HEAL_PERCENT: float = 0.08
const BOSS_BERSERK_COOLDOWN: float = 12.0
const BOSS_BERSERK_DURATION: float = 4.0
const BOSS_BERSERK_ATK_SPEED_MULTIPLIER: float = 2.0

## 战斗
const PLAYER_CRIT_SHAKE: float = 2.0
const ENEMY_CRIT_SHAKE: float = 3.0
const DEATH_SHAKE: float = 6.0
const SKILL_HEAVY_HIT_SHAKE: float = 4.0

## 技能
const MAX_ENERGY: int = 100
const ENERGY_REGEN_PER_SECOND: float = 2.0
const SKILL_HEAVY_HIT_POWER: float = 3.0
const SKILL_HEAL_PERCENT: float = 0.3
const SKILL_BERSERK_DURATION: float = 5.0
const SKILL_BERSERK_MULTIPLIER: float = 2.0

## 掉落
const NORMAL_DROP_CHANCE: float = 0.30
const BOSS_DROP_CHANCE: float = 0.65

## 商店
const UPGRADE_COST_BASE: int = 50
const MAX_BONUS_ATTACK: int = 40
const MAX_BONUS_DEFENSE: int = 40
const MAX_EXP_POTION_CHARGES: int = 50
const EXP_POTION_BUY_AMOUNT: int = 5
const EXP_POTION_MULTIPLIER: float = 1.5

## 装备生成
const EQUIPMENT_RARITY_MULT_BASE: float = 1.0
const EQUIPMENT_RARITY_MULT_STEP: float = 0.5
const EQUIPMENT_LEVEL_MULT: float = 0.12
const EQUIPMENT_BOSS_MULT: float = 1.5

const EQUIPMENT_WEAPON_ATK_BASE: int = 3
const EQUIPMENT_WEAPON_ASPD_MAX: float = 0.15
const EQUIPMENT_WEAPON_CRIT_MAX: float = 0.03

const EQUIPMENT_HELMET_HP_BASE: int = 8
const EQUIPMENT_HELMET_DEF_BASE: int = 1

const EQUIPMENT_ARMOR_DEF_BASE: int = 3
const EQUIPMENT_ARMOR_HP_BASE: int = 5

const EQUIPMENT_BOOTS_ASPD_MIN: float = 0.05
const EQUIPMENT_BOOTS_ASPD_MAX: float = 0.25
const EQUIPMENT_BOOTS_DEF_BASE: int = 1

const EQUIPMENT_RING_BRANCH_CHANCE: float = 0.5
const EQUIPMENT_RING_GOLD_MIN: float = 2.0
const EQUIPMENT_RING_GOLD_MAX: float = 8.0
const EQUIPMENT_RING_EXP_MIN: float = 2.0
const EQUIPMENT_RING_EXP_MAX: float = 8.0
const EQUIPMENT_RING_ATK_BASE: int = 2
const EQUIPMENT_RING_CRIT_MIN: float = 0.01
const EQUIPMENT_RING_CRIT_MAX: float = 0.05

const EQUIPMENT_RANDOM_BONUS_ATK: int = 2
const EQUIPMENT_RANDOM_BONUS_DEF: int = 1
const EQUIPMENT_RANDOM_BONUS_HP: int = 4
const EQUIPMENT_RANDOM_BONUS_ASPD_MIN: float = 0.02
const EQUIPMENT_RANDOM_BONUS_ASPD_MAX: float = 0.10
const EQUIPMENT_RANDOM_BONUS_CRIT_MIN: float = 0.01
const EQUIPMENT_RANDOM_BONUS_CRIT_MAX: float = 0.03
const EQUIPMENT_RANDOM_BONUS_GOLD_MIN: float = 1.0
const EQUIPMENT_RANDOM_BONUS_GOLD_MAX: float = 5.0
const EQUIPMENT_RANDOM_BONUS_EXP_MIN: float = 1.0
const EQUIPMENT_RANDOM_BONUS_EXP_MAX: float = 5.0

## 装备评分
const EQUIPMENT_SCORE_WEIGHT_ATK: int = 4
const EQUIPMENT_SCORE_WEIGHT_DEF: int = 4
const EQUIPMENT_SCORE_WEIGHT_HP: int = 1
const EQUIPMENT_SCORE_WEIGHT_ASPD: int = 50
const EQUIPMENT_SCORE_WEIGHT_CRIT: int = 200
const EQUIPMENT_SCORE_WEIGHT_GOLD: int = 3
const EQUIPMENT_SCORE_WEIGHT_EXP: int = 3
const EQUIPMENT_SCORE_RARITY: int = 20

## 装备出售
const EQUIPMENT_SELL_BASE: int = 10
const EQUIPMENT_SELL_LEVEL: int = 2
const EQUIPMENT_SELL_RARITY_MULT: float = 0.8

## 离线收益
const OFFLINE_REWARD_RATE_GOLD: float = 0.05
const OFFLINE_REWARD_RATE_EXP: float = 0.10
const OFFLINE_MAX_HOURS: float = 12.0
const OFFLINE_GOLD_CAP_PER_STAGE: float = 200.0
const OFFLINE_EXP_CAP_FACTOR: float = 0.5

## 存档
const SAVE_INTERVAL: float = 10.0
const SAVE_VERSION: int = 4

## Boss 解锁
const BOSS_UNLOCK_LEVEL: int = 5

## 关卡上限，防止存档篡改导致敌人数值异常
const MAX_STAGE: int = 9999

## 复活
const REVIVE_DELAY: float = 2.0

## 战力评分权重
const POWER_WEIGHT_HP: float = 0.5
const POWER_WEIGHT_ATK: float = 4.0
const POWER_WEIGHT_DEF: float = 3.0
const POWER_WEIGHT_ASPD: float = 100.0
const POWER_WEIGHT_CRIT: float = 200.0
