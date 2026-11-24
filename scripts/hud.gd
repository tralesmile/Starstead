class_name Hud
extends CanvasLayer
## Clock, day, season, money labels bound to GameState, plus a readable energy bar (and a fuel gauge while driving).

var label: Label
var bars: Control
var car = null   # CarView, set by main (fuel gauge while driving)
var legend_mode := "foot"   # KeyLegend mode, set by main each frame
var legend_on := true       # F1 toggles
var _t := 0.0

func _init() -> void:
	label = Label.new()   # kept for callers; the framed panel below replaces it on screen
	label.visible = false
	add_child(label)
	bars = Control.new()
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.set_anchors_preset(Control.PRESET_FULL_RECT)
	bars.draw.connect(_draw_bars)
	add_child(bars)

func _process(d: float) -> void:
	_t += d
	label.text = HudText.format(GameState.clock, GameState.money)
	bars.queue_redraw()

func _bar(pos: Vector2, w: float, f: float, tag: String, txt: String) -> void:
	var font := ThemeDB.fallback_font
	bars.draw_rect(Rect2(pos - Vector2(1, 1), Vector2(w + 2, 11)), Color(0, 0, 0, 0.8))
	bars.draw_rect(Rect2(pos, Vector2(w, 9)), Color(0.15, 0.13, 0.1))
	var col := HudBars.bar_color(f)
	if HudBars.low(f) and fmod(_t, 0.8) < 0.4:
		col = col.lightened(0.4)
	bars.draw_rect(Rect2(pos, Vector2(w * f, 9)), col)
	bars.draw_rect(Rect2(pos, Vector2(w * f, 2)), col.lightened(0.3))
	bars.draw_string(font, pos + Vector2(3, 8), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1))
	_rtext(pos + Vector2(w - 2, 8), txt, 8, Color(1, 1, 1))

const WOOD_D := Color(0.36, 0.21, 0.10)
const WOOD := Color(0.55, 0.34, 0.17)
const WOOD_L := Color(0.73, 0.49, 0.26)
const INK := Color(0.24, 0.15, 0.08)
const PAPER := Color(0.94, 0.87, 0.68)
const PANEL := Rect2(4, 4, 132, 52)

func _rtext(right_base: Vector2, txt: String, size: int, col: Color) -> void:
	## Right-aligned text ending at right_base.x (draw_string ignores alignment without a width).
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	bars.draw_string(font, Vector2(right_base.x - w, right_base.y), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

func _frame(r: Rect2) -> void:
	## Pixel-art wooden frame: dark outline, 3px plank border lit on top/left, parchment inside with a soft inner shadow.
	bars.draw_rect(r.grow(1), Color(0.13, 0.08, 0.04, 0.95))
	bars.draw_rect(r, WOOD)
	bars.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), WOOD_L)
	bars.draw_rect(Rect2(r.position, Vector2(1, r.size.y)), WOOD_L)
	bars.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 1), Vector2(r.size.x, 1)), WOOD_D)
	bars.draw_rect(Rect2(r.position + Vector2(r.size.x - 1, 0), Vector2(1, r.size.y)), WOOD_D)
	for x in range(int(r.position.x) + 9, int(r.end.x) - 4, 23):   # plank joints + nail heads
		bars.draw_rect(Rect2(x, r.position.y, 1, 3), WOOD_D)
		bars.draw_rect(Rect2(x - 3, r.position.y + 1, 1, 1), WOOD_L)
	var inner := r.grow(-3)
	bars.draw_rect(inner, PAPER)
	bars.draw_rect(Rect2(inner.position, Vector2(inner.size.x, 1)), PAPER.darkened(0.18))
	bars.draw_rect(Rect2(inner.position, Vector2(1, inner.size.y)), PAPER.darkened(0.12))

func _dial(c: Vector2, hour: float) -> void:
	## Half-disc sky window: the sun (day) or moon (night) travels left to right across it.
	var d := HudText.dial(hour)
	var day: bool = d["day"]
	var sky := Color(0.45, 0.72, 0.92) if day else Color(0.12, 0.14, 0.32)
	if day and (float(d["t"]) < 0.12 or float(d["t"]) > 0.88):
		sky = Color(0.95, 0.62, 0.38)   # dawn / dusk glow
	bars.draw_circle(c, 11.0, INK)
	bars.draw_circle(c, 10.0, sky)
	bars.draw_rect(Rect2(c.x - 11, c.y + 1, 23, 11), PAPER)   # only the upper half shows
	bars.draw_rect(Rect2(c.x - 11, c.y, 23, 1), INK)
	var a := PI * (1.0 - float(d["t"]))
	var p := c + Vector2(cos(a), -sin(a)) * 7.0
	if day:
		bars.draw_circle(p, 2.6, Color(1.0, 0.86, 0.3))
		bars.draw_circle(p - Vector2(0.6, 0.6), 1.2, Color(1.0, 0.97, 0.75))
	else:
		bars.draw_circle(p, 2.4, Color(0.92, 0.93, 0.98))
		bars.draw_circle(p + Vector2(1.0, -0.6), 1.8, Color(0.12, 0.14, 0.32))   # crescent
		if not day:
			bars.draw_rect(Rect2(c.x - 6, c.y - 6, 1, 1), Color(1, 1, 1, 0.8))
			bars.draw_rect(Rect2(c.x + 4, c.y - 8, 1, 1), Color(1, 1, 1, 0.6))

func _coin(c: Vector2) -> void:
	bars.draw_circle(c, 4.0, Color(0.45, 0.30, 0.05))
	bars.draw_circle(c, 3.0, Color(0.93, 0.74, 0.22))
	bars.draw_rect(Rect2(c.x - 1, c.y - 2, 1, 2), Color(1.0, 0.95, 0.65))

func _legend() -> void:
	## Small bottom-right panel: the keys that matter right now (KeyLegend), dimmed so it never competes with the world.
	var font := ThemeDB.fallback_font
	var rows := KeyLegend.rows(legend_mode)
	var sz := get_viewport().get_visible_rect().size
	var w := KeyLegend.panel_width(legend_mode)
	var h := 6.0 + rows.size() * 11.0
	var r := Rect2(sz.x - w - 4, sz.y - h - 22, w, h)
	bars.draw_rect(r.grow(1), Color(0.1, 0.06, 0.03, 0.55))
	bars.draw_rect(r, Color(0.94, 0.87, 0.68, 0.55))
	for i in rows.size():
		var y := r.position.y + 11.0 + i * 11.0
		bars.draw_string(font, Vector2(r.position.x + 4, y), String(rows[i][0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.42, 0.24, 0.05))
		_rtext(Vector2(r.end.x - 4, y), String(rows[i][1]), 8, INK)

func _draw_bars() -> void:
	var font := ThemeDB.fallback_font
	var c: GameClock = GameState.clock
	_frame(PANEL)
	var hour := float(c.hour()) + float(c.minute()) / 60.0
	_dial(PANEL.position + Vector2(17, 20), hour)
	bars.draw_string(font, PANEL.position + Vector2(33, 15), HudText.date_text(c), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, INK)
	_rtext(PANEL.position + Vector2(PANEL.size.x - 6, 15), c.time_string(), 11, INK)
	bars.draw_rect(Rect2(PANEL.position + Vector2(33, 19), Vector2(PANEL.size.x - 39, 1)), PAPER.darkened(0.2))
	_coin(PANEL.position + Vector2(38, 27))
	_rtext(PANEL.position + Vector2(PANEL.size.x - 6, 31), HudText.money_text(GameState.money), 11, Color(0.42, 0.28, 0.02))
	if legend_on:
		_legend()
	var e: Energy = GameState.energy
	_bar(PANEL.position + Vector2(6, 38), PANEL.size.x - 12, HudBars.frac(e.value, Energy.MAX), "EN", HudBars.text(e.value, Energy.MAX).replace("/" + str(Energy.MAX), ""))
	if car != null and car.driving:
		var f := HudBars.frac(car.fuel, VehicleMath.FUEL_MAX)
		_bar(Vector2(PANEL.position.x + 6, PANEL.end.y + 3), PANEL.size.x - 12, f, "FUEL", "%d%%" % int(f * 100.0))
