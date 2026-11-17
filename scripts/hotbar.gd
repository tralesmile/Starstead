class_name Hotbar
extends CanvasLayer
## Bottom-centre hotbar: icon slots (tools from held_tools.png, seeds from items.png), counts,
## selected slot highlighted, name of the selected tool above. Keys 1-9,0 or the mouse wheel select.

const SLOT := 28
const GAP := 2
var selected := 0
var canvas: Control
var tool_tex: Texture2D = load("res://assets/sprites/held_tools.png")
var item_tex: Texture2D = load("res://assets/sprites/items.png")
var icons: Dictionary = DataDB.load_json("item_icons")

func _init() -> void:
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_bar)
	add_child(canvas)

func current() -> String:
	return ToolUse.TOOLS[selected]

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		var i := TargetMath.key_slot(e.keycode)
		if i >= 0 and i < ToolUse.TOOLS.size():
			selected = i

func _process(_d: float) -> void:
	canvas.size = get_viewport().get_visible_rect().size
	canvas.queue_redraw()

func _draw_bar() -> void:
	var n := ToolUse.TOOLS.size()
	var total := n * SLOT + (n - 1) * GAP
	var x0 := (canvas.size.x - total) * 0.5
	var y0 := canvas.size.y - SLOT - 16.0
	var font := ThemeDB.fallback_font
	for i in n:
		var r := Rect2(x0 + i * (SLOT + GAP), y0, SLOT, SLOT)
		var sel := i == selected
		canvas.draw_rect(r.grow(1), Color(0.16, 0.1, 0.06, 0.95))
		canvas.draw_rect(r, Color(0.43, 0.29, 0.17, 0.92) if not sel else Color(0.62, 0.43, 0.24, 0.96))
		canvas.draw_rect(Rect2(r.position + Vector2(2, 2), r.size - Vector2(4, 4)), Color(0.26, 0.17, 0.1, 0.9))
		var t: String = ToolUse.TOOLS[i]
		_icon(t, r)
		canvas.draw_string(font, r.position + Vector2(3, 10), str((i + 1) % 10), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.75))
		if t == "watering_can":
			var f := GameState.can.fraction()
			canvas.draw_rect(Rect2(r.position + Vector2(3, SLOT - 5), Vector2(SLOT - 6, 3)), Color(0, 0, 0, 0.7))
			canvas.draw_rect(Rect2(r.position + Vector2(3, SLOT - 5), Vector2((SLOT - 6) * f, 3)), Color(0.35, 0.7, 1.0))
		if t.ends_with("_seed"):
			canvas.draw_string(font, r.position + Vector2(SLOT - 13, SLOT - 3), str(GameState.bag.count(t)), HORIZONTAL_ALIGNMENT_RIGHT, 12, 9, Color(1, 1, 1))
		if sel:
			canvas.draw_rect(r.grow(2), Color(1.0, 0.85, 0.2), false, 2.0)
	var name := String(ToolUse.TOOLS[selected]).replace("_", " ").capitalize()
	canvas.draw_string(font, Vector2(x0, y0 - 4), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.95, 0.7))

func _icon(t: String, r: Rect2) -> void:
	var dst := Rect2(r.position + Vector2(6, 6), Vector2(16, 16))
	var f := ToolUse.held_frame(t)
	if f >= 0:
		canvas.draw_texture_rect_region(tool_tex, dst, Rect2(f * 16, 0, 16, 16))
	elif icons.has(t) or icons.has(t.trim_suffix("_seed") + "_seed"):
		var fi := int(icons.get(t, 0))
		canvas.draw_texture_rect_region(item_tex, dst, Rect2(fi * 16, 0, 16, 16))
	else:
		canvas.draw_string(ThemeDB.fallback_font, r.position + Vector2(5, 18), "hand" if t == "hand" else "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.9))
