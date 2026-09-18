extends SceneTree
## Headless smoke for GameAssets. Run:
##   godot --headless --path . --script res://tools/headless_check.gd
## Scene loads that need autoloads should be checked with:
##   godot --headless --path . --quit-after 2

func _init() -> void:
	var failed := 0
	failed += _expect(ResourceLoader.exists("res://scenes/main.tscn"), "main.tscn missing")
	failed += _expect(ResourceLoader.exists("res://scenes/player/player.tscn"), "player.tscn missing")
	failed += _expect(ResourceLoader.exists("res://scenes/level/level_1.tscn"), "level_1.tscn missing")
	failed += _expect(ResourceLoader.exists("res://scenes/enemies/boss.tscn"), "boss.tscn missing")
	failed += _expect(FileAccess.file_exists("res://assets/sprites/player/player.png"), "player sheet file")
	failed += _expect(FileAccess.file_exists("res://assets/audio/bgm/level.wav"), "bgm file")

	var ga_script := load("res://scripts/autoload/game_assets.gd") as GDScript
	failed += _expect(ga_script != null, "game_assets.gd failed to load")
	var ga: Node = ga_script.new()
	root.add_child(ga)

	var frames: SpriteFrames = ga.call("player_frames")
	failed += _expect(frames != null and frames.has_animation("idle"), "player frames missing idle")
	failed += _expect(frames.get_frame_count("run") == 4, "player run should have 4 frames")
	failed += _expect(ga.call("runner_frames").has_animation("run"), "runner frames")
	failed += _expect(ga.call("flyer_frames").has_animation("fly"), "flyer frames")
	failed += _expect(ga.call("boss_frames").has_animation("attack"), "boss frames")
	failed += _expect(bool(ga.call("has_sprite", "player/player.png")), "committed player sheet should exist")
	failed += _expect(ga.call("audio", "sfx/jump.wav") != null, "jump sfx should load")
	failed += _expect(ga.call("audio", "bgm/level.wav", true) != null, "bgm should load")
	failed += _expect(ga.call("audio", "sfx/does_not_exist.wav") == null, "missing sfx should be null")
	var missing_tex: Texture2D = ga.call("texture", "no/such.png", Vector2i(8, 8), Color.MAGENTA)
	failed += _expect(missing_tex != null, "missing texture should still return placeholder")
	failed += _expect_melee_reaches_boss()
	failed += _expect_pits_not_covered_by_parallax_ground()

	if failed == 0:
		print("HEADLESS_CHECK_OK")
		quit(0)
	else:
		push_error("HEADLESS_CHECK_FAILED count=%s" % failed)
		quit(1)


func _expect(cond: bool, msg: String) -> int:
	if cond:
		return 0
	push_error("FAIL: " + msg)
	return 1


func _expect_melee_reaches_boss() -> int:
	# --script 不加载项目 autoload，不能 instantiate 玩家/Boss 场景；直接读 tscn。
	var player_txt := FileAccess.get_file_as_string("res://scenes/player/player.tscn")
	var boss_txt := FileAccess.get_file_as_string("res://scenes/enemies/boss.tscn")
	var player_gd := FileAccess.get_file_as_string("res://scripts/player/player.gd")
	var failed := 0
	failed += _expect(player_txt.contains("size = Vector2(18, 14)"), "player sword shape 18x14")
	failed += _expect(player_txt.contains("position = Vector2(12, 0)"), "player sword offset 12")
	failed += _expect(player_gd.contains("SWORD_OFFSET_X: float = 12.0"), "SWORD_OFFSET_X is 12")
	failed += _expect(boss_txt.contains("size = Vector2(20, 26)"), "boss hurtbox 20x26")
	# 剑右缘 12+9=21，Boss 受击半宽 10，合计 31 >= Boss.ATTACK_RANGE 28
	var sword_reach := 12.0 + 18.0 * 0.5
	var hurt_half := 20.0 * 0.5
	failed += _expect(sword_reach + hurt_half >= 28.0, "sword+boss hurtbox should reach ATTACK_RANGE")
	failed += _expect(player_txt.contains("collision_layer = 8") and player_txt.contains("collision_mask = 16"), "player sword layers")
	failed += _expect(boss_txt.contains("collision_layer = 16") and boss_txt.contains("collision_mask = 8"), "boss hurtbox layers")
	return failed


func _expect_pits_not_covered_by_parallax_ground() -> int:
	# Walkable floor lives on Terrain Ground* bodies (y 216–240). A parallax
	# GroundStrip or mountain fill in that band draws scrolling ground across pits.
	const GROUND_TOP := 216.0
	var level := FileAccess.get_file_as_string("res://scenes/level/level_1.tscn")
	var assets := FileAccess.get_file_as_string("res://scripts/autoload/game_assets.gd")
	var failed := 0
	failed += _expect(not level.contains("GroundStrip"), "level must not draw a full-width parallax GroundStrip")
	failed += _expect(not assets.contains("GroundStrip"), "decorate_parallax must not tile ground across a GroundStrip")
	failed += _expect(level.contains("KillZone1") and level.contains("KillZone2"), "pit kill zones remain")
	failed += _expect(_polygon_max_y(level, "FarMountains") <= GROUND_TOP, "FarMountains must stay above the ground/pit band")
	failed += _expect(_polygon_max_y(level, "NearMountains") <= GROUND_TOP, "NearMountains must stay above the ground/pit band")
	return failed


func _polygon_max_y(tscn: String, node_name: String) -> float:
	var marker := '[node name="%s"' % node_name
	var i := tscn.find(marker)
	if i < 0:
		return 9999.0
	var poly_i := tscn.find("polygon = PackedVector2Array(", i)
	if poly_i < 0:
		return 9999.0
	var start := poly_i + String("polygon = PackedVector2Array(").length()
	var end := tscn.find(")", start)
	if end < 0:
		return 9999.0
	var nums := tscn.substr(start, end - start).split(", ")
	var max_y := -INF
	var idx := 0
	for s in nums:
		if idx % 2 == 1:
			max_y = maxf(max_y, float(s))
		idx += 1
	return max_y
