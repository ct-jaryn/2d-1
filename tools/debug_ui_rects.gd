extends SceneTree

var _frame: int = 0
var _main: Node = null

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	_main = main_scene.instantiate()
	root.add_child(_main)

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 3:
		var battle_ui: Node = _main.get_node("BattleUI")
		var battle_viewport: Control = battle_ui.get_node("MainMargin/RootVBox/MainArea/BattleViewport")
		var bottom_bar: Control = battle_ui.get_node("MainMargin/RootVBox/BottomBar")
		var boss_btn: Control = battle_ui.get_node("MainMargin/RootVBox/BottomBar/BossButton")
		print("BattleViewport rect: ", battle_viewport.get_global_rect())
		print("BottomBar rect: ", bottom_bar.get_global_rect())
		print("BossButton rect: ", boss_btn.get_global_rect())
		print("BossButton disabled: ", boss_btn.disabled)
		print("BossButton mouse_filter: ", boss_btn.mouse_filter)
		print("BattleViewport mouse_filter: ", battle_viewport.mouse_filter)
		var img: Image = get_root().get_texture().get_image()
		img.save_png("res://tools/battle_capture.png")
		print("saved screenshot")
		quit()
	return false
