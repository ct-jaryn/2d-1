class_name BaseSubUI
extends CanvasLayer

@export var game_manager: GameManager
@export var battle_ui: CanvasLayer

func _ready() -> void:
	visible = false
	add_to_group("sub_ui")
	if game_manager == null:
		game_manager = get_tree().get_first_node_in_group("game_manager") as GameManager
	if battle_ui == null:
		battle_ui = get_node_or_null("../BattleUI") as CanvasLayer
	var back_button: Button = _find_back_button()
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func _find_back_button() -> Button:
	## 优先查找硬编码路径
	var paths: PackedStringArray = [
		"MarginContainer/PanelContainer/VBoxContainer/Header/BackButton",
		"MarginContainer/CenterContainer/PanelContainer/VBoxContainer/Header/BackButton"
	]
	for path: String in paths:
		var node: Node = get_node_or_null(path)
		if node is Button:
			return node
	
	## 兜底：递归查找名为 BackButton 或文本含“返回”的按钮
	return _find_back_button_recursive(self) as Button

func _find_back_button_recursive(node: Node) -> Button:
	for child: Node in node.get_children():
		if child is Button:
			var btn: Button = child as Button
			if btn.name == "BackButton" or (btn.text != "" and "返回" in btn.text):
				return btn
		var found: Button = _find_back_button_recursive(child)
		if found != null:
			return found
	return null

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()

func show_panel() -> void:
	## 子界面互斥：打开新面板前关闭其他已打开的子界面
	for sub_ui: CanvasLayer in get_tree().get_nodes_in_group("sub_ui"):
		if sub_ui != self and sub_ui.visible and sub_ui.has_method("hide_panel"):
			sub_ui.hide_panel()
	visible = true
	_refresh()
	var focus_target: Control = _find_back_button() as Control
	if focus_target == null:
		focus_target = _find_first_focusable(self)
	if focus_target != null:
		focus_target.grab_focus()

func _find_first_focusable(node: Node) -> Control:
	for child: Node in node.get_children():
		if child is Control and (child as Control).focus_mode != Control.FOCUS_NONE:
			return child as Control
		var found: Control = _find_first_focusable(child)
		if found != null:
			return found
	return null

func hide_panel() -> void:
	visible = false

func close_panel() -> void:
	## 公开方法：关闭面板并返回战斗界面，供 PauseMenu/全局导航调用
	_on_back_pressed()

func _on_back_pressed() -> void:
	_play_ui_click()
	hide_panel()
	if battle_ui:
		battle_ui.show_battle()

func _refresh() -> void:
	pass

func _play_ui_click() -> void:
	EventBus.play_sfx.emit("ui_click")

func _play_ui_hover() -> void:
	EventBus.play_sfx.emit("ui_hover")
