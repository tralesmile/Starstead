class_name CookView
extends CanvasLayer
## Kitchen stove menu: click a recipe (or press its number) to cook it from the bag.

signal closed
signal cooked(name: String)
var canvas: Control
var recipes: Dictionary = DataDB.load_json("recipes")
var items: Dictionary = DataDB.load_json("items")
var icons: Dictionary = DataDB.load_json("item_icons")
var item_tex: Texture2D = load("res://assets/sprites/items.png")
var msg := ""
const ORIGIN := Vector2(150, 60)
const ROW := 34.0

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
	msg = ""

func close() -> void:
	visible = false
	closed.emit()

func _process(_d: float) -> void:
	if visible:
		canvas.size = get_viewport().get_visible_rect().size
		canvas.queue_redraw()

func _try(i: int) -> void:
	var ids := recipes.keys()
	if i < 0 or i >= ids.size():
		return
	var r: Dictionary = recipes[ids[i]]
	if CookModel.cook(GameState.bag, r):
		msg = "Cooked %s!" % r["name"]
		cooked.emit(String(r["name"]))
	elif CookModel.can_cook(GameState.bag, r):
		msg = "Your bag is full"
	else:
		msg = "Missing ingredients"

func handle(e: InputEvent) -> bool:
	if not visible:
		return false
	if e.is_action_pressed("pause") or e.is_action_pressed("inventory") or e.is_action_pressed("interact"):
		close()
		return true
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var p := canvas.get_local_mouse_position() - ORIGIN
		if p.x >= 0.0 and p.x < 340.0 and p.y >= 0.0:
			_try(int(p.y / ROW))
	elif e is InputEventKey and e.pressed and not e.echo:
		var k := TargetMath.key_slot(e.keycode)
		if k >= 0:
			_try(k)
	return true

func _draw_all() -> void:
	var font := ThemeDB.fallback_font
	var ids := recipes.keys()
	var panel := Rect2(ORIGIN - Vector2(10, 34), Vector2(360, 60.0 + ids.size() * ROW))
	canvas.draw_rect(panel.grow(2), Color(0.16, 0.1, 0.06))
	canvas.draw_rect(panel, Color(0.36, 0.24, 0.14, 0.97))
	canvas.draw_string(font, ORIGIN + Vector2(0, -16), "Kitchen - click a dish or press its number", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.95, 0.7))
	var hover := int((canvas.get_local_mouse_position() - ORIGIN).y / ROW) if canvas.get_local_mouse_position().x > ORIGIN.x else -1
	for i in ids.size():
		var r: Dictionary = recipes[ids[i]]
		var y := ORIGIN.y + i * ROW
		var ok := CookModel.can_cook(GameState.bag, r)
		canvas.draw_rect(Rect2(ORIGIN.x, y, 340, ROW - 3), Color(0.3, 0.2, 0.12, 0.95) if i != hover else Color(0.42, 0.29, 0.17, 0.95))
		canvas.draw_texture_rect_region(item_tex, Rect2(ORIGIN.x + 4, y + 6, 20, 20), Rect2(int(icons.get(r["makes"], 0)) * 16, 0, 16, 16), Color.WHITE if ok else Color(1, 1, 1, 0.45))
		canvas.draw_string(font, Vector2(ORIGIN.x + 30, y + 13), "%d. %s   (+%d energy)" % [(i + 1) % 10, r["name"], int(items.get(r["makes"], {}).get("energy", 0))], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 1) if ok else Color(0.7, 0.65, 0.6))
		canvas.draw_string(font, Vector2(ORIGIN.x + 30, y + 25), CookModel.ingredient_text(GameState.bag, r), HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.75, 0.95, 0.7) if ok else Color(0.9, 0.6, 0.55))
	canvas.draw_string(font, ORIGIN + Vector2(0, 14 + ids.size() * ROW), msg if msg != "" else "Right-click a dish in your bag (Tab) to eat it.   E / Esc: leave", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 1, 0.8))
