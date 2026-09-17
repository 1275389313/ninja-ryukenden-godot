extends Node2D
## 第一关：地形 / 摄像机 / 视差背景 / 玩家重生。
## 敌人布点（SpawnTrigger）与 Boss 触发区由后续任务接入，BossArenaMarker 已预留。

const RESPAWN_POSITION := Vector2(40, 196)
const CAMERA_Y: float = 120.0
const CAMERA_FOLLOW_SPEED: float = 8.0
const RESPAWN_DELAY: float = 1.0

@onready var player: Player = get_node_or_null("Player") as Player
@onready var camera: Camera2D = get_node_or_null("Camera2D") as Camera2D
@onready var terrain: Node2D = get_node_or_null("Terrain") as Node2D


func _ready() -> void:
	GameManager.respawn_position = RESPAWN_POSITION
	GameEvents.player_died.connect(_on_player_died)
	_snap_camera(RESPAWN_POSITION)
	_apply_level_art()


func _physics_process(delta: float) -> void:
	if player == null or camera == null:
		return
	var pos := camera.global_position
	pos.x = lerpf(pos.x, player.global_position.x, CAMERA_FOLLOW_SPEED * delta)
	pos.y = CAMERA_Y
	camera.global_position = pos


func _on_player_died() -> void:
	if player == null:
		return
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	# 等待期间玩家被移除或已被其他逻辑复活时静默返回
	if player == null or not player.is_dead():
		return
	player.respawn(GameManager.respawn_position)
	_snap_camera(GameManager.respawn_position)
	GameManager.reset_timer()
	GameManager.is_playing = true


## 摄像机立即对准目标位置（重置平滑，之后再由 limit 夹取）。
func _snap_camera(target: Vector2) -> void:
	if camera == null:
		return
	camera.global_position = Vector2(target.x, CAMERA_Y)


func _apply_level_art() -> void:
	GameAssets.decorate_parallax(get_node_or_null("ParallaxBackground") as ParallaxBackground)
	if terrain != null:
		for child in terrain.get_children():
			var poly := child.get_node_or_null("Polygon2D") as Polygon2D
			if poly == null:
				continue
			var tile_path := "tiles/ground.png"
			var n := String(child.name)
			if n.begins_with("Plat") or n.begins_with("Float") or n.begins_with("Drop"):
				tile_path = "tiles/platform.png"
			elif n.begins_with("Bound"):
				tile_path = "tiles/wall.png"
			elif n.begins_with("Start") or n.begins_with("Step"):
				tile_path = "tiles/brick.png"
			var fallback := Color(0.26, 0.2, 0.21) if tile_path.ends_with("platform.png") else Color(0.23, 0.17, 0.18)
			GameAssets.apply_polygon_tile(poly, tile_path, fallback)
	var wall := get_node_or_null("WallClimb/Polygon2D") as Polygon2D
	if wall != null:
		GameAssets.apply_polygon_tile(wall, "tiles/wall.png", Color(0.16, 0.24, 0.26))
