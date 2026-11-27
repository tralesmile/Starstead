class_name TitleModel
extends RefCounted
## Pure rules for the title screen: its rows, labels, the two-press "new farm" guard, the layout
## and the chunky pixel lettering of the logo.

const PANEL_W := 232.0
const ROW_H := 22.0
const TOP := 118.0
const LOGO_PX := 6.0    # one logo pixel on the 640x360 screen

## 5x7 letters, only the ones STARSTEAD needs.
const GLYPHS := {
	"S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
	"T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
	"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
	"R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
	"E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
	"D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
}

## The title screen shows on a real launch (plain or --continue), never in QA/demo runs.
static func shows(args: PackedStringArray) -> bool:
	return PauseModel.quit_saves(args)

static func rows(has_save: bool) -> Array:
	var out := ["continue", "new"] if has_save else ["start"]
	out.append_array(["volume", "music", "sound", "keys", "quit"])
	return out

static func label(id: String, volume: int, muted: bool, armed: bool) -> String:
	match id:
		"continue": return "Continue"
		"new": return "Press again to ERASE this farm" if armed else "New farm"
		"start": return "Start farming"
		"quit": return "Quit"
	return PauseModel.label(id, volume, muted)

static func panel_rect(count: int) -> Rect2:
	return Rect2(floorf((640.0 - PANEL_W) * 0.5), TOP, PANEL_W, 30.0 + count * ROW_H + 40.0)

static func row_rect(i: int, count: int) -> Rect2:
	var r := panel_rect(count)
	return Rect2(r.position + Vector2(12, 28.0 + i * ROW_H), Vector2(PANEL_W - 24.0, ROW_H - 3.0))

static func row_at(p: Vector2, count: int) -> int:
	for i in count:
		if row_rect(i, count).has_point(p):
			return i
	return -1

## Logo pixels in logo-pixel units, letters one column apart.
static func logo_cells(word: String) -> Array:
	var out: Array = []
	var x := 0
	for ch in word:
		var g: Array = GLYPHS.get(ch, [])
		for y in g.size():
			var line: String = g[y]
			for i in line.length():
				if line[i] == "1":
					out.append(Vector2i(x + i, y))
		x += 6
	return out

static func logo_width(word: String) -> float:
	return float(maxi(word.length() * 6 - 1, 0)) * LOGO_PX

## Gentle one-wave bob per letter column, in whole screen pixels.
static func bob(letter: int, t: float) -> float:
	return roundf(sin(t * 1.6 - letter * 0.55) * 2.0)

## 0..1 twinkle for star i, each on its own beat.
static func twinkle(i: int, t: float) -> float:
	return clampf(0.5 + 0.5 * sin(t * (1.3 + (i % 5) * 0.37) + i * 2.1), 0.0, 1.0)
