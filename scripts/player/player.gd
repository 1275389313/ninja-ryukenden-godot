class_name Player
extends CharacterBody2D
## 玩家角色（仿 FC 忍者龙剑传）。
## 物理更新由各状态在 state_physics_process 中完成（含 move_and_slide）。

const RUN_SPEED: float = 90.0
const JUMP_VELOCITY: float = -240.0
const GRAVITY: float = 600.0
const CLIMB_SPEED: float = 40.0
const KNOCKBACK_SPEED: float = 120.0
const KNOCKBACK_UP: float = -120.0
const HURT_DURATION: float = 0.4
const INVINCIBLE_DURATION: float = 1.0
const ATTACK_DURATION: float = 0.25

const SWORD_OFFSET_X: float = 12.0

var facing: int = 1  # 1 右，-1 左
var last_damage_source: Vector2 = Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var sword_hitbox: Hitbox = $SwordHitbox
@onready var wall_ray_right: RayCast2D = $WallRayRight
@onready var wall_ray_left: RayCast2D = $WallRayLeft
@onready var state_machine: StateMachine = $StateMachine
@onready var health: Health = $Health
@onready var invincible_timer: Timer = $InvincibleTimer


func _ready() -> void:
	sprite.sprite_frames = GameAssets.player_frames()
	sprite.offset = Vector2(0, -3)  # 脚对齐碰撞体底部
	play_anim(&"idle")
	hurtbox.hit_received.connect(_on_hurtbox_hit)
	health.damaged.connect(_on_health_damaged)
	health.died.connect(_on_health_died)
	invincible_timer.timeout.connect(_on_invincible_timeout)
	face(facing)
	GameEvents.player_health_changed.emit(health.current, health.max_value)


func _process(_delta: float) -> void:
	# 无敌帧闪烁：按计时器剩余时间快速切换透明度
	if not invincible_timer.is_stopped():
		sprite.modulate.a = 0.25 if int(invincible_timer.time_left * 20.0) % 2 == 0 else 1.0


# ---- 公共 API（关卡 / 后续任务依赖，签名不得更改） ----

func die() -> void:
	if not is_dead():
		state_machine.change_to(&"dead")


func respawn(pos: Vector2) -> void:
	position = pos
	velocity = Vector2.ZERO
	health.reset_health()
	invincible_timer.stop()
	sprite.modulate.a = 1.0
	hurtbox.set_deferred("monitoring", true)
	state_machine.change_to(&"idle")
	GameEvents.player_health_changed.emit(health.current, health.max_value)


func take_hit(damage: int, source_position: Vector2) -> void:
	health.take_damage(damage, source_position)


func is_dead() -> bool:
	return state_machine.current_state != null \
		and state_machine.current_state.name.to_lower() == "dead"


func set_sword_active(on: bool) -> void:
	sword_hitbox.set_active(on)


func play_anim(anim: StringName) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if not sprite.sprite_frames.has_animation(anim):
		return
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)


func face(dir: int) -> void:
	if dir == 0:
		return
	facing = dir
	sprite.flip_h = dir < 0
	sword_hitbox.position.x = SWORD_OFFSET_X * dir
	wall_ray_right.enabled = dir > 0
	wall_ray_left.enabled = dir < 0


## 返回玩家正推向的墙壁方向（1 右墙，-1 左墙，0 无）。
func get_wall_dir() -> int:
	if wall_ray_right.enabled and wall_ray_right.is_colliding() \
			and Input.is_action_pressed("move_right"):
		return 1
	if wall_ray_left.enabled and wall_ray_left.is_colliding() \
			and Input.is_action_pressed("move_left"):
		return -1
	return 0


# ---- 信号回调 ----

func _on_hurtbox_hit(damage: int, source_position: Vector2) -> void:
	health.take_damage(damage, source_position)


func _on_health_damaged(_amount: int, source_position: Vector2) -> void:
	last_damage_source = source_position
	GameEvents.player_health_changed.emit(health.current, health.max_value)
	health.set_invincible_duration(INVINCIBLE_DURATION)
	invincible_timer.start(INVINCIBLE_DURATION)
	if health.current > 0 and not is_dead():
		state_machine.change_to(&"hurt")


func _on_health_died() -> void:
	die()


func _on_invincible_timeout() -> void:
	sprite.modulate.a = 1.0
