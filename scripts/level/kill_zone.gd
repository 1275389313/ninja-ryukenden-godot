class_name KillZone
extends Area2D
## 坠落致死区（triggers 层）：玩家身体进入即触发死亡。
## 配置：collision_layer = 128（第 8 层 triggers），collision_mask = 2（player_body）。


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.die()
