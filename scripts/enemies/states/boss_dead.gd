extends State
## Boss 死亡：停止移动，闪烁 1.0s 后广播 boss_defeated 并隐藏，再 0.5s 后通关。
## 本状态为终态，不回对象池。

const DEFEAT_FLASH_TIME: float = 1.0
const CLEAR_DELAY: float = 0.5

var boss: Boss:
	get:
		return host as Boss

var _timer: float = 0.0
var _defeated_emitted: bool = false
var _clear_called: bool = false


func enter(_previous_state: StringName) -> void:
	_timer = 0.0
	_defeated_emitted = false
	_clear_called = false
	boss.play_anim(&"dead")
	boss.velocity = Vector2.ZERO
	boss.sprite.modulate = Color.WHITE
	# 关闭全部判定（可能在物理回调中进入，统一走 deferred）
	boss.hurtbox.set_deferred("monitoring", false)
	boss.hurtbox.set_deferred("monitorable", false)
	boss.hitbox.set_deferred("monitoring", false)
	boss.hitbox.set_deferred("monitorable", false)
	boss.attack_hitbox.set_active(false)


func state_physics_process(delta: float) -> void:
	boss.velocity.x = 0.0
	boss.velocity.y += EnemyBase.GRAVITY * delta
	boss.move_and_slide()


func state_process(delta: float) -> void:
	_timer += delta
	if _timer < DEFEAT_FLASH_TIME:
		boss.sprite.visible = int(_timer * 10.0) % 2 == 0  # 快速闪烁
	elif not _defeated_emitted:
		_defeated_emitted = true
		boss.visible = false
		GameEvents.boss_defeated.emit()
	if _defeated_emitted and not _clear_called and _timer >= DEFEAT_FLASH_TIME + CLEAR_DELAY:
		_clear_called = true
		GameManager.on_level_cleared()
