class_name FloatingTextManager
extends CanvasLayer

const FloatingTextScene: PackedScene = preload("res://ui/floating_text.tscn")
const POOL_SIZE: int = 30

var _pool: Array[Label] = []
var _active: Array[Label] = []

func _ready() -> void:
	## 预创建对象池
	for i: int in range(POOL_SIZE):
		var label: Label = _create_label()
		label.visible = false
		_pool.append(label)

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

func _create_label() -> Label:
	var label: Label = FloatingTextScene.instantiate() as Label
	add_child(label)
	return label

func _get_label() -> Label:
	if _pool.is_empty():
		## 池耗尽时动态扩容，并回收最旧的活跃飘字
		if not _active.is_empty():
			_return_to_pool(_active.pop_front())
		else:
			return _create_label()
	var label: Label = _pool.pop_back()
	_active.append(label)
	return label

func _return_to_pool(label: Label) -> void:
	label.visible = false
	if label in _active:
		_active.erase(label)
	if not label in _pool:
		_pool.append(label)

func _create(text: String, color: Color, position: Vector2, is_crit: bool) -> void:
	var label: Label = _get_label()
	
	## 将世界坐标转换为屏幕坐标
	var camera: Camera2D = get_viewport().get_camera_2d()
	var screen_pos: Vector2 = position
	if camera:
		screen_pos = camera.unproject_position(position)
	
	label.init(text, color, screen_pos, is_crit, _return_to_pool)
