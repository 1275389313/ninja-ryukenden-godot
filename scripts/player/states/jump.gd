extends State
## 跳跃：进入时施加起跳速度（蹬墙跳除外），空中可控水平移动。

var player: Player:
	get:
		return host as Player


const RECLING_LOCK: float = 0.15  # 蹬墙跳后短时间内禁止重新贴墙

var _cling_lock: float = 0.0


func enter(previous_state: StringName) -> void:
	player.play_anim(&"jump")
	GameAudio.play_sfx("jump")
	if previous_state == &"wallcling":
		_cling_lock = RECLING_LOCK
	else:
		_cling_lock = 0.0
		player.velocity.y = Player.JUMP_VELOCITY


func state_physics_process(delta: float) -> void:
	_cling_lock = maxf(0.0, _cling_lock - delta)
	var axis := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(axis):
		player.face(int(sign(axis)))
		player.velocity.x = axis * Player.RUN_SPEED
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, 400.0 * delta)
	player.velocity.y += Player.GRAVITY * delta
	player.move_and_slide()

	if player.velocity.y >= 0.0:
		state_machine.change_to(&"fall")
		return
	if _cling_lock <= 0.0 and player.get_wall_dir() != 0:
		state_machine.change_to(&"wallcling")
		return
	if Input.is_action_just_pressed("attack"):
		state_machine.change_to(&"attack")
