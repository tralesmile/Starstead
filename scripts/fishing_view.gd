class_name FishingView
extends CanvasLayer
## Fishing UI: status text while waiting/biting, framed reel track with the fish icon and the green catch bar.

var fishing: Fishing
var _draw: Control
var item_tex: Texture2D = load("res://assets/sprites/items.png")
var icons: Dictionary = DataDB.load_json("item_icons")

func _init(f: Fishing) -> void:
	fishing = f
	layer = 5
	_draw = Control.new()
	_draw.draw.connect(_on_draw)
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_draw)

func _process(_d: float) -> void:
	_draw.queue_redraw()

func _chest(c: Vector2, prog: float, open: bool) -> void:
	## Little pixel treasure chest in the reel track with a fill ring below it.
	var r := Rect2(c - Vector2(7, 5), Vector2(14, 10))
	_draw.draw_rect(r.grow(1), Color(0.18, 0.1, 0.04))
	_draw.draw_rect(r, Color(0.62, 0.38, 0.16))
	_draw.draw_rect(Rect2(r.position, Vector2(14, 4)), Color(0.76, 0.5, 0.22) if not open else Color(1.0, 0.86, 0.35))
	_draw.draw_rect(Rect2(r.position + Vector2(0, 4), Vector2(14, 1)), Color(0.85, 0.68, 0.25))
	_draw.draw_rect(Rect2(c - Vector2(1, 1), Vector2(2, 3)), Color(0.95, 0.82, 0.3))
	if open:
		_draw.draw_rect(Rect2(c - Vector2(5, 9), Vector2(10, 3)), Color(1.0, 0.95, 0.5, 0.9))   # gold gleam
	else:
		_draw.draw_rect(Rect2(c + Vector2(-8, 7), Vector2(16, 2)), Color(0, 0, 0, 0.6))
		_draw.draw_rect(Rect2(c + Vector2(-8, 7), Vector2(16 * clampf(prog, 0.0, 1.0), 2)), Color(1.0, 0.8, 0.25))

func _on_draw() -> void:
	var s := fishing.state
	if s == Fishing.State.IDLE:
		return
	var font := ThemeDB.fallback_font
	var msg := ""
	match s:
		Fishing.State.WAITING: msg = "Waiting..."
		Fishing.State.BITE: msg = "BITE!  Click / F"
		Fishing.State.REELING: msg = "Hold to lift the bar"
	if msg != "":
		var w := font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 14.0
		var x0 := 320.0 - w * 0.5
		_draw.draw_rect(Rect2(x0, 40, w, 20), Color(0.1, 0.06, 0.03, 0.8))
		_draw.draw_string(font, Vector2(x0 + 7, 55), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.95, 0.5))
	if s == Fishing.State.REELING:
		var x := 556.0
		var top := 76.0
		var h := 208.0
		_draw.draw_rect(Rect2(x - 6, top - 8, 56, h + 16), Color(0.16, 0.1, 0.06))
		_draw.draw_rect(Rect2(x - 4, top - 6, 52, h + 12), Color(0.43, 0.29, 0.17))
		_draw.draw_rect(Rect2(x, top, 20, h), Color(0.05, 0.17, 0.27))
		for i in 8:  # depth ticks
			_draw.draw_rect(Rect2(x + 14, top + i * h / 8.0, 6, 1), Color(1, 1, 1, 0.15))
		var bh := h * fishing.bar_size
		var by := top + (1.0 - fishing.bar) * h - bh / 2.0
		var hit := fishing.overlapping()
		_draw.draw_rect(Rect2(x + 1, by, 18, bh), Color(0.35, 0.85, 0.4, 0.85) if hit else Color(0.35, 0.7, 0.4, 0.55))
		_draw.draw_rect(Rect2(x + 1, by, 18, bh), Color(0.8, 1, 0.8), false, 1.0)
		if fishing.treasure_on or fishing.treasure_got:
			_chest(Vector2(x + 10, top + (1.0 - fishing.treasure_pos) * h), fishing.treasure_prog, fishing.treasure_got)
		var fi := int(icons.get(fishing.fish_id, icons.get("minnow", 6)))
		var fy := top + (1.0 - fishing.fish_pos) * h - 8.0
		_draw.draw_texture_rect_region(item_tex, Rect2(x + 2, fy, 16, 16), Rect2(fi * 16, 0, 16, 16))
		_draw.draw_rect(Rect2(x + 26, top, 7, h), Color(0.05, 0.1, 0.15))
		var ph := h * fishing.progress
		_draw.draw_rect(Rect2(x + 27, top + h - ph, 5, ph), Color(1.0, 0.82, 0.2) if fishing.progress < 0.8 else Color(0.5, 1.0, 0.4))
