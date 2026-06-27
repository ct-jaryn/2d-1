class_name DeathParticles
extends CPUParticles2D

const DeathParticlesScene: PackedScene = preload("res://scenes/death_particles.tscn")

static var _pool: Array[CPUParticles2D] = []

static func spawn(parent: Node, global_pos: Vector2) -> CPUParticles2D:
	var p: CPUParticles2D
	if _pool.is_empty():
		p = DeathParticlesScene.instantiate() as CPUParticles2D
	else:
		p = _pool.pop_back()
	parent.add_child(p)
	p.global_position = global_pos
	p.emitting = true
	p._schedule_return()
	return p

func _schedule_return() -> void:
	await get_tree().create_timer(lifetime + 0.5).timeout
	if not is_instance_valid(self):
		return
	var parent_node = get_parent()
	if parent_node != null:
		parent_node.remove_child(self)
	emitting = false
	_pool.append(self)
