extends CanvasLayer
## 通关结算画面：仅负责表现，返回标题的输入检测由 main.gd 统一处理。

const BLINK_INTERVAL := 0.5

@onready var _prompt: Label = $PromptLabel
@onready var _score_label: Label = $ScoreLabel

var _blink_timer: float = 0.0


func _process(delta: float) -> void:
	_blink_timer += delta
	if _blink_timer >= BLINK_INTERVAL:
		_blink_timer = 0.0
		_prompt.visible = not _prompt.visible


func set_score(value: int) -> void:
	_score_label.text = "SCORE %06d" % value
