class_name EnemyBase
extends CharacterBody2D
## 敌人基类：对象池复用，负责生命值/受击闪烁/死亡回收与激活/停用生命周期。
## 具体行为由子类的 FSM 状态实现；节点结构由各子场景提供。

const GRAVITY: float = 600.0
const FLASH_DURATION: float = 0.1
const RECYCLE_DISTANCE: float = 400.0
const FALL_OUT_Y: float = 300.0

@export var max_health: int = 1
@export var damage: int = 1
@export var score_value: int = 100
@export var use_gravity: bool = true

## 是否由对象池管理：false 时死亡与远离玩家均不回池（如 Boss），死亡走 _on_non_pooled_died()。
var pooled: bool = true

## 激活时缓存的玩家引用（可能为 null）。
var player: Node2D

var _flash_time_left: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: Health = $Health
@onready var state_machine: StateMachine = $StateMachine


func _ready() -> void:
	health.max_value = max_health
	health.reset_health()
	hitbox.damage = damage
	hurtbox.hit_received.connect(health.take_damage)
	health.damaged.connect(_on_health_damaged)
	health.died.connect(_on_health_died)


func _process(delta: float) -> void:
	# 受击闪烁：modulate 变红，计时结束恢复
	if _flash_time_left > 0.0:
		_flash_time_left = maxf(0.0, _flash_time_left - delta)
		if _flash_time_left <= 0.0:
			sprite.modulate = Color.WHITE


func _physics_process(_delta: float) -> void:
	# 激活中持续确认玩家存在；远离玩家或掉出世界则回收
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		if player == null:
			return
	if not pooled:
		return  # 非池敌人（Boss）永不回收
	if global_position.distance_to(player.global_position) > RECYCLE_DISTANCE \
			or global_position.y > FALL_OUT_Y:
		release_to_pool()


# ---- 公共 API（对象池与关卡依赖，签名固定） ----

## 由对象池调用：复位到指定位置并重新开始活动。
func activate(spawn_pos: Vector2) -> void:
	global_position = spawn_pos
	velocity = Vector2.ZERO
	health.max_value = max_health
	health.reset_health()
	hitbox.damage = damage
	_flash_time_left = 0.0
	sprite.modulate = Color.WHITE
	player = get_tree().get_first_node_in_group("player") as Node2D
	# 恢复碰撞：与 release_to_pool 的关闭调用同样走 deferred，保证帧末按序执行
	body_shape.set_deferred("disabled", false)
	hitbox.set_deferred("monitoring", true)
	hitbox.set_deferred("monitorable", true)
	hurtbox.set_deferred("monitoring", true)
	hurtbox.set_deferred("monitorable", true)
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	state_machine.change_to(get_initial_state())


## 停止一切活动并通知对象池回收（敌人负责自我停用，池负责队列管理）。
func release_to_pool() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	body_shape.set_deferred("disabled", true)
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	player = null
	# 不做静态类型标注：release() 是 enemy_pool.gd 的脚本方法，静态类型 Node 上不存在；
	# 且不引用 EnemyPool 类名以避免与本类的循环依赖
	var pool = get_tree().get_first_node_in_group("enemy_pool")
	if pool != null:
		pool.release(self)


## 子类可覆盖：返回激活时进入的初始状态名（节点名小写）。
func get_initial_state() -> StringName:
	return &""


## 受击闪烁是否进行中（供状态脚本协调 modulate，避免覆盖闪烁）。
func is_flashing() -> bool:
	return _flash_time_left > 0.0


# ---- 信号回调 ----

func _on_health_damaged(_amount: int, _source_position: Vector2) -> void:
	_flash_time_left = FLASH_DURATION
	sprite.modulate = Color(1.0, 0.3, 0.3)


func _on_health_died() -> void:
	GameEvents.enemy_killed.emit(score_value)  # GameManager 自动累计分数
	if pooled:
		release_to_pool()
	else:
		_on_non_pooled_died()


## 非池敌人（pooled = false）的死亡分支，由子类实现（如 Boss 进入死亡状态）。
func _on_non_pooled_died() -> void:
	pass
