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
const ENEMY_HP_MULTIPLIER: float = 1.12
const ENEMY_ATK_MULTIPLIER: float = 1.10
const ENEMY_DEF_MULTIPLIER: float = 1.08
const ENEMY_SIZE_SCALE_MIN: float = 0.8
const ENEMY_SIZE_SCALE_MAX: float = 1.4
const BOSS_HP_MULTIPLIER: float = 3.0
const BOSS_ATK_MULTIPLIER: float = 1.3
const BOSS_CRIT_CHANCE: float = 0.2
const BOSS_CRIT_DAMAGE: float = 1.5
const BOSS_RAGE_THRESHOLD: float = 0.3
const BOSS_RAGE_MULTIPLIER: float = 1.5

## 战斗
const PLAYER_ATTACK_INTERVAL_BASE: float = 1.0
const ENEMY_ATTACK_INTERVAL_BASE: float = 1.2
const PLAYER_HIT_SHAKE: float = 0.0
const PLAYER_CRIT_SHAKE: float = 2.0
const ENEMY_HIT_SHAKE: float = 0.0
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
const SHOP_REFRESH_INTERVAL: float = 300.0
const MAX_BONUS_ATTACK: int = 40
const MAX_BONUS_DEFENSE: int = 40
const MAX_EXP_POTION_CHARGES: int = 50
const EXP_POTION_BUY_AMOUNT: int = 5
const EXP_POTION_MULTIPLIER: float = 1.5

## 离线收益
const OFFLINE_REWARD_RATE_GOLD: float = 0.05
const OFFLINE_REWARD_RATE_EXP: float = 0.10
const OFFLINE_MAX_HOURS: float = 12.0
const OFFLINE_GOLD_CAP_PER_STAGE: float = 200.0
const OFFLINE_EXP_CAP_FACTOR: float = 0.5

## 存档
const SAVE_INTERVAL: float = 10.0
const SAVE_VERSION: int = 3

## Boss 解锁
const BOSS_UNLOCK_LEVEL: int = 5
const BOSS_INTERVAL: int = 5

## 复活
const REVIVE_DELAY: float = 2.0

## 战力评分权重
const POWER_WEIGHT_HP: float = 0.5
const POWER_WEIGHT_ATK: float = 4.0
const POWER_WEIGHT_DEF: float = 3.0
const POWER_WEIGHT_ASPD: float = 100.0
const POWER_WEIGHT_CRIT: float = 200.0
