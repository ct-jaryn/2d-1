extends BaseSubUI

const CARD_BG_COLOR: Color = Color(0.18, 0.18, 0.28, 0.95)
const CARD_BORDER_COLOR: Color = Color(0.35, 0.4, 0.55, 1.0)

@onready var title_label: Label = %Title
@onready var gold_label: Label = %GoldLabel
@onready var item_list: VBoxContainer = %ItemList
@onready var message_label: Label = %MessageLabel

const ITEM_IDS: PackedStringArray = ["health_potion", "attack_boost", "defense_boost", "exp_potion", "equipment_box"]

func _ready() -> void:
	super._ready()
	title_label.text = tr("UI_SHOP_TITLE")
	if Services.player_data:
		Services.player_data.stats_changed.connect(_update_gold)
	if Services.shop_manager:
		Services.shop_manager.purchase_failed.connect(_show_message)
		Services.shop_manager.item_purchased.connect(_on_purchased)
	UIHelpers.add_gold_icon(gold_label)
	_refresh()

func show_shop() -> void:
	show_panel()

func hide_shop() -> void:
	hide_panel()

func _on_back_pressed() -> void:
	UIHelpers.play_ui_click()
	hide_shop()
	if battle_ui:
		battle_ui.show_battle.call_deferred()

func _refresh() -> void:
	_update_gold()
	_clear_items()
	if Services.shop_manager == null:
		return
	
	for id: String in ITEM_IDS:
		var item: Dictionary = Services.shop_manager.get_item(id)
		if item.is_empty():
			continue
		
		var card: PanelContainer = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var row: HBoxContainer = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 12)
		
		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = Vector2(56, 56)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = load(item.icon)
		row.add_child(icon)
		
		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var name_label: Label = Label.new()
		name_label.text = tr("UI_SHOP_PRICE_FORMAT") % [item.name, item.price]
		name_label.add_theme_font_size_override("font_size", 18)
		
		var desc_label: Label = Label.new()
		desc_label.text = item.desc
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
		
		info.add_child(name_label)
		info.add_child(desc_label)
		row.add_child(info)
		
		var buy_button: Button = Button.new()
		buy_button.text = tr("UI_SHOP_BUY")
		buy_button.custom_minimum_size = Vector2(72, 44)
		buy_button.pressed.connect(_on_buy_pressed.bind(id))
		buy_button.mouse_entered.connect(UIHelpers.play_ui_hover)
		row.add_child(buy_button)
		
		card.add_child(row)
		card.add_theme_stylebox_override("panel", UIHelpers.create_card_style(CARD_BG_COLOR, CARD_BORDER_COLOR))
		item_list.add_child(card)

func _clear_items() -> void:
	for child: Node in item_list.get_children():
		child.queue_free()

func _on_buy_pressed(id: String) -> void:
	UIHelpers.play_ui_click()
	if Services.shop_manager:
		if Services.shop_manager.purchase(id):
			_show_message(tr("UI_SHOP_PURCHASE_SUCCESS"))
			_update_gold()

func _on_purchased(_item_id: String, _price: int) -> void:
	_refresh()

func _update_gold() -> void:
	if not visible:
		return
	if Services.player_data:
		gold_label.text = "%s" % UIHelpers.format_number(Services.player_data.gold)

func _show_message(text: String) -> void:
	UIHelpers.show_temporary_message(self, message_label, text)
