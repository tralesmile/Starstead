class_name JournalView
extends CanvasLayer
## J opens the fish journal: every species with icon (silhouette until caught), count, best size and where to find it.

var canvas: Control
var table: Dictionary = DataDB.load_json("fish")
var icons: Dictionary = DataDB.load_json("item_icons")
var tex: Texture2D = load("res://assets/sprites/items.png")
signal closed

func _init() -> void:
	layer = 9
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false

func toggle() -> void:
	visible = not visible
	if not visible:
		closed.emit()

func handle(e: InputEvent) -> bool:
	if e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_J:
		toggle()
		return true
	if visible and (e.is_action_pressed("pause") or e.is_action_pressed("inventory")):
		toggle()
		return true
	return visible and (e is InputEventKey or e is InputEventMouseButton)

func _process(_d: float) -> void:
	if visible:
		canvas.size = get_viewport().get_visible_rect().size
		canvas.queue_redraw()

func _draw_all() -> void:
	var font := ThemeDB.fallback_font
	var rows := FishJournal.rows(table, GameState.journal.entries)
	var origin := Vector2(120, 70)
	var panel := Rect2(origin - Vector2(10, 30), Vector2(400, 46.0 + rows.size() * 28.0))
	canvas.draw_rect(panel.grow(2), Color(0.16, 0.1, 0.06))
	canvas.draw_rect(panel, Color(0.24, 0.34, 0.4, 0.97))
	canvas.draw_string(font, origin + Vector2(0, -12), "Fish journal   %d/%d species" % [GameState.journal.species_caught(), table.size()], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.9, 1, 1))
	for i in rows.size():
		var r: Dictionary = rows[i]
		var y := origin.y + i * 28.0
		canvas.draw_rect(Rect2(origin.x, y, 380, 26), Color(0.1, 0.16, 0.2, 0.9))
		var ir := Rect2(origin.x + 4, y + 5, 16, 16)
		var col := Color.WHITE if r["caught"] else Color(0.0, 0.0, 0.0, 0.7)
		canvas.draw_texture_rect_region(tex, ir, Rect2(int(icons.get(r["id"], 0)) * 16, 0, 16, 16), col)
		canvas.draw_string(font, Vector2(origin.x + 28, y + 11), String(r["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1) if r["caught"] else Color(0.7, 0.8, 0.85))
		canvas.draw_string(font, Vector2(origin.x + 28, y + 22), "%s water, %s" % [String(r["depth"]).capitalize(), r["seasons"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.7, 0.85, 0.9))
		if r["caught"]:
			canvas.draw_string(font, Vector2(origin.x + 200, y + 16), "caught %d   best %d cm" % [r["count"], r["best"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.95, 0.6))
		else:
			canvas.draw_string(font, Vector2(origin.x + 200, y + 16), "not caught yet", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.7, 0.75))
	canvas.draw_string(font, origin + Vector2(0, 8 + rows.size() * 28.0), "J or Esc to close", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.8))
