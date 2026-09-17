extends CanvasLayer
## FC 风格顶部信息栏：玩家血条 / Boss 血条 / SCORE / TIME / LIVES。
## 只与 GameEvents 信号打交道，不感知玩家 / 敌人内部实现。

const CELL_SIZE := Vector2(6, 4)
const PLAYER_CELL_COUNT := 8
const BOSS_CELL_COUNT := 10
const PLAYER_ON_COLOR := Color(0.35, 0.6, 1.0)
const PLAYER_OFF_COLOR := Color(0.15, 0.15, 0.2)
const BOSS_ON_COLOR := Color(0.9, 0.15, 0.15)
const BOSS_OFF_COLOR := Color(0.25, 0.1, 0.1)

@onready var _player_box: HBoxContainer = $TopBar/PlayerHealthBox
@onready var _boss_box: HBoxContainer = $TopBar/BossHealthBox
@onready var _score_label: Label = $TopBar/ScoreLabel
@onready var _time_label: Label = $TopBar/TimeLabel
@onready var _lives_label: Label = $TopBar/LivesLabel

var _player_cells: Array[Control] = []
var _boss_cells: Array[Control] = []
var _player_pip: Texture2D
var _boss_pip: Texture2D


func _ready() -> void:
	_player_pip = GameAssets.texture("ui/health_pip.png", Vector2i(6, 4), PLAYER_ON_COLOR)
	_boss_pip = GameAssets.texture("ui/boss_pip.png", Vector2i(6, 4), BOSS_ON_COLOR)
	_build_cells(_player_box, _player_cells, PLAYER_CELL_COUNT, _player_pip, PLAYER_ON_COLOR)
	_build_cells(_boss_box, _boss_cells, BOSS_CELL_COUNT, _boss_pip, BOSS_ON_COLOR)
	GameEvents.player_health_changed.connect(_on_player_health_changed)
	GameEvents.player_lives_changed.connect(_on_player_lives_changed)
	GameEvents.score_changed.connect(_on_score_changed)
	GameEvents.timer_changed.connect(_on_timer_changed)
	GameEvents.boss_fight_started.connect(_on_boss_fight_started)
	GameEvents.boss_health_changed.connect(_on_boss_health_changed)
	GameEvents.boss_defeated.connect(_on_boss_defeated)
	# HUD 先于 GameManager.start_new_game() 实例化，这里先按当前状态刷一次
	_on_score_changed(GameManager.score)
	_on_player_lives_changed(GameManager.lives)
	_on_timer_changed(ceili(GameManager.time_left))
	_on_player_health_changed(PLAYER_CELL_COUNT, PLAYER_CELL_COUNT)


func _build_cells(box: HBoxContainer, out: Array[Control], count: int, pip: Texture2D, _on_color: Color) -> void:
	for i in count:
		var cell := TextureRect.new()
		cell.custom_minimum_size = CELL_SIZE
		cell.texture = pip
		cell.stretch_mode = TextureRect.STRETCH_SCALE
		cell.modulate = Color.WHITE
		box.add_child(cell)
		out.append(cell)


func _update_cells(cells: Array[Control], current: int, _on_color: Color, _off_color: Color, _pip_rel: String) -> void:
	for i in cells.size():
		cells[i].modulate = Color.WHITE if i < current else Color(0.22, 0.22, 0.28, 1.0)


func _on_player_health_changed(current: int, _max_value: int) -> void:
	_update_cells(_player_cells, clampi(current, 0, PLAYER_CELL_COUNT), PLAYER_ON_COLOR, PLAYER_OFF_COLOR, "ui/health_pip.png")


func _on_player_lives_changed(lives: int) -> void:
	_lives_label.text = "LIVES x%d" % lives


func _on_score_changed(score: int) -> void:
	_score_label.text = "SCORE %06d" % score


func _on_timer_changed(seconds_left: int) -> void:
	_time_label.text = "TIME %03d" % seconds_left


## 开新局前由 main.gd 调用，清除上一局可能残留的 Boss 血条显示状态。
func reset() -> void:
	_boss_box.visible = false


func _on_boss_fight_started() -> void:
	_boss_box.visible = true


func _on_boss_health_changed(current: int, _max_value: int) -> void:
	_update_cells(_boss_cells, clampi(current, 0, BOSS_CELL_COUNT), BOSS_ON_COLOR, BOSS_OFF_COLOR, "ui/boss_pip.png")


func _on_boss_defeated() -> void:
	_boss_box.visible = false
