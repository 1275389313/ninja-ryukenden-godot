extends State
## Boss 攻击：抬手 0.4s（预警，精灵变黄）→ 身前攻击判定 0.2s → 收招 0.3s → 回行走。
## 攻击期间不移动；预警变色让位于受击闪烁（is_flashing）。

const WINDUP_TIME: float = 0.4
const STRIKE_TIME: float = 0.2
const RECOVER_TIME: float = 0.3

var boss: Boss:
	get:
		return host as Boss

var _timer: float = 0.0
var _phase: int = 0  # 0 抬手，1 判定，2 收招


func enter(_previous_state: StringName) -> void:
	_timer = 0.0
	_phase = 0
	boss.play_anim(&"attack")
	GameAudio.play_sfx("attack")
	boss.velocity.x = 0.0
	# 出手前面向玩家，攻击判定放在身前
	if boss.player != null and is_instance_valid(boss.player):
		boss.sprite.flip_h = boss.player.global_position.x < boss.global_position.x
	boss.attack_hitbox.position.x = -Boss.ATTACK_OFFSET_X if boss.sprite.flip_h else Boss.ATTACK_OFFSET_X
	if not boss.is_flashing():
		boss.sprite.modulate = Color(1.0, 1.0, 0.3)


func exit() -> void:
	boss.attack_hitbox.set_active(false)
	if not boss.is_flashing():
		boss.sprite.modulate = Color.WHITE


func state_physics_process(delta: float) -> void:
	_timer += delta
	boss.velocity.x = 0.0
	boss.velocity.y += EnemyBase.GRAVITY * delta
	boss.move_and_slide()
	match _phase:
		0:
			if not boss.is_flashing():
				boss.sprite.modulate = Color(1.0, 1.0, 0.3)  # 抬手预警，保持黄色
			if _timer >= WINDUP_TIME:
				_phase = 1
				if not boss.is_flashing():
					boss.sprite.modulate = Color.WHITE
				boss.attack_hitbox.set_active(true)
		1:
			if _timer >= WINDUP_TIME + STRIKE_TIME:
				_phase = 2
				boss.attack_hitbox.set_active(false)
		2:
			if _timer >= WINDUP_TIME + STRIKE_TIME + RECOVER_TIME:
				state_machine.change_to(&"walk")
