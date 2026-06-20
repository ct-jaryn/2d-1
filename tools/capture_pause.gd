extends SceneTree

var _frame: int = 0
var _main: Node = null

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	_main = main_scene.instantiate()
	root.add_child(_main)

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 10:
		var ev: InputEventKey = InputEventKey.new()
		ev.keycode = KEY_ESCAPE
		ev.pressed = true
		get_root().push_input(ev)
	if _frame == 15:
		var img: Image = get_root().get_texture().get_image()
		img.save_png("res://tools/pause_capture.png")
		print("saved pause_capture.png")
		quit()
	return false
