class_name Hurtbox
extends Area2D
## 受击判定区（玩家与敌人共用）。
## 检测到处于激活状态的 Hitbox 进入时，交给 Hitbox.try_hit 统一扣血（含站桩重叠）。

signal hit_received(damage: int, source_position: Vector2)


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area2D) -> void:
	if area is Hitbox:
		(area as Hitbox).try_hit(self)
