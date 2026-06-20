extends SceneTree

var _frame: int = 0

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/title_screen.tscn")
	var root_node: Node = scene.instantiate()
	root.add_child(root_node)

func _process(_delta: float) -> bool:
	_frame += 1
	if _frame == 10:
		var img: Image = get_root().get_texture().get_image()
		img.save_png("res://tools/title_capture.png")
		print("saved title_capture.png")
		quit()
	return false
