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
	sprite.sprite_frames = GameAssets.runner_frames()
	sprite.offset = Vector2(0, -2)
	play_anim(&"run")


func get_initial_state() -> StringName:
	return &"run"
