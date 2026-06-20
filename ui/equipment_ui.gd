extends BaseSubUI

const RESPONSIVE_WIDTH_THRESHOLD: int = 900

const GOLD_ICON: Texture2D = preload("res://assets/images/icon_gold.png")

const EQUIPMENT_ICONS: Dictionary = {
	EquipmentData.Type.WEAPON: preload("res://assets/images/equipment_weapon.png"),
	EquipmentData.Type.HELMET: preload("res://assets/images/equipment_helmet.png"),
	EquipmentData.Type.ARMOR: preload("res://assets/images/equipment_armor.png"),
	EquipmentData.Type.BOOTS: preload("res://assets/images/equipment_boots.png"),
	EquipmentData.Type.RING: preload("res://assets/images/equipment_ring.png")
}

@onready var wide_content: HBoxContainer = %WideContent
@onready var narrow_content: VBoxContainer = %NarrowContent
@onready var detail_panel: PanelContainer = $MarginContainer/PanelContainer/VBoxContainer/DetailPanel
@onready var detail_title: Label = $MarginContainer/PanelContainer/VBoxContainer/DetailPanel/VBox/DetailTitle
@onready var detail_stats: RichTextLabel = $MarginContainer/PanelContainer/VBoxContainer/DetailPanel/VBox/DetailStats
@onready var equip_button: Button = $MarginContainer/PanelContainer/VBoxContainer/DetailPanel/VBox/ButtonRow/EquipButton
@onready var unequip_button: Button = $MarginContainer/PanelContainer/VBoxContainer/DetailPanel/VBox/ButtonRow/UnequipButton
@onready var sell_button: Button = $MarginContainer/PanelContainer/VBoxContainer/DetailPanel/VBox/ButtonRow/SellButton
@onready var upgrade_button: Button = $MarginContainer/PanelContainer/VBoxContainer/DetailPanel/VBox/ButtonRow/UpgradeButton
@onready var auto_equip_button: Button = $MarginContainer/PanelContainer/VBoxContainer/DetailPanel/VBox/ButtonRow/AutoEquipButton
@onready var gold_label: Label = $MarginContainer/PanelContainer/VBoxContainer/Header/GoldLabel
@onready var capacity_label: Label = $MarginContainer/PanelContainer/VBoxContainer/Header/CapacityLabel

var equipment_manager: EquipmentManager = null
var selected_equipment: EquipmentData = null
var selected_is_equipped: bool = false

func _ready() -> void:
	super._ready()
	if game_manager:
		equipment_manager = game_manager.equipment_manager
		game_manager.player_data.stats_changed.connect(_update_top_bar)
		EventBus.equipment_dropped.connect(_on_equipment_dropped)
	if equipment_manager:
		equipment_manager.equipment_changed.connect(_refresh)

	equip_button.pressed.connect(_on_equip_pressed)
	unequip_button.pressed.connect(_on_unequip_pressed)
	sell_button.pressed.connect(_on_sell_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	auto_equip_button.pressed.connect(_on_auto_equip_pressed)

	_setup_gold_icon()

	get_viewport().size_changed.connect(_apply_responsive_layout)
	_apply_responsive_layout()
	_refresh()

func show_equipment() -> void:
	show_panel()
	_apply_responsive_layout()

func hide_equipment() -> void:
	hide_panel()

func _on_back_pressed() -> void:
	hide_equipment()
	if battle_ui:
		battle_ui.show_battle.call_deferred()

func _apply_responsive_layout() -> void:
	var width: int = DisplayServer.window_get_size().x
	wide_content.visible = width >= RESPONSIVE_WIDTH_THRESHOLD
	narrow_content.visible = width < RESPONSIVE_WIDTH_THRESHOLD
	_refresh()

func _get_equipped_list() -> VBoxContainer:
	return %WideContent/EquippedPanel/VBox/EquippedList if wide_content.visible else %NarrowContent/EquippedPanel/VBox/EquippedList

func _get_inventory_grid() -> GridContainer:
	return %WideContent/InventoryPanel/VBox/ScrollContainer/InventoryGrid if wide_content.visible else %NarrowContent/InventoryPanel/VBox/ScrollContainer/InventoryGrid

func _refresh() -> void:
	if equipment_manager == null:
		return
	_refresh_equipped()
	_refresh_inventory()
	_update_top_bar()
	_clear_detail()

func _refresh_equipped() -> void:
	var list: VBoxContainer = _get_equipped_list()
	for child: Node in list.get_children():
		child.queue_free()

	for type: int in range(EquipmentData.Type.size()):
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 56)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.icon = EQUIPMENT_ICONS[type]
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if equipment_manager.equipped.has(type):
			var equip: EquipmentData = equipment_manager.equipped[type]
			btn.text = "%s\nLv.%d %s" % [equip.equip_name, equip.level, EquipmentData.TYPE_NAMES[type]]
			btn.add_theme_color_override("font_color", equip.get_rarity_color())
			btn.pressed.connect(_select_equipment.bind(equip, true))
		else:
			btn.text = "未装备\n%s" % EquipmentData.TYPE_NAMES[type]
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color.GRAY)
		_add_button_interactions(btn)
		list.add_child(btn)

func _refresh_inventory() -> void:
	var grid: GridContainer = _get_inventory_grid()
	for child: Node in grid.get_children():
		child.queue_free()

	var btn_size: int = 120 if wide_content.visible else 96
	for equip: EquipmentData in equipment_manager.inventory:
		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(btn_size, btn_size * 0.6)
		btn.icon = EQUIPMENT_ICONS.get(equip.type, null)
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = "%s\nLv.%d" % [equip.equip_name, equip.level]
		btn.add_theme_color_override("font_color", equip.get_rarity_color())
		btn.pressed.connect(_select_equipment.bind(equip, false))
		_add_button_interactions(btn)
		grid.add_child(btn)

func _add_button_interactions(btn: Button) -> void:
	btn.mouse_entered.connect(func() -> void:
		EventBus.play_sfx.emit("ui_hover")
	)
	btn.focus_entered.connect(func() -> void:
		EventBus.play_sfx.emit("ui_hover")
	)

func _select_equipment(equip: EquipmentData, is_equipped_slot: bool) -> void:
	EventBus.play_sfx.emit("ui_click")
	selected_equipment = equip
	selected_is_equipped = is_equipped_slot
	detail_title.text = "%s Lv.%d" % [equip.get_display_name(), equip.level]
	detail_title.add_theme_color_override("font_color", equip.get_rarity_color())

	var stats_text: String = "[color=gray]%s[/color]\n%s" % [EquipmentData.TYPE_NAMES[equip.type], equip.get_stat_text()]
	stats_text += "\n[color=yellow]战力 %d[/color]" % equip.get_power_score()

	## 与当前同部位装备对比
	if equipment_manager and not is_equipped_slot:
		var current: EquipmentData = equipment_manager.get_equipped(equip.type)
		if current:
			var diff: int = equip.get_power_score() - current.get_power_score()
			var color: String = "green" if diff > 0 else ("red" if diff < 0 else "gray")
			stats_text += "\n[color=%s]对比已装备：%s%d[/color]" % [color, "+" if diff >= 0 else "", diff]

	detail_stats.text = stats_text
	detail_panel.visible = true
	equip_button.visible = not is_equipped_slot
	unequip_button.visible = is_equipped_slot
	upgrade_button.visible = true
	upgrade_button.text = "强化 (%d 金币)" % equip.get_upgrade_cost()
	sell_button.visible = not is_equipped_slot

func _clear_detail() -> void:
	selected_equipment = null
	selected_is_equipped = false
	detail_title.text = ""
	detail_title.remove_theme_color_override("font_color")
	detail_stats.text = ""
	detail_panel.visible = false
	equip_button.visible = false
	unequip_button.visible = false
	upgrade_button.visible = false
	sell_button.visible = false

func _on_upgrade_pressed() -> void:
	EventBus.play_sfx.emit("ui_click")
	if selected_equipment == null or game_manager == null or game_manager.player_data == null:
		return
	var cost: int = selected_equipment.get_upgrade_cost()
	if game_manager.player_data.gold < cost:
		EventBus.message_logged.emit("金币不足，无法强化")
		return
	game_manager.player_data.gold -= cost
	selected_equipment.upgrade()
	game_manager.player_data.stats_changed.emit()
	if equipment_manager:
		equipment_manager.equipment_changed.emit()
	EventBus.message_logged.emit("强化成功！%s 提升至 Lv.%d" % [selected_equipment.equip_name, selected_equipment.level])
	var upgraded: EquipmentData = selected_equipment
	var was_equipped: bool = selected_is_equipped
	_refresh()
	_select_equipment(upgraded, was_equipped)

func _on_equip_pressed() -> void:
	EventBus.play_sfx.emit("ui_click")
	if selected_equipment == null or equipment_manager == null:
		return
	equipment_manager.equip_item(selected_equipment)

func _on_unequip_pressed() -> void:
	EventBus.play_sfx.emit("ui_click")
	if selected_equipment == null or equipment_manager == null:
		return
	equipment_manager.unequip_item(selected_equipment.type)

func _on_sell_pressed() -> void:
	EventBus.play_sfx.emit("ui_click")
	if selected_equipment == null or equipment_manager == null or game_manager == null:
		return
	var price: int = equipment_manager.sell_item(selected_equipment)
	if price > 0:
		game_manager.player_data.add_gold(price)
		EventBus.message_logged.emit("出售获得 %d 金币" % price)

func _on_auto_equip_pressed() -> void:
	EventBus.play_sfx.emit("ui_click")
	if equipment_manager == null:
		return
	equipment_manager.auto_equip_best()
	EventBus.message_logged.emit("已自动装备最佳装备")

func _update_top_bar() -> void:
	if game_manager and game_manager.player_data:
		gold_label.text = "%s" % _format_number(game_manager.player_data.gold)
	if equipment_manager:
		capacity_label.text = "背包 %d/%d" % [equipment_manager.inventory.size(), EquipmentManager.MAX_INVENTORY]

func _setup_gold_icon() -> void:
	var icon: TextureRect = TextureRect.new()
	icon.texture = GOLD_ICON
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gold_label.get_parent().add_child(icon)
	gold_label.get_parent().move_child(icon, gold_label.get_index())

func _on_equipment_dropped(_equipment: EquipmentData) -> void:
	_refresh()

func _format_number(value: int) -> String:
	if value >= 1000000:
		return "%dM" % (value / 1000000)
	elif value >= 1000:
		return "%dK" % (value / 1000)
	return str(value)
