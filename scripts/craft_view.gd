class_name CraftView
extends CookView
## Crafting menu (C): turn wood into the tools you do not own yet. Same layout as the stove menu.

var tool_tex: Texture2D = load("res://assets/sprites/held_tools.png")


func _init() -> void:
	super._init()
	recipes = DataDB.load_json("crafting")
	title = "Craft - click a recipe or press its number"
	footer = "Chop trees with the axe for wood.   C / Esc: close"

func _try(i: int) -> void:
	var ids := recipes.keys()
	if i < 0 or i >= ids.size():
		return
	var r: Dictionary = recipes[ids[i]]
	msg = ToolKit.craft(GameState.tools_owned, r, GameState.bag)
	if msg == "":
		msg = "Crafted %s!" % r["name"]
		cooked.emit(String(r["name"]))

func handle(e: InputEvent) -> bool:
	if visible and e is InputEventKey and e.pressed and not e.echo and e.keycode == KEY_C:
		close()
		return true
	return super.handle(e)

func _try_at(p: Vector2) -> void:
	_try(CraftGrid.index_at(p, recipes.size()))

func _draw_all() -> void:
	var font := ThemeDB.fallback_font
	var ids := recipes.keys()
	var panel := CraftGrid.panel_rect(ids.size())
	canvas.draw_rect(panel.grow(2), Color(0.16, 0.1, 0.06))
	canvas.draw_rect(panel, Color(0.36, 0.24, 0.14, 0.97))
	canvas.draw_string(font, CraftGrid.GRID + Vector2(0, -12), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.95, 0.7))
	var hover := CraftGrid.index_at(canvas.get_local_mouse_position(), ids.size())
	for i in ids.size():
		var r: Dictionary = recipes[ids[i]]
		var cr := CraftGrid.cell_rect(i)
		var o := cr.position
		var is_item := bool(r.get("item", false))
		var have: bool = not is_item and String(r["makes"]) in GameState.tools_owned
		var ok := CookModel.can_cook(GameState.bag, r) and not have
		canvas.draw_rect(cr, Color(0.3, 0.2, 0.12, 0.95) if i != hover else Color(0.42, 0.29, 0.17, 0.95))
		var tint := Color.WHITE if ok or have else Color(1, 1, 1, 0.45)
		if is_item:
			canvas.draw_texture_rect_region(item_tex, Rect2(o + Vector2(4, 4), Vector2(20, 20)), Rect2(int(icons.get(String(r["makes"]), 0)) * 16, 0, 16, 16), tint)
		else:
			canvas.draw_texture_rect_region(tool_tex, Rect2(o + Vector2(4, 4), Vector2(20, 20)), Rect2(maxi(ToolUse.held_frame(r["makes"]), 0) * 16, 0, 16, 16), tint)
		var num := "%d. " % ((i + 1) % 10) if i < 10 else ""
		canvas.draw_string(font, o + Vector2(30, 12), "%s%s%s" % [num, r["name"], "  (owned)" if have else ""], HORIZONTAL_ALIGNMENT_LEFT, CraftGrid.CELL.x - 38, 9, Color(1, 1, 1) if ok or have else Color(0.7, 0.65, 0.6))
		canvas.draw_string(font, o + Vector2(30, 23), CookModel.ingredient_text(GameState.bag, r), HORIZONTAL_ALIGNMENT_LEFT, CraftGrid.CELL.x - 38, 8, Color(0.75, 0.95, 0.7) if ok else Color(0.9, 0.6, 0.55))
	canvas.draw_string(font, Vector2(CraftGrid.GRID.x, panel.end.y - 8), msg if msg != "" else footer, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 0.8))
