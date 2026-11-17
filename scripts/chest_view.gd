class_name ChestView
extends CanvasLayer
## Storage chest screen: chest grid on top, bag below. Left-click a stack to send it to the other side, Shift+click moves every stack of that item.

signal closed
const COLS := 10
const CELL := 28.0
const CHEST_ORIGIN := Vector2(140, 50)
const BAG_ORIGIN := Vector2(140, 170)
var canvas: Control
var items: Dictionary = DataDB.load_json("items")
var icons: Dictionary = DataDB.load_json("item_icons")
var item_tex: Texture2D = load("res://assets/sprites/items.png")

func _init() -> void:
	layer = 9
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.draw.connect(_draw_all)
	add_child(canvas)
	visible = false

func open() -> void:
	visible = true

func close() -> void:
	visible = false
	closed.emit()

func _process(_d: float) -> void:
	if visible:
		canvas.size = get_viewport().get_visible_rect().size
		canvas.queue_redraw()

func handle(e: InputEvent) -> bool:
	if not visible:
		return false
	if e.is_action_pressed("pause") or e.is_action_pressed("inventory") or e.is_action_pressed("interact"):
		close()
		return true
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var p := canvas.get_local_mouse_position()
		var ci := Inventory.slot_at(p, CHEST_ORIGIN, CELL, COLS, GameState.chest.slots.size())
		var bi := Inventory.slot_at(p, BAG_ORIGIN, CELL, COLS, GameState.bag.slots.size())
		var shift := Input.is_key_pressed(KEY_SHIFT)
		if ci >= 0 and GameState.chest.slots[ci] != null:
			if shift:
				ChestModel.move_all_of(GameState.chest, GameState.bag, GameState.chest.slots[ci]["id"])
			else:
				ChestModel.quick_move(GameState.chest, GameState.bag, ci)
		elif bi >= 0 and GameState.bag.slots[bi] != null:
			if shift:
				ChestModel.move_all_of(GameState.bag, GameState.chest, GameState.bag.slots[bi]["id"])
			else:
				ChestModel.quick_move(GameState.bag, GameState.chest, bi)
	return true

func _grid(inv: Inventory, origin: Vector2, title: String) -> void:
	var font := ThemeDB.fallback_font
	canvas.draw_string(font, origin + Vector2(0, -6), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 0.95, 0.7))
	var hover := Inventory.slot_at(canvas.get_local_mouse_position(), origin, CELL, COLS, inv.slots.size())
	for i in inv.slots.size():
		var r := Rect2(origin + Vector2((i % COLS) * CELL, (i / COLS) * CELL), Vector2(CELL - 2, CELL - 2))
		canvas.draw_rect(r, Color(0.22, 0.14, 0.08, 0.95))
		var s = inv.slots[i]
		if s != null:
			canvas.draw_texture_rect_region(item_tex, Rect2(r.position + Vector2(5, 3), Vector2(16, 16)), Rect2(int(icons.get(s.id, 0)) * 16, 0, 16, 16))
			if int(s.n) > 1:
				canvas.draw_string(font, r.position + Vector2(0, CELL - 5), str(s.n), HORIZONTAL_ALIGNMENT_RIGHT, CELL - 4, 9, Color(1, 1, 1))
			var rar := String(items.get(s.id, {}).get("rarity", ""))
			if ItemInfo.has_border(rar):
				canvas.draw_rect(r.grow(-1), ItemInfo.border_color(rar), false, 1.0)
		if i == hover:
			canvas.draw_rect(r, Color(1, 1, 1, 0.8), false, 1.0)

func _draw_all() -> void:
	var font := ThemeDB.fallback_font
	var panel := Rect2(Vector2(130, 18), Vector2(COLS * CELL + 20.0, 300))
	canvas.draw_rect(panel.grow(2), Color(0.16, 0.1, 0.06))
	canvas.draw_rect(panel, Color(0.36, 0.24, 0.14, 0.97))
	_grid(GameState.chest, CHEST_ORIGIN, "Storage chest")
	_grid(GameState.bag, BAG_ORIGIN, "Bag")
	canvas.draw_string(font, Vector2(140, 300), "Click: move stack   Shift+click: move all of that item   E / Esc: close", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.8))
