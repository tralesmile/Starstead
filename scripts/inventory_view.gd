class_name InventoryView
extends CanvasLayer
## Tab / I opens the bag: 10x3 slot grid with icons and counts, hover tooltip (name, sell price),
## click a slot then another to move/merge/swap, S sorts, X or Delete throws the picked slot away.

signal closed
signal ate(name: String, gained: int)
const COLS := WoodUI.GRID_COLS
const CELL := WoodUI.GRID_CELL
const ORIGIN := WoodUI.BAG_GRID
var canvas: Control
var picked := -1
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

func toggle() -> void:
	visible = not visible
	picked = -1
	if not visible:
		closed.emit()

func _process(_d: float) -> void:
	if visible:
		canvas.size = get_viewport().get_visible_rect().size
		canvas.queue_redraw()

func _slot_under_mouse() -> int:
	return Inventory.slot_at(canvas.get_local_mouse_position(), ORIGIN, CELL, COLS, GameState.bag.slots.size())

func handle(e: InputEvent) -> bool:
	## Returns true when the event was consumed (the bag is open).
	if e.is_action_pressed("inventory"):
		toggle()
		return true
	if not visible:
		return false
	if e.is_action_pressed("pause"):
		toggle()
		return true
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
		var ri := _slot_under_mouse()
		if ri >= 0 and GameState.bag.slots[ri] != null:
			var id: String = GameState.bag.slots[ri].id
			var gained := CookModel.eat(GameState.bag, items, GameState.energy, id, GameState.home.eat_mult())
			if gained >= 0:
				ate.emit(String(items[id].name), gained)
		return true
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var i := _slot_under_mouse()
		if i >= 0:
			if picked < 0:
				if GameState.bag.slots[i] != null:
					picked = i
			else:
				GameState.bag.swap(picked, i)
				picked = -1
		else:
			picked = -1
	elif e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_S:
			GameState.bag.sort()
			picked = -1
		elif (e.keycode == KEY_X or e.keycode == KEY_DELETE) and picked >= 0:
			GameState.bag.trash(picked)
			picked = -1
	return true

func _draw_all() -> void:
	var font := ThemeDB.fallback_font
	var bag := GameState.bag
	var perk := not PerkModel.pending(GameState.skill_xp, GameState.perks).is_empty()
	var panel := WoodUI.bag_window(bag.slots.size(), perk)
	WoodUI.panel(canvas, panel, "Bag", WoodUI.Trim.SAWDUST)
	WoodUI.plank_note(canvas, panel, "$%d    Energy %d" % [GameState.money, int(GameState.energy.value)])
	var hover := _slot_under_mouse()
	for i in bag.slots.size():
		var r := WoodUI.grid_slot_rect(ORIGIN, i)
		WoodUI.slot(canvas, r, i == hover, i == picked)
		var s = bag.slots[i]
		if s != null:
			canvas.draw_texture_rect_region(item_tex, Rect2(r.position + Vector2(5, 3), Vector2(16, 16)), Rect2(int(icons.get(s.id, 0)) * 16, 0, 16, 16))
			var rar := String(items.get(s.id, {}).get("rarity", ""))
			if ItemInfo.has_border(rar):
				canvas.draw_rect(r.grow(-1), ItemInfo.border_color(rar), false, 2.0)
			if int(s.n) > 1:
				WoodUI.count_badge(canvas, r, int(s.n))
		WoodUI.slot_mark(canvas, r, i == hover, i == picked)
	var gy := ORIGIN.y + WoodUI.grid_rows(bag.slots.size()) * CELL
	for si in SkillModel.SKILLS.size():
		var sk: String = SkillModel.SKILLS[si]
		var xp := int(GameState.skill_xp.get(sk, 0))
		var bx := ORIGIN.x + si * 71.0
		WoodUI.text(canvas, Vector2(bx, gy + 11), "%s %d" % [sk.capitalize(), SkillModel.level(xp)], 10, WoodUI.INK, 66)
		canvas.draw_rect(Rect2(bx, gy + 15, 65, 6), WoodUI.OUTLINE)
		canvas.draw_rect(Rect2(bx + 1, gy + 16, 63.0 * LevelFxMath.bar_fill(xp), 4), LevelFxMath.skill_color(sk))
	canvas.draw_rect(Rect2(ORIGIN.x, gy + 26, WoodUI.GRID_W, 1), Color(0.36, 0.21, 0.10, 0.5))
	WoodUI.text(canvas, Vector2(ORIGIN.x, gy + 37), "Click a slot, then another: move / swap", 10, WoodUI.INK, WoodUI.GRID_W, HORIZONTAL_ALIGNMENT_CENTER)
	WoodUI.text(canvas, Vector2(ORIGIN.x, gy + 49), "Right-click: eat   S: sort   X: trash   %s: close" % KeyBinds.label("inventory"), 10, WoodUI.INK_SOFT, WoodUI.GRID_W, HORIZONTAL_ALIGNMENT_CENTER)
	if perk:
		WoodUI.text(canvas, Vector2(ORIGIN.x, gy + 62), "P: choose a perk", 10, WoodUI.GOOD, WoodUI.GRID_W, HORIZONTAL_ALIGNMENT_CENTER)
	if hover >= 0 and bag.slots[hover] != null:
		var id: String = bag.slots[hover].id
		var def: Dictionary = items.get(id, {})
		var line := "%s  (sells $%d)" % [ItemInfo.display_name(def, int(bag.slots[hover].n)), int(def.get("price", 0))]
		var tip := WoodUI.tooltip_rect(canvas.get_local_mouse_position(), font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x, canvas.size)
		canvas.draw_rect(tip.grow(2), WoodUI.OUTLINE)
		canvas.draw_rect(tip.grow(1), WoodUI.WOOD)
		canvas.draw_rect(tip, WoodUI.PAPER)
		WoodUI.text(canvas, tip.position + Vector2(5, 13), line, 10)
