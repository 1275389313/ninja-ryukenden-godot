extends State
## Boss 待命：未激活时站立不动，仅受重力沉降。激活由 Boss.activate_boss() 完成。

var boss: Boss:
	get:
		return host as Boss


func state_physics_process(delta: float) -> void:
	boss.velocity.x = 0.0
	boss.velocity.y += EnemyBase.GRAVITY * delta
	boss.move_and_slide()
