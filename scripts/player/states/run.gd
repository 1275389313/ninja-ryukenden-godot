extends State
## 跑动：左右移动并转向；无输入回 idle，跳跃/攻击/离地切换对应状态。

var player: Player:
	get:
		return host as Player


func enter(_previous_state: StringName) -> void:
	player.play_anim(&"run")


func state_physics_process(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(axis):
		player.face(int(sign(axis)))
	player.velocity.x = axis * Player.RUN_SPEED
	player.velocity.y += Player.GRAVITY * delta
	player.move_and_slide()

	if not player.is_on_floor():
		state_machine.change_to(&"fall")
		return
	if is_zero_approx(axis):
		state_machine.change_to(&"idle")
		return
	if Input.is_action_just_pressed("jump"):
		state_machine.change_to(&"jump")
		return
	if Input.is_action_just_pressed("attack"):
		state_machine.change_to(&"attack")
