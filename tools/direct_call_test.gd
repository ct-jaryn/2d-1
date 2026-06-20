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
		print("battle_ui equipment_ui: ", battle_ui.equipment_ui)
		battle_ui._on_equipment_button_pressed()
		print("after call battle_ui visible: ", battle_ui.visible)
		if battle_ui.equipment_ui:
			print("equipment_ui visible: ", battle_ui.equipment_ui.visible)
	if _frame == 10:
		var img: Image = get_root().get_texture().get_image()
		img.save_png("res://tools/direct_call.png")
		print("saved direct_call.png")
		quit()
	return false
