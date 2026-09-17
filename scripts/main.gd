extends Node2D
## 游戏流程控制：标题画面 → 第一关（含 Boss 战）→ 通关结算 / 游戏结束 → 返回标题。
## 玩家死亡重生由关卡内部处理，这里只响应 GameEvents.game_over / level_cleared 两个出口。

enum FlowState { TITLE, PLAYING, GAME_OVER, CLEAR }

const TITLE_SCREEN_SCENE := preload("res://scenes/ui/title_screen.tscn")
const GAME_OVER_SCREEN_SCENE := preload("res://scenes/ui/game_over_screen.tscn")
const CLEAR_SCREEN_SCENE := preload("res://scenes/ui/clear_screen.tscn")
const HUD_SCENE := preload("res://scenes/ui/hud.tscn")
const LEVEL_1_SCENE := preload("res://scenes/level/level_1.tscn")

var _state: FlowState = FlowState.TITLE
var _screen: CanvasLayer = null
# 不做静态类型标注：reset() 是 hud.gd 的脚本方法，静态类型 CanvasLayer 上不存在
var _hud = null
var _level: Node2D = null


func _ready() -> void:
	# HUD 常驻，且必须先于 GameManager.start_new_game() 实例化（后者会 emit 初始值信号）
	_hud = HUD_SCENE.instantiate()
	_hud.visible = false
	add_child(_hud)
	_show_title_screen()
	GameEvents.game_over.connect(_on_game_over)
	GameEvents.level_cleared.connect(_on_level_cleared)


func _unhandled_input(_event: InputEvent) -> void:
	if not Input.is_action_just_pressed("start"):
		return
	match _state:
		FlowState.TITLE:
			start_game()
		FlowState.GAME_OVER, FlowState.CLEAR:
			back_to_title()


func start_game() -> void:
	if _state != FlowState.TITLE:
		return
	_state = FlowState.PLAYING
	_free_screen()
	GameManager.start_new_game()
	_level = LEVEL_1_SCENE.instantiate()
	add_child(_level)
	_hud.reset()
	_hud.visible = true


func back_to_title() -> void:
	if _state != FlowState.GAME_OVER and _state != FlowState.CLEAR:
		return
	_free_screen()
	_show_title_screen()


func _on_game_over() -> void:
	# 信号可能来自物理帧 / 其他节点的回调，节点增删延迟到空闲帧处理
	call_deferred("_show_game_over_screen")


func _on_level_cleared() -> void:
	call_deferred("_show_clear_screen")


func _show_title_screen() -> void:
	_state = FlowState.TITLE
	_screen = TITLE_SCREEN_SCENE.instantiate()
	add_child(_screen)


func _show_game_over_screen() -> void:
	if _state != FlowState.PLAYING:
		return
	_state = FlowState.GAME_OVER
	_free_level()
	_hud.visible = false
	_screen = GAME_OVER_SCREEN_SCENE.instantiate()
	add_child(_screen)


func _show_clear_screen() -> void:
	if _state != FlowState.PLAYING:
		return
	_state = FlowState.CLEAR
	_free_level()
	_hud.visible = false
	# 不做静态类型标注：set_score() 是脚本方法，静态类型会被推断为 Node 而导致编译错误
	var clear_screen = CLEAR_SCREEN_SCENE.instantiate()
	add_child(clear_screen)
	clear_screen.set_score(GameManager.score)
	_screen = clear_screen


func _free_screen() -> void:
	if _screen != null:
		_screen.queue_free()
		_screen = null


func _free_level() -> void:
	if _level != null:
		_level.queue_free()
		_level = null
