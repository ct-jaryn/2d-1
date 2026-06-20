extends Label

var velocity: Vector2 = Vector2.ZERO
var lifetime: float = 1.0

func _ready() -> void:
	z_index = 100
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func init(text_value: String, color: Color, start_position: Vector2, is_crit: bool = false) -> void:
	text = text_value
	modulate = color
	position = start_position
	
	if is_crit:
		add_theme_font_size_override("font_size", 28)
		velocity = Vector2(randf_range(-20, 20), -90)
	else:
		add_theme_font_size_override("font_size", 20)
		velocity = Vector2(randf_range(-10, 10), -60)
	
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "position", position + velocity, lifetime)
	tween.tween_property(self, "modulate:a", 0.0, lifetime)
	tween.chain().tween_callback(queue_free)
