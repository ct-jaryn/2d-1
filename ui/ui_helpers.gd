class_name UIHelpers
extends RefCounted

## 创建统一卡片样式框，减少 Quest/Achievement 等面板中的重复代码。

static func create_card_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style

## 将大整数格式化为 K/M 简写，统一所有 UI 的金币/数值显示。
static func format_number(value: int) -> String:
	if value >= 1_000_000_000:
		return "%dB" % (value / 1_000_000_000)
	elif value >= 1_000_000:
		return "%dM" % (value / 1_000_000)
	elif value >= 1_000:
		return "%dK" % (value / 1_000)
	return str(value)

## 在金币标签左侧添加金币图标，统一装备、商店等面板。
static func add_gold_icon(gold_label: Label, size: Vector2 = Vector2(20, 20)) -> void:
	const GOLD_ICON: Texture2D = preload("res://assets/images/icon_gold.png")
	var icon: TextureRect = TextureRect.new()
	icon.texture = GOLD_ICON
	icon.custom_minimum_size = size
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gold_label.get_parent().add_child(icon)
	gold_label.get_parent().move_child(icon, gold_label.get_index())

## 在指定 Label 上显示一条临时消息，duration 秒后清空。
static func show_temporary_message(caller: Node, label: Label, text: String, duration: float = 2.0) -> void:
	label.text = text
	await caller.get_tree().create_timer(duration).timeout
	if is_instance_valid(label):
		label.text = ""

static func play_ui_click() -> void:
	EventBus.play_sfx.emit("ui_click")

static func play_ui_hover() -> void:
	EventBus.play_sfx.emit("ui_hover")
