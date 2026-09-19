extends Node

# GLOBAL SOUND PLAYER (autoload "Sound").
#
# One looping music track plus a small pool of one-shot voices, so a hit and a
# kill in the same frame do not cut each other off.
#
# Files live in res://sound/ as <name>.mp3 / .ogg / .wav:
#   bg              background music (loops)
#   enemy_spotted   an enemy just spotted and started chasing the player
#   hit             player lost health
#   kill            enemy stomped
#   lose            game over
#   run             player running (loops) - only while actually moving
#   trap            player tripped a bear trap
#   win             escaped with every crystal
#
# A missing file is skipped with a warning instead of crashing the game.

const SOUND_DIR = "res://sound/"
const EXTENSIONS = [".mp3", ".ogg", ".wav"]
const ONESHOT_VOICES = 6

const MUSIC_NAME = "bg"
const MUSIC_VOLUME_DB = -10.0
const LOOP_VOLUME_DB = -6.0

var _cache := {}
var _music : AudioStreamPlayer
var _voices : Array[AudioStreamPlayer] = []
var _next_voice := 0
# Named looping channels, e.g. "run" - created on first use.
var _loops := {}


func _ready():
	# Keeps the music and the lose/win stingers audible after the game over
	# screen pauses the SceneTree.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	_music.volume_db = MUSIC_VOLUME_DB
	add_child(_music)

	for i in ONESHOT_VOICES:
		var voice = AudioStreamPlayer.new()
		voice.name = "Voice%d" % i
		add_child(voice)
		_voices.append(voice)

	play_music(MUSIC_NAME)


# LOOPS FOREVER. Calling it again restarts the track only if it changed.
func play_music(sound_name):
	var stream = _load_stream(sound_name)
	if stream == null:
		return

	_loop_stream(stream)

	if _music.stream == stream and _music.playing:
		return

	_music.stream = stream
	_music.play()


func stop_music():
	_music.stop()


# NAMED LOOPING CHANNEL - call it every frame with the current state, it only
# starts or stops when that state actually flips.
func set_looping(sound_name, should_play):
	var voice = _loops.get(sound_name)

	if not should_play:
		if voice != null and voice.playing:
			voice.stop()
		return

	if voice == null:
		voice = AudioStreamPlayer.new()
		voice.name = "Loop_" + sound_name
		voice.volume_db = LOOP_VOLUME_DB
		add_child(voice)
		_loops[sound_name] = voice

	if voice.stream == null:
		var stream = _load_stream(sound_name)
		if stream == null:
			return
		_loop_stream(stream)
		voice.stream = stream

	if not voice.playing:
		voice.play()


# SILENCE EVERY LOOP CHANNEL (game over pauses the tree, so a running player
# would otherwise leave its loop playing on the pause screen).
func stop_loops():
	for voice in _loops.values():
		if voice.playing:
			voice.stop()


# FIRE AND FORGET ONE SHOT
func play(sound_name, volume_db = 0.0):
	var stream = _load_stream(sound_name)
	if stream == null:
		return

	var voice = _free_voice()
	voice.stream = stream
	voice.volume_db = volume_db
	voice.play()


# REUSE A FINISHED VOICE FIRST, THEN ROTATE SO WE NEVER CUT OFF A PLAYING ONE
func _free_voice():
	for voice in _voices:
		if not voice.playing:
			return voice

	var voice = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	return voice


func _load_stream(sound_name):
	if _cache.has(sound_name):
		return _cache[sound_name]

	for ext in EXTENSIONS:
		var path = SOUND_DIR + sound_name + ext
		if ResourceLoader.exists(path):
			var stream = load(path)
			_cache[sound_name] = stream
			return stream

	push_warning("Sound: no file for '%s' in %s" % [sound_name, SOUND_DIR])
	_cache[sound_name] = null
	return null


func _loop_stream(stream):
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
