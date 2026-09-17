extends Node
## 全局游戏状态管理（Autoload: GameManager）。
## 通过 GameEvents 信号与 HUD / 关卡 / 流程模块通信。

const MAX_LIVES: int = 3
const LEVEL_TIME: int = 150

var score: int = 0
var lives: int = MAX_LIVES
var time_left: float = LEVEL_TIME
var is_playing: bool = false
var respawn_position: Vector2 = Vector2.ZERO

var _last_seconds_left: int = LEVEL_TIME


func _ready() -> void:
	GameEvents.enemy_killed.connect(add_score)


func _process(delta: float) -> void:
	if not is_playing:
		return
	time_left -= delta
	if time_left < 0.0:
		time_left = 0.0
	var seconds_left := ceili(time_left)
	if seconds_left != _last_seconds_left:
		_last_seconds_left = seconds_left
		GameEvents.timer_changed.emit(seconds_left)
	if time_left <= 0.0:
		on_player_death() # 时间耗尽致死


func start_new_game() -> void:
	score = 0
	lives = MAX_LIVES
	time_left = LEVEL_TIME
	_last_seconds_left = LEVEL_TIME
	is_playing = true
	GameEvents.score_changed.emit(score)
	GameEvents.player_lives_changed.emit(lives)
	GameEvents.timer_changed.emit(LEVEL_TIME)


func add_score(value: int) -> void:
	score += value
	GameEvents.score_changed.emit(score)


func on_player_death() -> void:
	lives -= 1
	GameEvents.player_lives_changed.emit(lives)
	is_playing = false
	if lives > 0:
		# 由关卡负责重生玩家并调用 reset_timer()
		GameEvents.player_died.emit()
	else:
		GameEvents.game_over.emit()


func on_level_cleared() -> void:
	is_playing = false
	GameEvents.level_cleared.emit()


func reset_timer() -> void:
	time_left = LEVEL_TIME
	_last_seconds_left = LEVEL_TIME
	GameEvents.timer_changed.emit(LEVEL_TIME)
