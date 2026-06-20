extends SceneTree

var _main: Node
var _battle_ui: CanvasLayer
var _step: int = 0
var _timer: float = 0.0

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	_main = scene.instantiate()
	root.add_child(_main)
	_battle_ui = _main.get_node("BattleUI")

func _process(delta: float) -> bool:
	_timer += delta
	if _step == 0 and _timer > 0.5:
		_battle_ui._on_equipment_button_pressed()
		_step = 1
		_timer = 0.0
	elif _step == 1 and _timer > 0.5:
		get_root().get_texture().get_image().save_png("res://tools/panel_equipment.png")
		print("saved panel_equipment.png")
		_battle_ui.show_battle()
		_battle_ui._on_shop_button_pressed()
		_step = 2
		_timer = 0.0
	elif _step == 2 and _timer > 0.5:
		get_root().get_texture().get_image().save_png("res://tools/panel_shop.png")
		print("saved panel_shop.png")
		_battle_ui.show_battle()
		_battle_ui._on_stats_button_pressed()
		_step = 3
		_timer = 0.0
	elif _step == 3 and _timer > 0.5:
		get_root().get_texture().get_image().save_png("res://tools/panel_stats.png")
		print("saved panel_stats.png")
		_battle_ui.show_battle()
		_battle_ui._on_achievement_button_pressed()
		_step = 4
		_timer = 0.0
	elif _step == 4 and _timer > 0.5:
		get_root().get_texture().get_image().save_png("res://tools/panel_achievement.png")
		print("saved panel_achievement.png")
		_battle_ui.show_battle()
		_battle_ui._on_quest_button_pressed()
		_step = 5
		_timer = 0.0
	elif _step == 5 and _timer > 0.5:
		get_root().get_texture().get_image().save_png("res://tools/panel_quest.png")
		print("saved panel_quest.png")
		quit()
	return false
