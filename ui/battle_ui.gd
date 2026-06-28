extends CanvasLayer

@export var equipment_ui: CanvasLayer
@export var shop_ui: CanvasLayer
@export var stats_ui: CanvasLayer
@export var achievement_ui: CanvasLayer
@export var achievement_toast: CanvasLayer
@export var quest_ui: CanvasLayer

var player_data: PlayerData
var battle_manager: BattleManager

@onready var main_margin: MarginContainer = %MainMargin
@onready var root_vbox: VBoxContainer = %RootVBox
@onready var top_bar: HBoxContainer = %TopBar
@onready var player_level: Label = %PlayerLevel
@onready var stage_label: Label = %StageLabel
@onready var gold_label: Label = %GoldLabel
@onready var player_hp: ProgressBar = %HPBar
@onready var exp_bar: ProgressBar = %EXPBar
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var enemy_name: Label = %EnemyName
@onready var enemy_level: Label = %EnemyLevel
@onready var enemy_hp: ProgressBar = %EnemyHPBar
@onready var side_panel: VBoxContainer = %SidePanel
@onready var skill_bar: HBoxContainer = %SkillBar
@onready var log_panel: PanelContainer = %LogPanel
@onready var log_text: RichTextLabel = %LogText
@onready var log_text_mobile: RichTextLabel = %LogTextMobile
@onready var floating_log_panel: PanelContainer = %FloatingLogPanel
@onready var toggle_log_button: Button = %ToggleLogButton
@onready var boss_button: Button = %BossButton
@onready var bottom_bar: HBoxContainer = %BottomBar
@onready var skill_panel: Control = %SkillPanel

const RESPONSIVE_WIDTH_THRESHOLD: int = 1000
const NARROW_WIDTH_THRESHOLD: int = 700

var skill_buttons: Dictionary = {}
var _skill_by_type: Dictionary = {}
var _current_log: RichTextLabel
var _stats_dirty: bool = false

func _mark_stats_dirty() -> void:
	_stats_dirty = true

func _ready() -> void:
	battle_manager = Services.battle_manager
	player_data = Services.player_data

	## 各子 UI 由场景通过 @export NodePath 接线，无需代码兜底查找。

	_current_log = log_text

	if player_data:
		## stats_changed 高频触发，用脏标记在 _process 中合并刷新，避免每帧多次全量重绘。
		EventBus.stats_changed.connect(_mark_stats_dirty)
		EventBus.player_leveled_up.connect(_on_level_up)
	EventBus.enemy_spawned.connect(_on_enemy_spawned)
	EventBus.message_logged.connect(_log_message)
	EventBus.stage_changed.connect(_on_stage_changed)
	EventBus.achievement_unlocked.connect(_on_achievement_unlocked)
	if battle_manager:
		battle_manager.player_attacked.connect(_on_player_attacked)
		battle_manager.enemy_attacked.connect(_on_enemy_attacked)
		battle_manager.enemy_died.connect(_on_enemy_defeated)

	_init_progress_bars()
	_init_skill_bar()
	UIHelpers.add_gold_icon(gold_label, Vector2(14, 14))
	_update_player_ui()
	_apply_responsive_layout()

	get_viewport().size_changed.connect(_on_viewport_size_changed)

	_log_message(tr("UI_LOG_WELCOME"))
	_log_message(tr("UI_LOG_TIP_BATTLE"))
	_log_message(tr("UI_LOG_TIP_BOSS"))
	
	## 若 GameManager 在 BattleUI._ready 之前已生成敌人，手动同步一次 UI
	if battle_manager and battle_manager.enemy_data != null:
		_on_enemy_spawned(battle_manager.enemy_data)
		_update_boss_button()
	
	## 调试面板：按 F12 显示/隐藏
	var debug_scene: PackedScene = preload("res://ui/debug_panel.tscn")
	var debug_panel: CanvasLayer = debug_scene.instantiate() as CanvasLayer
	add_child(debug_panel)
	
	_show_tutorial_if_needed()

func _unhandled_input(event: InputEvent) -> void:
	## 暂停或有子界面打开时，战斗快捷键不应响应
	if get_tree().paused:
		return
	if _any_sub_ui_visible():
		return
	
	## 使用 is_action_just_pressed 避免长按/手柄连发导致面板/技能反复切换
	if event.is_action_pressed("open_equipment", true, true):
		_on_equipment_button_pressed()
	elif event.is_action_pressed("open_shop", true, true):
		_on_shop_button_pressed()
	elif event.is_action_pressed("open_stats", true, true):
		_on_stats_button_pressed()
	elif event.is_action_pressed("open_achievements", true, true):
		_on_achievement_button_pressed()
	elif event.is_action_pressed("open_quests", true, true):
		_on_quest_button_pressed()
	elif event.is_action_pressed("cast_skill_1", true, true):
		_cast_skill_by_index(0)
	elif event.is_action_pressed("cast_skill_2", true, true):
		_cast_skill_by_index(1)
	elif event.is_action_pressed("cast_skill_3", true, true):
		_cast_skill_by_index(2)

func _any_sub_ui_visible() -> bool:
	for sub_ui: CanvasLayer in get_tree().get_nodes_in_group("sub_ui"):
		if sub_ui.visible:
			return true
	return false

func _cast_skill_by_index(index: int) -> void:
	if Services.skill_manager == null:
		return
	var skills: Array[SkillData] = Services.skill_manager.skills
	if index < 0 or index >= skills.size():
		return
	var skill: SkillData = skills[index]
	if not Services.skill_manager.can_cast(skill):
		return
	Services.skill_manager.cast_skill(skill)

func _show_tutorial_if_needed() -> void:
	if player_data == null or player_data.level > 1 or player_data.play_time_seconds > 0:
		return
	var tutorial_scene: PackedScene = load("res://ui/tutorial_overlay.tscn")
	var tutorial: CanvasLayer = tutorial_scene.instantiate() as CanvasLayer
	add_child(tutorial)
	var steps: Array[Dictionary] = [
		{"text": tr("UI_TUTORIAL_WELCOME"), "target": null},
		{"text": tr("UI_TUTORIAL_SKILL"), "target": skill_panel},
		{"text": tr("UI_TUTORIAL_BUTTONS"), "target": bottom_bar},
		{"text": tr("UI_TUTORIAL_BOSS"), "target": boss_button},
	]
	tutorial.start(steps)

func _on_viewport_size_changed() -> void:
	_apply_responsive_layout()

func _apply_responsive_layout() -> void:
	var window_size: Vector2i = DisplayServer.window_get_size()
	var width: int = window_size.x
	var height: int = window_size.y
	var is_narrow: bool = width < RESPONSIVE_WIDTH_THRESHOLD
	var is_tiny: bool = width < NARROW_WIDTH_THRESHOLD or height < 500

	if is_narrow:
		## 窄屏时隐藏日志面板（使用浮动日志），但保留技能栏可见
		log_panel.visible = false
		side_panel.visible = true
		side_panel.custom_minimum_size.x = 0
		toggle_log_button.visible = true
		_current_log = log_text_mobile
		## 在极窄屏下底部按钮只显示图标/首字
		_set_bottom_button_compact(is_tiny)
	else:
		log_panel.visible = true
		side_panel.visible = true
		side_panel.custom_minimum_size.x = 160
		toggle_log_panel(false)
		toggle_log_button.visible = false
		_current_log = log_text
		_set_bottom_button_compact(false)

func _set_bottom_button_compact(compact: bool) -> void:
	var texts: PackedStringArray = [tr("UI_BATTLE_BOSS"), tr("UI_BATTLE_EQUIPMENT"), tr("UI_BATTLE_SHOP"), tr("UI_BATTLE_STATS"), tr("UI_BATTLE_ACHIEVEMENTS"), tr("UI_BATTLE_QUESTS")]
	var compact_texts: PackedStringArray = ["Boss", tr("UI_BATTLE_EQUIPMENT"), tr("UI_BATTLE_SHOP"), tr("UI_BATTLE_STATS"), tr("UI_BATTLE_ACHIEVEMENTS"), tr("UI_BATTLE_QUESTS")]
	var buttons: Array[Button] = [
		boss_button,
		%EquipmentButton,
		%ShopButton,
		%StatsButton,
		%AchievementButton,
		%QuestButton
	]
	for i: int in range(buttons.size()):
		buttons[i].text = compact_texts[i] if compact else texts[i]

func _toggle_log_panel() -> void:
	floating_log_panel.visible = not floating_log_panel.visible

func toggle_log_panel(show: bool) -> void:
	floating_log_panel.visible = show

func _on_toggle_log_pressed() -> void:
	_toggle_log_panel()

func _init_progress_bars() -> void:
	_set_bar_colors(player_hp, Color(0.9, 0.22, 0.22, 1), Color(0.15, 0.08, 0.08, 1))
	_set_bar_colors(exp_bar, Color(0.2, 0.75, 0.95, 1), Color(0.08, 0.12, 0.15, 1))
	_set_bar_colors(energy_bar, Color(0.95, 0.8, 0.15, 1), Color(0.15, 0.12, 0.05, 1))
	_set_bar_colors(enemy_hp, Color(0.9, 0.22, 0.22, 1), Color(0.15, 0.08, 0.08, 1))

func _set_bar_colors(bar: ProgressBar, fg: Color, bg: Color) -> void:
	var fg_style: StyleBoxFlat = bar.get_theme_stylebox("fill").duplicate()
	var bg_style: StyleBoxFlat = bar.get_theme_stylebox("background").duplicate()
	fg_style.bg_color = fg
	bg_style.bg_color = bg
	bar.add_theme_stylebox_override("fill", fg_style)
	bar.add_theme_stylebox_override("background", bg_style)

func _init_skill_bar() -> void:
	if Services.skill_manager == null:
		return
	var skill_manager: SkillManager = Services.skill_manager
	skill_manager.energy_changed.connect(_on_energy_changed)
	skill_manager.skill_casted.connect(_on_skill_casted)
	skill_manager.cooldown_updated.connect(_on_cooldown_updated)

	for skill: SkillData in skill_manager.skills:
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(44, 36)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.text = "%s\n%d" % [tr(skill.skill_name), skill.energy_cost]
		btn.pressed.connect(_on_skill_button_pressed.bind(skill))
		btn.mouse_entered.connect(UIHelpers.play_ui_hover)
		skill_buttons[skill.type] = btn
		_skill_by_type[skill.type] = skill
		skill_bar.add_child(btn)

func _update_player_ui() -> void:
	if player_data == null:
		return
	player_level.text = "Lv.%d" % player_data.level
	player_hp.max_value = player_data.max_hp
	player_hp.value = player_data.hp
	exp_bar.max_value = player_data.exp_to_next
	exp_bar.value = player_data.exp
	gold_label.text = "%s" % UIHelpers.format_number(player_data.gold)
	stage_label.text = Services.stage_manager.get_stage_display() if Services.stage_manager else tr("UI_BATTLE_STAGE")

func _on_enemy_spawned(enemy: EnemyData) -> void:
	enemy_name.text = enemy.name
	enemy_level.text = "Lv.%d %s" % [enemy.level, "[Boss]" if enemy.is_boss else ""]
	enemy_hp.value = 100.0
	_update_boss_button()

func _on_enemy_defeated(enemy: EnemyData) -> void:
	if enemy.is_boss:
		_log_message(tr("UI_LOG_BOSS_DEFEATED"))

func _on_player_attacked(damage: int, is_crit: bool) -> void:
	## 玩家数值变动已由 stats_changed → 脏标记驱动刷新，此处仅记录战斗日志。
	var crit_text: String = tr("UI_LOG_CRIT") if is_crit else ""
	_log_message(tr("UI_LOG_PLAYER_DAMAGE") % [crit_text, damage])

func _on_enemy_attacked(damage: int, is_crit: bool) -> void:
	var crit_text: String = tr("UI_LOG_ENEMY_CRIT") if is_crit else ""
	_log_message(tr("UI_LOG_ENEMY_DAMAGE") % [crit_text, damage])

func _on_level_up(new_level: int) -> void:
	_log_message(tr("UI_LOG_LEVEL_UP") % new_level)

func _on_stage_changed(stage: int) -> void:
	stage_label.text = tr("UI_STAGE_FORMAT") % stage
	_update_boss_button()

func _on_energy_changed(current: int, maximum: int) -> void:
	energy_bar.max_value = maximum
	energy_bar.value = current
	_update_skill_buttons()

func _on_skill_casted(skill: SkillData) -> void:
	_log_message(tr("UI_LOG_SKILL_CAST") % tr(skill.skill_name))
	_update_skill_button(skill.type)

func _on_cooldown_updated(skill_type: int, _remaining: float) -> void:
	_update_skill_button(skill_type)

func _update_skill_buttons() -> void:
	for type: int in skill_buttons.keys():
		_update_skill_button(type)

func _update_skill_button(type: int) -> void:
	if Services.skill_manager == null:
		return
	var btn: Button = skill_buttons.get(type)
	var skill: SkillData = _skill_by_type.get(type)
	if btn == null or skill == null:
		return
	var sm: SkillManager = Services.skill_manager
	var cd: float = sm.get_remaining_cooldown(type)
	btn.disabled = not sm.can_cast(skill)
	if cd > 0.0:
		btn.text = "%s\n%.1fs" % [tr(skill.skill_name), cd]
	else:
		btn.text = "%s\n%d" % [tr(skill.skill_name), skill.energy_cost]
	
	## 可用高亮
	if not btn.disabled:
		btn.add_theme_color_override("font_color", Color(1, 1, 0.8, 1))
	else:
		btn.remove_theme_color_override("font_color")

func _process(_delta: float) -> void:
	## 合并本帧内多次 stats_changed 为一次全量刷新。
	if _stats_dirty:
		_stats_dirty = false
		_update_player_ui()
	if battle_manager and battle_manager.enemy_data:
		var enemy: EnemyData = battle_manager.enemy_data
		enemy_hp.value = float(enemy.hp) / float(enemy.max_hp) * 100.0

func _log_message(text: String) -> void:
	if _current_log:
		_current_log.text += text + "\n"
		_current_log.scroll_to_line(_current_log.get_line_count() - 1)

func _on_boss_button_pressed() -> void:
	UIHelpers.play_ui_click()
	if Services.stage_manager:
		Services.stage_manager.challenge_boss()

func _on_equipment_button_pressed() -> void:
	UIHelpers.play_ui_click()
	if equipment_ui:
		equipment_ui.show_equipment()
		visible = false

func _on_shop_button_pressed() -> void:
	UIHelpers.play_ui_click()
	if shop_ui:
		shop_ui.show_shop()
		visible = false

func _on_stats_button_pressed() -> void:
	UIHelpers.play_ui_click()
	if stats_ui:
		stats_ui.show_stats()
		visible = false

func _on_achievement_button_pressed() -> void:
	UIHelpers.play_ui_click()
	if achievement_ui:
		achievement_ui.show_achievements()
		visible = false

func _on_quest_button_pressed() -> void:
	UIHelpers.play_ui_click()
	if quest_ui:
		quest_ui.show_quests()
		visible = false

func _on_skill_button_pressed(skill: SkillData) -> void:
	UIHelpers.play_ui_click()
	if Services.skill_manager:
		Services.skill_manager.cast_skill(skill)

func _on_achievement_unlocked(achievement: AchievementData) -> void:
	if achievement_toast:
		achievement_toast.show_achievement(achievement)

func show_battle() -> void:
	visible = true

func _update_boss_button() -> void:
	if Services.stage_manager == null:
		return
	var stage_manager: StageManager = Services.stage_manager
	var can_challenge: bool = stage_manager.current_enemy_level >= stage_manager.boss_unlock_level and not stage_manager.is_fighting_boss
	boss_button.disabled = not can_challenge
	if stage_manager.is_fighting_boss:
		boss_button.text = tr("UI_BATTLE_BOSS_FIGHTING")
	elif can_challenge:
		boss_button.text = tr("UI_BATTLE_BOSS")
	else:
		boss_button.text = tr("UI_BATTLE_BOSS_UNLOCK") % stage_manager.boss_unlock_level


