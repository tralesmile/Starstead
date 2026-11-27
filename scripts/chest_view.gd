class_name ChestView
extends CanvasLayer
## Storage chest screen: chest grid on top, bag below. Left-click a stack to send it to the other side, Shift+click moves every stack of that item.

signal closed
const COLS := WoodUI.GRID_COLS
const CELL := WoodUI.GRID_CELL
const CHEST_ORIGIN := WoodUI.CHEST_GRID
const BAG_ORIGIN := WoodUI.CHEST_BAG_GRID
var canvas: Control
var items: Dictionary = DataDB.load_json("items")
var icons: Dictionary = DataDB.load_json("item_icons")
var item_tex: Texture2D = load("res://assets/sprites/items.png")

func _init() -> void:
	layer = 9
	canvas = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	WoodUI.text(canvas, origin + Vector2(0, -5), title, 11)
	var hover := Inventory.slot_at(canvas.get_local_mouse_position(), origin, CELL, COLS, inv.slots.size())
	for i in inv.slots.size():
		var r := WoodUI.grid_slot_rect(origin, i)
		WoodUI.slot(canvas, r, i == hover)
		var s = inv.slots[i]
		if s != null:
			canvas.draw_texture_rect_region(item_tex, Rect2(r.position + Vector2(5, 3), Vector2(16, 16)), Rect2(int(icons.get(s.id, 0)) * 16, 0, 16, 16))
			var rar := String(items.get(s.id, {}).get("rarity", ""))
			if ItemInfo.has_border(rar):
				canvas.draw_rect(r.grow(-1), ItemInfo.border_color(rar), false, 2.0)
			if int(s.n) > 1:
				WoodUI.count_badge(canvas, r, int(s.n))
		WoodUI.slot_mark(canvas, r, i == hover, false)

func _draw_all() -> void:
	WoodUI.panel(canvas, WoodUI.chest_window(GameState.bag.slots.size()), "Farmhouse storage", WoodUI.Trim.IRON)
	_grid(GameState.chest, CHEST_ORIGIN, "Storage chest")
	_grid(GameState.bag, BAG_ORIGIN, "Bag")
	var gy := BAG_ORIGIN.y + WoodUI.grid_rows(GameState.bag.slots.size()) * CELL
	WoodUI.text(canvas, Vector2(BAG_ORIGIN.x, gy + 13), "Click: move stack   Shift+click: move all of that item", 10, WoodUI.INK, WoodUI.GRID_W, HORIZONTAL_ALIGNMENT_CENTER)
	WoodUI.text(canvas, Vector2(BAG_ORIGIN.x, gy + 26), KeyBinds.hint("E / Esc: close"), 10, WoodUI.INK_SOFT, WoodUI.GRID_W, HORIZONTAL_ALIGNMENT_CENTER)
