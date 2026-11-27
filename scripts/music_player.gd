class_name MusicPlayer
extends Node
## Plays MusicSynth loops: composes each one on a worker thread the first time, cross-fades when the mood changes,
## and rests between plays of the calm moods. `level` is the music setting (0..1).

const FADE_SECS := 2.5
const BASE_GAIN := 0.45

var level := 1.0
var muted := false
var duck := 1.0              # lowered by heavy rain
var mood := ""               # what is playing (or fading in)
var want := ""
var gain := 0.0              # eased 0..1
var resting := 0.0
var played := 0.0            # seconds of the current mood since its last rest
var starts: Dictionary = {}  # mood -> times started (QA log)
var _cache: Dictionary = {}  # mood -> AudioStreamWAV
var _task := -1
var _task_mood := ""
var _task_data := PackedByteArray()
var _player := AudioStreamPlayer.new()

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player.volume_db = -60.0
	add_child(_player)

## Where the fade is heading: full while the wanted mood is the one playing and it is not resting.
static func target_gain(playing: String, wanted: String, rest: float) -> float:
	return 1.0 if playing == wanted and rest <= 0.0 else 0.0

static func rest_due(for_mood: String, secs_played: float) -> bool:
	if for_mood in MusicSynth.CONSTANT:
		return false
	return secs_played >= MusicSynth.loop_seconds(for_mood) * MusicSynth.PLAYS_BEFORE_REST

func set_mood(m: String) -> void:
	want = m

## Runs under the pause menu too, so the music setting and mute apply while you change them.
func _process(delta: float) -> void:
	level = float(PauseModel.music) / PauseModel.VOLUME_STEPS
	muted = Sfx.all_muted
	update(delta)

func update(delta: float) -> void:
	_collect()
	if want == "":
		return
	if mood != want and gain <= 0.001:
		_player.stop()
		mood = ""
		if _cache.has(want):
			mood = want
			played = 0.0
			resting = 0.0
			_player.stream = _cache[want]
		else:
			_compose(want)
	if resting > 0.0:
		resting -= delta
		if resting <= 0.0:
			played = 0.0
	elif mood != "":
		played += delta
		if rest_due(mood, played):
			resting = MusicSynth.REST_SECS
	gain = move_toward(gain, target_gain(mood, want, resting) if mood != "" else 0.0, delta / FADE_SECS)
	var out := gain * level * duck * BASE_GAIN
	if muted or out <= 0.005 or mood == "":
		if _player.playing:
			_player.stop()
		return
	_player.volume_db = linear_to_db(out)
	if _player.is_inside_tree() and not _player.playing:
		_player.play()
		starts[mood] = int(starts.get(mood, 0)) + 1

func _compose(m: String) -> void:
	if _task >= 0:
		return
	_task_mood = m
	_task = WorkerThreadPool.add_task(func(): _task_data = MusicSynth.render(m))

func _collect() -> void:
	if _task < 0 or not WorkerThreadPool.is_task_completed(_task):
		return
	WorkerThreadPool.wait_for_task_completion(_task)
	_task = -1
	_cache[_task_mood] = MusicSynth.stream(_task_data)
	_task_data = PackedByteArray()

func _exit_tree() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
