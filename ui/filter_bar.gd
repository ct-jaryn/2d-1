class_name FilterBar
extends HBoxContainer

signal filter_changed(index: int)

var _buttons: Dictionary = {}
var _current_filter: int = 0

func setup(filter_keys: PackedStringArray, initial_filter: int = 0) -> void:
	_current_filter = initial_filter
	for child: Node in get_children():
		child.queue_free()
	_buttons.clear()
	
	alignment = ALIGNMENT_CENTER
	add_theme_constant_override("separation", 8)
	
	for i: int in range(filter_keys.size()):
		var btn: Button = Button.new()
		btn.text = tr(filter_keys[i])
		btn.toggle_mode = true
		btn.button_pressed = (i == _current_filter)
		btn.pressed.connect(_on_filter_pressed.bind(i))
		btn.mouse_entered.connect(UIHelpers.play_ui_hover)
		_buttons[i] = btn
		add_child(btn)

func set_filter(index: int) -> void:
	_current_filter = index
	for i: int in _buttons.keys():
		(_buttons[i] as Button).button_pressed = (i == _current_filter)

func _on_filter_pressed(index: int) -> void:
	set_filter(index)
	filter_changed.emit(index)
