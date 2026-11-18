class_name Hud
extends CanvasLayer
## Clock, day, season, money labels bound to GameState, plus a readable energy bar (and a fuel gauge while driving).

var label: Label
var bars: Control
var car = null   # CarView, set by main (fuel gauge while driving)
var _t := 0.0

func _init() -> void:
	label = Label.new()
	label.position = Vector2(8, 6)
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
	bars.draw_string(font, pos + Vector2(w - 2, 8), txt, HORIZONTAL_ALIGNMENT_RIGHT, -1, 8, Color(1, 1, 1))

func _draw_bars() -> void:
	var e: Energy = GameState.energy
	_bar(Vector2(8, 22), 88, HudBars.frac(e.value, Energy.MAX), "EN", HudBars.text(e.value, Energy.MAX).replace("/" + str(Energy.MAX), ""))
	if car != null and car.driving:
		var f := HudBars.frac(car.fuel, VehicleMath.FUEL_MAX)
		_bar(Vector2(8, 34), 88, f, "FUEL", "%d%%" % int(f * 100.0))
