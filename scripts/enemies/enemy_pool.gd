class_name EnemyPool
extends Node2D
## 敌人对象池：预实例化固定数量的敌人，按需激活/回收。
## 职责划分：敌人自身负责停用（release_to_pool），池只负责空闲队列管理。

const RUNNER_SCENE: PackedScene = preload("res://scenes/enemies/runner_enemy.tscn")
const FLYER_SCENE: PackedScene = preload("res://scenes/enemies/flyer_enemy.tscn")

const POOL_SIZES: Dictionary = {
	&"runner": 8,
	&"flyer": 6,
}

var _free: Dictionary = {}    # StringName -> Array[EnemyBase]
var _owner: Dictionary = {}   # EnemyBase -> StringName（记录实例属于哪个池）


func _ready() -> void:
	add_to_group("enemy_pool")
	for enemy_type in POOL_SIZES:
		_free[enemy_type] = []
		var count: int = POOL_SIZES[enemy_type]
		var scene: PackedScene = _get_scene(enemy_type)
		if scene == null:
			continue
		for i in count:
			var enemy := scene.instantiate() as EnemyBase
			if enemy == null:
				continue
			add_child(enemy)
			_park(enemy)
			_free[enemy_type].append(enemy)
			_owner[enemy] = enemy_type


# ---- 公共 API（关卡 / SpawnTrigger 依赖，签名固定） ----

## 从对应池取一个空闲实例激活；池满则忽略并警告。
func spawn(enemy_type: StringName, spawn_pos: Vector2) -> void:
	if not _free.has(enemy_type):
		push_warning("EnemyPool: 未知的敌人类型 '%s'" % enemy_type)
		return
	if _free[enemy_type].is_empty():
		push_warning("EnemyPool: '%s' 池已耗尽，忽略本次生成" % enemy_type)
		return
	var enemy: EnemyBase = _free[enemy_type].pop_back()
	enemy.activate(spawn_pos)


## 回收敌人（此时敌人已完成自我停用，池只记录空闲）。
func release(enemy: EnemyBase) -> void:
	if not _owner.has(enemy):
		return  # 不是本池实例
	var enemy_type: StringName = _owner[enemy]
	if _free[enemy_type].has(enemy):
		return  # 已空闲，忽略重复回收
	_free[enemy_type].append(enemy)


# ---- 内部 ----

func _get_scene(enemy_type: StringName) -> PackedScene:
	match enemy_type:
		&"runner":
			return RUNNER_SCENE
		&"flyer":
			return FLYER_SCENE
	return null


## 停用并归位（初始状态，等池外触发激活）。
func _park(enemy: EnemyBase) -> void:
	enemy.visible = false
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	var body_shape := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape != null:
		body_shape.disabled = true
	var hitbox := enemy.get_node_or_null("Hitbox") as Hitbox
	if hitbox != null:
		hitbox.monitoring = false
		hitbox.monitorable = false
	var hurtbox := enemy.get_node_or_null("Hurtbox") as Hurtbox
	if hurtbox != null:
		hurtbox.monitoring = false
		hurtbox.monitorable = false
