extends SceneTree

var _frame: int = 0
var _main: Node = null

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	_main = main_scene.instantiate()
	root.add_child(_main)

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 5:
		var battle_ui: Node = _main.get_node("BattleUI")
		for btn_name: String in ["BossButton", "EquipmentButton", "ShopButton", "StatsButton", "AchievementButton", "QuestButton"]:
			var btn: Control = battle_ui.get_node("MainMargin/RootVBox/BottomBar/" + btn_name)
			print(btn_name, " rect: ", btn.get_global_rect(), " disabled: ", btn.disabled, " mouse_filter: ", btn.mouse_filter)
		var img: Image = get_root().get_texture().get_image()
		img.save_png("res://tools/btn_rects.png")
		print("saved btn_rects.png")
		quit()
	return false
