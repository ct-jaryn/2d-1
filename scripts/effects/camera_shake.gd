extends Camera2D

var shake_amount: float = 0.0
var shake_decay: float = 5.0

func _process(delta: float) -> void:
	if shake_amount > 0.0:
		offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		shake_amount = max(0.0, shake_amount - shake_decay * delta)
	else:
		offset = Vector2.ZERO

func shake(amount: float, decay: float = 5.0) -> void:
	shake_amount = max(shake_amount, amount)
	shake_decay = decay
