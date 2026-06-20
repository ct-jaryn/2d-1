extends SceneTree

var _frame: int = 0
var _main: Node = null

func _initialize() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	_main = main_scene.instantiate()
	root.add_child(_main)

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 30:
		# Simulate left mouse press on Equipment button (client coords ~323,690)
		var press: InputEventMouseButton = InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = Vector2(323, 690)
		get_root().push_input(press)
	if _frame == 35:
		var release: InputEventMouseButton = InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		release.position = Vector2(323, 690)
		get_root().push_input(release)
	if _frame == 60:
		var img: Image = get_root().get_texture().get_image()
		img.save_png("res://tools/after_click.png")
		print("saved after_click.png")
		quit()
	return false
