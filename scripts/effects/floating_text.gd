extends Label

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 1.0
var _tween: Tween = null
var _on_finished: Callable = Callable()

func _ready() -> void:
	z_index = 100
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func init(text_value: String, color: Color, start_position: Vector2, is_crit: bool = false, on_finished: Callable = Callable()) -> void:
	_on_finished = on_finished
	visible = true
	
	## 重置主题覆盖，避免复用时残留
	remove_theme_font_size_override("font_size")
	
	text = text_value
	modulate = color
	position = start_position
	
	if is_crit:
		add_theme_font_size_override("font_size", 28)
		velocity = Vector2(randf_range(-20, 20), -90)
	else:
		add_theme_font_size_override("font_size", 20)
		velocity = Vector2(randf_range(-10, 10), -60)
	
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel()
	_tween.tween_property(self, "position", position + velocity, lifetime)
	_tween.tween_property(self, "modulate:a", 0.0, lifetime)
	_tween.chain().tween_callback(_finish)

func _finish() -> void:
	visible = false
	if _on_finished.is_valid():
		_on_finished.call(self)
