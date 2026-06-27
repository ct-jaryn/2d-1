class_name AudioManager
extends Node

@onready var bgm_player: AudioStreamPlayer = $BGMPlayer

const SFX_POOL_SIZE: int = 4
var sfx_players: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0

const SOUNDS: Dictionary = {
	"attack": preload("res://assets/sounds/attack.wav"),
	"hit": preload("res://assets/sounds/hit.wav"),
	"level_up": preload("res://assets/sounds/level_up.wav"),
	"coin": preload("res://assets/sounds/coin.wav"),
	"ui_click": preload("res://assets/sounds/ui_click.wav"),
	"ui_hover": preload("res://assets/sounds/ui_hover.wav")
}

const BGM_PATH: String = "res://assets/sounds/bgm.wav"

var bgm_enabled: bool = true
var sfx_enabled: bool = true
var _pending_bgm: bool = true

func _ready() -> void:
	Services.audio_manager = self
	var bgm_stream: AudioStream = load(BGM_PATH)
	if bgm_stream:
		if bgm_stream is AudioStreamWAV:
			(bgm_stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		elif "loop" in bgm_stream:
			bgm_stream.loop = true
		bgm_player.stream = bgm_stream
	_pending_bgm = true
	_init_sfx_pool()
	EventBus.play_sfx.connect(play_sfx)

func _init_sfx_pool() -> void:
	bgm_player.bus = "BGM"
	for i: int in range(SFX_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "SFXPlayer%d" % i
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

func play_sfx(name: String) -> void:
	if not sfx_enabled:
		return
	if not SOUNDS.has(name):
		return
	var player: AudioStreamPlayer = sfx_players[_sfx_index]
	_sfx_index = (_sfx_index + 1) % sfx_players.size()
	player.stream = SOUNDS[name]
	player.play()

func play_bgm() -> void:
	if not bgm_enabled:
		return
	if not bgm_player.playing:
		bgm_player.play()

func try_play_bgm() -> void:
	if _pending_bgm:
		play_bgm()
		_pending_bgm = false

func stop_bgm() -> void:
	bgm_player.stop()

func set_bgm_enabled(enabled: bool) -> void:
	bgm_enabled = enabled
	if enabled:
		play_bgm()
	else:
		stop_bgm()

func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
