class_name FishingView
extends CanvasLayer
## Minimal fishing UI: status text while waiting/biting, vertical reel track while reeling.

var fishing: Fishing
var _draw: Control

func _init(f: Fishing) -> void:
	fishing = f
	layer = 5
	_draw = Control.new()
	_draw.draw.connect(_on_draw)
	_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_draw)

func _process(_d: float) -> void:
	_draw.queue_redraw()

func _on_draw() -> void:
	var s := fishing.state
	if s == Fishing.State.IDLE:
		return
	var font := ThemeDB.fallback_font
	var msg := ""
	match s:
		Fishing.State.WAITING: msg = "Waiting..."
		Fishing.State.BITE: msg = "BITE! Press F"
		Fishing.State.REELING: msg = "Hold F to lift the bar"
	if msg != "":
		_draw.draw_string(font, Vector2(260, 60), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.95, 0.5))
	if s == Fishing.State.REELING:
		var x := 560.0
		var top := 80.0
		var h := 200.0
		_draw.draw_rect(Rect2(x, top, 18, h), Color(0.05, 0.15, 0.25, 0.8))
		var bh := h * Fishing.BAR_SIZE
		var by := top + (1.0 - fishing.bar) * h - bh / 2.0
		_draw.draw_rect(Rect2(x + 1, by, 16, bh), Color(0.4, 0.9, 0.4, 0.8))
		_draw.draw_rect(Rect2(x + 5, top + (1.0 - fishing.fish_pos) * h - 4, 8, 8), Color(1, 0.6, 0.2))
		_draw.draw_rect(Rect2(x + 22, top + h * (1.0 - fishing.progress), 5, h * fishing.progress), Color(1, 0.85, 0.2))
