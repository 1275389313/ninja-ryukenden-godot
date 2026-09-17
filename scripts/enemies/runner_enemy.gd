class_name RunnerEnemy
extends EnemyBase
## 奔跑杂兵：落地后朝玩家方向直线奔跑，撞墙反向（FC 手感，不追踪）。

const RUN_SPEED: float = 60.0


func _init() -> void:
	use_gravity = true
	max_health = 1
	score_value = 100


func _ready() -> void:
	super._ready()
	sprite.texture = PlaceholderTexture.make(Vector2i(12, 12), Color(0.9, 0.2, 0.2))


func get_initial_state() -> StringName:
	return &"run"
