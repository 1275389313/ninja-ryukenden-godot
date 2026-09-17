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
