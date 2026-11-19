class_name CraftView
extends CookView
## Crafting menu (C): turn wood into the tools you do not own yet. Same layout as the stove menu.

var tool_tex: Texture2D = load("res://assets/sprites/held_tools.png")

func _init() -> void:
	super._init()
	recipes = DataDB.load_json("crafting")
	title = "Craft tools - click a tool or press its number"
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

func _draw_all() -> void:
	var font := ThemeDB.fallback_font
	var ids := recipes.keys()
	var panel := Rect2(ORIGIN - Vector2(10, 34), Vector2(360, 60.0 + ids.size() * ROW))
	canvas.draw_rect(panel.grow(2), Color(0.16, 0.1, 0.06))
	canvas.draw_rect(panel, Color(0.36, 0.24, 0.14, 0.97))
	canvas.draw_string(font, ORIGIN + Vector2(0, -16), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.95, 0.7))
	var hover := int((canvas.get_local_mouse_position() - ORIGIN).y / ROW) if canvas.get_local_mouse_position().x > ORIGIN.x else -1
	for i in ids.size():
		var r: Dictionary = recipes[ids[i]]
		var y := ORIGIN.y + i * ROW
		var have: bool = String(r["makes"]) in GameState.tools_owned
		var ok := CookModel.can_cook(GameState.bag, r) and not have
		canvas.draw_rect(Rect2(ORIGIN.x, y, 340, ROW - 3), Color(0.3, 0.2, 0.12, 0.95) if i != hover else Color(0.42, 0.29, 0.17, 0.95))
		canvas.draw_texture_rect_region(tool_tex, Rect2(ORIGIN.x + 4, y + 6, 20, 20), Rect2(maxi(ToolUse.held_frame(r["makes"]), 0) * 16, 0, 16, 16), Color.WHITE if ok or have else Color(1, 1, 1, 0.45))
		canvas.draw_string(font, Vector2(ORIGIN.x + 30, y + 13), "%d. %s%s" % [(i + 1) % 10, r["name"], "   (owned)" if have else ""], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1) if ok or have else Color(0.7, 0.65, 0.6))
		canvas.draw_string(font, Vector2(ORIGIN.x + 30, y + 25), CookModel.ingredient_text(GameState.bag, r), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.75, 0.95, 0.7) if ok else Color(0.9, 0.6, 0.55))
	canvas.draw_string(font, ORIGIN + Vector2(0, 14 + ids.size() * ROW), msg if msg != "" else footer, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 0.8))
