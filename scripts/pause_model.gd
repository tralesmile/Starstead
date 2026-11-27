class_name PauseModel
extends RefCounted
## Pure rules for the pause menu: which rows it shows, volume steps, row rectangles, when a quit may write the save,
## and the small settings file.

const VOLUME_STEPS := 10
const SETTINGS_PATH := "user://settings.json"
const PANEL_W := 220.0
const ROW_H := 24.0
const SCREEN := Vector2(640, 360)
const MUSIC_DEFAULT := 7
static var music := MUSIC_DEFAULT    # music level in VOLUME_STEPS, on top of the master volume

## Row ids in order. `leave` is "" outdoors, else the place name ("building" / "mine").
static func rows(leave: String = "") -> Array:
	var out := ["resume", "save", "volume", "music", "sound", "keys"]
	if leave != "":
		out.append("leave")
	out.append("quit")
	return out

static func label(id: String, volume: int, muted: bool, leave: String = "") -> String:
	match id:
		"resume": return "Resume"
		"save": return "Save game"
		"volume": return "< Volume %d%% >" % (volume * 100 / VOLUME_STEPS)
		"music": return "< Music off >" if music <= 0 else "< Music %d%% >" % (music * 100 / VOLUME_STEPS)
		"sound": return "Sound: %s" % ("off" if muted else "on")
		"keys": return "Controls"
		"leave": return "Leave the %s" % leave
		_: return "Save and quit"

static func move(sel: int, dir: int, count: int) -> int:
	return posmod(sel + dir, maxi(count, 1))

static func step_volume(volume: int, dir: int) -> int:
	return clampi(volume + dir, 0, VOLUME_STEPS)

## Master bus gain in dB. Squared so each step sounds like a similar change; 0 is silence.
static func volume_db(volume: int) -> float:
	var v := clampf(float(volume) / VOLUME_STEPS, 0.0, 1.0)
	return -80.0 if v <= 0.0 else linear_to_db(v * v)

static func panel_rect(count: int) -> Rect2:
	var h := 20.0 + 12.0 + count * ROW_H + 22.0
	return Rect2(((SCREEN - Vector2(PANEL_W, h)) * 0.5).floor(), Vector2(PANEL_W, h))

static func row_rect(i: int, count: int) -> Rect2:
	var r := panel_rect(count)
	return Rect2(r.position + Vector2(12, 30.0 + i * ROW_H), Vector2(PANEL_W - 24.0, ROW_H - 3.0))

static func row_at(p: Vector2, count: int) -> int:
	for i in count:
		if row_rect(i, count).has_point(p):
			return i
	return -1

## Quitting writes the save only in a real session (plain launch or --continue), never in QA/demo runs,
## so a screenshot run can not overwrite a player's farm.
static func quit_saves(args: PackedStringArray) -> bool:
	return args.is_empty() or ("--continue" in args)

static func clean_volume(d, key := "volume", fallback := VOLUME_STEPS) -> int:
	if d is Dictionary and d.has(key) and (d[key] is float or d[key] is int):
		return clampi(int(d[key]), 0, VOLUME_STEPS)
	return fallback

static func read_settings(path: String = SETTINGS_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var d = JSON.parse_string(FileAccess.get_file_as_string(path))
	return d if d is Dictionary else {}

static func load_volume(path: String = SETTINGS_PATH, key := "volume", fallback := VOLUME_STEPS) -> int:
	return clean_volume(read_settings(path), key, fallback)

## Writes one setting and keeps the others.
static func store_volume(volume: int, path: String = SETTINGS_PATH, key := "volume") -> void:
	var d := read_settings(path)
	d[key] = volume
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))
