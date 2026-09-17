extends CanvasLayer
## 通关结算画面：仅负责表现，返回标题的输入检测由 main.gd 统一处理。

const BLINK_INTERVAL := 0.5

@onready var _prompt: Label = $PromptLabel
@onready var _score_label: Label = $ScoreLabel

var _blink_timer: float = 0.0


func _ready() -> void:
	if GameAssets.has_sprite("bg/sky.png"):
		var sky := TextureRect.new()
		sky.set_anchors_preset(Control.PRESET_FULL_RECT)
		sky.grow_horizontal = Control.GROW_DIRECTION_BOTH
		sky.grow_vertical = Control.GROW_DIRECTION_BOTH
		sky.texture = GameAssets.texture("bg/sky.png", Vector2i(256, 240), Color(0.02, 0.02, 0.08))
		sky.stretch_mode = TextureRect.STRETCH_SCALE
		sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sky)
		move_child(sky, 1)


func _process(delta: float) -> void:
	_blink_timer += delta
	if _blink_timer >= BLINK_INTERVAL:
		_blink_timer = 0.0
		_prompt.visible = not _prompt.visible


func set_score(value: int) -> void:
	_score_label.text = "SCORE %06d" % value
