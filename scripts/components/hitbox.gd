class_name Hitbox
extends Area2D
## 攻击判定区（玩家与敌人共用）。
## 默认不激活，攻击时由实体调用 set_active(true) 启用。

@export var damage: int = 1


func set_active(on: bool) -> void:
	# Area2D 的 monitoring/monitorable 可能在物理回调中被切换，统一走 deferred
	set_deferred("monitoring", on)
	set_deferred("monitorable", on)
