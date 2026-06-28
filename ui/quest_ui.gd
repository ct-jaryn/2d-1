extends BaseSubUI

const CHECK_ICON: Texture2D = preload("res://assets/images/icon_check.png")

@onready var title_label: Label = %Title
@onready var quest_list: VBoxContainer = %QuestList
@onready var refresh_button: Button = %RefreshButton
@onready var message_label: Label = %MessageLabel
@onready var root_vbox: VBoxContainer = %QuestList.get_parent().get_parent() as VBoxContainer

var quest_manager: QuestManager = null
var _card_nodes: Dictionary = {}
var _current_filter: int = 0  ## 0=全部, 1=可领取, 2=进行中, 3=已完成
var _filter_bar: FilterBar = null

const FILTER_KEYS: PackedStringArray = ["UI_FILTER_ALL", "UI_FILTER_CLAIMABLE", "UI_FILTER_IN_PROGRESS", "UI_QUEST_FILTER_FINISHED"]

func _ready() -> void:
	super._ready()
	title_label.text = tr("UI_QUEST_TITLE")
	refresh_button.text = tr("UI_QUEST_REFRESH")
	refresh_button.pressed.connect(_on_refresh_pressed)
	quest_manager = Services.quest_manager
	EventBus.daily_quests_refreshed.connect(_rebuild_all)
	EventBus.quest_updated.connect(_on_quest_updated)
	_setup_filter_bar()

func _setup_filter_bar() -> void:
	if root_vbox == null:
		return
	_filter_bar = FilterBar.new()
	_filter_bar.name = "FilterBar"
	_filter_bar.setup(FILTER_KEYS, _current_filter)
	_filter_bar.filter_changed.connect(_on_filter_changed)
	root_vbox.add_child(_filter_bar)
	root_vbox.move_child(_filter_bar, 1)

func _on_filter_changed(index: int) -> void:
	UIHelpers.play_ui_click()
	_current_filter = index
	_rebuild_all()

func _refresh() -> void:
	_rebuild_all()

func show_quests() -> void:
	show_panel()

func hide_quests() -> void:
	hide_panel()

func _on_back_pressed() -> void:
	UIHelpers.play_ui_click()
	hide_quests()
	if battle_ui:
		battle_ui.show_battle.call_deferred()

func _passes_filter(quest: QuestData) -> bool:
	match _current_filter:
		1:
			return quest.completed and not quest.claimed
		2:
			return not quest.completed
		3:
			return quest.claimed
		_:
			return true

func _rebuild_all() -> void:
	_clear_list()
	_card_nodes.clear()
	if quest_manager == null:
		return
	
	_update_refresh_button()
	
	for quest: QuestData in quest_manager.quests:
		if not _passes_filter(quest):
			continue
		var nodes: Dictionary = _build_card(quest)
		var card: PanelContainer = nodes["card"] as PanelContainer
		quest_list.add_child(card)
		_card_nodes[quest] = nodes

func _build_card(quest: QuestData) -> Dictionary:
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	card.add_theme_stylebox_override("panel", _get_card_style(quest))
	
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 12)
	
	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var title: Label = Label.new()
	title.name = "TitleLabel"
	title.text = tr(quest.title)
	title.add_theme_font_size_override("font_size", 18)
	
	var progress: Label = Label.new()
	progress.name = "ProgressLabel"
	progress.text = quest.get_progress_text()
	progress.add_theme_font_size_override("font_size", 14)
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	title_row.add_child(title)
	title_row.add_child(progress)
	
	var desc: Label = Label.new()
	desc.name = "DescLabel"
	desc.text = tr(quest.description)
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	
	var reward: Label = Label.new()
	reward.name = "RewardLabel"
	reward.text = tr("UI_QUEST_REWARD_FORMAT") % quest.get_reward_text()
	reward.add_theme_font_size_override("font_size", 13)
	reward.add_theme_color_override("font_color", Color.LIME_GREEN)
	
	var progress_bar: ProgressBar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.value = quest.get_progress_ratio() * 100.0
	progress_bar.max_value = 100.0
	progress_bar.size_flags_vertical = 4
	_set_quest_bar_colors(progress_bar)
	
	info.add_child(title_row)
	info.add_child(desc)
	info.add_child(progress_bar)
	info.add_child(reward)
	
	var action: Control = _create_action_control(quest)
	action.name = "ActionControl"
	
	hbox.add_child(info)
	hbox.add_child(action)
	card.add_child(hbox)
	return {
		"card": card,
		"title": title,
		"progress_label": progress,
		"reward": reward,
		"progress_bar": progress_bar,
		"action": action,
	}

func _get_card_style(quest: QuestData) -> StyleBoxFlat:
	var bg_color: Color
	var border_color: Color
	if quest.claimed:
		bg_color = Color(0.15, 0.25, 0.15, 0.95)
		border_color = Color(0.4, 0.7, 0.4, 1)
	elif quest.completed:
		bg_color = Color(0.25, 0.2, 0.1, 0.95)
		border_color = Color(1.0, 0.75, 0.2, 1)
	else:
		bg_color = Color(0.12, 0.12, 0.16, 0.95)
		border_color = Color(0.35, 0.32, 0.45, 1)
	return UIHelpers.create_card_style(bg_color, border_color)

func _update_card(quest: QuestData) -> void:
	var nodes: Dictionary = _card_nodes.get(quest, {})
	var card: PanelContainer = nodes.get("card") as PanelContainer
	if card == null:
		return
	
	card.add_theme_stylebox_override("panel", _get_card_style(quest))
	
	var title: Label = nodes.get("title") as Label
	var progress_label: Label = nodes.get("progress_label") as Label
	var reward: Label = nodes.get("reward") as Label
	var progress_bar: ProgressBar = nodes.get("progress_bar") as ProgressBar
	var action: Control = nodes.get("action") as Control
	var hbox: HBoxContainer = card.get_child(0) as HBoxContainer
	
	title.text = tr(quest.title)
	if quest.completed:
		title.add_theme_color_override("font_color", Color.GOLD)
	else:
		title.remove_theme_color_override("font_color")
	progress_label.text = quest.get_progress_text()
	reward.text = tr("UI_QUEST_REWARD_FORMAT") % quest.get_reward_text()
	progress_bar.value = quest.get_progress_ratio() * 100.0
	
	## 替换 action 区域
	action.queue_free()
	var new_action: Control = _create_action_control(quest)
	new_action.name = "ActionControl"
	nodes["action"] = new_action
	hbox.add_child(new_action)
	hbox.move_child(new_action, 1)

func _set_quest_bar_colors(bar: ProgressBar) -> void:
	var fg: StyleBoxFlat = bar.get_theme_stylebox("fill").duplicate()
	var bg: StyleBoxFlat = bar.get_theme_stylebox("background").duplicate()
	fg.bg_color = Color(0.3, 0.85, 0.35, 1)
	bg.bg_color = Color(0.1, 0.15, 0.1, 1)
	bar.add_theme_stylebox_override("fill", fg)
	bar.add_theme_stylebox_override("background", bg)

func _create_action_control(quest: QuestData) -> Control:
	if quest.claimed:
		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 4)
		var icon: TextureRect = TextureRect.new()
		icon.texture = CHECK_ICON
		icon.custom_minimum_size = Vector2(18, 18)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var label: Label = Label.new()
		label.text = tr("UI_QUEST_CLAIMED")
		label.add_theme_color_override("font_color", Color.GREEN)
		hbox.add_child(icon)
		hbox.add_child(label)
		return hbox
	
	if quest.completed:
		var btn: Button = Button.new()
		btn.text = tr("UI_QUEST_CLAIM")
		btn.custom_minimum_size = Vector2(72, 44)
		btn.pressed.connect(_on_claim_pressed.bind(quest))
		btn.mouse_entered.connect(UIHelpers.play_ui_hover)
		return btn
	
	var label: Label = Label.new()
	label.text = tr("UI_QUEST_IN_PROGRESS")
	label.add_theme_color_override("font_color", Color.GRAY)
	return label

func _clear_list() -> void:
	for child: Node in quest_list.get_children():
		child.queue_free()

func _on_quest_updated(quest: QuestData) -> void:
	if visible:
		_update_card(quest)
		_update_refresh_button()

func _on_refresh_pressed() -> void:
	UIHelpers.play_ui_click()
	if quest_manager == null:
		return
	if quest_manager.try_manual_refresh():
		_rebuild_all()
	else:
		UIHelpers.show_temporary_message(self, message_label, tr("UI_QUEST_REFRESH_FAIL"))

func _on_claim_pressed(quest: QuestData) -> void:
	UIHelpers.play_ui_click()
	if quest_manager == null:
		return
	if quest_manager.claim_reward(quest):
		UIHelpers.show_temporary_message(self, message_label, tr("UI_QUEST_CLAIM_SUCCESS"))
		_update_card(quest)

func _update_refresh_button() -> void:
	if quest_manager == null:
		return
	if quest_manager.free_refresh_used:
		refresh_button.text = tr("UI_QUEST_REFRESH_COST") % QuestManager.REFRESH_COST
	else:
		refresh_button.text = tr("UI_QUEST_REFRESH_FREE")
