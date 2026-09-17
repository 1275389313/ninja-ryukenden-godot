extends State
## 飞行：进入时朝玩家定向一次，水平匀速飞行，垂直方向叠加正弦波动。

var enemy: FlyerEnemy:
	get:
		return host as FlyerEnemy

var _move_dir: int = 1
var _time: float = 0.0


func enter(_previous_state: StringName) -> void:
	_move_dir = 1
	_time = 0.0
	if enemy.player != null and is_instance_valid(enemy.player):
		if enemy.player.global_position.x < enemy.global_position.x:
			_move_dir = -1
	enemy.sprite.flip_h = _move_dir < 0


func state_physics_process(delta: float) -> void:
	_time += delta
	enemy.velocity = Vector2(
		_move_dir * FlyerEnemy.SPEED,
		sin(_time * FlyerEnemy.WAVE_FREQUENCY) * FlyerEnemy.WAVE_AMPLITUDE
	)
	enemy.move_and_slide()
