extends State
## 待机：速度衰减到 0，响应移动/跳跃/攻击输入。

var player: Player:
	get:
		return host as Player


func enter(_previous_state: StringName) -> void:
	player.play_anim(&"idle")


func state_physics_process(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0.0, 800.0 * delta)
	player.velocity.y += Player.GRAVITY * delta
	player.move_and_slide()

	if not player.is_on_floor():
		state_machine.change_to(&"fall")
		return

	var axis := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(axis):
		state_machine.change_to(&"run")
		return
	if Input.is_action_just_pressed("jump"):
		state_machine.change_to(&"jump")
		return
	if Input.is_action_just_pressed("attack"):
		state_machine.change_to(&"attack")
