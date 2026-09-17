extends State
## 下落：空中可控水平移动；落地回 idle/run，可攀墙时进入 wallcling。

var player: Player:
	get:
		return host as Player


func state_physics_process(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(axis):
		player.face(int(sign(axis)))
		player.velocity.x = axis * Player.RUN_SPEED
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, 400.0 * delta)
	player.velocity.y += Player.GRAVITY * delta
	player.move_and_slide()

	if player.is_on_floor():
		state_machine.change_to(&"run" if not is_zero_approx(axis) else &"idle")
		return
	if player.get_wall_dir() != 0:
		state_machine.change_to(&"wallcling")
		return
	if Input.is_action_just_pressed("attack"):
		state_machine.change_to(&"attack")
