extends SceneTree

var _main: Node = null
var _checks_done: bool = false

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	if main_scene == null:
		push_error("Failed to load main.tscn")
		quit()
		return

	_main = main_scene.instantiate()
	root.add_child(_main)

func _process(_delta: float) -> bool:
	if _checks_done:
		return false
	_checks_done = true

	var ui_names: PackedStringArray = ["EquipmentUI", "ShopUI", "StatsUI", "AchievementUI", "QuestUI"]
	for ui_name: String in ui_names:
		var ui: Node = _main.get_node_or_null(ui_name)
		if ui == null:
			push_error("Missing UI: %s" % ui_name)
			continue
		var back: Button = ui._find_back_button() if ui.has_method("_find_back_button") else null
		if back == null:
			push_error("%s back_button not found" % ui_name)
			continue
		var connections: Array = back.pressed.get_connections()
		if connections.is_empty():
			push_error("%s back_button has no pressed connections" % ui_name)
		else:
			print("%s back_button OK (%d connections)" % [ui_name, connections.size()])

		if ui.has_method("show_panel"):
			ui.show_panel()
			if not ui.visible:
				push_error("%s show_panel did not make visible" % ui_name)
			ui.hide_panel()
			if ui.visible:
				push_error("%s hide_panel did not hide" % ui_name)

	print("UI test complete.")
	quit()
	return false
