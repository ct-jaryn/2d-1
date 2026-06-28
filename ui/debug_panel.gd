extends CanvasLayer

## 游戏内调试面板：按 F12 显示/隐藏
## 显示 FPS、玩家/敌人属性、关卡信息，并提供手动存档/读档/测试按钮。

const MAX_LOG_LINES: int = 50

@onready var panel: PanelContainer = %Panel
@onready var fps_label: Label = %FPSLabel
@onready var player_label: Label = %PlayerLabel
@onready var enemy_label: Label = %EnemyLabel
@onready var stage_label: Label = %StageLabel
@onready var log_text: RichTextLabel = %LogText
@onready var save_button: Button = %SaveButton
@onready var load_button: Button = %LoadButton
@onready var delete_button: Button = %DeleteButton
@onready var gold_button: Button = %GoldButton
@onready var level_button: Button = %LevelButton
@onready var kill_button: Button = %KillButton

var _log_history: PackedStringArray = []
var _last_fps: int = 0

func _ready() -> void:
	visible = false
	_connect_buttons()
	EventBus.message_logged.connect(_on_message_logged)
	_refresh_static_info()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug", true, true):
		toggle()

func toggle() -> void:
	visible = not visible
	if visible:
		_refresh_static_info()

func _process(_delta: float) -> void:
	if not visible:
		return
	var fps: int = Engine.get_frames_per_second()
	if fps != _last_fps:
		_last_fps = fps
		fps_label.text = "FPS: %d" % fps
	_refresh_dynamic_info()

func _connect_buttons() -> void:
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	gold_button.pressed.connect(_on_gold_pressed)
	level_button.pressed.connect(_on_level_pressed)
	kill_button.pressed.connect(_on_kill_pressed)

func _refresh_static_info() -> void:
	_log_text()
	_refresh_dynamic_info()

func _refresh_dynamic_info() -> void:
	var pd: PlayerData = Services.player_data
	if pd != null:
		player_label.text = (
			tr("UI_DEBUG_PLAYER_FORMAT") %
			[pd.level, pd.hp, pd.max_hp, pd.attack, pd.defense, pd.attack_speed, UIHelpers.format_number(pd.gold)]
		)
	else:
		player_label.text = tr("UI_PLAYER_DATA_NO_INIT")

	var bm: BattleManager = Services.battle_manager
	if bm != null and bm.enemy_data != null:
		var enemy: EnemyData = bm.enemy_data
		enemy_label.text = (
			tr("UI_DEBUG_ENEMY_FORMAT") %
			[enemy.level, enemy.name, enemy.hp, enemy.max_hp, enemy.attack, enemy.defense,
			 enemy.attack_speed, tr("UI_DEBUG_ENEMY_BOSS") if enemy.is_boss else ""]
		)
	else:
		enemy_label.text = tr("UI_ENEMY_NONE")

	var sm: StageManager = Services.stage_manager
	if sm != null:
		stage_label.text = tr("UI_DEBUG_STAGE_FORMAT") % sm.get_stage_display()
	else:
		stage_label.text = tr("UI_STAGE_NONE")

func _on_message_logged(message: String) -> void:
	_log_history.append(message)
	if _log_history.size() > MAX_LOG_LINES:
		_log_history.remove_at(0)
	_log_text()

func _log_text() -> void:
	if log_text == null:
		return
	log_text.text = "\n".join(_log_history)
	log_text.scroll_to_line(log_text.get_line_count() - 1)

func _on_save_pressed() -> void:
	var gm: GameManager = Services.game_manager
	if gm != null and gm.save_manager != null:
		gm._save_game()
		EventBus.message_logged.emit(tr("UI_DEBUG_SAVE_DONE"))

func _on_load_pressed() -> void:
	var gm: GameManager = Services.game_manager
	if gm != null:
		gm._load_save()
		EventBus.message_logged.emit(tr("UI_DEBUG_LOAD_DONE"))

func _on_delete_pressed() -> void:
	var gm: GameManager = Services.game_manager
	if gm != null and gm.save_manager != null:
		gm.save_manager.delete_save()
		EventBus.message_logged.emit(tr("UI_DEBUG_DELETE_DONE"))

func _on_gold_pressed() -> void:
	var pd: PlayerData = Services.player_data
	if pd != null:
		pd.add_gold(10000)
		EventBus.message_logged.emit(tr("UI_DEBUG_GOLD_DONE"))

func _on_level_pressed() -> void:
	var pd: PlayerData = Services.player_data
	if pd != null:
		pd.gain_exp(pd.exp_to_next)
		EventBus.message_logged.emit(tr("UI_DEBUG_LEVEL_DONE"))

func _on_kill_pressed() -> void:
	var bm: BattleManager = Services.battle_manager
	if bm != null and bm.enemy_data != null and bm.enemy_data.is_alive():
		bm.deal_damage_to_enemy(bm.enemy_data.hp, false, true)
		EventBus.message_logged.emit(tr("UI_DEBUG_KILL_DONE"))
