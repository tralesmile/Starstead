class_name InventoryView
extends CanvasLayer
## Tab / I opens the bag: 10x3 slot grid with icons and counts, hover tooltip (name, sell price),
## click a slot then another to move/merge/swap, S sorts, X or Delete throws the picked slot away.

signal closed
signal ate(name: String, gained: int)
const COLS := 10
const CELL := 28.0
const ORIGIN := Vector2(140, 96)
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
	var w := COLS * CELL + 20.0
	var rows := ceili(float(bag.slots.size()) / COLS)
	var h := rows * CELL + 92.0
	var panel := Rect2(ORIGIN - Vector2(10, 34), Vector2(w, h))
	canvas.draw_rect(panel.grow(2), Color(0.16, 0.1, 0.06))
	canvas.draw_rect(panel, Color(0.36, 0.24, 0.14, 0.97))
	canvas.draw_string(font, ORIGIN + Vector2(0, -16), "Bag   $%d   Energy %d" % [GameState.money, int(GameState.energy.value)], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.95, 0.7))
	var by := ORIGIN.y + rows * CELL + 28.0
	for si in SkillModel.SKILLS.size():
		var sk: String = SkillModel.SKILLS[si]
		var xp := int(GameState.skill_xp.get(sk, 0))
		var bx := ORIGIN.x + si * 68.0
		canvas.draw_string(font, Vector2(bx, by), "%s %d" % [sk.capitalize(), SkillModel.level(xp)], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, LevelFxMath.skill_color(sk))
		canvas.draw_rect(Rect2(bx, by + 3, 60, 4), Color(0.1, 0.06, 0.04))
		canvas.draw_rect(Rect2(bx, by + 3, 60.0 * LevelFxMath.bar_fill(xp), 4), LevelFxMath.skill_color(sk))
	var hover := _slot_under_mouse()
	for i in bag.slots.size():
		var r := Rect2(ORIGIN + Vector2((i % COLS) * CELL, (i / COLS) * CELL), Vector2(CELL - 2, CELL - 2))
		canvas.draw_rect(r, Color(0.22, 0.14, 0.08, 0.95) if i >= Inventory.HOTBAR or true else Color.BLACK)
		var s = bag.slots[i]
		if s != null:
			canvas.draw_texture_rect_region(item_tex, Rect2(r.position + Vector2(5, 3), Vector2(16, 16)), Rect2(int(icons.get(s.id, 0)) * 16, 0, 16, 16))
			if int(s.n) > 1:
				canvas.draw_string(font, r.position + Vector2(0, CELL - 5), str(s.n), HORIZONTAL_ALIGNMENT_RIGHT, CELL - 4, 9, Color(1, 1, 1))
		if s != null:
			var rar := String(items.get(s.id, {}).get("rarity", ""))
			if ItemInfo.has_border(rar):
				canvas.draw_rect(r.grow(-1), ItemInfo.border_color(rar), false, 1.0)
		if i == picked:
			canvas.draw_rect(r.grow(1), Color(1.0, 0.85, 0.2), false, 2.0)
		elif i == hover:
			canvas.draw_rect(r, Color(1, 1, 1, 0.8), false, 1.0)
	var hint := "Click a slot, then another to move/swap   Right-click: eat   S sort   X trash   Tab close"
	canvas.draw_string(font, ORIGIN + Vector2(0, rows * CELL + 10), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1, 1, 1, 0.8))
	if hover >= 0 and bag.slots[hover] != null:
		var id: String = bag.slots[hover].id
		var def: Dictionary = items.get(id, {})
		var line := "%s  (sells $%d)" % [ItemInfo.display_name(def, int(bag.slots[hover].n)), int(def.get("price", 0))]
		var m := canvas.get_local_mouse_position() + Vector2(10, 12)
		canvas.draw_rect(Rect2(m, Vector2(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x + 8, 16)), Color(0.05, 0.03, 0.02, 0.95))
		canvas.draw_string(font, m + Vector2(4, 12), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1))
