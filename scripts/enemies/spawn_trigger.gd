class_name SpawnTrigger
extends Area2D
## 生成触发器：玩家进入区域时通过 EnemyPool 在指定位置生成敌人。
## EnemyPool 可能尚不存在（关卡并行开发中），找不到时静默返回。

@export var enemy_type: StringName = &"runner"
@export var spawn_offset: Vector2 = Vector2(0, 0)
@export var spawn_once: bool = true


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var pool := get_tree().get_first_node_in_group("enemy_pool") as EnemyPool
	if pool == null:
		return
	pool.spawn(enemy_type, global_position + spawn_offset)
	if spawn_once:
		set_deferred("monitoring", false)
