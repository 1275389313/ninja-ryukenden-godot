extends State
## 奔跑：进入时朝玩家定向一次，之后保持方向直线奔跑；受重力，撞墙反向。

var enemy: RunnerEnemy:
	get:
		return host as RunnerEnemy

var _move_dir: int = 1


func enter(_previous_state: StringName) -> void:
	enemy.play_anim(&"run")
	_move_dir = 1
	if enemy.player != null and is_instance_valid(enemy.player):
		if enemy.player.global_position.x < enemy.global_position.x:
			_move_dir = -1
	enemy.sprite.flip_h = _move_dir < 0


func state_physics_process(delta: float) -> void:
	enemy.velocity.x = _move_dir * RunnerEnemy.RUN_SPEED
	enemy.velocity.y += EnemyBase.GRAVITY * delta
	enemy.move_and_slide()
	if enemy.is_on_wall():
		_move_dir = -_move_dir
		enemy.sprite.flip_h = _move_dir < 0
