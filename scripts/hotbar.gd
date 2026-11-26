class_name Hotbar
extends CanvasLayer
## Bottom-centre hotbar: icon slots (tools from held_tools.png, seeds from items.png), counts,
## selected slot highlighted, name of the selected tool above. Keys 1-9,0 or the mouse wheel select.

const SLOT := 28
const GAP := 2
var selected := 0
var seed_ids: Array = []   # every seed in crops.json; the seed slot plants the chosen one
var seed_idx := 0
const PLACEABLES := ["sprinkler", "crab_pot", "snare", "fertiliser", "scarecrow"]   # slot 0 holds both; press its key again to switch
var place_idx := 0
var melee_idx := 0   # the club slot switches to the bow once you own one (press 8 again)
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
	return slot_tool(selected)

func slot_tool(i: int) -> String:
	## The seed slot stands for whichever seed is chosen (press its key again to cycle).
	var t: String = ToolUse.TOOLS[i]
	if t == "turnip_seed" and not seed_ids.is_empty():
		return seed_ids[seed_idx % seed_ids.size()]
	if t == "sprinkler":
		return PLACEABLES[place_idx % PLACEABLES.size()]
	if t == "club":
		return ToolKit.melee_tool(melee_idx, GameState.tools_owned)
	return t

func cycle_seed() -> void:
	## Next seed you actually carry; if you carry none, just the next type.
	if seed_ids.is_empty():
		return
	for k in range(1, seed_ids.size() + 1):
		var j := (seed_idx + k) % seed_ids.size()
		if GameState.bag.count(seed_ids[j]) > 0:
			seed_idx = j
			return
	seed_idx = (seed_idx + 1) % seed_ids.size()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		var i := TargetMath.key_slot(e.keycode)
		if i >= 0 and i < ToolUse.TOOLS.size():
			if i == selected and ToolUse.TOOLS[i] == "turnip_seed":
				cycle_seed()
			elif i == selected and ToolUse.TOOLS[i] == "sprinkler":
				place_idx = (place_idx + 1) % PLACEABLES.size()
			elif i == selected and ToolUse.TOOLS[i] == "club":
				melee_idx += 1
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
	# wooden tray behind the slots (same plank frame as the HUD panel)
	var tray := Rect2(x0 - 5, y0 - 4, total + 10, SLOT + 8)
	canvas.draw_rect(tray.grow(1), Color(0.13, 0.08, 0.04, 0.95))
	canvas.draw_rect(tray, Color(0.55, 0.34, 0.17))
	canvas.draw_rect(Rect2(tray.position, Vector2(tray.size.x, 1)), Color(0.73, 0.49, 0.26))
	canvas.draw_rect(Rect2(tray.position + Vector2(0, tray.size.y - 1), Vector2(tray.size.x, 1)), Color(0.36, 0.21, 0.1))
	for i in n:
		var sel := i == selected
		var r := Rect2(x0 + i * (SLOT + GAP), y0 - (2.0 if sel else 0.0), SLOT, SLOT)   # the picked slot lifts a little
		# inset slot: dark rim on top/left (shadow), lit rim bottom/right, warm inner
		canvas.draw_rect(r, Color(0.30, 0.18, 0.08))
		canvas.draw_rect(Rect2(r.position + Vector2(1, 1), r.size - Vector2(1, 1)), Color(0.80, 0.62, 0.38) if sel else Color(0.66, 0.47, 0.26))
		canvas.draw_rect(Rect2(r.position + Vector2(2, 2), r.size - Vector2(3, 3)), Color(0.96, 0.88, 0.66) if sel else Color(0.86, 0.74, 0.52))
		canvas.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 3, 1)), Color(0.70, 0.56, 0.36))
		var t: String = slot_tool(i)
		_icon(t, r)
		if not ToolKit.owns(GameState.tools_owned, t):
			canvas.draw_rect(Rect2(r.position + Vector2(2, 2), r.size - Vector2(3, 3)), Color(0.18, 0.12, 0.07, 0.62))
		canvas.draw_string(font, r.position + Vector2(3, 9), str((i + 1) % 10), HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.36, 0.22, 0.1, 0.9))
		if t == "watering_can":
			var f := GameState.can.fraction()
			canvas.draw_rect(Rect2(r.position + Vector2(3, SLOT - 5), Vector2(SLOT - 6, 3)), Color(0.2, 0.14, 0.08, 0.8))
			canvas.draw_rect(Rect2(r.position + Vector2(3, SLOT - 5), Vector2((SLOT - 6) * f, 3)), Color(0.35, 0.7, 1.0))
		if t.ends_with("_seed") or t in PLACEABLES or t == "bow":
			var cnt := str(GameState.bag.count("arrow" if t == "bow" else t))
			var w := font.get_string_size(cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
			var p := r.position + Vector2(SLOT - 2 - w, SLOT - 2)
			for o in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				canvas.draw_string(font, p + o, cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.2, 0.12, 0.05))
			canvas.draw_string(font, p, cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1))
		if sel:
			canvas.draw_rect(r.grow(1), Color(1.0, 0.82, 0.25), false, 2.0)
			canvas.draw_rect(r.grow(2.5), Color(0.35, 0.2, 0.05, 0.6), false, 1.0)
	# name tag above the picked slot
	var name := String(current()).replace("_", " ").capitalize()
	var nw := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var sx := x0 + selected * (SLOT + GAP) + SLOT * 0.5
	var tag := Rect2(clampf(sx - nw * 0.5 - 4, 2.0, canvas.size.x - nw - 10), y0 - 20, nw + 8, 13)
	canvas.draw_rect(tag.grow(1), Color(0.13, 0.08, 0.04, 0.95))
	canvas.draw_rect(tag, Color(0.94, 0.87, 0.68))
	canvas.draw_string(font, tag.position + Vector2(4, 10), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.24, 0.15, 0.08))

func _icon(t: String, r: Rect2) -> void:
	var dst := Rect2(r.position + Vector2(6, 6), Vector2(16, 16))
	var f := ToolUse.held_frame(t)
	if f >= 0:
		canvas.draw_texture_rect_region(tool_tex, dst, Rect2(f * 16, 0, 16, 16))
	elif icons.has(t) or icons.has(t.trim_suffix("_seed") + "_seed"):
		var fi := int(icons.get(t, 0))
		canvas.draw_texture_rect_region(item_tex, dst, Rect2(fi * 16, 0, 16, 16))
	else:
		canvas.draw_string(ThemeDB.fallback_font, r.position + Vector2(5, 18), "hand" if t == "hand" else "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.3, 0.18, 0.08))
