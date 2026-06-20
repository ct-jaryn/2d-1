class_name FloatingTextManager
extends CanvasLayer

const FloatingTextScene: PackedScene = preload("res://ui/floating_text.tscn")

func show_damage(position: Vector2, damage: int, is_player: bool, is_crit: bool = false) -> void:
	var color: Color = Color.WHITE if is_player else Color.ORANGE_RED
	if is_crit:
		color = Color.GOLD
	var text: String = str(damage)
	if is_crit:
		text += "!"
	_create(text, color, position, is_crit)

func show_heal(position: Vector2, amount: int) -> void:
	_create("+%d" % amount, Color.LIME_GREEN, position, false)

func show_text(position: Vector2, text: String, color: Color = Color.WHITE) -> void:
	_create(text, color, position, false)

func _create(text: String, color: Color, position: Vector2, is_crit: bool) -> void:
	var label: Label = FloatingTextScene.instantiate() as Label
	add_child(label)
	
	## 将世界坐标转换为屏幕坐标
	var camera: Camera2D = get_viewport().get_camera_2d()
	var screen_pos: Vector2 = position
	if camera:
		screen_pos = camera.unproject_position(position)
	
	label.init(text, color, screen_pos, is_crit)
