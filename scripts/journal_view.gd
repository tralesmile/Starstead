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
	var rows := FishJournal.rows(table, GameState.journal.entries)
	var panel := FishJournal.PANEL
	WoodUI.panel(canvas, panel, "Fish journal   %d/%d species" % [GameState.journal.species_caught(), table.size()])
	for i in rows.size():
		var r: Dictionary = rows[i]
		var cell := FishJournal.cell_rect(i, rows.size())
		var legend := bool(table[r["id"]].get("legendary", false))
		WoodUI.row(canvas, cell, false, r["caught"])
		if legend:
			canvas.draw_rect(Rect2(cell.position, Vector2(3, cell.size.y)), Color(0.93, 0.68, 0.12))
		var ir := Rect2(cell.position + Vector2(7, 6), Vector2(16, 16))
		WoodUI.icon_well(canvas, ir.grow(3))
		var col := Color.WHITE if r["caught"] else Color(0.0, 0.0, 0.0, 0.7)
		canvas.draw_texture_rect_region(tex, ir, Rect2(int(icons.get(r["id"], 0)) * 16, 0, 16, 16), col)
		var place := "%s %s, %s" % [String(r["depth"]).capitalize(), "sea" if bool(table[r["id"]].get("sea", false)) else "lake", r["seasons"]]
		WoodUI.text(canvas, cell.position + Vector2(32, 13), String(r["name"]), 10, WoodUI.INK if r["caught"] else WoodUI.INK_SOFT)
		WoodUI.text(canvas, cell.position + Vector2(32, 25), ("Legendary - " + place) if legend else place, 8, WoodUI.INK_SOFT)
		if r["caught"]:
			WoodUI.text(canvas, cell.position + Vector2(180, 19), "x%d  best %d cm" % [r["count"], r["best"]], 10, WoodUI.GOOD, 104, HORIZONTAL_ALIGNMENT_RIGHT)
		else:
			WoodUI.text(canvas, cell.position + Vector2(180, 19), "not yet", 9, WoodUI.INK_SOFT, 104, HORIZONTAL_ALIGNMENT_RIGHT)
	WoodUI.text(canvas, Vector2(panel.position.x, panel.end.y - 8), "J or Esc to close", 9, WoodUI.INK_SOFT, panel.size.x, HORIZONTAL_ALIGNMENT_CENTER)
