extends CanvasLayer
## 标题画面：仅负责表现，开始游戏的输入检测由 main.gd 统一处理。

const BLINK_INTERVAL := 0.5

@onready var _prompt: Label = $PromptLabel

var _blink_timer: float = 0.0


func _ready() -> void:
	_decorate()


func _process(delta: float) -> void:
	_blink_timer += delta
	if _blink_timer >= BLINK_INTERVAL:
		_blink_timer = 0.0
		_prompt.visible = not _prompt.visible


func _decorate() -> void:
	if GameAssets.has_sprite("bg/sky.png"):
		var sky := TextureRect.new()
		sky.name = "SkyArt"
		sky.set_anchors_preset(Control.PRESET_FULL_RECT)
		sky.grow_horizontal = Control.GROW_DIRECTION_BOTH
		sky.grow_vertical = Control.GROW_DIRECTION_BOTH
		sky.texture = GameAssets.texture("bg/sky.png", Vector2i(256, 240), Color(0.02, 0.02, 0.08))
		sky.stretch_mode = TextureRect.STRETCH_SCALE
		sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sky)
		move_child(sky, 1)
	if GameAssets.has_sprite("bg/moon.png"):
		var moon := TextureRect.new()
		moon.name = "MoonArt"
		moon.texture = GameAssets.texture("bg/moon.png", Vector2i(16, 16), Color(0.9, 0.9, 0.7))
		moon.position = Vector2(196, 24)
		moon.custom_minimum_size = Vector2(24, 24)
		moon.size = Vector2(24, 24)
		moon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		moon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(moon)
		move_child(moon, 2)
	var ninja := AnimatedSprite2D.new()
	ninja.name = "TitleNinja"
	ninja.sprite_frames = GameAssets.player_frames()
	ninja.position = Vector2(128, 128)
	ninja.centered = true
	add_child(ninja)
	var title := get_node_or_null("TitleLabel")
	if title != null:
		move_child(ninja, title.get_index())
	if ninja.sprite_frames != null and ninja.sprite_frames.has_animation(&"idle"):
		ninja.play(&"idle")
