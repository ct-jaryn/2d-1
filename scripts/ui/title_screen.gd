extends Control

@onready var continue_button: Button = $MarginContainer/VBoxContainer/ContinueButton
@onready var new_game_button: Button = $MarginContainer/VBoxContainer/NewGameButton
@onready var exit_button: Button = $MarginContainer/VBoxContainer/ExitButton

var save_manager: SaveManager = SaveManager.new()

func _ready() -> void:
	continue_button.visible = save_manager.has_save()
	if OS.has_feature("web"):
		exit_button.visible = false
	
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func _start_game(scene_path: String) -> void:
	var audio_manager: AudioManager = get_tree().get_first_node_in_group("audio_manager") as AudioManager
	if audio_manager:
		audio_manager.try_play_bgm()
	get_tree().change_scene_to_file(scene_path)

func _on_new_game_pressed() -> void:
	save_manager.delete_save()
	_start_game("res://scenes/main.tscn")

func _on_continue_pressed() -> void:
	_start_game("res://scenes/main.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
