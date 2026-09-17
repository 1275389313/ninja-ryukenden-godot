class_name Boss
extends EnemyBase
## 关卡 Boss：不入对象池（pooled = false），原地待命，由 BossTrigger 激活。
## 激活后走向玩家并近战攻击；死亡时广播 boss_defeated 并推进通关流程。

const WALK_SPEED: float = 30.0
const ATTACK_RANGE: float = 28.0
const ATTACK_OFFSET_X: float = 14.0

var _activated: bool = false

@onready var attack_hitbox: Hitbox = $AttackHitbox


func _init() -> void:
	use_gravity = true
	max_health = 10
	damage = 1
	score_value = 1000
	pooled = false


func _ready() -> void:
	super._ready()
	sprite.texture = PlaceholderTexture.make(Vector2i(16, 24), Color(1.0, 0.55, 0.1))
	sprite.offset = Vector2(0, -1)  # 脚对齐碰撞体底部
	attack_hitbox.damage = damage


## 由 BossTrigger 调用：开始 Boss 战。幂等——重复调用无副作用。
func activate_boss() -> void:
	if _activated:
		return
	_activated = true
	player = get_tree().get_first_node_in_group("player") as Node2D
	state_machine.change_to(&"walk")
	GameEvents.boss_health_changed.emit(health.current, health.max_value)


func get_initial_state() -> StringName:
	return &"idle"


func _on_health_damaged(_amount: int, _source_position: Vector2) -> void:
	super._on_health_damaged(_amount, _source_position)  # 复用受击闪烁，不击退（霸体）
	GameEvents.boss_health_changed.emit(health.current, health.max_value)


func _on_non_pooled_died() -> void:
	state_machine.change_to(&"dead")
