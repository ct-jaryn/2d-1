extends SceneTree

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main: Node = main_scene.instantiate()
	root.add_child(main)

	var ui: Node = main.get_node_or_null("ShopUI")
	print("ui script: %s" % ui.get_script().resource_path)
	print("base script: %s" % ui.get_script().get_base_script().resource_path)
	print("back_button via get: %s" % ui.get("back_button"))
	print("back_button direct: %s" % ui.back_button)
	print("find method: %s" % ui._find_back_button())
	print("members: %s" % ui.get_script().get_script_property_list())

	quit()
