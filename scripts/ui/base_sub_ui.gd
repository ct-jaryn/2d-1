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
	var paths: PackedStringArray = [
		"MarginContainer/PanelContainer/VBoxContainer/Header/BackButton",
		"MarginContainer/CenterContainer/PanelContainer/VBoxContainer/Header/BackButton"
	]
	for path: String in paths:
		var node: Node = get_node_or_null(path)
		if node is Button:
			return node
	return null

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()

func show_panel() -> void:
	visible = true
	_refresh()
	var back_button: Button = _find_back_button()
	if back_button:
		back_button.grab_focus()

func hide_panel() -> void:
	visible = false

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
