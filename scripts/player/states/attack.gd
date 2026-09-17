extends State
## 攻击：持续 ATTACK_DURATION，前 SWORD_ACTIVE_TIME 启用剑判定。
## 地面攻击锁定水平速度；空中攻击保持水平速度。

const SWORD_ACTIVE_TIME: float = 0.15

var player: Player:
	get:
		return host as Player

var _timer: float = 0.0


func enter(_previous_state: StringName) -> void:
	_timer = 0.0
	player.set_sword_active(true)
	if player.is_on_floor():
		player.velocity.x = 0.0


func exit() -> void:
	player.set_sword_active(false)


func state_physics_process(delta: float) -> void:
	_timer += delta
	if _timer >= SWORD_ACTIVE_TIME:
		player.set_sword_active(false)

	if player.is_on_floor():
		player.velocity.x = 0.0
	else:
		player.velocity.y += Player.GRAVITY * delta
	player.move_and_slide()

	if _timer >= Player.ATTACK_DURATION:
		if player.is_on_floor():
			var axis := Input.get_axis("move_left", "move_right")
			state_machine.change_to(&"run" if not is_zero_approx(axis) else &"idle")
		else:
			state_machine.change_to(&"fall")
