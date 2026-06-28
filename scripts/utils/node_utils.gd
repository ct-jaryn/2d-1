class_name NodeUtils
extends RefCounted

## 安全终止并清空一个 Tween，避免动作叠加。
static func kill_tween(tween: Tween) -> Tween:
	if tween != null and tween.is_valid():
		tween.kill()
	return null

## 恢复节点默认色调（受击闪烁后复位）。
static func reset_flash(node: CanvasItem) -> void:
	node.modulate = Color.WHITE
