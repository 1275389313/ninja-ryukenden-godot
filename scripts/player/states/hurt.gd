extends State
## 受击：按伤害来源方向击退，锁输入 HURT_DURATION 秒。

var player: Player:
	get:
		return host as Player

var _timer: float = 0.0


func enter(_previous_state: StringName) -> void:
	_timer = 0.0
	player.set_sword_active(false)
	# 伤害来源在右侧则向左击退，反之向右
	var dir := -1 if player.last_damage_source.x > player.global_position.x else 1
	player.velocity = Vector2(dir * Player.KNOCKBACK_SPEED, Player.KNOCKBACK_UP)


func state_physics_process(delta: float) -> void:
	_timer += delta
	player.velocity.y += Player.GRAVITY * delta
	player.move_and_slide()

	if _timer >= Player.HURT_DURATION:
		state_machine.change_to(&"idle" if player.is_on_floor() else &"fall")
