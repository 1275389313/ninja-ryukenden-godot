class_name Hitbox
extends Area2D
## 攻击判定区（玩家与敌人共用）。
## 默认不激活，攻击时由实体调用 set_active(true) 启用。
##
## Godot Area2D 在「已重叠时把 monitorable/monitoring 从关拨开」时经常不发
## area_entered（#71489 / #79464）。近战站桩挥砍必须在启用后主动查询重叠。

@export var damage: int = 1

## 本轮激活已打到的 Hurtbox，避免 query 与 area_entered 重复扣血。
var _struck: Dictionary = {}


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func set_active(on: bool) -> void:
	# Area2D 的 monitoring/monitorable 可能在物理回调中被切换，统一走 deferred
	if on:
		_struck.clear()
	set_deferred("monitoring", on)
	set_deferred("monitorable", on)
	if on:
		# 排在上面两次 set_deferred 之后：monitoring 已为 true 再扫当前重叠。
		call_deferred("_hit_current_overlaps")


func try_hit(area: Area2D) -> void:
	if not monitoring or area == null or not (area is Hurtbox):
		return
	var id := area.get_instance_id()
	if _struck.has(id):
		return
	_struck[id] = true
	(area as Hurtbox).hit_received.emit(damage, global_position)


func _on_area_entered(area: Area2D) -> void:
	try_hit(area)


func _on_area_exited(area: Area2D) -> void:
	_struck.erase(area.get_instance_id())


func _hit_current_overlaps() -> void:
	if not is_instance_valid(self) or not monitoring:
		return
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null or shape_node.disabled:
		return
	var world := get_world_2d()
	if world == null:
		return
	var space := world.direct_space_state
	if space == null:
		return
	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape_node.shape
	params.transform = shape_node.global_transform
	params.collision_mask = collision_mask
	params.collide_with_areas = true
	params.collide_with_bodies = false
	params.exclude = [get_rid()]
	for result in space.intersect_shape(params, 16):
		var collider = result.get("collider")
		if collider is Area2D:
			try_hit(collider)
