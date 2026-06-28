extends CanvasLayer

@export var steps: Array[Dictionary] = []
@export var current_step: int = 0

@onready var panel: Panel = %Panel
@onready var label: RichTextLabel = %RichTextLabel
@onready var next_button: Button = %NextButton
@onready var skip_button: Button = %SkipButton
@onready var highlight: ColorRect = %Highlight

signal tutorial_finished

func _ready() -> void:
	visible = false
	skip_button.text = tr("UI_TUTORIAL_SKIP")
	next_button.pressed.connect(_next_step)
	skip_button.pressed.connect(_finish)

func start(p_steps: Array[Dictionary]) -> void:
	steps = p_steps
	current_step = 0
	visible = true
	_show_step()

func _show_step() -> void:
	if current_step >= steps.size():
		_finish()
		return
	var step: Dictionary = steps[current_step]
	label.text = step.get("text", "")
	
	var target: Control = _resolve_target(step.get("target", ""))
	if target:
		highlight.visible = true
		var rect: Rect2 = target.get_global_rect()
		highlight.position = rect.position - Vector2(4, 4)
		highlight.size = rect.size + Vector2(8, 8)
	else:
		highlight.visible = false
	
	## 修复原代码中放在 return 之后的 unreachable 赋值，并本地化
	var is_last_step: bool = current_step >= steps.size() - 1
	next_button.text = tr("UI_TUTORIAL_START") if is_last_step else tr("UI_TUTORIAL_NEXT")

func _resolve_target(raw: Variant) -> Control:
	if raw == null:
		return null
	if raw is Control:
		return raw as Control
	if raw is String:
		var target_path: String = raw as String
		if target_path == "":
			return null
		## TutorialOverlay 被添加到 BattleUI 下，目标节点在 BattleUI 内部，所以从父节点查找
		if get_parent() != null:
			var found: Control = get_parent().get_node_or_null(target_path) as Control
			if found != null:
				return found
		return get_node_or_null(target_path) as Control
	return null

func _next_step() -> void:
	current_step += 1
	_show_step()

func _finish() -> void:
	visible = false
	tutorial_finished.emit()
	queue_free()
