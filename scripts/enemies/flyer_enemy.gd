class_name FlyerEnemy
extends EnemyBase
## 飞行杂兵：朝玩家方向水平飞行，叠加正弦垂直波动，不受重力。

const SPEED: float = 50.0
const WAVE_AMPLITUDE: float = 20.0
const WAVE_FREQUENCY: float = 4.0


func _init() -> void:
	use_gravity = false
	max_health = 1
	score_value = 150


func _ready() -> void:
	super._ready()
	sprite.texture = PlaceholderTexture.make(Vector2i(12, 10), Color(0.7, 0.3, 0.9))


func get_initial_state() -> StringName:
	return &"fly"
