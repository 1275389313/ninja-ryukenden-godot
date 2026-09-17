extends Node
## SFX / BGM players. Missing streams are a no-op (no error spam).

const SFX_VOICES := 4

var _bgm: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _bgm_name := ""


func _ready() -> void:
	_bgm = AudioStreamPlayer.new()
	_bgm.name = "BgmPlayer"
	add_child(_bgm)
	for i in SFX_VOICES:
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		add_child(player)
		_sfx.append(player)


func play_sfx(sfx_name: String) -> void:
	var stream: AudioStream = GameAssets.audio("sfx/%s.wav" % sfx_name)
	if stream == null:
		return
	var voice := _free_sfx_player()
	if voice == null:
		return
	voice.stream = stream
	voice.play()


func play_bgm(track_name: String) -> void:
	var stream: AudioStream = GameAssets.audio("bgm/%s.wav" % track_name, true)
	if stream == null:
		stop_bgm()
		return
	if _bgm_name == track_name and _bgm.playing:
		return
	_bgm_name = track_name
	_bgm.stream = stream
	_bgm.play()


func stop_bgm() -> void:
	_bgm_name = ""
	if _bgm != null:
		_bgm.stop()
		_bgm.stream = null


func _free_sfx_player() -> AudioStreamPlayer:
	for player in _sfx:
		if not player.playing:
			return player
	if _sfx.is_empty():
		return null
	return _sfx[0]
