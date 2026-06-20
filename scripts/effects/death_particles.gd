extends CPUParticles2D

func _ready() -> void:
	emitting = true
	one_shot = true
	await get_tree().create_timer(lifetime + 0.5).timeout
	queue_free()
