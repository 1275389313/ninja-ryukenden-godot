extends State
## 贴墙攀爬：上下移动；跳=蹬墙跳，按反方向=松手下落，落地回 idle。

var player: Player:
	get:
		return host as Player

var _wall_dir: int = 1  # 墙所在方向（1 右，-1 左）


func enter(_previous_state: StringName) -> void:
	_wall_dir = player.get_wall_dir()
	if _wall_dir == 0:
		_wall_dir = player.facing
	player.velocity = Vector2.ZERO


func state_physics_process(_delta: float) -> void:
	var ray := player.wall_ray_right if _wall_dir > 0 else player.wall_ray_left

	if Input.is_action_just_pressed("jump"):
		# 蹬墙跳：背向墙弹出（vy 由 jump 状态保留，因为 previous 是 wallcling）
		player.face(-_wall_dir)
		player.velocity = Vector2(-_wall_dir * Player.RUN_SPEED, Player.JUMP_VELOCITY * 0.9)
		state_machine.change_to(&"jump")
		return

	var away_action := "move_left" if _wall_dir > 0 else "move_right"
	if Input.is_action_pressed(away_action):
		state_machine.change_to(&"fall")
		return

	if not ray.is_colliding():
		state_machine.change_to(&"fall")
		return

	player.velocity.x = 0.0
	if Input.is_action_pressed("move_up"):
		player.velocity.y = -Player.CLIMB_SPEED
	elif Input.is_action_pressed("move_down"):
		player.velocity.y = Player.CLIMB_SPEED
	else:
		player.velocity.y = 0.0
	player.move_and_slide()

	if player.is_on_floor():
		state_machine.change_to(&"idle")
