class_name Sfx
extends Node
## Plays SfxSynth sounds: a small pool for one-shots (cached streams, variants, pitch jitter, per-name rate limit)
## and one player per ambience loop with eased volumes. Safe headless and before the node enters the tree.

const POOL_SIZE := 8
const AMBIENCE_EASE := 1.5     # volume change per second (0..1 scale)
const AMBIENCE_GAIN := 0.6     # ambience sits under the one-shots
const VARIANTS := {"step_grass": 3, "step_path": 3, "step_wood": 3, "step_snow": 3, "step_wet": 3, "chop": 3, "mine": 3}
const DEFAULT_INTERVAL := 0.05
const MIN_INTERVAL := {
	"step_grass": 0.16, "step_path": 0.16, "step_wood": 0.16, "step_snow": 0.16, "step_wet": 0.16,
	"chop": 0.1, "mine": 0.1, "tree_fall": 0.5, "water_pour": 0.4, "splash": 0.15, "pickup": 0.06, "coin": 0.08,
	"bow_draw": 0.3, "error": 0.25, "ship_horn": 2.0}
const NO_JITTER: Array[String] = ["coin", "bow_perfect", "ui_open", "ui_close", "error", "ship_horn"]

var muted := false
static var all_muted := false        # mirrors `muted` for players outside this node (car engine, tyre squeal)
static var vehicles_hushed := false  # set by SfxDirector while a menu is open or the player is indoors
var play_counts: Dictionary = {}       # name -> times played
var ambience: Dictionary = {}          # loop name -> current eased level 0..1

var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _loop_players: Dictionary = {}     # loop name -> AudioStreamPlayer
var _cache: Dictionary = {}            # "name#variant" -> AudioStreamWAV
var _last_time: Dictionary = {}        # name -> seconds of the last play
var _last_variant: Dictionary = {}
var _rng := RandomNumberGenerator.new()

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # menu clicks still sound while the game is paused
	_rng.randomize()
	all_muted = false
	vehicles_hushed = false
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	for k in SfxSynth.LOOPS:
		var p := AudioStreamPlayer.new()
		p.volume_db = SfxSynth.SILENT_DB
		add_child(p)
		_loop_players[k] = p
		ambience[k] = 0.0

func play(name: String, gain: float = 1.0, pitch: float = 1.0) -> bool:
	## true if the sound was started (false: muted, silent gain, unknown name or rate limited).
	if muted or gain <= 0.01 or not (name in SfxSynth.NAMES):
		return false
	var now := _now()
	if _last_time.has(name) and now - float(_last_time[name]) < float(MIN_INTERVAL.get(name, DEFAULT_INTERVAL)):
		return false
	_last_time[name] = now
	var p := _free_player()
	p.stream = _stream(name, _pick_variant(name))
	p.volume_db = linear_to_db(minf(gain, 2.0))
	var jitter := 1.0 if name in NO_JITTER else _rng.randf_range(0.95, 1.05)
	p.pitch_scale = clampf(pitch * jitter, 0.25, 4.0)
	if p.is_inside_tree():
		p.play()
	play_counts[name] = int(play_counts.get(name, 0)) + 1
	return true

func set_ambience(levels: Dictionary, delta: float) -> void:
	## Call every frame with SfxSynth.ambience_levels(); volumes ease and silent loops stop. Missing keys mean 0.
	for k in SfxSynth.LOOPS:
		var target := clampf(float(levels.get(k, 0.0)), 0.0, 1.0)
		var cur := move_toward(float(ambience[k]), target, AMBIENCE_EASE * maxf(delta, 0.0))
		ambience[k] = cur
		var p: AudioStreamPlayer = _loop_players[k]
		if muted or cur <= 0.01:
			if p.playing:
				p.stop()
			p.volume_db = SfxSynth.SILENT_DB
			continue
		if p.stream == null:
			p.stream = _stream(k, 0)  # synthesised the first time it is heard
		p.volume_db = SfxSynth.volume_db(cur * AMBIENCE_GAIN)
		if p.is_inside_tree() and not p.playing:
			p.play()

func set_muted(value: bool) -> void:
	muted = value
	all_muted = value
	if muted:
		for p in _pool:
			p.stop()
		for p in _loop_players.values():
			p.stop()

func toggle_mute() -> bool:
	## Returns the new muted state.
	set_muted(not muted)
	return muted

func _now() -> float:
	return Time.get_ticks_usec() / 1000000.0

func _stream(name: String, variant: int) -> AudioStreamWAV:
	var key := "%s#%d" % [name, variant]
	if not _cache.has(key):
		_cache[key] = SfxSynth.stream(name, variant)
	return _cache[key]

func _pick_variant(name: String) -> int:
	var count := int(VARIANTS.get(name, 1))
	if count <= 1:
		return 0
	var v := _rng.randi() % count
	if v == int(_last_variant.get(name, -1)):
		v = (v + 1) % count
	_last_variant[name] = v
	return v

func _free_player() -> AudioStreamPlayer:
	## An idle player, else steal in round-robin order.
	for i in POOL_SIZE:
		var j := (_next + i) % POOL_SIZE
		if not _pool[j].playing:
			_next = (j + 1) % POOL_SIZE
			return _pool[j]
	var p := _pool[_next]
	_next = (_next + 1) % POOL_SIZE
	return p
