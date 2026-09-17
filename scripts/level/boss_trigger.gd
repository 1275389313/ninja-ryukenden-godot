class_name BossTrigger
extends Area2D
## Boss 战触发区（triggers 层）：玩家进入即激活 Boss 并广播 boss_fight_started。
## 只触发一次；boss_path 指向关卡中的 Boss 实例。

@export var boss_path: NodePath


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body is Player:
		return
	var boss := get_node_or_null(boss_path) as Boss
	if boss != null:
		boss.activate_boss()
	GameEvents.boss_fight_started.emit()
	set_deferred("monitoring", false)
