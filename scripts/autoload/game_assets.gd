extends Node
## Central asset loader. Looks under res://assets/sprites and res://assets/audio.
## Missing files fall back to PlaceholderTexture / silent audio so gameplay never crashes.

const SPRITES_ROOT := "res://assets/sprites/"
const AUDIO_ROOT := "res://assets/audio/"

const PLAYER_FRAME := Vector2i(16, 24)
const RUNNER_FRAME := Vector2i(16, 16)
const FLYER_FRAME := Vector2i(16, 16)
const BOSS_FRAME := Vector2i(24, 32)
const TILE_FRAME := Vector2i(16, 16)

const PLAYER_COLOR := Color(0.2, 0.4, 1.0)
const RUNNER_COLOR := Color(0.9, 0.2, 0.2)
const FLYER_COLOR := Color(0.7, 0.3, 0.9)
const BOSS_COLOR := Color(1.0, 0.55, 0.1)

## Linear frame indices into 4-column sheets produced by tools/generate_assets.py.
const PLAYER_ANIMS := {
	"idle": {"frames": [0, 1], "fps": 4.0, "loop": true},
	"run": {"frames": [2, 3, 4, 5], "fps": 10.0, "loop": true},
	"jump": {"frames": [6], "fps": 1.0, "loop": false},
	"fall": {"frames": [7], "fps": 1.0, "loop": false},
	"attack": {"frames": [8, 9, 10], "fps": 12.0, "loop": false},
	"hurt": {"frames": [11], "fps": 1.0, "loop": false},
	"climb": {"frames": [12, 13], "fps": 8.0, "loop": true},
	"dead": {"frames": [14], "fps": 1.0, "loop": false},
}
const RUNNER_ANIMS := {
	"run": {"frames": [0, 1, 2, 3], "fps": 8.0, "loop": true},
}
const FLYER_ANIMS := {
	"fly": {"frames": [0, 1, 2, 3], "fps": 8.0, "loop": true},
}
const BOSS_ANIMS := {
	"idle": {"frames": [0, 1], "fps": 3.0, "loop": true},
	"walk": {"frames": [2, 3, 4, 5], "fps": 6.0, "loop": true},
	"attack": {"frames": [6, 7, 8], "fps": 6.0, "loop": false},
	"dead": {"frames": [9], "fps": 1.0, "loop": false},
}

var _tex_cache: Dictionary = {}
var _frames_cache: Dictionary = {}
var _audio_cache: Dictionary = {}


func has_sprite(rel_path: String) -> bool:
	return _file_exists(SPRITES_ROOT + rel_path)


func has_audio(rel_path: String) -> bool:
	return _file_exists(AUDIO_ROOT + rel_path)


func texture(rel_path: String, fallback_size: Vector2i = TILE_FRAME, fallback_color: Color = Color.MAGENTA) -> Texture2D:
	var res_path := SPRITES_ROOT + rel_path
	if _tex_cache.has(res_path):
		return _tex_cache[res_path]
	var loaded := _load_texture(res_path)
	if loaded != null:
		_tex_cache[res_path] = loaded
		return loaded
	var placeholder := PlaceholderTexture.make(fallback_size, fallback_color)
	_tex_cache[res_path] = placeholder
	return placeholder


func audio(rel_path: String, loop: bool = false) -> AudioStream:
	var cache_key := "%s:%s" % [rel_path, loop]
	if _audio_cache.has(cache_key):
		return _audio_cache[cache_key]
	var res_path := AUDIO_ROOT + rel_path
	var stream := _load_audio(res_path)
	if stream == null:
		_audio_cache[cache_key] = null
		return null
	if loop and stream is AudioStreamWAV:
		var wav := (stream as AudioStreamWAV).duplicate() as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		var bytes_per_frame := 2 if wav.format == AudioStreamWAV.FORMAT_16_BITS else 1
		if wav.stereo:
			bytes_per_frame *= 2
		if bytes_per_frame > 0:
			wav.loop_end = int(wav.data.size() / bytes_per_frame)
		stream = wav
	_audio_cache[cache_key] = stream
	return stream


func player_frames() -> SpriteFrames:
	return frames_from_sheet("player/player.png", PLAYER_FRAME, 4, PLAYER_ANIMS, PLAYER_COLOR)


func runner_frames() -> SpriteFrames:
	return frames_from_sheet("enemies/runner.png", RUNNER_FRAME, 4, RUNNER_ANIMS, RUNNER_COLOR)


func flyer_frames() -> SpriteFrames:
	return frames_from_sheet("enemies/flyer.png", FLYER_FRAME, 4, FLYER_ANIMS, FLYER_COLOR)


func boss_frames() -> SpriteFrames:
	return frames_from_sheet("enemies/boss.png", BOSS_FRAME, 4, BOSS_ANIMS, BOSS_COLOR)


func frames_from_sheet(rel_path: String, frame_size: Vector2i, columns: int, animations: Dictionary, fallback_color: Color) -> SpriteFrames:
	var key := rel_path
	if _frames_cache.has(key):
		return _frames_cache[key]
	var tex := texture(rel_path, frame_size, fallback_color)
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	var sheet_ok := tex.get_width() >= columns * frame_size.x and tex.get_height() >= frame_size.y
	for anim_name in animations:
		var spec: Dictionary = animations[anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, float(spec.get("fps", 8.0)))
		frames.set_animation_loop(anim_name, bool(spec.get("loop", true)))
		var indices: Array = spec.get("frames", [0])
		if sheet_ok:
			for idx in indices:
				var i := int(idx)
				var col := i % columns
				var row := int(i / columns)
				var atlas := AtlasTexture.new()
				atlas.atlas = tex
				atlas.filter_clip = true
				atlas.region = Rect2(col * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)
				frames.add_frame(anim_name, atlas)
		else:
			frames.add_frame(anim_name, tex)
	_frames_cache[key] = frames
	return frames


func make_tiled(tile: Texture2D, dest_size: Vector2i) -> Texture2D:
	dest_size = Vector2i(maxi(1, dest_size.x), maxi(1, dest_size.y))
	var src := tile.get_image()
	if src == null:
		return PlaceholderTexture.make(dest_size, Color(0.23, 0.17, 0.18))
	if src.is_compressed():
		src = src.duplicate()
		src.decompress()
	var out := Image.create(dest_size.x, dest_size.y, false, Image.FORMAT_RGBA8)
	var tw: int = maxi(1, src.get_width())
	var th: int = maxi(1, src.get_height())
	var y := 0
	while y < dest_size.y:
		var x := 0
		while x < dest_size.x:
			var w := mini(tw, dest_size.x - x)
			var h := mini(th, dest_size.y - y)
			out.blit_rect(src, Rect2i(0, 0, w, h), Vector2i(x, y))
			x += tw
		y += th
	return ImageTexture.create_from_image(out)


func apply_polygon_tile(poly: Polygon2D, rel_path: String, fallback_color: Color) -> void:
	if poly == null or poly.polygon.is_empty():
		return
	if not has_sprite(rel_path):
		return
	var tile := texture(rel_path, TILE_FRAME, fallback_color)
	var min_p := poly.polygon[0]
	var max_p := poly.polygon[0]
	for p in poly.polygon:
		min_p.x = minf(min_p.x, p.x)
		min_p.y = minf(min_p.y, p.y)
		max_p.x = maxf(max_p.x, p.x)
		max_p.y = maxf(max_p.y, p.y)
	var size := Vector2i(
		maxi(1, int(round(max_p.x - min_p.x))),
		maxi(1, int(round(max_p.y - min_p.y)))
	)
	poly.texture = make_tiled(tile, size)
	poly.color = Color.WHITE
	var uvs := PackedVector2Array()
	for p in poly.polygon:
		uvs.append(p - min_p)
	poly.uv = uvs


func decorate_parallax(parallax: ParallaxBackground) -> void:
	if parallax == null:
		return
	var far := parallax.get_node_or_null("FarLayer") as ParallaxLayer
	if far != null:
		_cover_color_rect(far, "Sky", "bg/sky.png", Color(0.05, 0.06, 0.12))
		if has_sprite("bg/moon.png") and far.get_node_or_null("Moon") == null:
			var moon := Sprite2D.new()
			moon.name = "Moon"
			moon.texture = texture("bg/moon.png", Vector2i(16, 16), Color(0.9, 0.9, 0.7))
			moon.position = Vector2(210, 36)
			moon.centered = true
			far.add_child(moon)
	# NearLayer is distant scenery only. Never tile walkable ground.png here:
	# a full-width strip ignores collision pits and scrolls, so holes look solid.


func _cover_color_rect(parent: Node, node_name: String, rel_path: String, fallback: Color) -> void:
	var rect := parent.get_node_or_null(node_name) as ColorRect
	if rect == null or not has_sprite(rel_path):
		return
	if parent.get_node_or_null(node_name + "Sprite") != null:
		return
	var w := int(round(rect.offset_right - rect.offset_left))
	var h := int(round(rect.offset_bottom - rect.offset_top))
	if w <= 0 or h <= 0:
		return
	var spr := Sprite2D.new()
	spr.name = node_name + "Sprite"
	spr.centered = false
	spr.position = Vector2(rect.offset_left, rect.offset_top)
	var src := texture(rel_path, TILE_FRAME, fallback)
	spr.texture = make_tiled(src, Vector2i(w, h))
	parent.add_child(spr)
	parent.move_child(spr, rect.get_index())
	rect.visible = false


func _file_exists(res_path: String) -> bool:
	if ResourceLoader.exists(res_path):
		return true
	return FileAccess.file_exists(res_path)


func _load_texture(res_path: String) -> Texture2D:
	if ResourceLoader.exists(res_path):
		var res = ResourceLoader.load(res_path)
		if res is Texture2D:
			return res
	if FileAccess.file_exists(res_path):
		var img := Image.new()
		if img.load(res_path) == OK and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null


func _load_audio(res_path: String) -> AudioStream:
	if ResourceLoader.exists(res_path):
		var res = ResourceLoader.load(res_path)
		if res is AudioStream:
			return res
	if FileAccess.file_exists(res_path):
		return _load_wav_file(res_path)
	return null


func _load_wav_file(res_path: String) -> AudioStreamWAV:
	var f := FileAccess.open(res_path, FileAccess.READ)
	if f == null:
		return null
	f.big_endian = false
	if f.get_buffer(4).get_string_from_ascii() != "RIFF":
		return null
	f.get_32()
	if f.get_buffer(4).get_string_from_ascii() != "WAVE":
		return null
	var format := 1
	var channels := 1
	var rate := 22050
	var bits := 16
	var data := PackedByteArray()
	while f.get_position() + 8 <= f.get_length():
		var chunk_id := f.get_buffer(4).get_string_from_ascii()
		var chunk_size := int(f.get_32())
		var next_pos := int(f.get_position()) + chunk_size
		if chunk_id == "fmt ":
			format = f.get_16()
			channels = f.get_16()
			rate = f.get_32()
			f.get_32()
			f.get_16()
			bits = f.get_16()
		elif chunk_id == "data":
			data = f.get_buffer(chunk_size)
		if next_pos > f.get_length():
			break
		f.seek(next_pos)
		if chunk_size % 2 == 1 and next_pos + 1 <= f.get_length():
			f.seek(next_pos + 1)
	if data.is_empty() or format != 1:
		return null
	var stream := AudioStreamWAV.new()
	if bits == 16:
		stream.format = AudioStreamWAV.FORMAT_16_BITS
	elif bits == 8:
		stream.format = AudioStreamWAV.FORMAT_8_BITS
	else:
		return null
	stream.mix_rate = rate
	stream.stereo = channels == 2
	stream.data = data
	return stream
