extends State
## 死亡：小幅上抛后下落，禁用受击框，0.6s 后通知 GameManager。

const DEAD_DURATION: float = 0.6

var player: Player:
	get:
		return host as Player

var _timer: float = 0.0
var _notified: bool = false


func enter(_previous_state: StringName) -> void:
	_timer = 0.0
	_notified = false
	player.play_anim(&"dead")
	player.set_sword_active(false)
	player.velocity = Vector2(0.0, -140.0)
	player.hurtbox.set_deferred("monitoring", false)


func state_physics_process(delta: float) -> void:
	_timer += delta
	player.velocity.y += Player.GRAVITY * delta
	player.move_and_slide()

	if _timer >= DEAD_DURATION and not _notified:
		_notified = true
		GameManager.on_player_death()
