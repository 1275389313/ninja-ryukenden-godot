class_name Health
extends Node
## 生命值组件（玩家与敌人共用）。
## 受击入口为 take_damage()，支持限时无敌。

signal damaged(amount: int, source_position: Vector2)
signal died

@export var max_value: int = 3

var current: int
var _invincible_time_left: float = 0.0


func _ready() -> void:
	current = max_value


func _process(delta: float) -> void:
	if _invincible_time_left > 0.0:
		_invincible_time_left = maxf(0.0, _invincible_time_left - delta)


func take_damage(amount: int, source_position: Vector2) -> void:
	if is_invincible() or current <= 0:
		return
	current = maxi(0, current - amount)
	damaged.emit(amount, source_position)
	if current <= 0:
		died.emit()


func set_invincible_duration(duration: float) -> void:
	_invincible_time_left = maxf(_invincible_time_left, duration)


func is_invincible() -> bool:
	return _invincible_time_left > 0.0


func reset_health() -> void:
	current = max_value
	_invincible_time_left = 0.0
