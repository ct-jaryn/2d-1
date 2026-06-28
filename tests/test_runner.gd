extends Node

## 核心逻辑 headless 单元测试 Runner
## 运行方式：
## ./Godot_v4.3-stable_win64_console.exe --headless --path . res://tests/test_runner.tscn

var _passed: int = 0
var _failed: int = 0

func _ready() -> void:
	print("=== 开始核心逻辑单元测试 ===")
	
	## headless 测试期间禁用音效，避免 AudioStreamPlaybackWAV 资源在退出时泄漏。
	## 直接修改字段而非调用 setter，避免把测试状态持久化到用户配置。
	var audio: AudioManager = Services.audio_manager
	if audio:
		audio.sfx_enabled = false
		audio.bgm_enabled = false
		audio.stop_bgm()
	
	await test_player_data_leveling()
	await test_player_data_gold()
	await test_player_data_combat()
	await test_equipment_manager_basic()
	await test_equipment_manager_sell()
	await test_enemy_data_stats()
	await test_enemy_data_scaling()
	await test_boss_mechanics()
	await test_skill_manager()
	await test_save_round_trip()
	await test_save_v3_migration()
	await test_save_checksum_and_validation()
	await test_save_backup_rotation()
	await test_stage_manager_validation()
	await test_battle_manager_attack_iteration_cap()
	await test_floating_text_pool()
	await test_death_particles_pool()
	await test_reward_manager_gold_single_count()
	await test_shop_manager_purchase()
	await test_audio_settings_persistence()
	
	print("=== 测试结束 ===")
	print("通过：%d，失败：%d" % [_passed, _failed])
	get_tree().quit(_failed > 0)

func _assert(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
		print("  [PASS] %s" % message)
	else:
		_failed += 1
		push_error("  [FAIL] %s" % message)

func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	_assert(actual == expected, "%s (期望 %s，实际 %s)" % [message, str(expected), str(actual)])

func test_player_data_leveling() -> void:
	print("\n[PlayerData] 升级逻辑")
	var pd: PlayerData = PlayerData.new()
	pd.gain_exp(pd.exp_to_next)
	_assert(pd.level == 2, "升级后等级为 2")
	_assert(pd.exp == 0, "升级后当前经验清零")
	_assert(pd.exp_to_next > 100, "下一级所需经验递增")

func test_player_data_gold() -> void:
	print("\n[PlayerData] 金币逻辑")
	var pd: PlayerData = PlayerData.new()
	pd.add_gold(100)
	_assert_eq(pd.gold, 100, "加金币后余额正确")
	pd.spend_gold(30)
	_assert_eq(pd.gold, 70, "消费后余额正确")
	_assert(not pd.spend_gold(100), "余额不足时消费失败")
	_assert_eq(pd.gold, 70, "消费失败后余额不变")

func test_player_data_combat() -> void:
	print("\n[PlayerData] 战斗数值")
	var pd: PlayerData = PlayerData.new()
	pd.max_hp = 100
	pd.hp = 100
	pd.defense = 5
	var actual: int = pd.take_damage(20)
	_assert_eq(actual, 15, "伤害结算减防正确")
	_assert_eq(pd.hp, 85, "受伤后血量正确")
	pd.heal(10)
	_assert_eq(pd.hp, 95, "治疗后血量正确")
	pd.heal(100)
	_assert_eq(pd.hp, 100, "治疗不超过最大生命")

func test_equipment_manager_basic() -> void:
	print("\n[EquipmentManager] 装备穿戴")
	var em: EquipmentManager = EquipmentManager.new()
	add_child(em)
	var equip: EquipmentData = EquipmentData.new("测试剑", EquipmentData.Type.WEAPON, EquipmentData.Rarity.COMMON, 1)
	em.add_to_inventory(equip)
	_assert_eq(em.inventory.size(), 1, "装备加入背包")
	_assert(em.equip_item(equip), "穿戴成功")
	_assert_eq(em.inventory.size(), 0, "穿戴后从背包移除")
	_assert(em.get_equipped(EquipmentData.Type.WEAPON) == equip, "已装备部位正确")
	var result: EquipmentManager.UnequipResult = em.unequip_item(EquipmentData.Type.WEAPON)
	_assert_eq(result, EquipmentManager.UnequipResult.SUCCESS, "卸下成功")
	_assert_eq(em.inventory.size(), 1, "卸下后回到背包")
	em.queue_free()

func test_equipment_manager_sell() -> void:
	print("\n[EquipmentManager] 装备出售")
	var em: EquipmentManager = EquipmentManager.new()
	add_child(em)
	var equip: EquipmentData = EquipmentData.new("测试剑", EquipmentData.Type.WEAPON, EquipmentData.Rarity.COMMON, 1)
	em.add_to_inventory(equip)
	var result: Dictionary = em.sell_item(equip)
	_assert(result.ok, "出售成功")
	_assert(result.price > 0, "出售价格大于 0")
	_assert_eq(em.inventory.size(), 0, "出售后背包清空")
	var fail: Dictionary = em.sell_item(equip)
	_assert(not fail.ok, "出售不存在的装备失败")
	em.queue_free()

func test_enemy_data_stats() -> void:
	print("\n[EnemyData] 属性生成")
	var enemy: EnemyData = EnemyData.new("史莱姆", 1, false)
	_assert(enemy.max_hp > 0, "普通怪最大生命大于 0")
	_assert(enemy.attack > 0, "普通怪攻击大于 0")
	_assert_eq(enemy.is_boss, false, "普通怪不是 Boss")
	
	var boss: EnemyData = EnemyData.new("恶龙", 10, true)
	_assert(boss.max_hp > enemy.max_hp, "Boss 生命高于普通怪")
	_assert(boss.is_boss, "Boss 标记正确")

func test_enemy_data_scaling() -> void:
	print("\n[EnemyData] 属性倍率独立生效")
	## 在等级 11 处 HP/ATK/DEF 倍率各不相同，验证三者分别使用各自常量而非共用 ATK 倍率
	var enemy: EnemyData = EnemyData.new("测试怪", 11, false)
	var hp_mult: float = 1.0 + (enemy.level - 1) * BalanceConfig.ENEMY_HP_MULTIPLIER
	var def_mult: float = 1.0 + (enemy.level - 1) * BalanceConfig.ENEMY_DEF_MULTIPLIER
	_assert_eq(enemy.max_hp, int(BalanceConfig.ENEMY_BASE_HP * hp_mult), "HP 使用 ENEMY_HP_MULTIPLIER")
	_assert_eq(enemy.defense, int((BalanceConfig.ENEMY_BASE_DEF + enemy.level * 0.3) * def_mult), "DEF 使用 ENEMY_DEF_MULTIPLIER")
	## 确认 HP 倍率确实高于 ATK 倍率（否则常量未生效）
	_assert(BalanceConfig.ENEMY_HP_MULTIPLIER > BalanceConfig.ENEMY_ATK_MULTIPLIER, "HP 成长倍率高于 ATK")
	_assert(BalanceConfig.ENEMY_DEF_MULTIPLIER < BalanceConfig.ENEMY_ATK_MULTIPLIER, "DEF 成长倍率低于 ATK")

func test_boss_mechanics() -> void:
	print("\n[BossMechanics] Boss 机制")
	var boss: EnemyData = EnemyData.new("恶龙", 10, true)
	var initial_hp: int = boss.max_hp - 50
	boss.hp = initial_hp
	var mechanics: BossMechanics = BossMechanics.new(boss)
	
	## 6 秒治疗
	mechanics.update(BalanceConfig.BOSS_HEAL_INTERVAL + 0.1)
	_assert(boss.hp > initial_hp, "Boss 治疗后血量增加")
	_assert(boss.hp <= boss.max_hp, "Boss 治疗后血量不超过上限")
	
	## 推进到狂暴触发（前面已推进 6.1 秒，再推进约 6 秒即可达到 12 秒冷却）
	for i: int in range(6):
		mechanics.update(1.0)
	_assert(mechanics.is_berserk, "Boss 进入狂暴")
	_assert(boss.attack_speed > mechanics.base_attack_speed, "狂暴时攻速提升")
	
	## 4 秒后结束狂暴
	mechanics.update(BalanceConfig.BOSS_BERSERK_DURATION + 0.1)
	_assert(not mechanics.is_berserk, "狂暴结束")

func test_skill_manager() -> void:
	print("\n[SkillManager] 技能逻辑")
	var sm: SkillManager = SkillManager.new()
	## 直接调用 _ready 中的初始化，因为 new() 不会触发 _ready
	sm._init_default_skills()
	add_child(sm)
	
	var pd: PlayerData = PlayerData.new()
	pd.max_hp = 100
	pd.hp = 50
	pd.attack = 20
	sm.player_data = pd
	
	var bm: BattleManager = BattleManager.new()
	add_child(bm)
	bm.player_data = pd
	bm.start_battle(EnemyData.new("史莱姆", 1, false))
	sm.battle_manager = bm
	
	## 能量相关
	sm.add_energy(100)
	_assert_eq(sm.energy, 100, "能量加满")
	
	var heal_skill: SkillData = sm.skills[SkillData.Type.HEAL]
	_assert(sm.can_cast(heal_skill), "有能量时可施放治疗")
	
	sm.cast_skill(heal_skill)
	_assert(pd.hp > 50, "治疗生效")
	_assert(sm.cooldowns.has(SkillData.Type.HEAL), "治疗进入冷却")
	_assert(not sm.can_cast(heal_skill), "冷却中不可施放")
	
	## 重击需要敌人
	var heavy_skill: SkillData = sm.skills[SkillData.Type.HEAVY_HIT]
	_assert(sm.cast_skill(heavy_skill), "有敌人时可施放重击")
	
	## 狂暴注入攻速倍率
	var berserk_skill: SkillData = sm.skills[SkillData.Type.BERSERK]
	sm.energy = 100
	sm.cast_skill(berserk_skill)
	_assert_eq(pd.attack_speed_multiplier, BalanceConfig.SKILL_BERSERK_MULTIPLIER, "狂暴倍率写入 PlayerData")
	
	## 模拟时间结束狂暴
	sm._process(BalanceConfig.SKILL_BERSERK_DURATION + 0.1)
	_assert_eq(pd.attack_speed_multiplier, 1.0, "狂暴结束后倍率恢复")
	
	sm.queue_free()
	bm.queue_free()

func test_save_round_trip() -> void:
	print("\n[SaveManager] 存档序列化往返")
	var pd: PlayerData = PlayerData.new()
	pd.add_gold(1234)
	pd.gain_exp(pd.exp_to_next)
	pd.bonus_attack = 5
	pd.recalc_stats()

	var em: EquipmentManager = EquipmentManager.new()
	add_child(em)
	var equip: EquipmentData = EquipmentData.new("测试剑", EquipmentData.Type.WEAPON, EquipmentData.Rarity.RARE, 3)
	em.add_to_inventory(equip)

	var stage: StageManager = StageManager.new()
	add_child(stage)
	stage.current_enemy_level = 5

	var sm: SaveManager = SaveManager.new()
	var save_path: String = sm.SAVE_PATH
	var backup_path: String = save_path + ".test_backup"

	## 备份现有存档（如有），避免污染
	var dir: DirAccess = DirAccess.open("user://")
	if dir != null and FileAccess.file_exists(save_path):
		dir.copy(save_path, backup_path)
		dir.remove(save_path)

	var save_ok: bool = sm.save_game(pd, em, stage, null, null, null, null)
	_assert(save_ok, "存档写入成功")

	var pd2: PlayerData = PlayerData.new()
	var em2: EquipmentManager = EquipmentManager.new()
	add_child(em2)
	var stage2: StageManager = StageManager.new()
	add_child(stage2)
	var load_ok: bool = sm.load_game(pd2, em2, stage2, null, null, null, null)
	_assert(load_ok, "存档读取成功")
	_assert_eq(pd2.gold, 1234, "金币往返正确")
	_assert_eq(pd2.level, 2, "等级往返正确")
	_assert_eq(stage2.current_enemy_level, 5, "关卡往返正确")
	_assert_eq(em2.inventory.size(), 1, "背包装备往返正确")
	var loaded: EquipmentData = em2.inventory[0]
	_assert_eq(loaded.equip_name, "测试剑", "装备名称往返正确")
	_assert_eq(loaded.rarity, EquipmentData.Rarity.RARE, "装备稀有度往返正确")

	## 清理并恢复备份
	if dir != null:
		if FileAccess.file_exists(save_path):
			dir.remove(save_path)
		if FileAccess.file_exists(save_path + ".tmp"):
			dir.remove(save_path + ".tmp")
		if FileAccess.file_exists(save_path + ".bak"):
			dir.remove(save_path + ".bak")
		if FileAccess.file_exists(backup_path):
			dir.copy(backup_path, save_path)
			dir.remove(backup_path)

	em.queue_free()
	stage.queue_free()
	em2.queue_free()
	stage2.queue_free()

func test_save_v3_migration() -> void:
	print("\n[SaveManager] v3 → v4 存档迁移")
	var sm: SaveManager = SaveManager.new()
	var save_path: String = sm.SAVE_PATH
	var backup_path: String = save_path + ".test_backup"

	## 备份现有存档（如有）
	var dir: DirAccess = DirAccess.open("user://")
	if dir != null and FileAccess.file_exists(save_path):
		dir.copy(save_path, backup_path)
		dir.remove(save_path)

	## 手写一份 v3 格式存档：stage 为裸 int，equipped/inventory 在顶层。
	var equip_dict: Dictionary = {"0": {"name": "旧剑", "type": 0, "rarity": 1, "level": 2, "attack": 5}}
	var v3_data: Dictionary = {
		"version": 3,
		"timestamp": Time.get_unix_time_from_system(),
		"player": {"level": 3, "exp": 10, "gold": 500, "hp": 80, "bonus_attack": 1},
		"stage": 7,
		"equipped": equip_dict,
		"inventory": [{"name": "旧盔", "type": 1, "rarity": 0, "level": 1, "defense": 2}],
		"skill": {"energy": 40, "cooldowns": {}, "berserk_timer": 0.0, "berserk_multiplier": 1.0},
		"shop": {"exp_potion_charges": 2},
		"achievements": {"completed": ["first_blood"]},
		"quests": {"last_refresh_day": -1, "free_refresh_used": false, "quests": []}
	}
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(v3_data))
	file.close()

	var pd: PlayerData = PlayerData.new()
	var em: EquipmentManager = EquipmentManager.new()
	add_child(em)
	var stage: StageManager = StageManager.new()
	add_child(stage)
	var ach: AchievementManager = AchievementManager.new()
	add_child(ach)
	var quest: QuestManager = QuestManager.new()
	add_child(quest)
	var load_ok: bool = sm.load_game(pd, em, stage, ach, quest, null, null)
	_assert(load_ok, "v3 存档迁移后加载成功")
	_assert_eq(pd.gold, 500, "迁移后玩家金币正确")
	_assert_eq(pd.level, 3, "迁移后玩家等级正确")
	_assert_eq(stage.current_enemy_level, 7, "迁移后关卡正确")
	_assert_eq(em.inventory.size(), 1, "迁移后背包装备正确")
	_assert_eq(em.get_equipped(EquipmentData.Type.WEAPON).equip_name, "旧剑", "迁移后已装备武器正确")

	## 清理并恢复备份
	if dir != null:
		if FileAccess.file_exists(save_path):
			dir.remove(save_path)
		if FileAccess.file_exists(save_path + ".tmp"):
			dir.remove(save_path + ".tmp")
		if FileAccess.file_exists(save_path + ".bak"):
			dir.remove(save_path + ".bak")
		if FileAccess.file_exists(backup_path):
			dir.copy(backup_path, save_path)
			dir.remove(backup_path)

	em.queue_free()
	stage.queue_free()
	ach.queue_free()
	quest.queue_free()

func test_save_checksum_and_validation() -> void:
	print("\n[SaveManager] 校验和与数值校验")
	var pd: PlayerData = PlayerData.new()
	pd.level = 5
	pd.gold = 1000
	pd.hp = 50

	var em: EquipmentManager = EquipmentManager.new()
	add_child(em)
	var stage: StageManager = StageManager.new()
	add_child(stage)

	var sm: SaveManager = SaveManager.new()
	var save_path: String = sm.SAVE_PATH
	var backup_path: String = save_path + ".test_backup"

	var dir: DirAccess = DirAccess.open("user://")
	if dir != null and FileAccess.file_exists(save_path):
		dir.copy(save_path, backup_path)
		dir.remove(save_path)

	_assert(sm.save_game(pd, em, stage, null, null, null, null), "存档写入成功")

	## 篡改金币后加载：校验和应不匹配，但加载仍应成功（防损坏而非防作弊）
	## 新版存档已加密，需先解密、篡改、再加密写回
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	var encrypted_content: String = file.get_as_text()
	file.close()
	var marker_len: int = SaveManager.ENCRYPTION_MARKER.length()
	var cipher_text: String = encrypted_content.substr(marker_len)
	var json_text: String = sm._decrypt(cipher_text)
	json_text = json_text.replace('"gold":1000', '"gold":999999')
	var tampered_encrypted: String = SaveManager.ENCRYPTION_MARKER + sm._encrypt(json_text)
	file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(tampered_encrypted)
	file.close()

	var pd2: PlayerData = PlayerData.new()
	var em2: EquipmentManager = EquipmentManager.new()
	add_child(em2)
	var stage2: StageManager = StageManager.new()
	add_child(stage2)
	var load_ok: bool = sm.load_game(pd2, em2, stage2, null, null, null, null)
	_assert(load_ok, "篡改后仍可加载（容错）")
	_assert_eq(pd2.gold, 999999, "篡改金币被加载（演示校验和警告）")

	## 验证非法数值会被钳制
	var invalid_data: Dictionary = {
		"version": BalanceConfig.SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"player": {"level": -10, "exp": -100, "gold": -5000, "hp": -5},
		"stage": {"level": -3},
		"equipment": {"equipped": {}, "inventory": []},
		"skill": {"energy": -50, "cooldowns": {}, "berserk_timer": -1.0, "berserk_multiplier": -2.0},
		"shop": {"exp_potion_charges": -5},
		"achievements": {"completed": []},
		"quests": {"last_refresh_day": -1, "free_refresh_used": false, "quests": []}
	}
	file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(invalid_data))
	file.close()

	var pd3: PlayerData = PlayerData.new()
	var em3: EquipmentManager = EquipmentManager.new()
	add_child(em3)
	var stage3: StageManager = StageManager.new()
	add_child(stage3)
	load_ok = sm.load_game(pd3, em3, stage3, null, null, null, null)
	_assert(load_ok, "非法数值存档加载成功并被修复")
	_assert_eq(pd3.level, 1, "非法等级被钳制到 1")
	_assert_eq(pd3.gold, 0, "非法金币被钳制到 0")
	_assert_eq(pd3.hp, 1, "非法 HP 被钳制到 1")
	_assert_eq(stage3.current_enemy_level, 1, "非法关卡被钳制到 1")

	## 清理并恢复备份
	if dir != null:
		if FileAccess.file_exists(save_path):
			dir.remove(save_path)
		if FileAccess.file_exists(save_path + ".tmp"):
			dir.remove(save_path + ".tmp")
		if FileAccess.file_exists(save_path + ".bak"):
			dir.remove(save_path + ".bak")
		if FileAccess.file_exists(backup_path):
			dir.copy(backup_path, save_path)
			dir.remove(backup_path)

	em.queue_free()
	stage.queue_free()
	em2.queue_free()
	stage2.queue_free()
	em3.queue_free()
	stage3.queue_free()

func test_save_backup_rotation() -> void:
	print("\n[SaveManager] 存档备份轮转")
	var pd: PlayerData = PlayerData.new()
	var em: EquipmentManager = EquipmentManager.new()
	add_child(em)
	var stage: StageManager = StageManager.new()
	add_child(stage)

	var sm: SaveManager = SaveManager.new()
	var dir: DirAccess = DirAccess.open("user://")

	## 清理旧备份，避免污染
	var cleanup_paths: PackedStringArray = [sm.SAVE_PATH, sm.TEMP_PATH]
	cleanup_paths.append_array(SaveManager.BACKUP_PATHS)
	for path: String in cleanup_paths:
		if FileAccess.file_exists(path):
			dir.remove(path)

	## 连续保存 4 次（首次无旧存档可备份），应生成 .bak、.bak1、.bak2 三份历史备份
	for i: int in range(4):
		pd.gold = i * 100
		_assert(sm.save_game(pd, em, stage, null, null, null, null), "第 %d 次存档成功" % (i + 1))

	for path: String in SaveManager.BACKUP_PATHS:
		_assert(FileAccess.file_exists(path), "备份文件存在：%s" % path)

	## 清理
	cleanup_paths = [sm.SAVE_PATH, sm.TEMP_PATH]
	cleanup_paths.append_array(SaveManager.BACKUP_PATHS)
	for path: String in cleanup_paths:
		if FileAccess.file_exists(path):
			dir.remove(path)

	em.queue_free()
	stage.queue_free()

func test_stage_manager_validation() -> void:
	print("\n[StageManager] 关卡数值校验")
	var stage: StageManager = StageManager.new()
	add_child(stage)
	stage.deserialize({"level": -5})
	_assert_eq(stage.current_enemy_level, 1, "负关卡被钳制到 1")
	stage.deserialize({"level": 999999})
	_assert_eq(stage.current_enemy_level, BalanceConfig.MAX_STAGE, "超上限关卡被钳制到 MAX_STAGE")
	stage.queue_free()

func test_battle_manager_attack_iteration_cap() -> void:
	print("\n[BattleManager] 攻击循环迭代上限")
	var pd: PlayerData = PlayerData.new()
	pd.crit_rate = 0.0
	pd.attack_speed = 100.0  ## 远超正常上限，验证单帧不会无限结算

	var enemy: EnemyData = EnemyData.new("史莱姆", 1, false)
	enemy.max_hp = 99999
	enemy.hp = enemy.max_hp

	var bm: BattleManager = BattleManager.new()
	add_child(bm)
	bm.player_data = pd
	bm.start_battle(enemy)
	bm.player_attack_timer = 10.0

	var initial_hp: int = enemy.hp
	bm._process(1.0)
	var expected_damage: int = 5 * maxi(1, pd.attack - enemy.defense)
	_assert_eq(initial_hp - enemy.hp, expected_damage, "单帧攻击次数被限制为 MAX_ATTACK_ITERATIONS")
	bm.queue_free()

func test_floating_text_pool() -> void:
	print("\n[FloatingTextManager] 飘字对象池")
	var ftm: FloatingTextManager = FloatingTextManager.new()
	add_child(ftm)

	## 连续创建未超过池容量，应全部从池中取出
	for i: int in range(5):
		ftm.show_damage(Vector2.ZERO, i + 1, true, false)
	_assert_eq(ftm._active.size(), 5, "活跃飘字数量等于创建数")
	_assert_eq(ftm._pool.size(), ftm.POOL_SIZE - 5, "池内剩余数量正确")

	## 超过池容量时，应复用最旧的活跃对象而非无限增长
	for i: int in range(ftm.POOL_SIZE + 10):
		ftm.show_damage(Vector2.ZERO, i + 1, true, false)
	_assert_eq(ftm._active.size(), ftm.POOL_SIZE, "活跃飘字不超过池容量")
	_assert(ftm._pool.is_empty(), "池被耗尽时无剩余对象")

	## 立即释放，避免测试退出时队列释放尚未执行导致泄漏报告
	ftm.free()

func test_death_particles_pool() -> void:
	print("\n[DeathParticles] 死亡粒子对象池")
	var parent: Node = Node.new()
	add_child(parent)

	## 生成 3 个粒子
	for i: int in range(3):
		DeathParticles.spawn(parent, Vector2.ZERO)
	_assert_eq(parent.get_child_count(), 3, "生成 3 个粒子")

	## 等待粒子生命周期 + 回收延时后，粒子应自动回到对象池
	var scene: PackedScene = DeathParticles.DeathParticlesScene
	var temp_particle: CPUParticles2D = scene.instantiate()
	var particle_lifetime: float = temp_particle.lifetime
	temp_particle.free()
	await get_tree().create_timer(particle_lifetime + 0.6).timeout
	_assert_eq(parent.get_child_count(), 0, "粒子生命周期结束后从父节点移除")
	_assert_eq(DeathParticles._pool.size(), 3, "粒子回收到对象池")

	## 再次生成应复用池中对象
	var reused: CPUParticles2D = DeathParticles.spawn(parent, Vector2.ZERO)
	_assert_eq(DeathParticles._pool.size(), 2, "复用池中粒子后池数量减少")
	_assert_eq(parent.get_child_count(), 1, "复用粒子已挂回父节点")

	## 清理静态对象池，避免 headless 退出时泄漏
	for p: CPUParticles2D in parent.get_children():
		p.free()
	for p: CPUParticles2D in DeathParticles._pool:
		p.free()
	DeathParticles._pool.clear()

	parent.free()

func test_reward_manager_gold_single_count() -> void:
	print("\n[RewardManager] 击败敌人金币只累计一次")
	var pd: PlayerData = PlayerData.new()
	var stage: StageManager = StageManager.new()
	add_child(stage)
	stage.current_enemy_level = 1
	var rm: RewardManager = RewardManager.new()
	add_child(rm)
	rm.player_data = pd
	rm.stage_manager = stage
	rm.equipment_manager = null
	rm.shop_manager = null

	var enemy: EnemyData = EnemyData.new("史莱姆", 1, false)
	var gold_before: int = pd.total_gold_earned
	rm._on_enemy_defeated(enemy)
	## add_gold 内部已累加 total_gold_earned，reward_manager 不得再次累加，否则翻倍
	_assert_eq(pd.total_gold_earned, gold_before + enemy.gold_reward, "累计金币只增加一次掉落金币")
	stage.queue_free()
	rm.queue_free()

func test_shop_manager_purchase() -> void:
	print("\n[ShopManager] 购买原子性")
	var pd: PlayerData = PlayerData.new()
	pd.add_gold(1000)
	pd.max_hp = 100
	pd.hp = 30

	var shop: ShopManager = ShopManager.new()
	add_child(shop)
	shop.player_data = pd

	## 成功购买生命药水：扣款并恢复生命
	var gold_before: int = pd.gold
	_assert(shop.purchase("health_potion"), "生命药水购买成功")
	_assert_eq(pd.gold, gold_before - 50, "购买后金币正确扣减")
	_assert(pd.hp > 30, "生命药水生效")

	## 满血时再次购买应失败且不扣款
	pd.hp = pd.max_hp
	gold_before = pd.gold
	_assert(not shop.purchase("health_potion"), "满血时购买失败")
	_assert_eq(pd.gold, gold_before, "前置校验失败时不扣款")

	## 金币不足时购买应失败
	pd.gold = 10
	_assert(not shop.purchase("attack_boost"), "金币不足时购买失败")

	shop.queue_free()

func test_audio_settings_persistence() -> void:
	print("\n[AudioManager] 音频设置持久化")
	var scene: PackedScene = load("res://scenes/audio_manager.tscn")
	var audio: AudioManager = scene.instantiate() as AudioManager
	add_child(audio)

	## 先写入非默认状态（关闭不会触发播放，适合 headless 测试）
	audio.set_bgm_enabled(false)
	audio.set_sfx_enabled(true)
	_assert_eq(audio.bgm_enabled, false, "BGM 已关闭")
	_assert_eq(audio.sfx_enabled, true, "SFX 已开启")

	## 新建实例模拟重启后读取配置
	var audio2: AudioManager = scene.instantiate() as AudioManager
	add_child(audio2)
	_assert_eq(audio2.bgm_enabled, false, "重启后 BGM 保持关闭")
	_assert_eq(audio2.sfx_enabled, true, "重启后 SFX 保持开启")

	## 通过直接字段赋值 + 保存来恢复默认，避免 headless 下播放 BGM 产生音频泄漏
	audio2.bgm_enabled = true
	audio2.sfx_enabled = true
	audio2._save_settings()

	## 再次新建实例验证已恢复默认
	var audio3: AudioManager = scene.instantiate() as AudioManager
	add_child(audio3)
	_assert_eq(audio3.bgm_enabled, true, "BGM 恢复默认")
	_assert_eq(audio3.sfx_enabled, true, "SFX 恢复默认")

	## 清理测试配置文件，避免污染用户设置
	var settings_path: String = audio3.SETTINGS_PATH
	if FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(settings_path)

	audio.queue_free()
	audio2.queue_free()
	audio3.queue_free()
