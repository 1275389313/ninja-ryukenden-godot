extends SceneTree
## Standing melee must register even when the sword is enabled on top of a hurtbox
## (Godot often skips area_entered in that case). Run:
##   godot --headless --path . --script res://tools/melee_hit_check.gd

var _hits: int = 0
var _frames: int = 0
var _hitbox: Hitbox
var _done: bool = false
var _activated: bool = false


func _init() -> void:
	call_deferred("_setup")


func _setup() -> void:
	var player := Node2D.new()
	player.position = Vector2(100, 100)
	root.add_child(player)

	_hitbox = Hitbox.new()
	_hitbox.position = Vector2(12, 0)
	_hitbox.collision_layer = 8
	_hitbox.collision_mask = 16
	_hitbox.monitoring = false
	_hitbox.monitorable = false
	_hitbox.damage = 1
	var sword_cs := CollisionShape2D.new()
	var sword := RectangleShape2D.new()
	sword.size = Vector2(18, 14)
	sword_cs.shape = sword
	_hitbox.add_child(sword_cs)
	player.add_child(_hitbox)

	var boss := Node2D.new()
	# 原点距 20：贴身。剑启用时二者已经重叠。
	boss.position = Vector2(120, 100)
	root.add_child(boss)
	boss.add_child(_make_hurtbox())

	var boss_melee := Node2D.new()
	# 原点距 28：Boss.ATTACK_RANGE，旧判定打不中。
	boss_melee.position = Vector2(128, 100)
	root.add_child(boss_melee)
	boss_melee.add_child(_make_hurtbox())


func _on_hit(_damage: int, _src: Vector2) -> void:
	_hits += 1


func _make_hurtbox() -> Hurtbox:
	var hurtbox := Hurtbox.new()
	hurtbox.collision_layer = 16
	hurtbox.collision_mask = 8
	var hurt_cs := CollisionShape2D.new()
	var hurt := RectangleShape2D.new()
	hurt.size = Vector2(20, 26)
	hurt_cs.shape = hurt
	hurtbox.add_child(hurt_cs)
	hurtbox.hit_received.connect(_on_hit)
	return hurtbox


func _physics_process(_delta: float) -> bool:
	if _hitbox == null or _done:
		return false
	_frames += 1
	if not _activated and _frames >= 2:
		_hitbox.set_active(true)
		_activated = true
		return false
	if _activated and _frames >= 8:
		_done = true
		if _hits < 2:
			push_error("FAIL: standing melee did not register (hits=%s, want 2)" % _hits)
			quit(1)
		else:
			print("MELEE_HIT_OK hits=%s" % _hits)
			quit(0)
		return true
	return false
