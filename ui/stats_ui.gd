extends BaseSubUI

@onready var title_label: Label = %Title
@onready var stats_text: RichTextLabel = %StatsText

func _ready() -> void:
	super._ready()
	title_label.text = tr("UI_STATS_TITLE")

func show_stats() -> void:
	show_panel()

func hide_stats() -> void:
	hide_panel()

func _on_back_pressed() -> void:
	UIHelpers.play_ui_click()
	hide_stats()
	if battle_ui:
		battle_ui.show_battle.call_deferred()

func _refresh() -> void:
	if Services.player_data == null:
		return
	
	var pd: PlayerData = Services.player_data
	var play_time: String = _format_time(pd.play_time_seconds)
	
	stats_text.text = """
[center][b][color=gold]%s[/color][/b][/center]

[color=#d4b86a]%s[/color]
%s
%s
%s
%s
%s
%s

[color=#d4b86a]%s[/color]
%s
%s
%s
%s
%s
%s
%s

[color=#d4b86a]%s[/color]
%s
%s
""" % [
		tr("UI_STATS_HEADER"),
		tr("UI_STATS_BASE_ATTR"),
		tr("UI_STATS_LEVEL") % pd.level,
		tr("UI_STATS_ATTACK") % pd.attack,
		tr("UI_STATS_DEFENSE") % pd.defense,
		tr("UI_STATS_HP") % [pd.hp, pd.max_hp],
		tr("UI_STATS_ATTACK_SPEED") % pd.attack_speed,
		tr("UI_STATS_CRIT") % (pd.crit_rate * 100.0),
		tr("UI_STATS_BATTLE_RECORD"),
		tr("UI_STATS_KILLS") % pd.total_kills,
		tr("UI_STATS_TOTAL_GOLD") % UIHelpers.format_number(pd.total_gold_earned),
		tr("UI_STATS_DAMAGE_DEALT") % UIHelpers.format_number(pd.total_damage_dealt),
		tr("UI_STATS_DAMAGE_TAKEN") % UIHelpers.format_number(pd.total_damage_taken),
		tr("UI_STATS_DEATHS") % pd.death_count,
		tr("UI_STATS_BOSSES") % pd.bosses_defeated,
		tr("UI_STATS_HIGHEST_STAGE") % pd.highest_stage,
		tr("UI_STATS_OTHER"),
		tr("UI_STATS_PLAY_TIME") % play_time,
		tr("UI_STATS_CURRENT_GOLD") % UIHelpers.format_number(pd.gold)
	]

func _format_time(seconds: float) -> String:
	var hours: int = int(seconds) / 3600
	var minutes: int = (int(seconds) % 3600) / 60
	var secs: int = int(seconds) % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]
