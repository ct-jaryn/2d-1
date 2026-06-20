extends SceneTree

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)

	var ui_names: PackedStringArray = ["EquipmentUI", "ShopUI", "StatsUI", "AchievementUI", "QuestUI"]
	for ui_name: String in ui_names:
		var ui: Node = main.get_node_or_null(ui_name)
		if ui == null:
			print("Missing UI: %s" % ui_name)
			continue
		print("Checking %s" % ui_name)
		print("  has _find_back_button: %s" % ui.has_method("_find_back_button"))
		var found: Button = ui._find_back_button() if ui.has_method("_find_back_button") else null
		print("  _find_back_button result: %s" % found)
		var back: Button = ui.get("back_button")
		print("  back_button property: %s" % back)
		var direct: Node = ui.get_node_or_null("MarginContainer/PanelContainer/VBoxContainer/Header/BackButton")
		print("  direct node: %s" % direct)

	print("Done")
	quit()
