extends State
## Boss 行走：朝玩家方向移动并面向玩家，水平距离进入攻击范围后切换攻击。

var boss: Boss:
	get:
		return host as Boss


func enter(_previous_state: StringName) -> void:
	boss.play_anim(&"walk")


func state_physics_process(delta: float) -> void:
	if boss.player != null and is_instance_valid(boss.player):
		var dx: float = boss.player.global_position.x - boss.global_position.x
		if absf(dx) < Boss.ATTACK_RANGE:
			state_machine.change_to(&"attack")
			return
		var dir: int = 1 if dx >= 0.0 else -1
		boss.velocity.x = dir * Boss.WALK_SPEED
		boss.sprite.flip_h = dir < 0
	else:
		boss.velocity.x = 0.0
	boss.velocity.y += EnemyBase.GRAVITY * delta
	boss.move_and_slide()
