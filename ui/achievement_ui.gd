extends BaseSubUI

const ACHIEVEMENT_ICON: Texture2D = preload("res://assets/images/icon_achievement.png")
const CIRCLE_ICON: Texture2D = preload("res://assets/images/icon_circle.png")

@onready var title_label: Label = %Title
@onready var achievement_list: VBoxContainer = %AchievementList
@onready var progress_label: Label = %ProgressLabel
@onready var root_vbox: VBoxContainer = %AchievementList.get_parent().get_parent() as VBoxContainer

var achievement_manager: AchievementManager = null
var _card_nodes: Dictionary = {}
var _current_filter: int = 0  ## 0=全部, 1=已完成, 2=未完成
var _filter_bar: FilterBar = null

const FILTER_KEYS: PackedStringArray = ["UI_FILTER_ALL", "UI_FILTER_COMPLETED", "UI_FILTER_INCOMPLETE"]

func _ready() -> void:
	super._ready()
	title_label.text = tr("UI_ACHIEVEMENT_TITLE")
	achievement_manager = Services.achievement_manager
	if achievement_manager:
		achievement_manager.achievement_unlocked.connect(_on_achievement_unlocked)
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

func show_achievements() -> void:
	show_panel()

func hide_achievements() -> void:
	hide_panel()

func _on_back_pressed() -> void:
	UIHelpers.play_ui_click()
	hide_achievements()
	if battle_ui:
		battle_ui.show_battle.call_deferred()

func _rebuild_all() -> void:
	if achievement_manager == null:
		return
	
	progress_label.text = tr("UI_ACHIEVEMENT_PROGRESS") % [achievement_manager.get_completed_count(), achievement_manager.get_total_count()]
	
	for child: Node in achievement_list.get_children():
		child.queue_free()
	_card_nodes.clear()
	
	for ach: AchievementData in achievement_manager.achievements:
		if not _passes_filter(ach):
			continue
		var nodes: Dictionary = _build_card(ach)
		var card: PanelContainer = nodes["card"] as PanelContainer
		achievement_list.add_child(card)
		_card_nodes[ach] = nodes

func _passes_filter(ach: AchievementData) -> bool:
	match _current_filter:
		1:
			return ach.completed
		2:
			return not ach.completed
		_:
			return true

func _build_card(ach: AchievementData) -> Dictionary:
	var card: PanelContainer = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	card.add_theme_stylebox_override("panel", _get_card_style(ach))
	
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var title_row: HBoxContainer = HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var icon: TextureRect = TextureRect.new()
	icon.name = "Icon"
	icon.texture = ACHIEVEMENT_ICON if ach.completed else CIRCLE_ICON
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var title: Label = Label.new()
	title.name = "TitleLabel"
	title.text = tr(ach.name)
	title.add_theme_font_size_override("font_size", 18)
	if ach.completed:
		title.add_theme_color_override("font_color", Color.GOLD)
	
	var type_label: Label = Label.new()
	type_label.name = "TypeLabel"
	type_label.text = ach.get_type_name()
	type_label.add_theme_font_size_override("font_size", 13)
	type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1))
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	type_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	title_row.add_child(icon)
	title_row.add_child(title)
	title_row.add_child(type_label)
	
	var desc: Label = Label.new()
	desc.name = "DescLabel"
	desc.text = tr(ach.description)
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	
	var reward: Label = Label.new()
	reward.name = "RewardLabel"
	reward.text = ach.get_reward_text()
	reward.add_theme_font_size_override("font_size", 13)
	reward.add_theme_color_override("font_color", Color.LIME_GREEN)
	
	vbox.add_child(title_row)
	vbox.add_child(desc)
	vbox.add_child(reward)
	card.add_child(vbox)
	return {"card": card, "icon": icon, "title": title}

func _get_card_style(ach: AchievementData) -> StyleBoxFlat:
	var bg_color: Color
	var border_color: Color
	if ach.completed:
		bg_color = Color(0.18, 0.28, 0.18, 0.95)
		border_color = Color(0.7, 0.65, 0.25, 1)
	else:
		bg_color = Color(0.12, 0.12, 0.16, 0.95)
		border_color = Color(0.35, 0.32, 0.45, 1)
	return UIHelpers.create_card_style(bg_color, border_color)

func _update_card(ach: AchievementData) -> void:
	var nodes: Dictionary = _card_nodes.get(ach, {})
	var card: PanelContainer = nodes.get("card") as PanelContainer
	if card == null:
		return
	
	card.add_theme_stylebox_override("panel", _get_card_style(ach))
	
	var icon: TextureRect = nodes.get("icon") as TextureRect
	var title: Label = nodes.get("title") as Label
	
	icon.texture = ACHIEVEMENT_ICON if ach.completed else CIRCLE_ICON
	title.text = tr(ach.name)
	if ach.completed:
		title.add_theme_color_override("font_color", Color.GOLD)
	else:
		title.remove_theme_color_override("font_color")

func _on_achievement_unlocked(achievement: AchievementData) -> void:
	if visible:
		_update_card(achievement)
		progress_label.text = tr("UI_ACHIEVEMENT_PROGRESS") % [achievement_manager.get_completed_count(), achievement_manager.get_total_count()]
