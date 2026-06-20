extends Node2D

@export var data: PlayerData
@export var battle_manager: BattleManager

@onready var body: AnimatedSprite2D = $Body
@onready var shadow: Polygon2D = $Shadow
@onready var hit_flash: Timer = $HitFlashTimer

const ANIM_PATHS: Dictionary = {
	"idle": "res://assets/images/animations/hero/hero_idle.png",
	"attack": "res://assets/images/animations/hero/hero_attack.png",
	"hit": "res://assets/images/animations/hero/hero_hit.png",
	"death": "res://assets/images/animations/hero/hero_death.png",
}

const ANIM_FRAMES: Dictionary = {
	"idle": 6,
	"attack": 6,
	"hit": 6,
	"death": 6,
}

const ANIM_FPS: Dictionary = {
	"idle": 5.0,
	"attack": 10.0,
	"hit": 8.0,
	"death": 6.0,
}

const ANIM_LOOP: Dictionary = {
	"idle": true,
	"attack": false,
	"hit": false,
	"death": false,
}

const BASE_SCALE: float = 1.0

var base_position: Vector2
var _is_dead: bool = false
var _breath_time: float = 0.0

func _ready() -> void:
	base_position = position
	add_to_group("player")

	if data == null:
		var gm = get_tree().get_first_node_in_group("game_manager") as GameManager
		if gm:
			data = gm.player_data

	if battle_manager == null:
		battle_manager = get_tree().get_first_node_in_group("battle_manager") as BattleManager

	if battle_manager:
		battle_manager.enemy_attacked.connect(_on_enemy_attacked)
		battle_manager.player_attacked.connect(_on_player_attacked)
		battle_manager.player_died.connect(_on_player_died)

	_setup_sprite_frames()
	_update_appearance()
	body.animation_finished.connect(_on_animation_finished)
	body.play("idle")

func _setup_sprite_frames() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation("default")

	for anim_name: String in ANIM_PATHS.keys():
		var texture: Texture2D = load(ANIM_PATHS[anim_name]) as Texture2D
		if texture == null:
			push_warning("Failed to load hero animation: %s" % ANIM_PATHS[anim_name])
			continue

		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, ANIM_LOOP[anim_name])
		frames.set_animation_speed(anim_name, ANIM_FPS[anim_name])

		var frame_count: int = ANIM_FRAMES[anim_name]
		var frame_width: float = texture.get_width() / float(frame_count)
		var frame_height: float = float(texture.get_height())

		for i: int in range(frame_count):
			var atlas: AtlasTexture = AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(i * frame_width, 0.0, frame_width, frame_height)
			frames.add_frame(anim_name, atlas)

	body.sprite_frames = frames

func _process(delta: float) -> void:
	## 待机呼吸位移动画（使用 delta 累加，避免帧率绑定和每秒跳变）
	if not _is_dead:
		_breath_time += delta
		position.y = base_position.y + sin(_breath_time * 2.0) * 2.0

func _update_appearance() -> void:
	if data == null:
		return
	## 随等级略微变大
	var scale_factor: float = BASE_SCALE + (data.level - 1) * 0.02
	scale = Vector2(scale_factor, scale_factor)

func _play_animation(anim_name: String) -> void:
	if _is_dead and anim_name != "death":
		return
	if body.sprite_frames.has_animation(anim_name):
		body.play(anim_name)

func _on_animation_finished() -> void:
	if _is_dead:
		return
	if body.animation != "idle":
		body.play("idle")

func _on_enemy_attacked(damage: int, is_crit: bool) -> void:
	if _is_dead:
		return
	_play_animation("hit")
	body.modulate = Color.RED
	hit_flash.start(0.1)
	var tween: Tween = create_tween()
	tween.tween_property(self, "position:x", base_position.x - 8.0, 0.05)
	tween.tween_property(self, "position:x", base_position.x, 0.05)
	_show_floating_text(damage, is_crit, false)

func _on_player_attacked(damage: int, is_crit: bool) -> void:
	if _is_dead:
		return
	_play_animation("attack")
	_show_floating_text(damage, is_crit, true)

func _on_player_died() -> void:
	_is_dead = true
	_play_animation("death")

func _show_floating_text(damage: int, is_crit: bool, is_player_attacking: bool) -> void:
	var ftm: FloatingTextManager = get_tree().get_first_node_in_group("floating_text_manager") as FloatingTextManager
	if ftm == null:
		return
	if is_player_attacking:
		ftm.show_damage(global_position + Vector2(0, -40), damage, true, is_crit)
	else:
		ftm.show_damage(global_position + Vector2(0, -40), damage, false, is_crit)

func _on_hit_flash_timer_timeout() -> void:
	body.modulate = Color.WHITE
